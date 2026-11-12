-- =========================================
-- 트랜잭션: 주문 생성 = 주문 저장 + 주문상품 저장 + 재고 차감
-- 하나라도 실패하면 전부 취소(ROLLBACK)
-- =========================================

-- 함수 하나는 하나의 트랜잭션으로 실행됨
-- 중간에 raise exception이 나면 앞에서 한 insert/update도 모두 ROLLBACK
-- items 예시: [{"product_id": 1, "quantity": 2}, {"product_id": 3, "quantity": 1}]
create or replace function public.create_order(items jsonb)
returns bigint
language plpgsql
security definer          -- 재고 차감(products update)은 관리자만 가능해서 함수 권한으로 실행
set search_path = public
as $$
declare
    new_order_id bigint;
    item         jsonb;
    p            products%rowtype;
    qty          integer;
    total        integer := 0;
begin
    if auth.uid() is null then
        raise exception '로그인이 필요합니다';
    end if;

    if items is null or jsonb_array_length(items) = 0 then
        raise exception '주문할 상품이 없습니다';
    end if;

    -- 1) 주문 먼저 만들기 (총액은 마지막에 계산)
    insert into orders (member_id, total_price)
    values (auth.uid(), 0)
    returning id into new_order_id;

    -- 2) 상품마다 재고 확인 → 주문상품 저장 → 재고 차감
    for item in select * from jsonb_array_elements(items)
    loop
        qty := (item ->> 'quantity')::integer;

        select * into p from products
        where id = (item ->> 'product_id')::bigint
        for update;  -- 동시에 주문해도 재고가 꼬이지 않게 잠금

        if not found then
            raise exception '없는 상품입니다 (id=%)', item ->> 'product_id';
        end if;

        if p.stock < qty then
            raise exception '재고 부족: % (재고 %개, 주문 %개)', p.name, p.stock, qty;
        end if;

        insert into order_items (order_id, product_id, quantity, price)
        values (new_order_id, p.id, qty, p.price);

        update products set stock = stock - qty where id = p.id;

        total := total + p.price * qty;
    end loop;

    -- 3) 총액 저장
    update orders set total_price = total where id = new_order_id;

    return new_order_id;
end;
$$;

grant execute on function public.create_order(jsonb) to authenticated;


-- =========================================
-- SQL Editor에서 직접 COMMIT / ROLLBACK 확인해보기
-- (아래는 한 블록씩 선택해서 실행)
-- =========================================

-- [COMMIT 예시] 두 상품 재고를 함께 조정
-- begin;
--     update products set stock = stock + 5 where name = '무선 마우스';
--     update products set stock = stock + 5 where name = '기계식 키보드';
-- commit;
-- select name, stock from products;

-- [ROLLBACK 예시] 실수로 전부 0원으로 바꿨다가 취소
-- begin;
--     update products set price = 0;
--     select name, price from products;   -- 0원으로 보임
-- rollback;
-- select name, price from products;       -- 원래 가격 그대로
