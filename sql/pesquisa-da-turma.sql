-- =====================================================================
-- Pesquisa da turma: o que elas querem aprender e onde travam hoje
-- Projeto: Cadastro de Creators (mfrmnquvwwuxraqgemyh)
--
-- 100% ADITIVO: 1 tabela nova e 2 funções novas. Não toca em nada
-- que já existe.
-- =====================================================================

create table if not exists public.imersao_pesquisa (
  id           bigserial primary key,
  arroba       text not null unique,
  nome         text,
  momento      text,                                  -- em que ponto da carreira ela está
  fechados     text,                                  -- quantas marcas já fechou
  dificuldades jsonb not null default '[]'::jsonb,    -- o que trava hoje (várias)
  aprender     text,                                  -- o que mais quer aprender
  duvida       text,                                  -- a dúvida pra aula
  ia           text,                                  -- o quanto já usa IA
  extra        text,                                  -- o que ela quiser contar
  criado_em    timestamptz not null default now(),
  visto_em     timestamptz not null default now()
);

alter table public.imersao_pesquisa enable row level security;

drop policy if exists imersao_pesquisa_admin on public.imersao_pesquisa;
create policy imersao_pesquisa_admin on public.imersao_pesquisa
  for all to authenticated using (is_admin()) with check (is_admin());

-- A porta da aluna: só essa função escreve, e só a linha dela.
create or replace function public.imersao_salvar_pesquisa(
  p_arroba text, p_nome text, p_momento text, p_fechados text,
  p_dificuldades jsonb, p_aprender text, p_duvida text, p_ia text, p_extra text
) returns void language plpgsql security definer set search_path = public as $fn$
declare a text;
begin
  a := lower(regexp_replace(coalesce(p_arroba,''), '[^a-zA-Z0-9._]', '', 'g'));
  if a = '' or length(a) > 40 then return; end if;
  insert into imersao_pesquisa (arroba, nome, momento, fechados, dificuldades, aprender, duvida, ia, extra)
  values (a,
          left(nullif(trim(coalesce(p_nome,'')),''),80),
          left(coalesce(p_momento,''),40),
          left(coalesce(p_fechados,''),40),
          coalesce(p_dificuldades,'[]'::jsonb),
          left(coalesce(p_aprender,''),700),
          left(coalesce(p_duvida,''),700),
          left(coalesce(p_ia,''),40),
          left(coalesce(p_extra,''),700))
  on conflict (arroba) do update set
    nome         = coalesce(excluded.nome, imersao_pesquisa.nome),
    momento      = excluded.momento,
    fechados     = excluded.fechados,
    dificuldades = excluded.dificuldades,
    aprender     = excluded.aprender,
    duvida       = excluded.duvida,
    ia           = excluded.ia,
    extra        = excluded.extra,
    visto_em     = now();
end $fn$;

revoke all on function public.imersao_salvar_pesquisa(text,text,text,text,jsonb,text,text,text,text) from public;
grant execute on function public.imersao_salvar_pesquisa(text,text,text,text,jsonb,text,text,text,text) to anon, authenticated;

create or replace function public.admin_imersao_pesquisa()
returns setof imersao_pesquisa language sql security definer set search_path = public as $fn$
  select * from public.imersao_pesquisa where is_admin() order by visto_em desc;
$fn$;

revoke all on function public.admin_imersao_pesquisa() from public;
grant execute on function public.admin_imersao_pesquisa() to authenticated;

-- =====================================================================
-- Perguntas extras (18/09, a pedido dela): nicho, computador,
-- portfólio de hoje, onde ela trava e o medo dos dois dias.
-- A função ganha os campos novos COM DEFAULT, então uma página antiga
-- em cache continua gravando sem erro.
-- =====================================================================

alter table public.imersao_pesquisa add column if not exists nicho      text;
alter table public.imersao_pesquisa add column if not exists computador text;
alter table public.imersao_pesquisa add column if not exists portfolio  text;
alter table public.imersao_pesquisa add column if not exists trava      text;
alter table public.imersao_pesquisa add column if not exists medo       text;

drop function if exists public.imersao_salvar_pesquisa(text,text,text,text,jsonb,text,text,text,text);

