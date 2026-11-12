-- 01_members.ipynb에서 admin01 회원가입 후 실행
-- (회원은 스스로 role을 바꿀 수 없어서 SQL Editor에서 관리자 지정)
update public.members set role = 'admin' where email = 'admin01@test.com';

select email, name, role from public.members;
