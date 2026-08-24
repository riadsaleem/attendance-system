-- =============================================================
-- نظام إدارة الحضور والغياب — مخطط قاعدة البيانات (Supabase/Postgres)
-- انسخ هذا الملف كاملاً والصقه في: Supabase Dashboard → SQL Editor → Run
-- =============================================================

-- ---------- 1) الملفات الشخصية للمستخدمين ----------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default '',
  role        text not null default 'viewer' check (role in ('admin','teacher','viewer')),
  created_at  timestamptz not null default now()
);

-- ---------- 2) المراحل الدراسية ----------
create table if not exists public.grades (
  id          bigint generated always as identity primary key,
  name        text not null unique,
  created_at  timestamptz not null default now()
);

-- ---------- 3) الصفوف ----------
create table if not exists public.classes (
  id          bigint generated always as identity primary key,
  name        text not null,
  grade_id    bigint not null references public.grades(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (name, grade_id)
);

-- ---------- 4) الطلاب ----------
create table if not exists public.students (
  id              bigint generated always as identity primary key,
  full_name       text not null,
  class_id        bigint not null references public.classes(id) on delete cascade,
  guardian_name   text,
  guardian_phone  text,
  fingerprint_id  text unique,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);
create index if not exists idx_students_class on public.students(class_id);

-- ---------- 5) سجلات الحضور ----------
create table if not exists public.attendance_logs (
  id               bigint generated always as identity primary key,
  student_id       bigint not null references public.students(id) on delete cascade,
  attendance_date  date not null,
  check_in_time    timestamptz,
  check_out_time   timestamptz,
  status           text not null default 'present' check (status in ('present','late','absent')),
  note             text,
  recorded_by      uuid references auth.users(id) on delete set null,
  created_at       timestamptz not null default now(),
  unique (student_id, attendance_date)
);
create index if not exists idx_attendance_date on public.attendance_logs(attendance_date);
create index if not exists idx_attendance_student on public.attendance_logs(student_id);

-- ---------- 6) دوال مساعدة للصلاحيات ----------
create or replace function public.my_role()
returns text
language sql stable security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()) = 'admin', false);
$$;

create or replace function public.can_edit_attendance()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()) in ('admin','teacher'), false);
$$;

-- ---------- 7) إنشاء profile تلقائياً عند تسجيل مستخدم جديد ----------
-- أول مستخدم يسجل في النظام يصبح مدير (admin) تلقائياً، والباقي مشاهدين
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  first_user boolean;
begin
  select not exists (select 1 from public.profiles) into first_user;
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    case when first_user then 'admin' else 'viewer' end
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- منع المستخدم من ترقية نفسه لمدير (تغيير الدور يتم من حساب مدير فقط)
create or replace function public.guard_role_change()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  if new.role <> old.role and not public.is_admin() then
    raise exception 'تغيير الدور مسموح للمدير فقط';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_role_change_trg on public.profiles;
create trigger guard_role_change_trg
  before update on public.profiles
  for each row execute function public.guard_role_change();

-- ---------- 8) تفعيل RLS على كل الجداول ----------
alter table public.profiles        enable row level security;
alter table public.grades          enable row level security;
alter table public.classes         enable row level security;
alter table public.students        enable row level security;
alter table public.attendance_logs enable row level security;

-- profiles
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select to authenticated using (true);

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self" on public.profiles
  for update to authenticated using (id = auth.uid());

-- grades: القراءة للجميع، التعديل للمدير فقط
drop policy if exists "grades_select" on public.grades;
create policy "grades_select" on public.grades
  for select to authenticated using (true);

drop policy if exists "grades_write_admin" on public.grades;
create policy "grades_write_admin" on public.grades
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- classes
drop policy if exists "classes_select" on public.classes;
create policy "classes_select" on public.classes
  for select to authenticated using (true);

drop policy if exists "classes_write_admin" on public.classes;
create policy "classes_write_admin" on public.classes
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- students
drop policy if exists "students_select" on public.students;
create policy "students_select" on public.students
  for select to authenticated using (true);

