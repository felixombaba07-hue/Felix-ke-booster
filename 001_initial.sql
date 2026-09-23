create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'user' check (role in ('user','admin')),
  status text not null default 'active' check (status in ('active','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  platform text not null,
  description text,
  price_per_1000 numeric(12,2) not null check (price_per_1000 >= 0),
  min_quantity integer not null default 100 check (min_quantity > 0),
  max_quantity integer not null default 100000 check (max_quantity >= min_quantity),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  service_id uuid references public.services(id),
  service_name text not null,
  target text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  total_amount numeric(12,2) not null check (total_amount >= 0),
  status text not null default 'pending' check (status in ('pending','paid','processing','completed','partial','cancelled','failed')),
  provider_order_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  reference text unique not null,
  amount numeric(12,2) not null,
  currency text not null default 'KES',
  status text not null default 'pending' check (status in ('pending','success','failed')),
  provider_response jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  balance numeric(12,2) not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('credit','debit','refund','adjustment')),
  amount numeric(12,2) not null check (amount > 0),
  reference text,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.provider_orders (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  provider_order_id text,
  status text,
  response jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.site_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity text,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz not null default now()
);

-- Safe admin check: SECURITY DEFINER avoids recursive profiles RLS evaluation.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'active');
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

alter table public.profiles enable row level security;
alter table public.services enable row level security;
alter table public.orders enable row level security;
alter table public.payments enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.provider_orders enable row level security;
alter table public.site_settings enable row level security;
alter table public.audit_logs enable row level security;

-- Profiles: users may read/update only themselves. Admin access uses is_admin().
create policy profiles_select_self_or_admin on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy profiles_update_self_or_admin on public.profiles for update to authenticated using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());

create policy services_public_read on public.services for select to anon,authenticated using (active = true or public.is_admin());
create policy services_admin_insert on public.services for insert to authenticated with check (public.is_admin());
create policy services_admin_update on public.services for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy services_admin_delete on public.services for delete to authenticated using (public.is_admin());

create policy orders_user_read on public.orders for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy orders_user_insert on public.orders for insert to authenticated with check (user_id = auth.uid());
create policy orders_admin_update on public.orders for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy payments_user_read on public.payments for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy payments_admin_insert on public.payments for insert to authenticated with check (public.is_admin());
create policy payments_admin_update on public.payments for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy wallets_user_read on public.wallets for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy wallet_tx_user_read on public.wallet_transactions for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy provider_admin_all on public.provider_orders for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy settings_public_read on public.site_settings for select to anon,authenticated using (true);
create policy settings_admin_write on public.site_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy audit_admin_read on public.audit_logs for select to authenticated using (public.is_admin());
create policy audit_admin_insert on public.audit_logs for insert to authenticated with check (public.is_admin());

insert into public.services(name,category,platform,description,price_per_1000,min_quantity,max_quantity) values
('Facebook Followers','Followers','Facebook','Facebook follower growth service.',150,100,100000),
('Instagram Followers','Followers','Instagram','Instagram follower growth service.',350,100,100000),
('TikTok Followers','Followers','TikTok','TikTok follower growth service.',500,100,100000),
('X Followers','Followers','X','X follower growth service.',700,100,100000),
('WhatsApp Services','Followers','WhatsApp','WhatsApp growth service.',650,100,100000),
('Telegram Subscribers','Subscribers','Telegram','Telegram subscriber growth service.',300,100,100000),
('Facebook Likes','Likes','Facebook','Facebook likes service.',100,100,100000),
('Instagram Likes','Likes','Instagram','Instagram likes service.',150,100,100000),
('TikTok Likes','Likes','TikTok','TikTok likes service.',80,100,100000)
on conflict do nothing;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id,email) values(new.id,new.email) on conflict (id) do nothing;
  insert into public.wallets(user_id,balance) values(new.id,0) on conflict (user_id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
