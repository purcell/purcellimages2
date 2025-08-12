(* From https://github.com/ocurrent/ocaml-ci/pull/760 *)
let drop_trailing_slash next_handler request =
  let target = "///" ^ Dream.target request in
  let path, query = Dream.split_target target in
  let path = Dream.from_path path |> Dream.drop_trailing_slash |> Dream.to_path in
  let target = path ^ if query = "" then "" else "?" ^ query in
  if Dream.target request = target then next_handler request
  else Dream.redirect request target

let site_base_url req =
  "https://" ^ (Dream.header req "host" |> Option.value ~default:"127.0.0.1")

let handle_image loader req  = let photo_id = Dream.param req "photo_id" |> int_of_string in
  let%lwt data = Dream.sql req (loader photo_id) in
  let etag = "\"" ^ Digest.MD5.(string data |> to_hex) ^ "\"" in
  match Dream.header req "If-None-Match" with
  | Some t when t = etag -> Dream.empty ~headers:[("Etag", etag)] `Not_Modified
  | _ -> Dream.respond ~headers:[("Content-Type", "image/jpeg"); ("ETag", etag)] data

let () =
  Dream.run
  @@ Dream.logger
  @@ drop_trailing_slash
  @@ Dream.sql_pool "postgresql:///purcellimages"
  @@ Dream.router [

    Dream.get "/" (fun _ ->
        Dream_html.respond Templates.home);

    Dream.get "/images/large/:photo_id" (handle_image Db.get_large_photo_data);

    Dream.get "/images/thumbnail/:photo_id" (handle_image Db.get_thumbnail_photo_data);

    Dream.get "/galleries/:name" (fun req ->
        let name = Dream.param req "name" in
        let%lwt meta = Dream.sql req (Db.get_gallery_meta name) in
        let%lwt photos = Dream.sql req (Db.get_gallery_photos name) in
        Dream_html.respond (Templates.gallery meta photos);
      );

    Dream.get "/galleries" (fun req ->
        let%lwt galleries = Dream.sql req Db.get_galleries in
        Dream_html.respond (Templates.galleries galleries);
      );

    Dream.get "/galleries/:name/:photo_id" (fun req ->
        let name = Dream.param req "name" in
        let photo_id = Dream.param req "photo_id" |> int_of_string in
        let%lwt meta = Dream.sql req (Db.get_photo_meta photo_id) in
        let%lwt context = Dream.sql req (Db.get_gallery_photo_context name photo_id) in
        Dream_html.respond (Templates.photo (site_base_url req) meta context);
      );
  ]
