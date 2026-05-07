-- =================================================================
-- CARBON CONNECT: PRODUCTION MASTER DATABASE SETUP (FINAL VERSION)
-- =================================================================

-- 1. EXTENSIONS & PERMISSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- 2. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id),
  phone text UNIQUE,
  full_name text,
  email text,
  location text,
  role text CHECK (role = ANY (ARRAY['BUYER'::text, 'SELLER'::text])),
  kyc_status text DEFAULT 'PENDING'::text CHECK (kyc_status = ANY (ARRAY['PENDING'::text, 'VERIFIED'::text, 'REJECTED'::text])),
  fcm_token text,
  created_at timestamp with time zone DEFAULT now()
);

-- Ensure all columns exist for existing users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS full_name text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS location text;

-- 3. KYC DOCUMENTS TABLE
CREATE TABLE IF NOT EXISTS public.kyc_documents (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.users(id),
  doc_type text CHECK (doc_type = ANY (ARRAY['PAN'::text, 'AADHAAR'::text, 'BANK'::text])),
  doc_url text,
  status text DEFAULT 'PENDING'::text CHECK (status = ANY (ARRAY['PENDING'::text, 'VERIFIED'::text, 'REJECTED'::text])),
  verified_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now()
);

-- 4. BANK DETAILS TABLE
CREATE TABLE IF NOT EXISTS public.bank_details (
  user_id uuid NOT NULL PRIMARY KEY REFERENCES public.users(id),
  bank_name text NOT NULL,
  account_number text NOT NULL,
  ifsc_code text NOT NULL,
  account_holder_name text NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);

-- 5. WALLETS TABLE
CREATE TABLE IF NOT EXISTS public.wallets (
  user_id uuid NOT NULL PRIMARY KEY REFERENCES public.users(id),
  inr_balance numeric DEFAULT 0.00,
  ccc_balance integer DEFAULT 0,
  unsettled_balance numeric DEFAULT 0.00,
  updated_at timestamp with time zone DEFAULT now()
);

-- 6. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.users(id),
  type text CHECK (type IN ('DEPOSIT','WITHDRAWAL','TRADE_CREDIT','TRADE_DEBIT')),
  amount numeric NOT NULL,
  status text DEFAULT 'COMPLETED' CHECK (status IN ('PENDING','COMPLETED','FAILED')),
  description text,
  reference_id text,
  created_at timestamp with time zone DEFAULT now()
);

-- 7. ORDERS TABLE
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.users(id),
  type text CHECK (type = ANY (ARRAY['BUY'::text, 'SELL'::text])),
  price numeric NOT NULL,
  quantity integer NOT NULL,
  status text DEFAULT 'OPEN'::text CHECK (status = ANY (ARRAY['OPEN'::text, 'MATCHED'::text, 'CANCELLED'::text])),
  created_at timestamp with time zone DEFAULT now()
);

-- 8. TRADES TABLE
CREATE TABLE IF NOT EXISTS public.trades (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  buy_order_id uuid REFERENCES public.orders(id),
  sell_order_id uuid REFERENCES public.orders(id),
  buyer_id uuid REFERENCES public.users(id),
  seller_id uuid REFERENCES public.users(id),
  price numeric NOT NULL,
  quantity integer NOT NULL,
  executed_at timestamp with time zone DEFAULT now()
);

-- 9. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.users(id),
  title text,
  body text,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now()
);

-- =================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Dynamic Policies (Users can only see their own data)
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can view own data" ON users;
    CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
    
    DROP POLICY IF EXISTS "Users can insert own kyc" ON kyc_documents;
    CREATE POLICY "Users can insert own kyc" ON kyc_documents FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Users can manage own bank" ON bank_details;
    CREATE POLICY "Users can manage own bank" ON bank_details FOR ALL TO authenticated USING (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Users can view own wallet" ON wallets;
    CREATE POLICY "Users can view own wallet" ON wallets FOR SELECT TO authenticated USING (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
    CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT TO authenticated USING (auth.uid() = user_id);
END $$;

-- =================================================================
-- TRIGGERS & FUNCTIONS
-- =================================================================

-- 1. AUTO-SYNC AUTH.USERS -> PUBLIC.USERS
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, phone, role, kyc_status)
  VALUES (NEW.id, NEW.email, NEW.phone, 'BUYER', 'PENDING')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. AUTO-CREATE WALLET
CREATE OR REPLACE FUNCTION public.create_wallet_for_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.wallets (user_id, inr_balance, ccc_balance)
  VALUES (NEW.id, 0.00, 0)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_user_created_wallet ON public.users;
CREATE TRIGGER on_user_created_wallet
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.create_wallet_for_user();

-- =================================================================
-- REALTIME SETUP
-- =================================================================
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE public.notifications, public.wallets, public.orders, public.transactions;
COMMIT;

-- FINAL GRANTS
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
