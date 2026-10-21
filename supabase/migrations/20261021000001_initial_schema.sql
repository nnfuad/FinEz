-- ==============================================================================
-- Migration: 20261021000001_initial_schema.sql
-- Project: FinEz — Financial Management for Somiti
-- Description: Core tables, foreign keys, check constraints, RLS policies,
--              audit logging, ledger triggers, and secure database functions.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMS & DOMAINS
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('ADMIN', 'MEMBER');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE installment_status AS ENUM ('due', 'partial', 'paid', 'waived');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_type AS ENUM (
        'installment_receipt',
        'income',
        'expense',
        'transfer_in',
        'transfer_out',
        'adjustment'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. TABLES

-- Table: members
CREATE TABLE IF NOT EXISTS public.members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_code TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    mobile TEXT NOT NULL,
    address TEXT,
    monthly_installment NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (monthly_installment >= 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Table: profiles (Authenticated accounts linked to members)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    member_id UUID UNIQUE REFERENCES public.members(id) ON DELETE SET NULL,
    role user_role NOT NULL DEFAULT 'MEMBER',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Table: bank_accounts
CREATE TABLE IF NOT EXISTS public.bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_name TEXT NOT NULL,
    bank_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    opening_balance NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Table: installments
CREATE TABLE IF NOT EXISTS public.installments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE RESTRICT,
    period_month DATE NOT NULL, -- Stored as the 1st of the month (e.g. 2026-10-01)
    amount_due NUMERIC(12,2) NOT NULL CHECK (amount_due >= 0),
    status installment_status NOT NULL DEFAULT 'due',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_member_period UNIQUE (member_id, period_month)
);

-- Table: payments
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    installment_id UUID NOT NULL REFERENCES public.installments(id) ON DELETE RESTRICT,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE RESTRICT,
    bank_account_id UUID REFERENCES public.bank_accounts(id) ON DELETE RESTRICT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL,
    recorded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reference TEXT,
    correction_reason TEXT,
    is_corrected BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Table: financial_transactions (Authoritative Bank Ledger)
CREATE TABLE IF NOT EXISTS public.financial_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_account_id UUID NOT NULL REFERENCES public.bank_accounts(id) ON DELETE RESTRICT,
    tx_type transaction_type NOT NULL,
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    transaction_date DATE NOT NULL,
    description TEXT,
    related_payment_id UUID REFERENCES public.payments(id) ON DELETE CASCADE,
    related_transfer_id UUID,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Table: audit_logs (Immutable Administrative Trail)
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    old_values JSONB,
    new_values JSONB,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Table: import_batches
CREATE TABLE IF NOT EXISTS public.import_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    import_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'completed',
    summary JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_members_code ON public.members(member_code);
CREATE INDEX IF NOT EXISTS idx_members_mobile ON public.members(mobile);
CREATE INDEX IF NOT EXISTS idx_installments_member_period ON public.installments(member_id, period_month);
CREATE INDEX IF NOT EXISTS idx_installments_period ON public.installments(period_month);
CREATE INDEX IF NOT EXISTS idx_payments_installment ON public.payments(installment_id);
CREATE INDEX IF NOT EXISTS idx_payments_member ON public.payments(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON public.payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_fin_tx_bank ON public.financial_transactions(bank_account_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON public.audit_logs(entity_type, entity_id);

-- 5. VIEWS
-- Public Member Directory View (Names only, no private phone/balance/address)
CREATE OR REPLACE VIEW public.public_members_view AS
SELECT
    id,
    member_code,
    full_name,
    is_active
FROM public.members
WHERE is_active = true;

-- Bank Balance Reconciliation View
CREATE OR REPLACE VIEW public.bank_balances_view AS
SELECT
    ba.id,
    ba.bank_name,
    ba.account_name,
    ba.account_number,
    ba.opening_balance,
    ba.is_active,
    ba.opening_balance + COALESCE(SUM(
        CASE
            WHEN ft.tx_type IN ('installment_receipt', 'income', 'transfer_in') THEN ft.amount
            WHEN ft.tx_type IN ('expense', 'transfer_out') THEN -ft.amount
            ELSE 0
        END
    ), 0.00) AS current_balance,
    COALESCE(SUM(CASE WHEN ft.tx_type IN ('installment_receipt', 'income', 'transfer_in') THEN ft.amount ELSE 0 END), 0.00) AS total_inflow,
    COALESCE(SUM(CASE WHEN ft.tx_type IN ('expense', 'transfer_out') THEN ft.amount ELSE 0 END), 0.00) AS total_outflow
FROM public.bank_accounts ba
LEFT JOIN public.financial_transactions ft ON ft.bank_account_id = ba.id
GROUP BY ba.id, ba.bank_name, ba.account_name, ba.account_number, ba.opening_balance, ba.is_active;

-- 6. SECURITY DEFINER HELPER FUNCTIONS (Restricted Search Path)

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'ADMIN'
    );
$$;

CREATE OR REPLACE FUNCTION public.current_member_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT member_id FROM public.profiles
    WHERE id = auth.uid();
$$;

-- 7. TRIGGERS

-- Automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_members_updated_at ON public.members;
CREATE TRIGGER trg_members_updated_at
BEFORE UPDATE ON public.members
FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_bank_accounts_updated_at ON public.bank_accounts;
CREATE TRIGGER trg_bank_accounts_updated_at
BEFORE UPDATE ON public.bank_accounts
FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_installments_updated_at ON public.installments;
CREATE TRIGGER trg_installments_updated_at
BEFORE UPDATE ON public.installments
FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_payments_updated_at ON public.payments;
CREATE TRIGGER trg_payments_updated_at
BEFORE UPDATE ON public.payments
FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

-- Recalculate Installment Status on Payment Changes
CREATE OR REPLACE FUNCTION public.fn_sync_installment_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_inst_id UUID;
    v_total_paid NUMERIC(12,2);
    v_amount_due NUMERIC(12,2);
    v_current_status installment_status;
BEGIN
    v_inst_id := COALESCE(NEW.installment_id, OLD.installment_id);

    SELECT amount_due, status INTO v_amount_due, v_current_status
    FROM public.installments
    WHERE id = v_inst_id;

    IF v_current_status = 'waived' THEN
        RETURN NEW;
    END IF;

    SELECT COALESCE(SUM(amount), 0.00) INTO v_total_paid
    FROM public.payments
    WHERE installment_id = v_inst_id AND is_corrected = false;

    IF v_total_paid >= v_amount_due AND v_amount_due > 0 THEN
        UPDATE public.installments
        SET status = 'paid', updated_at = timezone('utc'::text, now())
        WHERE id = v_inst_id;
    ELSIF v_total_paid > 0 THEN
        UPDATE public.installments
        SET status = 'partial', updated_at = timezone('utc'::text, now())
        WHERE id = v_inst_id;
    ELSE
        UPDATE public.installments
        SET status = 'due', updated_at = timezone('utc'::text, now())
        WHERE id = v_inst_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payments_sync_installment ON public.payments;
CREATE TRIGGER trg_payments_sync_installment
AFTER INSERT OR UPDATE OR DELETE ON public.payments
FOR EACH ROW EXECUTE FUNCTION public.fn_sync_installment_status();

-- 8. ROW LEVEL SECURITY (RLS) POLICIES

ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.import_batches ENABLE ROW LEVEL SECURITY;

-- Policy: profiles
CREATE POLICY "Users can read own profile"
ON public.profiles FOR SELECT
TO authenticated
USING (id = auth.uid() OR public.is_admin());

CREATE POLICY "Admins can manage all profiles"
ON public.profiles FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Policy: members
CREATE POLICY "Admins full access to members"
ON public.members FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Members can view only their own member record"
ON public.members FOR SELECT
TO authenticated
USING (id = public.current_member_id());

-- Policy: installments
CREATE POLICY "Admins full access to installments"
ON public.installments FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Members can view only their own installments"
ON public.installments FOR SELECT
TO authenticated
USING (member_id = public.current_member_id());

-- Policy: payments
CREATE POLICY "Admins full access to payments"
ON public.payments FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Members can view only their own payments"
ON public.payments FOR SELECT
TO authenticated
USING (member_id = public.current_member_id());

-- Policy: bank_accounts (Admins Only)
CREATE POLICY "Admins full access to bank accounts"
ON public.bank_accounts FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Policy: financial_transactions (Admins Only)
CREATE POLICY "Admins full access to financial transactions"
ON public.financial_transactions FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Policy: audit_logs (Admins Only - Read Only via UI, Inserted via trusted functions)
CREATE POLICY "Admins can read audit logs"
ON public.audit_logs FOR SELECT
TO authenticated
USING (public.is_admin());

CREATE POLICY "Admins can insert audit logs"
ON public.audit_logs FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

-- Policy: import_batches (Admins Only)
CREATE POLICY "Admins full access to import batches"
ON public.import_batches FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- 9. TRANSACTION-SAFE RPC OPERATIONS

-- RPC: Record a payment atomically with bank ledger and audit trail
CREATE OR REPLACE FUNCTION public.record_payment_with_ledger(
    p_installment_id UUID,
    p_member_id UUID,
    p_bank_account_id UUID,
    p_amount NUMERIC,
    p_payment_date DATE,
    p_reference TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_payment_id UUID;
    v_admin_id UUID;
    v_member_name TEXT;
    v_member_code TEXT;
    v_period DATE;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Administrator privileges required.';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Payment amount must be greater than zero.';
    END IF;

    v_admin_id := auth.uid();

    SELECT full_name, member_code INTO v_member_name, v_member_code
    FROM public.members WHERE id = p_member_id;

    SELECT period_month INTO v_period
    FROM public.installments WHERE id = p_installment_id;

    -- 1. Insert Payment Record
    INSERT INTO public.payments (
        installment_id,
        member_id,
        bank_account_id,
        amount,
        payment_date,
        recorded_by,
        reference
    ) VALUES (
        p_installment_id,
        p_member_id,
        p_bank_account_id,
        p_amount,
        p_payment_date,
        v_admin_id,
        p_reference
    ) RETURNING id INTO v_payment_id;

    -- 2. If bank account specified, insert into financial ledger
    IF p_bank_account_id IS NOT NULL THEN
        INSERT INTO public.financial_transactions (
            bank_account_id,
            tx_type,
            amount,
            transaction_date,
            description,
            related_payment_id,
            created_by
        ) VALUES (
            p_bank_account_id,
            'installment_receipt',
            p_amount,
            p_payment_date,
            'Installment receipt for ' || v_member_name || ' (' || v_member_code || ') - ' || to_char(v_period, 'Mon YYYY'),
            v_payment_id,
            v_admin_id
        );
    END IF;

    -- 3. Write Audit Log
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        entity_type,
        entity_id,
        new_values,
        reason
    ) VALUES (
        v_admin_id,
        'RECORD_PAYMENT',
        'payments',
        v_payment_id::text,
        jsonb_build_object(
            'installment_id', p_installment_id,
            'member_id', p_member_id,
            'amount', p_amount,
            'payment_date', p_payment_date,
            'bank_account_id', p_bank_account_id,
            'reference', p_reference
        ),
        'Regular installment payment recorded'
    );

    RETURN v_payment_id;
END;
$$;

-- RPC: Correct an erroneous payment with full audit preservation
CREATE OR REPLACE FUNCTION public.correct_payment_with_audit(
    p_payment_id UUID,
    p_new_amount NUMERIC,
    p_new_date DATE,
    p_new_bank_id UUID,
    p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_old_payment RECORD;
    v_admin_id UUID;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Administrator privileges required.';
    END IF;

    IF p_reason IS NULL OR trim(p_reason) = '' THEN
        RAISE EXCEPTION 'Correction reason is mandatory.';
    END IF;

    v_admin_id := auth.uid();

    SELECT * INTO v_old_payment FROM public.payments WHERE id = p_payment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment record not found.';
    END IF;

    -- 1. Update Payment Record
    UPDATE public.payments
    SET
        amount = p_new_amount,
        payment_date = p_new_date,
        bank_account_id = p_new_bank_id,
        correction_reason = p_reason,
        is_corrected = true,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_payment_id;

    -- 2. Update matching financial transaction if exists
    IF p_new_bank_id IS NOT NULL THEN
        UPDATE public.financial_transactions
        SET
            bank_account_id = p_new_bank_id,
            amount = p_new_amount,
            transaction_date = p_new_date,
            description = description || ' (Corrected: ' || p_reason || ')'
        WHERE related_payment_id = p_payment_id;
    END IF;

    -- 3. Write Audit Log
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        entity_type,
        entity_id,
        old_values,
        new_values,
        reason
    ) VALUES (
        v_admin_id,
        'CORRECT_PAYMENT',
        'payments',
        p_payment_id::text,
        jsonb_build_object(
            'amount', v_old_payment.amount,
            'payment_date', v_old_payment.payment_date,
            'bank_account_id', v_old_payment.bank_account_id
        ),
        jsonb_build_object(
            'amount', p_new_amount,
            'payment_date', p_new_date,
            'bank_account_id', p_new_bank_id
        ),
        p_reason
    );
END;
$$;

-- RPC: Generate monthly installments for all active members (Duplicate-Safe)
CREATE OR REPLACE FUNCTION public.generate_monthly_installments(
    p_target_month DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_norm_month DATE;
    v_member RECORD;
    v_generated_count INT := 0;
    v_skipped_count INT := 0;
    v_admin_id UUID;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Administrator privileges required.';
    END IF;

    v_admin_id := auth.uid();
    -- Normalize target month to 1st of month
    v_norm_month := date_trunc('month', p_target_month)::date;

    FOR v_member IN
        SELECT id, monthly_installment FROM public.members WHERE is_active = true
    LOOP
        -- Insert if not existing (idempotent / duplicate-safe)
        IF NOT EXISTS (
            SELECT 1 FROM public.installments
            WHERE member_id = v_member.id AND period_month = v_norm_month
        ) THEN
            INSERT INTO public.installments (
                member_id,
                period_month,
                amount_due,
                status
            ) VALUES (
                v_member.id,
                v_norm_month,
                v_member.monthly_installment,
                'due'
            );
            v_generated_count := v_generated_count + 1;
        ELSE
            v_skipped_count := v_skipped_count + 1;
        END IF;
    END LOOP;

    -- Audit log
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        entity_type,
        entity_id,
        new_values,
        reason
    ) VALUES (
        v_admin_id,
        'GENERATE_INSTALLMENTS',
        'installments',
        v_norm_month::text,
        jsonb_build_object(
            'period_month', v_norm_month,
            'generated_count', v_generated_count,
            'skipped_count', v_skipped_count
        ),
        'Generated monthly installments'
    );

    RETURN jsonb_build_object(
        'period_month', v_norm_month,
        'generated_count', v_generated_count,
        'skipped_count', v_skipped_count
    );
END;
$$;

-- RPC: Inter-Account Bank Transfer (Safe, no double counting)
CREATE OR REPLACE FUNCTION public.transfer_bank_funds(
    p_source_account_id UUID,
    p_target_account_id UUID,
    p_amount NUMERIC,
    p_transfer_date DATE,
    p_description TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_transfer_id UUID := gen_random_uuid();
    v_admin_id UUID;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Administrator privileges required.';
    END IF;

    IF p_source_account_id = p_target_account_id THEN
        RAISE EXCEPTION 'Source and target bank accounts must be different.';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be greater than zero.';
    END IF;

    v_admin_id := auth.uid();

    -- Outflow from source account
    INSERT INTO public.financial_transactions (
        bank_account_id,
        tx_type,
        amount,
        transaction_date,
        description,
        related_transfer_id,
        created_by
    ) VALUES (
        p_source_account_id,
        'transfer_out',
        p_amount,
        p_transfer_date,
        'Transfer to target account: ' || COALESCE(p_description, ''),
        v_transfer_id,
        v_admin_id
    );

    -- Inflow to target account
    INSERT INTO public.financial_transactions (
        bank_account_id,
        tx_type,
        amount,
        transaction_date,
        description,
        related_transfer_id,
        created_by
    ) VALUES (
        p_target_account_id,
        'transfer_in',
        p_amount,
        p_transfer_date,
        'Transfer from source account: ' || COALESCE(p_description, ''),
        v_transfer_id,
        v_admin_id
    );

    -- Audit Log
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        entity_type,
        entity_id,
        new_values,
        reason
    ) VALUES (
        v_admin_id,
        'TRANSFER_FUNDS',
        'financial_transactions',
        v_transfer_id::text,
        jsonb_build_object(
            'source_account_id', p_source_account_id,
            'target_account_id', p_target_account_id,
            'amount', p_amount,
            'transfer_date', p_transfer_date,
            'description', p_description
        ),
        'Inter-account bank fund transfer'
    );

    RETURN v_transfer_id;
END;
$$;

-- RPC: Setup first admin safely (Idempotent initial setup)
CREATE OR REPLACE FUNCTION public.setup_initial_admin(
    p_admin_email TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_admin_count INT;
BEGIN
    SELECT count(*) INTO v_admin_count FROM public.profiles WHERE role = 'ADMIN';

    -- Only allow if no admin exists yet OR caller is already an admin
    IF v_admin_count > 0 AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Initial admin already configured. Unauthorized.';
    END IF;

    SELECT id INTO v_user_id FROM auth.users WHERE email = p_admin_email;
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User with email % does not exist in auth.users. Please sign up first.', p_admin_email;
    END IF;

    INSERT INTO public.profiles (id, role)
    VALUES (v_user_id, 'ADMIN')
    ON CONFLICT (id) DO UPDATE SET role = 'ADMIN', updated_at = timezone('utc'::text, now());

    RETURN 'User ' || p_admin_email || ' is now configured as ADMIN.';
END;
$$;
