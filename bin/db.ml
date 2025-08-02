module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type
open Caqti_request.Infix

type photo_meta = {
    id : int;
    title : string;
    year: int option;
    month: int option;
    day: int option;
    camera: string option;
    film: string option;
    lens: string option;
    tech_comments: string;
    location: string;
    large_width: int;
    large_height: int;
  }

let get_photo_meta photo_id =
  let query =
    (T.int ->! T.(t12 int string (option int) (option int) (option int) (option string) (option string) (option string) string string int int))
      {|
        SELECT p.id, p.title, p.year, p.month, p.day
             , c.name AS camera, f.name AS film, l.name AS lens
             , p.tech_comments, p.location
             , d.width as large_width
             , d.height as large_height
          FROM photo p
          JOIN large_photo_data d ON d.id = p.large_data
          LEFT JOIN camera c ON c.id = p.camera
          LEFT JOIN film f ON f.id = p.film
          LEFT JOIN lens l ON l.id = p.lens
         WHERE p.id = ?
      |} in
  fun (module Db : DB) ->
    let%lwt meta_or_error = Db.find query photo_id in
    match%lwt Caqti_lwt.or_fail meta_or_error with
    | (id, title, year, month, day, camera, film, lens, tech_comments, location, large_width, large_height) ->
        Lwt.return { id; title; year; month; day; camera; film; lens; tech_comments; location; large_width; large_height };;

let get_large_photo_data photo_id =
  let query =
    (T.int ->! T.octets)
      {|
        SELECT data
          FROM large_photo_data d
         WHERE id = (SELECT large_data FROM photo WHERE id = ?)
      |} in
  fun (module Db : DB) ->
    let%lwt meta_or_error = Db.find query photo_id in
    Caqti_lwt.or_fail meta_or_error

let get_thumbnail_photo_data photo_id =
  let query =
    (T.int ->! T.octets)
      {|
        SELECT data
          FROM thumbnail_photo_data d
         WHERE id = (SELECT thumbnail_data FROM photo WHERE id = ?)
      |} in
  fun (module Db : DB) ->
    let%lwt meta_or_error = Db.find query photo_id in
    Caqti_lwt.or_fail meta_or_error

type gallery_meta = {
    id: int;
    name: string;
    title: string;
    summary: string;
    cover_photo_id: int option;
  }

let get_galleries =
  let query =
    (T.unit ->* T.(t5 int string string string (option int)))
      {|
        SELECT id, name, title, summary, cover
          FROM gallery
         WHERE visibility not in ('private', 'viewable')
         ORDER BY array_position(array['primary', 'featured', 'listed'], visibility) ASC, seq ASC
      |} in
  fun (module Db : DB) ->
    let%lwt meta_or_error = Db.collect_list query () in
    let%lwt items = Caqti_lwt.or_fail meta_or_error in
    Lwt.return (List.map
      (fun (id, name, title, summary, cover_photo_id) ->
        { id; name; title; summary; cover_photo_id }
      ) items)

let get_gallery_meta name =
  let query =
    (T.string ->! T.(t5 int string string string (option int)))
      {|
        SELECT id, name, title, summary, cover
          FROM gallery
         WHERE visibility != 'private'
           AND name = ?
      |} in
  fun (module Db : DB) ->
    let%lwt meta_or_error = Db.find query name in
    match%lwt Caqti_lwt.or_fail meta_or_error with
    | (id, name, title, summary, cover_photo_id) ->
        Lwt.return { id; name; title; summary; cover_photo_id }

type gallery_photo_meta = {
    id: int;
    title: string;
    thumb_width: int;
    thumb_height: int;
  }

let get_gallery_photos name =
    let query =
    (T.string ->* T.(t4 int string int int))
      {|
        SELECT p.id, p.title, d.width as thumb_width, d.height as thumb_height
          FROM photo p
          JOIN thumbnail_photo_data d ON d.id = p.thumbnail_data
          JOIN gallery_photo gp ON gp.photo = p.id
          JOIN gallery g ON gp.gallery = g.id AND g.name = ?
           AND g.visibility != 'private'
         ORDER BY gp.seq ASC
      |} in
  fun (module Db : DB) ->
    let%lwt meta_or_error = Db.collect_list query name in
    let%lwt items = Caqti_lwt.or_fail meta_or_error in
    Lwt.return (List.map (fun (id, title, thumb_width, thumb_height) -> { id; title; thumb_width; thumb_height }) items)

type gallery_photo_context = {
    gallery_name: string;
    gallery_title: string;
    prev_photo: int option;
    next_photo: int option;
  }

let get_gallery_photo_context name photo_id =
    let query =
    (T.(t2 string int) ->! T.(t4 string string (option int) (option int)))
      {|
        WITH photos AS (
          SELECT photo
               , LEAD(photo) OVER (ORDER BY gp.seq) AS next_photo
               , LAG(photo)  OVER (ORDER BY gp.seq) AS prev_photo
               , g.name AS gallery_name
               , g.title AS gallery_title
            FROM gallery_photo gp
            JOIN gallery g ON g.id = gp.gallery
                 AND g.visibility != 'private'
                 AND g.name = ?
        )
        SELECT gallery_name, gallery_title, prev_photo, next_photo
          FROM photos WHERE photo = ?
      |} in
    fun (module Db : DB) ->
      let%lwt res = Db.find query (name, photo_id) in
      match%lwt Caqti_lwt.or_fail res with
      | (gallery_name, gallery_title, prev_photo, next_photo) ->
        Lwt.return { gallery_name; gallery_title; prev_photo; next_photo }
