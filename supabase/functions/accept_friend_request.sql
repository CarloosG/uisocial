create or replace function accept_friend_request(
  friendship_id uuid,
  user_id_param uuid,
  friend_id_param uuid
) returns void as $$
begin
  -- Actualizar el estado de la solicitud a 'accepted'
  update friendships
  set status = 'accepted',
      updated_at = now()
  where id = friendship_id;

  -- Eliminar registros existentes si los hay
  delete from friends
  where (user_id = user_id_param and friend_id = friend_id_param)
     or (user_id = friend_id_param and friend_id = user_id_param);

  -- Crear registros bidireccionales en la tabla friends
  insert into friends (user_id, friend_id)
  values
    (user_id_param, friend_id_param),
    (friend_id_param, user_id_param);
end;
$$ language plpgsql; 