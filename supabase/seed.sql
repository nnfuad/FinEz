-- ==============================================================================
-- Seed: synthetic test data for development and testing
-- Project: FinEz — Financial Management for Somiti
-- Note: Synthetic data only. No real personal or banking credentials.
-- ==============================================================================

-- 1. Synthetic Bank Accounts
INSERT INTO public.bank_accounts (id, account_name, bank_name, account_number, opening_balance, is_active)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'Somiti General Fund', 'Sonali Bank PLC', 'SB-1002938471', 150000.00, true),
    ('22222222-2222-2222-2222-222222222222', 'Somiti Emergency Reserve', 'Islami Bank Bangladesh PLC', 'IB-9876543210', 75000.00, true)
ON CONFLICT (id) DO NOTHING;

-- 2. Synthetic Members
INSERT INTO public.members (id, member_code, full_name, mobile, address, monthly_installment, is_active)
VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'FM-0001', 'Md. Abdul Karim', '01711000001', 'House 12, Road 4, Sector 3, Uttara, Dhaka', 2000.00, true),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'FM-0002', 'Rahima Begum', '01811000002', 'Flat 4B, Green View Tower, Mirpur-10, Dhaka', 2000.00, true),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'FM-0003', 'Tanvir Hasan', '01911000003', 'Holding 45, Shahid Minar Road, Dhanmondi, Dhaka', 2500.00, true),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'FM-0004', 'Nusrat Jahan', '01511000004', 'Plot 10, Block C, Bashundhara R/A, Dhaka', 2000.00, true),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'FM-0005', 'Kamal Uddin', '01611000005', 'Station Road, Mymensingh Sadar, Mymensingh', 1500.00, false)
ON CONFLICT (id) DO NOTHING;

-- 3. Synthetic Installments for Oct 2026
INSERT INTO public.installments (id, member_id, period_month, amount_due, status)
VALUES
    ('10000001-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2026-10-01', 2000.00, 'paid'),
    ('10000002-0000-0000-0000-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '2026-10-01', 2000.00, 'partial'),
    ('10000003-0000-0000-0000-000000000003', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '2026-10-01', 2500.00, 'due'),
    ('10000004-0000-0000-0000-000000000004', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '2026-10-01', 2000.00, 'due')
ON CONFLICT (member_id, period_month) DO NOTHING;

-- 4. Synthetic Payments
INSERT INTO public.payments (id, installment_id, member_id, bank_account_id, amount, payment_date, reference)
VALUES
    ('p1111111-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 2000.00, '2026-10-10', 'Sonali Bank Deposit Slip #8821'),
    ('p2222222-0000-0000-0000-000000000002', '10000002-0000-0000-0000-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 1000.00, '2026-10-15', 'Partial cash deposit to account')
ON CONFLICT (id) DO NOTHING;

-- 5. Corresponding Financial Transactions
INSERT INTO public.financial_transactions (bank_account_id, tx_type, amount, transaction_date, description, related_payment_id)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'installment_receipt', 2000.00, '2026-10-10', 'Installment receipt for Md. Abdul Karim (FM-0001) - Oct 2026', 'p1111111-0000-0000-0000-000000000001'),
    ('11111111-1111-1111-1111-111111111111', 'installment_receipt', 1000.00, '2026-10-15', 'Installment receipt for Rahima Begum (FM-0002) - Oct 2026', 'p2222222-0000-0000-0000-000000000002')
ON CONFLICT (id) DO NOTHING;
