create or replace function public.can_upload_import(object_name text)
returns boolean
language sql
stable
security definer
set search_path = public, storage
as $$
  select exists (
    select 1
    from public.importacoes i
    where i.id::text = (storage.foldername(object_name))[2]
      and i.storage_original_path = object_name
      and i.status = 'aguardando_upload'
  );
$$;

revoke all on function public.can_upload_import(text) from public;
grant execute on function public.can_upload_import(text) to anon;

create policy "scoped_anon_insert_importacoes"
on storage.objects for insert to anon
with check (
  bucket_id = 'importacoes'
  and (storage.foldername(name))[1] = 'originais'
  and public.can_upload_import(name)
);