create or replace function public.imersao_salvar_pesquisa(
  p_arroba text, p_nome text, p_momento text, p_fechados text,
  p_dificuldades jsonb, p_aprender text, p_duvida text, p_ia text, p_extra text,
  p_nicho text default null, p_computador text default null, p_portfolio text default null,
  p_trava text default null, p_medo text default null
) returns void language plpgsql security definer set search_path = public as $fn$
declare a text;
begin
  a := lower(regexp_replace(coalesce(p_arroba,''), '[^a-zA-Z0-9._]', '', 'g'));
  if a = '' or length(a) > 40 then return; end if;
  insert into imersao_pesquisa (arroba, nome, momento, fechados, dificuldades, aprender, duvida, ia, extra,
                                nicho, computador, portfolio, trava, medo)
  values (a,
          left(nullif(trim(coalesce(p_nome,'')),''),80),
          left(coalesce(p_momento,''),40),
          left(coalesce(p_fechados,''),40),
          coalesce(p_dificuldades,'[]'::jsonb),
          left(coalesce(p_aprender,''),700),
          left(coalesce(p_duvida,''),700),
          left(coalesce(p_ia,''),40),
          left(coalesce(p_extra,''),700),
          left(coalesce(p_nicho,''),120),
          left(coalesce(p_computador,''),60),
          left(coalesce(p_portfolio,''),60),
          left(coalesce(p_trava,''),700),
          left(coalesce(p_medo,''),700))
  on conflict (arroba) do update set
    nome         = coalesce(excluded.nome, imersao_pesquisa.nome),
    momento      = excluded.momento,
    fechados     = excluded.fechados,
    dificuldades = excluded.dificuldades,
    aprender     = excluded.aprender,
    duvida       = excluded.duvida,
    ia           = excluded.ia,
    extra        = excluded.extra,
    nicho        = excluded.nicho,
    computador   = excluded.computador,
    portfolio    = excluded.portfolio,
    trava        = excluded.trava,
    medo         = excluded.medo,
    visto_em     = now();
end $fn$;

revoke all on function public.imersao_salvar_pesquisa(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text) from public;
grant execute on function public.imersao_salvar_pesquisa(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text) to anon, authenticated;

-- =====================================================================
-- Troca do nicho pelo WhatsApp (18/09): a coluna nova entra e a função
-- ganha mais um parâmetro com default.
-- =====================================================================

alter table public.imersao_pesquisa add column if not exists whatsapp text;

drop function if exists public.imersao_salvar_pesquisa(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text);

create or replace function public.imersao_salvar_pesquisa(
  p_arroba text, p_nome text, p_momento text, p_fechados text,
  p_dificuldades jsonb, p_aprender text, p_duvida text, p_ia text, p_extra text,
  p_nicho text default null, p_computador text default null, p_portfolio text default null,
  p_trava text default null, p_medo text default null, p_whatsapp text default null
) returns void language plpgsql security definer set search_path = public as $fn$
declare a text; w text;
begin
  a := lower(regexp_replace(coalesce(p_arroba,''), '[^a-zA-Z0-9._]', '', 'g'));
  if a = '' or length(a) > 40 then return; end if;
  w := nullif(regexp_replace(coalesce(p_whatsapp,''), '[^0-9]', '', 'g'),'');
  insert into imersao_pesquisa (arroba, nome, momento, fechados, dificuldades, aprender, duvida, ia, extra,
                                nicho, computador, portfolio, trava, medo, whatsapp)
  values (a,
          left(nullif(trim(coalesce(p_nome,'')),''),80),
          left(coalesce(p_momento,''),40),
          left(coalesce(p_fechados,''),40),
          coalesce(p_dificuldades,'[]'::jsonb),
          left(coalesce(p_aprender,''),700),
          left(coalesce(p_duvida,''),700),
          left(coalesce(p_ia,''),40),
          left(coalesce(p_extra,''),700),
          left(coalesce(p_nicho,''),120),
          left(coalesce(p_computador,''),60),
          left(coalesce(p_portfolio,''),60),
          left(coalesce(p_trava,''),700),
          left(coalesce(p_medo,''),700),
          left(w,20))
  on conflict (arroba) do update set
    nome         = coalesce(excluded.nome, imersao_pesquisa.nome),
    momento      = excluded.momento,
    fechados     = excluded.fechados,
    dificuldades = excluded.dificuldades,
    aprender     = excluded.aprender,
    duvida       = excluded.duvida,
    ia           = excluded.ia,
    extra        = excluded.extra,
    nicho        = excluded.nicho,
    computador   = excluded.computador,
    portfolio    = excluded.portfolio,
    trava        = excluded.trava,
    medo         = excluded.medo,
    whatsapp     = coalesce(excluded.whatsapp, imersao_pesquisa.whatsapp),
    visto_em     = now();
end $fn$;

revoke all on function public.imersao_salvar_pesquisa(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text,text) from public;
grant execute on function public.imersao_salvar_pesquisa(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text,text) to anon, authenticated;
