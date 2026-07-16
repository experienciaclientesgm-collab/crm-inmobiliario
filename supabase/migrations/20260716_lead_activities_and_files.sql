-- CRM: agenda, historial de contactos y archivos por lead
create extension if not exists pgcrypto;

create table if not exists public.lead_activities (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references public.leads(id) on delete cascade,
  tipo text not null check (tipo in ('llamada', 'visita', 'whatsapp', 'nota')),
  titulo text not null,
  detalle text,
  programado_para timestamptz,
  completado_en timestamptz,
  estado text not null default 'pendiente' check (estado in ('pendiente', 'completado', 'cancelado')),
  creado_por text not null default 'Sin asignar',
  created_at timestamptz not null default now()
);

create index if not exists lead_activities_lead_id_idx on public.lead_activities(lead_id);
create index if not exists lead_activities_programado_para_idx on public.lead_activities(programado_para);

create table if not exists public.lead_files (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references public.leads(id) on delete cascade,
  nombre text not null,
  ruta_storage text not null unique,
  tipo_mime text,
  tamanio_bytes bigint,
  subido_por text not null default 'Sin asignar',
  created_at timestamptz not null default now()
);

create index if not exists lead_files_lead_id_idx on public.lead_files(lead_id);

insert into storage.buckets (id, name, public)
values ('lead-files', 'lead-files', true)
on conflict (id) do update set public = true;

alter table public.lead_activities enable row level security;
alter table public.lead_files enable row level security;

-- La app actual usa la clave anónima y ya gestiona leads sin autenticación.
-- Estas políticas mantienen el mismo modelo. Restringe a usuarios autenticados
-- antes de usar el CRM en producción con datos sensibles.
drop policy if exists "lead activities public access" on public.lead_activities;
create policy "lead activities public access" on public.lead_activities for all using (true) with check (true);

drop policy if exists "lead files public access" on public.lead_files;
create policy "lead files public access" on public.lead_files for all using (true) with check (true);

drop policy if exists "lead files storage public access" on storage.objects;
create policy "lead files storage public access" on storage.objects for all
using (bucket_id = 'lead-files') with check (bucket_id = 'lead-files');