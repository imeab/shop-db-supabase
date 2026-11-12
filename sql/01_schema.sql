-- =========================================
-- 쇼핑몰 스키마: 회원(members), 상품(products), 주문(orders, order_items)
-- Supabase SQL Editor에서 실행
-- 명명 규칙: 테이블은 복수형 snake_case, PK는 id, FK는 <단수>_id
-- =========================================

-- 다시 실행할 수 있게 기존 객체 삭제 (DROP)
drop function if exists public.create_order(jsonb);
drop table if exists public.order_items;
drop table if exists public.orders;
drop table if exists public.products;
drop table if exists public.members;

-- 1. 회원: Supabase Auth(auth.users)와 1:1
create table public.members (
    id          uuid primary key references auth.users (id) on delete cascade,
    email       text not null unique,
    name        text not null,
    role        text not null default 'customer' check (role in ('admin', 'customer')),
    created_at  timestamptz not null default now()
);

-- 2. 상품
create table public.products (
    id          bigint generated always as identity primary key,
    name        text not null,
    price       integer not null check (price >= 0),
    stock       integer not null default 0 check (stock >= 0),
    created_at  timestamptz not null default now()
);

-- 3. 주문 (주문 1건)
create table public.orders (
    id           bigint generated always as identity primary key,
    member_id    uuid not null references public.members (id) on delete cascade,
    total_price  integer not null check (total_price >= 0),
    status       text not null default 'ordered' check (status in ('ordered', 'cancelled')),
    created_at   timestamptz not null default now()
);

-- 4. 주문 상품 (주문 1건에 상품 여러 개 → 정규화해서 분리)
create table public.order_items (
    id          bigint generated always as identity primary key,
    order_id    bigint not null references public.orders (id) on delete cascade,
    product_id  bigint not null references public.products (id),
    quantity    integer not null check (quantity > 0),
    price       integer not null check (price >= 0), -- 주문 당시 가격
    unique (order_id, product_id)
);

-- 변경 (ALTER): 회원 전화번호 컬럼 추가
alter table public.members add column phone text;
