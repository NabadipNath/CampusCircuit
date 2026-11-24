-- NN ElectroLab Store Release 2 — Supabase foundation
-- Run this entire file in Supabase SQL Editor.
-- This replaces the old starter schema: do NOT run the old users/password_hash schema.
-- Passwords and identities are managed by Supabase Auth (auth.users).

begin;

create extension if not exists pgcrypto;

-- User profile and authorization role. Never store passwords in this table.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'customer'
    check (role in ('customer','staff','admin','owner')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- Create a profile automatically whenever a Supabase Auth user is created.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', new.raw_user_meta_data ->> 'name')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_auth_user();

-- Authorization helper. The function reads the role from the protected profile table.
create or replace function public.has_store_role(allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.is_active = true
      and p.role = any (allowed_roles)
  );
$$;

revoke all on function public.has_store_role(text[]) from public;
grant execute on function public.has_store_role(text[]) to anon, authenticated;

-- Catalogue.
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  short_description text not null default '',
  description text not null default '',
  category text not null,
  categories text[] not null default '{}',
  difficulty text,
  tags text[] not null default '{}',
  specs jsonb not null default '[]'::jsonb,
  bom jsonb not null default '[]'::jsonb,
  icon text,
  is_published boolean not null default false,
  sort_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();

create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  sku text unique,
  name text not null,
  description text not null default '',
  price_paise bigint not null check (price_paise >= 0),
  stock_qty integer not null default 0 check (stock_qty >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists product_variants_set_updated_at on public.product_variants;
create trigger product_variants_set_updated_at
before update on public.product_variants
for each row execute function public.set_updated_at();

-- Customer orders. Public/anonymous order creation is intentionally NOT enabled here.
-- Use a Supabase Edge Function for validated checkout and stock reservation in the next step.
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  user_id uuid references auth.users(id) on delete set null,
  customer_name text not null,
  customer_email text,
  customer_phone text not null,
  shipping_address jsonb,
  status text not null default 'pending'
    check (status in ('pending','confirmed','processing','shipped','delivered','cancelled','refunded')),
  payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid','pending','paid','failed','refunded')),
  subtotal_paise bigint not null check (subtotal_paise >= 0),
  shipping_paise bigint not null default 0 check (shipping_paise >= 0),
  total_paise bigint not null check (total_paise >= 0),
  payment_reference text,
  tracking_number text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  variant_id uuid references public.product_variants(id) on delete set null,
  product_title_snapshot text not null,
  variant_title_snapshot text not null,
  unit_price_paise bigint not null check (unit_price_paise >= 0),
  quantity integer not null check (quantity > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.inventory_movements (
  id bigint generated always as identity primary key,
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  quantity_delta integer not null,
  reason text not null,
  reference text,
  actor_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists products_published_sort_idx
  on public.products (is_published, sort_order);
create index if not exists product_variants_product_idx
  on public.product_variants (product_id);
create index if not exists orders_created_at_idx
  on public.orders (created_at desc);
create index if not exists orders_status_idx
  on public.orders (status);
create index if not exists orders_user_idx
  on public.orders (user_id);
create index if not exists order_items_order_idx
  on public.order_items (order_id);
create index if not exists inventory_movements_variant_idx
  on public.inventory_movements (variant_id, created_at desc);

-- Enable RLS on every table exposed through the Supabase Data API.
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.audit_logs enable row level security;

-- Profiles: users can read/update their own profile, admins can read all.
drop policy if exists "profile_select_self_or_admin" on public.profiles;
create policy "profile_select_self_or_admin"
on public.profiles for select to authenticated
using (id = (select auth.uid()) or public.has_store_role(array['owner','admin']));

drop policy if exists "profile_update_self_or_admin" on public.profiles;
create policy "profile_update_self_or_admin"
on public.profiles for update to authenticated
using (id = (select auth.uid()) or public.has_store_role(array['owner','admin']))
with check (id = (select auth.uid()) or public.has_store_role(array['owner','admin']));

-- Prevent users from promoting themselves or changing their own role.
create or replace function public.prevent_profile_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role
     and coalesce(auth.role(), '') <> 'service_role'
     and not public.has_store_role(array['owner']) then
    raise exception 'Only an owner or trusted server can change account roles';
  end if;
  if new.is_active is distinct from old.is_active
     and coalesce(auth.role(), '') <> 'service_role'
     and not public.has_store_role(array['owner']) then
    raise exception 'Only an owner or trusted server can change account status';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_escalation on public.profiles;
create trigger profiles_prevent_role_escalation
before update on public.profiles
for each row execute function public.prevent_profile_role_escalation();

-- Public catalogue reads only published products.
drop policy if exists "public_read_published_products" on public.products;
create policy "public_read_published_products"
on public.products for select to anon, authenticated
using (is_published = true);

drop policy if exists "admins_manage_products" on public.products;
create policy "admins_manage_products"
on public.products for all to authenticated
using (public.has_store_role(array['owner','admin','staff']))
with check (public.has_store_role(array['owner','admin','staff']));

-- Public reads active variants belonging to published products.
drop policy if exists "public_read_active_variants" on public.product_variants;
create policy "public_read_active_variants"
on public.product_variants for select to anon, authenticated
using (
  is_active = true
  and exists (
    select 1 from public.products p
    where p.id = product_id and p.is_published = true
  )
);

drop policy if exists "admins_manage_variants" on public.product_variants;
create policy "admins_manage_variants"
on public.product_variants for all to authenticated
using (public.has_store_role(array['owner','admin','staff']))
with check (public.has_store_role(array['owner','admin','staff']));

-- Orders: customers can only read their own authenticated orders.
-- Anonymous checkout is deliberately handled later by a server-side Edge Function.
drop policy if exists "customer_read_own_orders" on public.orders;
create policy "customer_read_own_orders"
on public.orders for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "staff_manage_orders" on public.orders;
create policy "staff_manage_orders"
on public.orders for all to authenticated
using (public.has_store_role(array['owner','admin','staff']))
with check (public.has_store_role(array['owner','admin','staff']));

drop policy if exists "customer_read_own_order_items" on public.order_items;
create policy "customer_read_own_order_items"
on public.order_items for select to authenticated
using (
  exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = (select auth.uid())
  )
);

drop policy if exists "staff_manage_order_items" on public.order_items;
create policy "staff_manage_order_items"
on public.order_items for all to authenticated
using (public.has_store_role(array['owner','admin','staff']))
with check (public.has_store_role(array['owner','admin','staff']));

drop policy if exists "admins_read_inventory_movements" on public.inventory_movements;
create policy "admins_read_inventory_movements"
on public.inventory_movements for select to authenticated
using (public.has_store_role(array['owner','admin','staff']));

drop policy if exists "admins_write_inventory_movements" on public.inventory_movements;
create policy "admins_write_inventory_movements"
on public.inventory_movements for insert to authenticated
with check (public.has_store_role(array['owner','admin','staff']));

drop policy if exists "admins_read_audit_logs" on public.audit_logs;
create policy "admins_read_audit_logs"
on public.audit_logs for select to authenticated
using (public.has_store_role(array['owner','admin']));

-- Storage bucket for catalogue images. Public read; staff/admin/owner write.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "public_read_product_images" on storage.objects;
create policy "public_read_product_images"
on storage.objects for select to anon, authenticated
using (bucket_id = 'product-images');

drop policy if exists "staff_upload_product_images" on storage.objects;
create policy "staff_upload_product_images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'product-images'
  and public.has_store_role(array['owner','admin','staff'])
);

drop policy if exists "staff_update_product_images" on storage.objects;
create policy "staff_update_product_images"
on storage.objects for update to authenticated
using (
  bucket_id = 'product-images'
  and public.has_store_role(array['owner','admin','staff'])
)
with check (
  bucket_id = 'product-images'
  and public.has_store_role(array['owner','admin','staff'])
);

drop policy if exists "staff_delete_product_images" on storage.objects;
create policy "staff_delete_product_images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'product-images'
  and public.has_store_role(array['owner','admin','staff'])
);

commit;

-- OWNER BOOTSTRAP (run separately after creating your account in Authentication > Users):
-- Replace the email below with the exact email used for your first owner account.
-- update public.profiles
-- set role = 'owner', is_active = true
-- where id = (select id from auth.users where email = 'YOUR_LOGIN_EMAIL');
