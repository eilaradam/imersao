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
