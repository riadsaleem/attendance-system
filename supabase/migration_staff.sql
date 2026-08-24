-- =============================================================
-- تحديث: جداول الموظفين والعمال وحضورهم
-- انسخ والصق في: Supabase Dashboard → SQL Editor → Run
-- =============================================================

-- ---------- الموظفون والعمال ----------
create table if not exists public.staff (
  id              bigint generated always as identity primary key,
  full_name       text not null,
  category        text not null check (category in ('employee','worker')),
  job_title       text,
  phone           text,
  fingerprint_id  text unique,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);
create index if not exists idx_staff_category on public.staff(category);

-- ---------- حضور الموظفين والعمال ----------
create table if not exists public.staff_attendance (
  id               bigint generated always as identity primary key,
  staff_id         bigint not null references public.staff(id) on delete cascade,
  attendance_date  date not null,
  check_in_time    timestamptz,
  status           text not null default 'present' check (status in ('present','late','absent')),
  note             text,
  recorded_by      uuid references auth.users(id) on delete set null,
  created_at       timestamptz not null default now(),
  unique (staff_id, attendance_date)
);
create index if not exists idx_staff_attendance_date on public.staff_attendance(attendance_date);

-- ---------- تفعيل الحماية ----------
alter table public.staff            enable row level security;
alter table public.staff_attendance enable row level security;

-- القراءة للجميع المصرح لهم
drop policy if exists "staff_select" on public.staff;
create policy "staff_select" on public.staff
  for select to authenticated using (true);

drop policy if exists "staff_write_admin" on public.staff;
create policy "staff_write_admin" on public.staff
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "staff_attendance_select" on public.staff_attendance;
create policy "staff_attendance_select" on public.staff_attendance
  for select to authenticated using (true);

drop policy if exists "staff_attendance_insert" on public.staff_attendance;
create policy "staff_attendance_insert" on public.staff_attendance
  for insert to authenticated with check (public.can_edit_attendance());

drop policy if exists "staff_attendance_update" on public.staff_attendance;
create policy "staff_attendance_update" on public.staff_attendance
  for update to authenticated using (public.can_edit_attendance()) with check (public.can_edit_attendance());

drop policy if exists "staff_attendance_delete" on public.staff_attendance;
create policy "staff_attendance_delete" on public.staff_attendance
  for delete to authenticated using (public.is_admin());
