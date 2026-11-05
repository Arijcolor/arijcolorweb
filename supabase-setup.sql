-- =====================================================================
--  Arij Color · configuración de Supabase para el panel de administración
--  Pégalo entero en: Supabase > SQL Editor > New query > Run
--
--  ANTES DE EJECUTAR: cambia el email autorizado (aparece 7 veces abajo,
--  entre comillas simples) por el email con el que entrarás al panel.
--  Si usas más de uno: in ('uno@correo.com', 'otro@correo.com')
-- =====================================================================

-- 1) Tablas -----------------------------------------------------------
create table if not exists public.site_texts (
  lang       text        not null,
  path       text        not null,
  value      text        not null,
  updated_at timestamptz not null default now(),
  primary key (lang, path)
);

create table if not exists public.site_images (
  key        text        primary key,
  path       text        not null,
  updated_at timestamptz not null default now()
);

alter table public.site_texts  enable row level security;
alter table public.site_images enable row level security;

-- 2) Permisos de las tablas: todos leen, solo el admin escribe --------
drop policy if exists "texts_public_read"  on public.site_texts;
drop policy if exists "texts_admin_write"  on public.site_texts;
drop policy if exists "images_public_read" on public.site_images;
drop policy if exists "images_admin_write" on public.site_images;

create policy "texts_public_read" on public.site_texts
  for select using (true);

create policy "texts_admin_write" on public.site_texts
  for all to authenticated
  using      ((auth.jwt() ->> 'email') in ('contact@arijcolor.com'))
  with check ((auth.jwt() ->> 'email') in ('contact@arijcolor.com'));

create policy "images_public_read" on public.site_images
  for select using (true);

create policy "images_admin_write" on public.site_images
  for all to authenticated
  using      ((auth.jwt() ->> 'email') in ('contact@arijcolor.com'))
  with check ((auth.jwt() ->> 'email') in ('contact@arijcolor.com'));

-- 3) Bucket público de imágenes ---------------------------------------
insert into storage.buckets (id, name, public)
values ('arij-color', 'arij-color', true)
on conflict (id) do update set public = true;

drop policy if exists "arij_color_public_read"  on storage.objects;
drop policy if exists "arij_color_admin_insert" on storage.objects;
drop policy if exists "arij_color_admin_update" on storage.objects;
drop policy if exists "arij_color_admin_delete" on storage.objects;

create policy "arij_color_public_read" on storage.objects
  for select using (bucket_id = 'arij-color');

create policy "arij_color_admin_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'arij-color' and (auth.jwt() ->> 'email') in ('contact@arijcolor.com'));

create policy "arij_color_admin_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'arij-color' and (auth.jwt() ->> 'email') in ('contact@arijcolor.com'));

create policy "arij_color_admin_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'arij-color' and (auth.jwt() ->> 'email') in ('contact@arijcolor.com'));

-- 4) Recomendado (en el panel de Supabase, no en SQL):
--    Authentication > Providers > Email > desactiva "Allow new users to sign up"
--    y crea tu usuario en Authentication > Users > Add user (con el email de arriba).
