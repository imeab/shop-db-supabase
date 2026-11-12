-- =========================================
-- RLS (Row Level Security): 사용자별 접근 제어
-- auth.uid() = 지금 로그인한 사용자 id
-- =========================================

alter table public.members     enable row level security;
alter table public.products    enable row level security;
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

-- 관리자인지 확인하는 함수
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
    select exists (select 1 from members where id = auth.uid() and role = 'admin');
$$;

-- ---------- members ----------
-- 본인 정보만 등록 / 조회 / 수정 / 삭제
create policy "members_insert_own" on public.members
    for insert to authenticated with check (id = auth.uid() and role = 'customer');
create policy "members_select_own" on public.members
    for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "members_update_own" on public.members
    for update to authenticated using (id = auth.uid());
create policy "members_delete_own" on public.members
    for delete to authenticated using (id = auth.uid());

-- 회원은 이름, 전화번호만 수정 가능 (role을 스스로 admin으로 못 바꾸게)
revoke update on public.members from authenticated;
grant update (name, phone) on public.members to authenticated;

-- ---------- products ----------
-- 조회는 누구나, 등록/수정/삭제는 관리자만
create policy "products_select_all" on public.products
    for select using (true);
create policy "products_insert_admin" on public.products
    for insert to authenticated with check (public.is_admin());
create policy "products_update_admin" on public.products
    for update to authenticated using (public.is_admin());
create policy "products_delete_admin" on public.products
    for delete to authenticated using (public.is_admin());

-- ---------- orders ----------
-- 본인 주문만 조회 / 수정(취소) / 삭제, 생성은 create_order 함수로
create policy "orders_select_own" on public.orders
    for select to authenticated using (member_id = auth.uid() or public.is_admin());
create policy "orders_update_own" on public.orders
    for update to authenticated using (member_id = auth.uid());
create policy "orders_delete_own" on public.orders
    for delete to authenticated using (member_id = auth.uid());

-- ---------- order_items ----------
create policy "order_items_select_own" on public.order_items
    for select to authenticated
    using (exists (select 1 from orders o where o.id = order_id and (o.member_id = auth.uid() or public.is_admin())));
