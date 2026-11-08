-- Telão Missa: base para várias paróquias (aditiva: o site atual continua funcionando como paróquia nº 1)
create extension if not exists pgcrypto with schema extensions;

create table public.paroquias (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length(slug) between 3 and 60),
  nome text not null check (length(nome) between 3 and 120),
  cidade text, uf text check (uf is null or uf ~ '^[A-Z]{2}$'),
  plano text not null default 'teste' check (plano in ('teste','comunidade','paroquia','paroquia_comunidades','fundadora')),
  status text not null default 'teste' check (status in ('teste','ativa','pendente','suspensa','cancelada')),
  teste_ate date default (current_date + 30),
  logo_url text,
  criado timestamptz not null default now()
);

insert into public.paroquias (id, slug, nome, plano, status, teste_ate)
values ('00000000-0000-4000-8000-000000000001', 'piloto', 'Paróquia piloto', 'fundadora', 'ativa', null);

create table public.membros (
  paroquia_id uuid not null references public.paroquias(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  papel text not null check (papel in ('responsavel','coordenador','operador','musico')),
  email text,
  criado timestamptz not null default now(),
  primary key (paroquia_id, user_id)
);
create index membros_user on public.membros(user_id);

create table public.convites (
  id uuid primary key default gen_random_uuid(),
  paroquia_id uuid not null references public.paroquias(id) on delete cascade,
  papel text not null check (papel in ('coordenador','operador','musico')),
  email text,
  codigo text not null unique default encode(extensions.gen_random_bytes(12), 'hex'),
  criado_por uuid references auth.users(id) on delete set null,
  criado timestamptz not null default now(),
  expira timestamptz not null default now() + interval '14 days',
  usado_por uuid references auth.users(id) on delete set null,
  usado_em timestamptz
);
create index convites_paroquia on public.convites(paroquia_id);

-- funções de permissão
create or replace function private.uuid_ou_nulo(t text) returns uuid
language plpgsql immutable set search_path = '' as $$ begin return t::uuid; exception when others then return null; end $$;
create or replace function private.papel_em(p uuid) returns text
language sql stable security definer set search_path = '' as $$
  select m.papel from public.membros m where m.paroquia_id = p and m.user_id = (select auth.uid());
$$;
create or replace function private.pode_editar(p uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.membros m where m.paroquia_id = p and m.user_id = (select auth.uid())
                 and m.papel in ('responsavel','coordenador','operador'));
$$;
create or replace function private.eh_responsavel(p uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.membros m where m.paroquia_id = p and m.user_id = (select auth.uid()) and m.papel = 'responsavel');
$$;
create or replace function private.eh_curador() returns boolean  -- quem cuida do acervo compartilhado
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.membros m where m.paroquia_id = '00000000-0000-4000-8000-000000000001'
                 and m.user_id = (select auth.uid()) and m.papel in ('responsavel','coordenador','operador'));
$$;
grant execute on function private.uuid_ou_nulo(text), private.papel_em(uuid), private.pode_editar(uuid), private.eh_responsavel(uuid), private.eh_curador() to anon, authenticated;

-- editores (site atual) viram membros da paróquia 1, e continuam sincronizados
insert into public.membros (paroquia_id, user_id, papel, email)
select '00000000-0000-4000-8000-000000000001', e.user_id,
       case when u.email = 'santos.diegohl@gmail.com' then 'responsavel' else 'coordenador' end, u.email
from public.editores e join auth.users u on u.id = e.user_id
on conflict do nothing;

create or replace function private.sincronizar_editor() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    insert into public.membros (paroquia_id, user_id, papel, email)
    values ('00000000-0000-4000-8000-000000000001', new.user_id, 'coordenador', (select email from auth.users where id = new.user_id))
    on conflict do nothing;
    return new;
  else
    delete from public.membros where paroquia_id = '00000000-0000-4000-8000-000000000001' and user_id = old.user_id and papel <> 'responsavel';
    return old;
  end if;
end $$;
create trigger editores_sync after insert or delete on public.editores for each row execute function private.sincronizar_editor();

