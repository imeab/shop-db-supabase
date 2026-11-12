-- =========================================
-- 테이블 구조 확인 (README 캡처용)
-- =========================================

-- 테이블별 PK / FK
select
    conrelid::regclass as table_name,
    case contype when 'p' then 'PRIMARY KEY' else 'FOREIGN KEY' end as type,
    pg_get_constraintdef(oid) as definition
from pg_constraint
where connamespace = 'public'::regnamespace
  and contype in ('p', 'f')
order by conrelid::regclass::text, contype desc;

-- 컬럼 목록
select table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('members', 'products', 'orders', 'order_items')
order by table_name, ordinal_position;
