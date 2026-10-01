-- Run this script once in Supabase SQL Editor for a new CRM project.
create table public.agents (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null,
 email text not null,
 created timestamptz not null default now()
);
create table public.records (
 id uuid primary key default gen_random_uuid(),
 kind text not null check (kind in ('prospect','task','interaction','offer')),
 data jsonb not null check (jsonb_typeof(data)='object'),
 updated timestamptz not null default now()
);
create index idx_records_kind on public.records(kind);
create index idx_records_updated on public.records(updated desc);
alter table public.agents enable row level security;
alter table public.records enable row level security;
create policy agents_team_read on public.agents for select to authenticated using (true);
create policy records_team_read on public.records for select to authenticated using (true);
revoke all on public.agents,public.records from anon,authenticated;
grant select on public.agents,public.records to authenticated;

create function public.handle_new_agent() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.agents(id,name,email) values (new.id,coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'),''),new.email,'Agent'),coalesce(new.email,''));
 return new;
end;$$;
revoke all on function public.handle_new_agent() from public,anon,authenticated;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_agent();
-- Include users created before the schema was installed.
insert into public.agents(id,name,email)
select id,coalesce(nullif(trim(raw_user_meta_data->>'full_name'),''),email,'Agent'),coalesce(email,'') from auth.users
on conflict(id) do nothing;

create function public.validate_crm_data(k text,d jsonb) returns void language plpgsql set search_path='' as $$
declare f text;
begin
 if k not in ('prospect','task','interaction','offer') or d is null or jsonb_typeof(d)<>'object' then raise exception 'Invalid record' using errcode='22023'; end if;
 if octet_length(d::text)>30000 then raise exception 'Record too large' using errcode='22023';end if;
 if k='prospect' then
  if coalesce(length(trim(d->>'name')),0)=0 or length(d->>'name')>300 or d->>'stage' is null or d->>'stage' not in ('Nou','Contactat','Interesat','Ofertă de trimis','Ofertă trimisă','Ofertă trimisă','Follow-up','Negociere','Câștigat','Pierdut') then raise exception 'Invalid prospect' using errcode='22023';end if;
  if coalesce(d->>'website','')<>'' and d->>'website' !~ '^https?://' then raise exception 'Invalid website' using errcode='22023';end if;
 else
  if not exists(select 1 from public.records where id=(d->>'prospectId')::uuid and kind='prospect') then raise exception 'Prospect missing' using errcode='23503';end if;
  if coalesce(d->>'date','') !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'Invalid date' using errcode='22023';end if;
  perform (d->>'date')::date;
 end if;
 if k in ('prospect','task') and not exists(select 1 from public.agents where id=(d->>'agentId')::uuid) then raise exception 'Agent missing' using errcode='23503';end if;
 if k='task' and (coalesce(d->>'time','') !~ '^([01]\d|2[0-3]):[0-5]\d$' or coalesce(jsonb_typeof(d->'done'),'')<>'boolean') then raise exception 'Invalid task' using errcode='22023';end if;
 if k='interaction' and coalesce(length(trim(d->>'notes')),0)=0 then raise exception 'Notes required' using errcode='22023';end if;
 if k='offer' and (coalesce(length(trim(d->>'number')),0)=0 or coalesce(jsonb_typeof(d->'value'),'')<>'number' or (d->>'value')::numeric<0 or (d->>'value')::numeric>1000000000000 or d->>'status' is null or d->>'status' not in ('De pregătit','Trimisă','Acceptată','Refuzată')) then raise exception 'Invalid offer' using errcode='22023';end if;
end;$$;
revoke all on function public.validate_crm_data(text,jsonb) from public,anon,authenticated;

-- One transaction saves the discussion, its next action, and the prospect stage.
create function public.save_crm_record(p_kind text,p_data jsonb,p_id uuid default null,p_next jsonb default null,p_stage text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();rid uuid:=coalesce(p_id,gen_random_uuid());old_data jsonb;stored jsonb;stamp text:=to_char(now() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
begin
 if uid is null then raise exception 'Authentication required' using errcode='42501';end if;
 if not exists(select 1 from public.agents where id=uid) then raise exception 'Agent profile missing' using errcode='42501';end if;
 perform public.validate_crm_data(p_kind,p_data);
 if p_id is not null then
  select data into old_data from public.records where id=p_id and kind=p_kind for update;
  if not found then raise exception 'Record missing' using errcode='P0002';end if;
 end if;
 stored=(p_data-'id'-'kind'-'created'-'createdBy'-'updatedBy')||jsonb_build_object('created',coalesce(old_data->>'created',stamp),'createdBy',coalesce(old_data->>'createdBy',uid::text),'updatedBy',uid::text);
 if p_id is null then insert into public.records(id,kind,data) values(rid,p_kind,stored);
 else update public.records set data=stored,updated=now() where id=rid;end if;
 if p_kind='interaction' then
  if p_next is null or p_next->>'prospectId' is distinct from p_data->>'prospectId' or p_stage is null or p_stage not in ('Nou','Contactat','Interesat','Ofertă de trimis','Ofertă trimisă','Follow-up','Negociere','Câștigat','Pierdut') then raise exception 'Next action required' using errcode='22023';end if;
  perform public.validate_crm_data('task',p_next);
  insert into public.records(kind,data) values('task',(p_next-'id'-'kind'-'created'-'createdBy'-'updatedBy')||jsonb_build_object('created',stamp,'createdBy',uid::text,'updatedBy',uid::text));
  update public.records set data=data||jsonb_build_object('stage',p_stage,'updatedBy',uid::text),updated=now() where id=(p_data->>'prospectId')::uuid and kind='prospect';
 end if;
 return jsonb_build_object('id',rid,'kind',p_kind)||stored;
end;$$;
revoke all on function public.save_crm_record(text,jsonb,uuid,jsonb,text) from public,anon;
grant execute on function public.save_crm_record(text,jsonb,uuid,jsonb,text) to authenticated;