-- dados por paróquia
alter table public.missas add column paroquia_id uuid not null default '00000000-0000-4000-8000-000000000001' references public.paroquias(id) on delete cascade;
alter table public.missas drop constraint missas_pkey, add primary key (paroquia_id, data, horario);
alter table public.config add column paroquia_id uuid not null default '00000000-0000-4000-8000-000000000001' references public.paroquias(id) on delete cascade;
alter table public.config drop constraint config_pkey, add primary key (paroquia_id, id);
alter table public.avisos add column paroquia_id uuid not null default '00000000-0000-4000-8000-000000000001' references public.paroquias(id) on delete cascade;
create index avisos_paroquia on public.avisos(paroquia_id);
alter table public.pedidos add column paroquia_id uuid not null default '00000000-0000-4000-8000-000000000001' references public.paroquias(id) on delete cascade;
alter table public.pedidos drop constraint pedidos_pkey, add primary key (paroquia_id, user_id);
alter table public.musicas add column paroquia_id uuid references public.paroquias(id) on delete cascade;  -- null = acervo compartilhado
create index musicas_paroquia on public.musicas(paroquia_id);

-- regras de escrita por paróquia
drop policy "equipe altera missas" on public.missas; drop policy "equipe apaga missas" on public.missas; drop policy "equipe cria missas" on public.missas;
create policy "equipe cria missas" on public.missas for insert to authenticated with check ((select private.pode_editar(paroquia_id)));
create policy "equipe altera missas" on public.missas for update to authenticated using ((select private.pode_editar(paroquia_id))) with check ((select private.pode_editar(paroquia_id)));
create policy "equipe apaga missas" on public.missas for delete to authenticated using ((select private.pode_editar(paroquia_id)));

drop policy "equipe altera config" on public.config; drop policy "equipe cria config" on public.config;
create policy "equipe cria config" on public.config for insert to authenticated with check ((select private.pode_editar(paroquia_id)));
create policy "equipe altera config" on public.config for update to authenticated using ((select private.pode_editar(paroquia_id))) with check ((select private.pode_editar(paroquia_id)));

drop policy "equipe altera avisos" on public.avisos; drop policy "equipe apaga avisos" on public.avisos; drop policy "equipe cria avisos" on public.avisos;
create policy "equipe cria avisos" on public.avisos for insert to authenticated with check ((select private.pode_editar(paroquia_id)));
create policy "equipe altera avisos" on public.avisos for update to authenticated using ((select private.pode_editar(paroquia_id))) with check ((select private.pode_editar(paroquia_id)));
create policy "equipe apaga avisos" on public.avisos for delete to authenticated using ((select private.pode_editar(paroquia_id)));

drop policy "equipe altera cantos" on public.musicas; drop policy "equipe apaga cantos" on public.musicas; drop policy "equipe cria cantos" on public.musicas;
create policy "equipe cria cantos" on public.musicas for insert to authenticated
  with check (case when paroquia_id is null then (select private.eh_curador()) else (select private.pode_editar(paroquia_id)) end);
create policy "equipe altera cantos" on public.musicas for update to authenticated
  using (case when paroquia_id is null then (select private.eh_curador()) else (select private.pode_editar(paroquia_id)) end)
  with check (case when paroquia_id is null then (select private.eh_curador()) else (select private.pode_editar(paroquia_id)) end);
create policy "equipe apaga cantos" on public.musicas for delete to authenticated
  using (case when paroquia_id is null then (select private.eh_curador()) else (select private.pode_editar(paroquia_id)) end);

-- paróquias, membros, convites
alter table public.paroquias enable row level security;
alter table public.membros enable row level security;
alter table public.convites enable row level security;
grant select on public.paroquias to anon, authenticated;
grant update (nome, cidade, uf, logo_url) on public.paroquias to authenticated;
grant select, update, delete on public.membros to authenticated;
grant select, insert, delete on public.convites to authenticated;
create policy "todos leem paroquias" on public.paroquias for select to anon, authenticated using (true);
create policy "responsavel altera paroquia" on public.paroquias for update to authenticated
  using ((select private.eh_responsavel(id))) with check ((select private.eh_responsavel(id)));
create policy "equipe ve membros" on public.membros for select to authenticated
  using (user_id = (select auth.uid()) or (select private.papel_em(paroquia_id)) is not null);
