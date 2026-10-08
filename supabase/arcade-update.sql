-- Atualização de jogos; NÃO reseta saldos.
begin;
alter table public.bet_rounds drop constraint if exists bet_rounds_game_check;
alter table public.bet_rounds add constraint bet_rounds_game_check check(game in('aviator','verite','double','mines','plinko','mateo','pirate','bacbo','mecha','sahur','fishing'));
alter table public.bet_rounds add column if not exists progress jsonb not null default '{"found":[],"misses":0}';
create or replace function public.bet_love(p_user uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare a public.bet_profiles;
begin
 select * into a from public.bet_profiles where id=p_user for update;
 if not found or a.balance<>0 then raise exception 'O abraço fica disponível quando o saldo zerar';end if;
 if exists(select 1 from public.bet_rounds where user_id=p_user and status='open') or exists(select 1 from public.bet_duels where status='active' and p_user in(sender,receiver)) then raise exception 'Termine a rodada primeiro';end if;
 update public.bet_profiles set balance=3000 where id=p_user;
 return jsonb_build_object('balance',3000);
end $$;
create or replace function public.bet_arcade_hit(p_user uuid,p_round uuid,p_target integer,p_at double precision) returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.bet_rounds;hits jsonb;misses integer;hit boolean; elapsed double precision;phase double precision;multi numeric;award bigint;a public.bet_profiles;finish boolean;
begin
 select * into r from public.bet_rounds where id=p_round and user_id=p_user for update;
 if not found or r.game<>'mecha' then raise exception 'Rodada indisponível';end if;
 if r.status<>'open' then return jsonb_build_object('ended',true,'progress',r.progress);end if;
 hits=coalesce(r.progress->'found','[]');misses=coalesce((r.progress->>'misses')::integer,0);
 elapsed=extract(epoch from clock_timestamp()-r.created);
 if r.game='mecha' then
  hit=p_target between 0 and 7;
  if hit and hits @> jsonb_build_array(p_target) then return jsonb_build_object('hit',false,'duplicate',true,'progress',r.progress);end if;
 else
  if elapsed-coalesce((r.progress->>'last')::double precision,-2)<1.25 then raise exception 'Espere o próximo compasso';end if;
  phase=(greatest(extract(epoch from r.created),least(extract(epoch from clock_timestamp()),p_at/1000))-extract(epoch from r.created))/1.5;
  phase=phase-floor(phase);hit=phase between .38 and .62;
  p_target=jsonb_array_length(hits);
 end if;
 if elapsed>=60 then hit=false;misses=2;elsif hit then hits=hits||jsonb_build_array(p_target);else misses=misses+1;end if;
 update public.bet_rounds set progress=jsonb_build_object('found',hits,'misses',misses,'last',elapsed) where id=r.id returning * into r;
 multi=(array[0,.35,.6,.9,1.2,1.6,2.2,3,4.5])[jsonb_array_length(hits)+1];
 finish=misses>=2 or jsonb_array_length(hits)>=8;
 if finish then
  if misses>=2 then multi=0;end if;award=round(r.bet*multi);
  update public.bet_profiles set balance=balance+award,rounds=rounds+1,wins=wins+case when award>r.bet then 1 else 0 end where id=p_user returning * into a;
  insert into public.bet_events(id,user_id,game,bet,payout,multiplier) values(r.id,p_user,r.game,r.bet,award,multi);
  update public.bet_rounds set status='settled' where id=r.id;
 end if;
 return jsonb_build_object('hit',hit,'progress',r.progress,'multi',multi,'ended',finish,'balance',a.balance,'payout',award,'serverTime',extract(epoch from clock_timestamp())*1000);
end $$;
revoke all on function public.bet_love(uuid),public.bet_arcade_hit(uuid,uuid,integer,double precision) from public,anon,authenticated;
grant execute on function public.bet_love(uuid),public.bet_arcade_hit(uuid,uuid,integer,double precision) to service_role;

create or replace function public.bet_duel(p_user uuid,p_id uuid,p_action text,p_plans jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
declare d public.bet_duels; own jsonb; entry jsonb; a uuid; b uuid; na bigint; nb bigint; award bigint; w uuid; l uuid; n integer; r public.bet_rounds;
begin
 select * into d from public.bet_duels where id=p_id for update;
 if not found or p_user not in(d.sender,d.receiver) then raise exception 'X1 indisponível';end if;
 perform id from public.bet_profiles where id in(d.sender,d.receiver) order by id for update;
 if p_action='accept' then
  if p_user<>d.receiver or d.status<>'pending' or d.created<now()-interval '10 minutes' then raise exception 'Convite expirado';end if;
  if exists(select 1 from public.bet_duels where id<>d.id and status='active' and (sender in(d.sender,d.receiver) or receiver in(d.sender,d.receiver))) then raise exception 'Um jogador já está em um x1';end if;
  if exists(select 1 from public.bet_rounds where user_id in(d.sender,d.receiver) and status='open') then raise exception 'Terminem a rodada atual primeiro';end if;
  if exists(select 1 from public.bet_profiles where id in(d.sender,d.receiver) and balance<7500) then raise exception 'Cada jogador precisa ter pelo menos R$ 75 fictícios';end if;
  if jsonb_array_length(p_plans->d.sender::text)<>15 or jsonb_array_length(p_plans->d.receiver::text)<>15 then raise exception 'Plano inválido';end if;
  update public.bet_duels set status='active',plans=p_plans,started=now()+interval '3 seconds',ends=now()+interval '33 seconds' where id=d.id returning * into d;
 elsif p_action='decline' and d.status='pending' then
  update public.bet_duels set status='declined' where id=d.id returning * into d;
 end if;
 if d.status='active' and now()>=d.ends then
  select coalesce(sum((x->>'payout')::bigint-500),0) into na from jsonb_array_elements(coalesce(d.plays->d.sender::text,'[]')) x;
  select coalesce(sum((x->>'payout')::bigint-500),0) into nb from jsonb_array_elements(coalesce(d.plays->d.receiver::text,'[]')) x;
  w=case when na>nb then d.sender when nb>na then d.receiver else null end;
  l=case when w=d.sender then d.receiver when w=d.receiver then d.sender else null end;
  award=case when w=d.sender then greatest(nb,0) when w=d.receiver then greatest(na,0) else 0 end;
  if award>0 then update public.bet_profiles set balance=balance+case when id=w then award else -award end where id in(w,l);end if;
  update public.bet_duels set status='finished',winner=w,transfer=award where id=d.id returning * into d;
 end if;
 if p_action='spin' and d.status='active' then
  if now()<d.started then raise exception 'Aguarde a contagem regressiva';end if;
  own=coalesce(d.plays->p_user::text,'[]');n=jsonb_array_length(own);
  if n>=15 then raise exception 'Limite de 15 giros alcançado';end if;
  if n>0 and now()<(own->(n-1)->>'time')::timestamptz+interval '1.5 seconds' then raise exception 'Aguarde o próximo giro';end if;
  entry=d.plans->p_user::text->n;
  award=round(500*(entry->>'multi')::numeric);
  update public.bet_profiles set balance=balance-500+award,rounds=rounds+1,wins=wins+case when award>500 then 1 else 0 end where id=p_user and balance>=500;
  if not found then raise exception 'Saldo insuficiente';end if;
  insert into public.bet_rounds(user_id,game,seed,bet,result,status) values(p_user,d.game,(entry->>'seed')::bigint,500,entry,'settled') returning * into r;
  insert into public.bet_events(id,user_id,game,bet,payout,multiplier) values(r.id,p_user,d.game,500,award,(entry->>'multi')::numeric);
  entry=entry||jsonb_build_object('payout',award,'time',now());
  update public.bet_duels set plays=jsonb_set(plays,array[p_user::text],own||jsonb_build_array(entry)) where id=d.id returning * into d;
 end if;
 return (to_jsonb(d)-'plans')||jsonb_build_object('serverTime',extract(epoch from clock_timestamp())*1000);
end $$;

commit;

