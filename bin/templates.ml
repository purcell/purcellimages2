open Dream_html
open HTML

let site_css = {|
  html * { color: #222 }
  html { font-family: -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",Arial,"Noto Sans",sans-serif; }
  body { background-color: #dadada; }
  footer { margin-top: 5em; font-size: 0.7em; color: #444; border-top: solid 1px #bbb; }
  header { margin: 1em 0; padding-bottom: 1em; border-bottom: solid 1px #bbb; }
  a:link, a:visited { color: #401 }
  img.large { display: block; margin: 4em auto; max-width: 100%; height: auto; }

  .photo-page { text-align: center; }
  .photo-page h1 { font-size: 1.5em; }

  ul.photo-context { list-style-type: none; padding-left: 0; }
  ul.photo-context li { display: inline-block; }
  ul.photo-context li:after { content: " · "; }
  ul.photo-context li:last-child:after { content: ""; }

  ul.photo-info { list-style-type: none; padding-left: 0; }
  ul.photo-info li { display: inline-block; }
  ul.photo-info li:after { content: " · "; }
  ul.photo-info li:last-child:after { content: ""; }

  ul.thumbs { padding-left: 0; display: flex; flex-wrap: wrap;
    gap: 2em 2em;
  }
  ul.thumbs li { display: flex; flex-wrap: wrap; min-width: 135px; }
  ul.thumbs li a { display: block; margin: 0 auto; }
|}

(* HELPERS *)

let current_year = (Unix.time () |> Unix.gmtime).tm_year + 1900
let blank_to_option s = if String.equal "" (String.trim s) then None else Some s
let format_title title = blank_to_option title |> Option.value ~default:"Untitled"

(* TEMPLATES *)

let page (page_title : string) (contents : node list) =
  html [lang "en"] [
    head [] [
      meta [charset "utf-8"];
      title [] "%s | Steve Purcell Photography" page_title;
      style [ type_ "text/css" ] "%s" site_css
    ];
    header [] [
      a [href "/"] [txt "Steve Purcell Photography"];
    ];
    body [] contents;
    footer [] [
      p [] [
        txt "Copyright © 2002-%d Steve Purcell. Reproduction in whole or in part without written permission is prohibited." current_year]
    ]
  ]

let photo (photo : Db.photo_meta) (context : Db.gallery_photo_context) =
  let page_title = [
    Some (format_title photo.title);
    blank_to_option photo.location;
    Option.map string_of_int photo.year
  ] |> List.concat_map Option.to_list |> String.concat ", " in
  page page_title
    [ script [ lang "javascript" ] {|
        document.addEventListener("keyup", function (event) {
          var to_click = null;
          if (event.metaKey || event.altKey || event.ctrlKey) return;
          if (event.keyCode == 37) to_click = document.getElementById("previous-photo");
          if (event.keyCode == 39) to_click = document.getElementById("next-photo");
          if (to_click) to_click.click();
        });
      |};
      article [ class_ "photo-page" ] [
        nav [] [
          ul [ class_ "photo-context" ] [
            li []
              (match context.prev_photo with
               | Some p -> [a [href "/galleries/%s/%d" context.gallery_name p; id "previous-photo"] [txt "← Previous"]]
               | None -> []);
            li [] [a [href "/galleries/%s" context.gallery_name]
                     [txt "%s" context.gallery_title]];
            li []
              (match context.next_photo with
               | Some p -> [a [href "/galleries/%s/%d" context.gallery_name p; id "next-photo"] [txt "Next →"]]
               | None -> []);
          ];
          h1 [] [txt "%s" page_title];
          img [class_ "large"; width "%d" photo.large_width; height "%d" photo.large_height; src "/images/large/%d" photo.id];
          ul [class_ "photo-info"]
            ([photo.camera; photo.lens; photo.film;
              (if String.length photo.tech_comments > 0
               then Some photo.tech_comments else None)]
             |> List.concat_map Option.to_list |> List.map (fun i -> li [] [txt "%s" i])
            )
        ]
      ]
    ]

let galleries (galleries : Db.gallery_meta list) =
  page "Galleries"
    [article [] [
        h1 [] [txt "Galleries"];
        ul [] (List.map
                 (fun gallery ->
                    li [] [a [href "/galleries/%s" gallery.Db.name]
                             [txt "%s" gallery.title]])
                 galleries)
      ]
    ]

let gallery (gallery : Db.gallery_meta) (photos: Db.gallery_photo_meta list) =
  page gallery.title
    [article [] [
        h1 [] [txt "%s" gallery.title];
        p [] [ txt "%s" gallery.summary ];
        ul [class_ "thumbs"]
          (List.map
             (fun p ->
                li [] [a [href "/galleries/%s/%i" gallery.name p.Db.id]
                         [img [ class_ "thumb"; width "%d" p.thumb_width; height "%d" p.thumb_height; src "/images/thumbnail/%d" p.id; alt "%s" (format_title p.title)]  ]])
             photos)
      ]
    ]