create policy "responsavel muda papel" on public.membros for update to authenticated
  using ((select private.eh_responsavel(paroquia_id))) with check ((select private.eh_responsavel(paroquia_id)) and papel <> 'responsavel');
create policy "responsavel remove ou membro sai" on public.membros for delete to authenticated
  using (((select private.eh_responsavel(paroquia_id)) and papel <> 'responsavel') or (user_id = (select auth.uid()) and papel <> 'responsavel'));
create policy "responsavel ve convites" on public.convites for select to authenticated using ((select private.eh_responsavel(paroquia_id)));
create policy "responsavel cria convites" on public.convites for insert to authenticated
  with check ((select private.eh_responsavel(paroquia_id)) and criado_por = (select auth.uid()));
create policy "responsavel apaga convites" on public.convites for delete to authenticated using ((select private.eh_responsavel(paroquia_id)));

-- cadastro de paróquia (quem cria vira responsável; 30 dias de teste)
create or replace function public.criar_paroquia(p_nome text, p_slug text, p_cidade text default null, p_uf text default null)
returns public.paroquias language plpgsql security definer set search_path = '' as $$
declare r public.paroquias; uid uuid := (select auth.uid());
begin
  if uid is null then raise exception 'entre com sua conta primeiro' using errcode = '28000'; end if;
  if (select count(*) from public.membros where user_id = uid and papel = 'responsavel') >= 5 then
    raise exception 'limite de paróquias por conta atingido' using errcode = 'P0001'; end if;
  insert into public.paroquias (nome, slug, cidade, uf) values (trim(p_nome), lower(trim(p_slug)), nullif(trim(p_cidade),''), nullif(upper(trim(p_uf)),''))
  returning * into r;
  insert into public.membros (paroquia_id, user_id, papel, email) values (r.id, uid, 'responsavel', (select email from auth.users where id = uid));
  insert into public.config (paroquia_id, id, valor) select r.id, c.id, c.valor from public.config c
    where c.paroquia_id = '00000000-0000-4000-8000-000000000001' and c.id in ('layout','oracoes');
  insert into public.config (paroquia_id, id, valor) values (r.id, 'agenda', '{"horarios":{"0":["09:00"]},"vigilia":false}'::jsonb);
  return r;
end $$;
revoke all on function public.criar_paroquia(text,text,text,text) from public, anon;
grant execute on function public.criar_paroquia(text,text,text,text) to authenticated;

create or replace function public.aceitar_convite(p_codigo text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare c public.convites; uid uuid := (select auth.uid());
begin
  if uid is null then raise exception 'entre com sua conta primeiro' using errcode = '28000'; end if;
  select * into c from public.convites where codigo = p_codigo for update;
  if c.id is null or c.usado_por is not null or c.expira < now() then
    raise exception 'convite inválido ou vencido' using errcode = 'P0001'; end if;
  insert into public.membros (paroquia_id, user_id, papel, email) values (c.paroquia_id, uid, c.papel, (select email from auth.users where id = uid))
  on conflict (paroquia_id, user_id) do update set papel = excluded.papel where public.membros.papel <> 'responsavel';
  update public.convites set usado_por = uid, usado_em = now() where id = c.id;
  return c.paroquia_id;
end $$;
revoke all on function public.aceitar_convite(text) from public, anon;
grant execute on function public.aceitar_convite(text) to authenticated;

-- arquivos: novas paróquias guardam em <paroquia_id>/...
create policy "paroquia envia arquivos" on storage.objects for insert to authenticated
  with check (bucket_id in ('capas','audios') and (select private.pode_editar(private.uuid_ou_nulo((storage.foldername(name))[1]))));
create policy "paroquia altera arquivos" on storage.objects for update to authenticated
  using (bucket_id in ('capas','audios') and (select private.pode_editar(private.uuid_ou_nulo((storage.foldername(name))[1]))));
create policy "paroquia apaga arquivos" on storage.objects for delete to authenticated
  using (bucket_id in ('capas','audios') and (select private.pode_editar(private.uuid_ou_nulo((storage.foldername(name))[1]))));

alter publication supabase_realtime add table public.paroquias;
