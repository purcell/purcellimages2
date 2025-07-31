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
    comments: string;
    tech_comments: string;
    location: string;
  }

let get_photo_meta photo_id =
  let query =
    (T.int ->! T.(t11 int string (option int) (option int) (option int) (option string) (option string) (option string) string string string))
      {|
        SELECT p.id, p.title, p.year, p.month, p.day
             , c.name AS camera, f.name AS film, l.name AS lens
             , p.comments, p.tech_comments, p.location
          FROM photo p
          LEFT JOIN camera c ON c.id = p.camera
          LEFT JOIN film f ON f.id = p.film
          LEFT JOIN lens l ON l.id = p.lens
         WHERE p.id = ?
      |} in
  fun (module Db : DB) ->
    let%lwt meta_or_error = Db.find query photo_id in
    match%lwt Caqti_lwt.or_fail meta_or_error with
    | (id, title, year, month, day, camera, film, lens, comments, tech_comments, location) ->
        Lwt.return { id; title; year; month; day; camera; film; lens; comments; tech_comments; location };;

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
  }

let get_gallery_photos name =
    let query =
    (T.string ->* T.(t2 int string))
      {|
        SELECT p.id, p.title
          FROM photo p
          JOIN gallery_photo gp ON gp.photo = p.id
          JOIN gallery g ON gp.gallery = g.id AND g.name = ?
           AND g.visibility != 'private'
         ORDER BY gp.seq ASC
      |} in
  fun (module Db : DB) ->
    let%lwt meta_or_error = Db.collect_list query name in
    let%lwt items = Caqti_lwt.or_fail meta_or_error in
    Lwt.return (List.map (fun (id, title) -> { id; title}) items)

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
