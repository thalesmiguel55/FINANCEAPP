-- ============================================================
-- FINANCEAPP - SUPABASE SCHEMA
-- Execute este arquivo no SQL Editor do Supabase.
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- PROFILES
-- Espelha auth.users com os dados publicos usados pelo app.
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text not null default '',
  avatar_url text,
  monthly_income numeric(15, 2) not null default 0 check (monthly_income >= 0),
  monthly_budget numeric(15, 2) not null default 0 check (monthly_budget >= 0),
  currency text not null default 'BRL',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ============================================================
-- TRANSACTIONS
-- Receitas e despesas do usuario.
-- ============================================================
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  amount numeric(15, 2) not null check (amount > 0),
  type text not null check (type in ('income', 'expense')),
  category text not null,
  description text,
  date timestamptz not null,
  is_recurring boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_user_id on public.transactions(user_id);
create index if not exists idx_transactions_user_date on public.transactions(user_id, date desc);
create index if not exists idx_transactions_user_type on public.transactions(user_id, type);
create index if not exists idx_transactions_user_category on public.transactions(user_id, category);

alter table public.transactions enable row level security;

drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own"
  on public.transactions for select
  using (auth.uid() = user_id);

drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own"
  on public.transactions for insert
  with check (auth.uid() = user_id);

drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own"
  on public.transactions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own"
  on public.transactions for delete
  using (auth.uid() = user_id);

-- ============================================================
-- INVESTMENTS
-- Carteira de investimentos do usuario.
-- ============================================================
create table if not exists public.investments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  symbol text not null,
  name text not null,
  quantity numeric(15, 6) not null check (quantity > 0),
  average_price numeric(15, 6) not null check (average_price > 0),
  purchase_date timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_investments_user_id on public.investments(user_id);
create index if not exists idx_investments_user_symbol on public.investments(user_id, symbol);

alter table public.investments enable row level security;

drop policy if exists "investments_select_own" on public.investments;
create policy "investments_select_own"
  on public.investments for select
  using (auth.uid() = user_id);

drop policy if exists "investments_insert_own" on public.investments;
create policy "investments_insert_own"
  on public.investments for insert
  with check (auth.uid() = user_id);

drop policy if exists "investments_update_own" on public.investments;
create policy "investments_update_own"
  on public.investments for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "investments_delete_own" on public.investments;
create policy "investments_delete_own"
  on public.investments for delete
  using (auth.uid() = user_id);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists set_transactions_updated_at on public.transactions;
create trigger set_transactions_updated_at
  before update on public.transactions
  for each row execute function public.set_updated_at();

drop trigger if exists set_investments_updated_at on public.investments;
create trigger set_investments_updated_at
  before update on public.investments
  for each row execute function public.set_updated_at();

-- ============================================================
-- AUTH USER -> PROFILE
-- Cria o perfil automaticamente quando o usuario se cadastra.
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'name', '')
  )
  on conflict (id) do update
    set email = excluded.email,
        name = coalesce(nullif(excluded.name, ''), public.profiles.name),
        updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- MONTHLY SUMMARY
-- Resumo mensal usado para consultas e relatorios.
-- ============================================================
create or replace view public.monthly_summary as
select
  user_id,
  date_trunc('month', date) as month,
  sum(case when type = 'income' then amount else 0 end) as total_income,
  sum(case when type = 'expense' then amount else 0 end) as total_expenses,
  sum(case when type = 'income' then amount else -amount end) as balance,
  count(*) as total_transactions
from public.transactions
group by user_id, date_trunc('month', date);

-- Dados de teste opcionais:
-- Depois de criar uma conta pelo app, substitua SEU_USER_UUID pelo id do usuario.
-- insert into public.transactions (user_id, title, amount, type, category, date)
-- values
--   ('SEU_USER_UUID', 'Salario', 5000.00, 'income', 'Salario', now()),
--   ('SEU_USER_UUID', 'Aluguel', 1500.00, 'expense', 'Moradia', now()),
--   ('SEU_USER_UUID', 'Supermercado', 450.00, 'expense', 'Alimentacao', now()),
--   ('SEU_USER_UUID', 'Uber', 35.50, 'expense', 'Transporte', now());
