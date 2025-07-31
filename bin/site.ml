let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sql_pool "postgresql:///purcellimages"
  @@ Dream.router [

    Dream.get "/images/large/:photo_id" (fun req ->
        let photo_id = Dream.param req "photo_id" |> int_of_string in
        let%lwt data = Dream.sql req (Db.get_large_photo_data photo_id) in
        Dream.respond ~headers:[("Content-Type", "image/jpeg")] data
      );

    Dream.get "/images/thumbnail/:photo_id" (fun req ->
        let photo_id = Dream.param req "photo_id" |> int_of_string in
        let%lwt data = Dream.sql req (Db.get_thumbnail_photo_data photo_id) in
        Dream.respond ~headers:[("Content-Type", "image/jpeg")] data
      );

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
        Dream_html.respond (Templates.photo meta context);
      );
  ]