drop policy if exists "students_write_admin" on public.students;
create policy "students_write_admin" on public.students
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- attendance_logs: القراءة للجميع، التسجيل والتعديل للمدير والمعلم
drop policy if exists "attendance_select" on public.attendance_logs;
create policy "attendance_select" on public.attendance_logs
  for select to authenticated using (true);

drop policy if exists "attendance_insert" on public.attendance_logs;
create policy "attendance_insert" on public.attendance_logs
  for insert to authenticated with check (public.can_edit_attendance());

drop policy if exists "attendance_update" on public.attendance_logs;
create policy "attendance_update" on public.attendance_logs
  for update to authenticated using (public.can_edit_attendance()) with check (public.can_edit_attendance());

drop policy if exists "attendance_delete" on public.attendance_logs;
create policy "attendance_delete" on public.attendance_logs
  for delete to authenticated using (public.is_admin());

-- ---------- 9) بيانات تجريبية ----------
insert into public.grades (name) values
  ('ابتدائي'), ('متوسط'), ('ثانوي')
on conflict (name) do nothing;

insert into public.classes (name, grade_id)
select v.class_name, g.id
from (values
  ('الأول أ', 'ابتدائي'),
  ('الثاني أ', 'ابتدائي'),
  ('الأول ب', 'متوسط'),
  ('الثاني ب', 'متوسط'),
  ('الثالث أ', 'ثانوي')
) as v(class_name, grade_name)
join public.grades g on g.name = v.grade_name
on conflict do nothing;

insert into public.students (full_name, class_id, guardian_name, guardian_phone)
select v.student_name, c.id, v.guardian, v.phone
from (values
  ('أحمد محمد صالح',   'الأول أ', 'محمد صالح',   '777100001'),
  ('ياسر علي قاسم',    'الأول أ', 'علي قاسم',    '777100002'),
  ('عمر خالد ناصر',    'الأول أ', 'خالد ناصر',   '777100003'),
  ('فهد سعيد الحكيمي', 'الأول أ', 'سعيد الحكيمي','777100004'),
  ('سامي عبدالله',     'الثاني أ','عبدالله',     '777100005'),
  ('خالد إبراهيم',     'الثاني أ','إبراهيم',     '777100006'),
  ('نواف حسن',         'الثاني أ','حسن',         '777100007'),
  ('ريان ماجد',        'الثاني أ','ماجد',        '777100008'),
  ('بدر فيصل',         'الأول ب', 'فيصل',        '777100009'),
  ('ماجد ناصر',        'الأول ب', 'ناصر',        '777100010'),
  ('تركي سعد',         'الأول ب', 'سعد',         '777100011'),
  ('زياد طارق',        'الثاني ب','طارق',        '777100012'),
  ('أنس وليد',         'الثاني ب','وليد',        '777100013'),
  ('حسام جمال',        'الثالث أ','جمال',        '777100014'),
  ('مروان هاني',       'الثالث أ','هاني',        '777100015')
) as v(student_name, class_name, guardian, phone)
join public.classes c on c.name = v.class_name
where not exists (select 1 from public.students s where s.full_name = v.student_name);

-- حضور تجريبي لآخر 7 أيام (لتظهر التقارير والإحصائيات فوراً)
insert into public.attendance_logs (student_id, attendance_date, check_in_time, status)
select
  s.id,
  d::date,
  (d + make_time(7, 10 + floor(random() * 40)::int, 0))::timestamptz,
  case
    when random() < 0.08 then 'absent'
    when random() < 0.15 then 'late'
    else 'present'
  end
from public.students s
cross join generate_series(
  (current_date - interval '6 days')::date,
  current_date,
  interval '1 day'
) as d
where s.is_active
  and extract(dow from d) between 0 and 4
  and not exists (
    select 1 from public.attendance_logs a
    where a.student_id = s.id and a.attendance_date = d::date
  );

-- =============================================================
-- تم! الآن أنشئ حسابك من التطبيق — أول حساب يصبح مدير النظام تلقائياً
-- =============================================================
