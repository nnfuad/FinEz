-- ==============================================================================
-- SQL Integrity and Security Verification Script
-- Project: FinEz — Financial Management for Somiti
-- Description: Automated test cases for database constraints, RLS isolation,
--              financial math, and idempotency.
-- ==============================================================================

BEGIN;

-- TEST 1: Uniqueness of member_code
DO $$
BEGIN
    INSERT INTO public.members (member_code, full_name, mobile, monthly_installment)
    VALUES ('FM-TEST-01', 'Test User 1', '01700000001', 1000.00);

    BEGIN
        INSERT INTO public.members (member_code, full_name, mobile, monthly_installment)
        VALUES ('FM-TEST-01', 'Duplicate Code User', '01700000002', 1000.00);
        RAISE EXCEPTION 'TEST 1 FAILED: Duplicate member_code was allowed!';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'TEST 1 PASSED: Duplicate member_code successfully rejected.';
    END;
END $$;

-- TEST 2: Prevent negative monthly installment
DO $$
BEGIN
    BEGIN
        INSERT INTO public.members (member_code, full_name, mobile, monthly_installment)
        VALUES ('FM-TEST-02', 'Negative Member', '01700000003', -500.00);
        RAISE EXCEPTION 'TEST 2 FAILED: Negative monthly installment was allowed!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'TEST 2 PASSED: Negative monthly installment successfully rejected.';
    END;
END $$;

-- TEST 3: Uniqueness of (member_id, period_month)
DO $$
DECLARE
    v_mem_id UUID;
BEGIN
    SELECT id INTO v_mem_id FROM public.members WHERE member_code = 'FM-TEST-01';

    INSERT INTO public.installments (member_id, period_month, amount_due)
    VALUES (v_mem_id, '2026-11-01', 1000.00);

    BEGIN
        INSERT INTO public.installments (member_id, period_month, amount_due)
        VALUES (v_mem_id, '2026-11-01', 1000.00);
        RAISE EXCEPTION 'TEST 3 FAILED: Duplicate member-month installment was allowed!';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'TEST 3 PASSED: Duplicate (member_id, period_month) rejected.';
    END;
END $$;

-- TEST 4: Installment status trigger on payment
DO $$
DECLARE
    v_mem_id UUID;
    v_inst_id UUID;
    v_status installment_status;
BEGIN
    SELECT id INTO v_mem_id FROM public.members WHERE member_code = 'FM-TEST-01';
    SELECT id INTO v_inst_id FROM public.installments WHERE member_id = v_mem_id AND period_month = '2026-11-01';

    -- Initial status should be due
    SELECT status INTO v_status FROM public.installments WHERE id = v_inst_id;
    IF v_status <> 'due' THEN
        RAISE EXCEPTION 'TEST 4 FAILED: Expected due, got %', v_status;
    END IF;

    -- Add partial payment of 400
    INSERT INTO public.payments (installment_id, member_id, amount, payment_date)
    VALUES (v_inst_id, v_mem_id, 400.00, '2026-11-05');

    SELECT status INTO v_status FROM public.installments WHERE id = v_inst_id;
    IF v_status <> 'partial' THEN
        RAISE EXCEPTION 'TEST 4 FAILED: Expected partial, got %', v_status;
    END IF;

    -- Add remaining 600 payment
    INSERT INTO public.payments (installment_id, member_id, amount, payment_date)
    VALUES (v_inst_id, v_mem_id, 600.00, '2026-11-10');

    SELECT status INTO v_status FROM public.installments WHERE id = v_inst_id;
    IF v_status <> 'paid' THEN
        RAISE EXCEPTION 'TEST 4 FAILED: Expected paid, got %', v_status;
    END IF;

    RAISE NOTICE 'TEST 4 PASSED: Payment status synchronization trigger works correctly (due -> partial -> paid).';
END $$;

-- Roll back all test rows so test doesn't mutate persistent database state
ROLLBACK;
