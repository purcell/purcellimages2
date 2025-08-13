open Dream_html
open HTML

let site_css = {|
  html { color: #222; font-family: ui-rounded, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, sans-serif; }
  body { background-color: #dadada; }
  footer { margin-top: 5em; font-size: 0.8em; color: #444; border-top: solid 1px #bbb; }
  header { margin: 1em 0; border-bottom: solid 1px #bbb; }
  a:link, a:visited { color: #603; text-decoration: none; }
  a:hover { text-decoration: underline; }
  img.large { display: block; margin: 4em auto; max-width: 100%; height: auto; }

  .photo-page { text-align: center; }
  .photo-page h1 { font-size: 1.5em; }

  ul.horizontal { list-style-type: none; padding-left: 0; }
  ul.horizontal li { display: inline-block; }
  ul.horizontal li:after { content: " · "; }
  ul.horizontal li:last-child:after { content: ""; }
  li.primary { font-weight: 600; }

  ul.thumbs { padding-left: 0; display: flex; flex-wrap: wrap;
    gap: 3em 3em; margin-top: 3em;
  }
  ul.thumbs li { display: flex; flex-wrap: wrap; min-width: 135px; }
  ul.thumbs li a { display: block; margin: 0 auto; }
|}

let navigation_js = script [ async; lang "javascript" ] {|
  function nav_click(id) { document.getElementById(id)?.click(); }
  function nav_up() { nav_click("nav-up"); }
  function nav_next() { nav_click("nav-next"); }
  function nav_prev() { nav_click("nav-prev"); }
  document.addEventListener("keyup", function (event) {
    if (event.metaKey || event.altKey || event.ctrlKey) return;
    if (event.key == 'ArrowLeft') return nav_prev();
    if (event.key == 'ArrowRight') return nav_next();
    if (event.key == 'Escape') return nav_up();
  });
  var touches = {};
  document.addEventListener("touchstart", function(event) {
    var touch = event.changedTouches[0];
    touches[event.changedTouches[0].identifier] = function(end_touch) {
      var dx = end_touch.screenX - touch.screenX;
      var dy = end_touch.screenY - touch.screenY;
      if ( Math.abs(dy) > Math.abs(dx) ) return;
      if ( dx < -40 ) return nav_next();
      if ( dx >  40 ) return nav_prev();
    };
  });
  document.addEventListener("touchend", function(event) {
    var touch = event.changedTouches[0];
    touches[touch.identifier](touch);
  });
  document.addEventListener("touchcancel", function(event) {
    touches.removeAttribute(event.target.changedTouches[0]);
  });
|}

(* HELPERS *)

let current_year = (Unix.time () |> Unix.gmtime).tm_year + 1900
let blank_to_option s = if String.equal "" (String.trim s) then None else Some s
let format_title title = blank_to_option title |> Option.value ~default:"Untitled"

(* TEMPLATES *)

let page ?(extra_head = []) (page_title : string) (contents : node list) =
  html [lang "en"] [
    head [] ([
        meta [ charset "utf-8" ];
        meta [ name "viewport"; content "width=device-width, initial-scale=1, viewport-fit=cover" ];
        title [] "%s | Steve Purcell Photography" page_title;
        meta [ string_attr "property" "og:title"; content "%s" page_title; ];
        meta [ string_attr "property" "og:site_name"; content "Steve Purcell Photography"; ];
        meta [ string_attr "property" "og:type"; content "article"; ];
        style [ type_ "text/css" ] "%s" site_css;
        script [ defer; string_attr "data-domain" "purcellimages.com"; src "https://plausible.io/js/script.js" ] "";
      ] @ extra_head);
    header [] [
      nav [] [
        ul [ class_ "horizontal" ] [
          li [ class_ "primary" ] [ a [href "/"] [txt "Steve Purcell Photography"] ];
          li [] [ a [href "/galleries"] [txt "Galleries"] ];
        ]
      ]
    ];
    body [] contents;
    footer [] [
      p [] [
        txt "Copyright © 2002-%d Steve Purcell. Reproduction in whole or in part without written permission is prohibited." current_year];
      nav [] [
        ul [ class_ "horizontal" ] [
          li [] [ a [href "mailto:contact@purcellimages.com"] [txt "Email me"] ];
          li [] [ a [href "https://hachyderm.io/@sanityinc"; rel "me"; class_ "mastodon-link" ] [ txt "Follow me on Mastodon" ]];
          li [] [ a [ href "https://github.com/purcell/purcellimages2" ] [ txt "Source code"] ];
        ]]
    ]
  ]

let home =
  page "Welcome" [
    h1 [] [ txt "Welcome"];
    p [] [ txt {| After a long time offline, as of August 2025 I've brought back this site's collection
                  of photos taken during the early 2000s in locations around the world.|}];
    p [] [ txt {| Most photos were taken on black and white 35mm film with analog equipment,
                  usually a Leica M6, and developed, scanned and printed by hand. I became obsessed with manual control,
                  eventually even abandoning light meters. I preferred to miss a shot than to take multiple frames,
                  and came to staunchly avoid cropping. |}];
    p [] [ txt {| The photos are presented in their original rather small and inconsistently-adjusted form — quirky borders and all.
                  With luck I will upgrade them in time. |}];
    p [] [ a [ href "/galleries" ] [ txt "To the galleries →" ]]
  ]

let photo base_url (photo : Db.photo_meta) (context : Db.gallery_photo_context) =
  let page_title = [
    Some (format_title photo.title);
    blank_to_option photo.location;
    Option.map string_of_int photo.year
  ] |> List.concat_map Option.to_list |> String.concat ", " in
  let og_tags = [
    meta [ string_attr "property" "og:url"; content "%s/galleries/%s/%d" base_url context.gallery_name photo.id ];
    meta [ string_attr "property" "og:image"; content "%s/images/large/%d" base_url photo.id;];
    meta [ string_attr "property" "og:image:width"; content "%d" photo.large_width;];
    meta [ string_attr "property" "og:image:height"; content "%d" photo.large_height;];
  ] in
  page ~extra_head:og_tags
    page_title
    [ navigation_js;
      article [ class_ "photo-page" ] [
        nav [] [
          ul [ class_ "horizontal" ] (
            (context.prev_photo |> Option.map (fun p -> li [] [a [href "/galleries/%s/%d" context.gallery_name p; id "nav-prev"] [txt "← Previous"]]) |> Option.to_list)
            @ [ li [ class_ "primary" ] [a [href "/galleries/%s" context.gallery_name; id "nav-up"] [txt "%s" context.gallery_title]]]
            @ (context.next_photo |> Option.map
                 (fun p -> li [] [a [href "/galleries/%s/%d" context.gallery_name p; id "nav-next"] [txt "Next →"]])
               |> Option.to_list);
          )
        ];
        h1 [] [txt "%s" page_title];
        img [class_ "large"; width "%d" photo.large_width; height "%d" photo.large_height; src "/images/large/%d" photo.id];
        ul [class_ "horizontal"]
          ([photo.camera; photo.lens; photo.film;
            (if String.length photo.tech_comments > 0
             then Some photo.tech_comments else None)]
           |> List.concat_map Option.to_list |> List.map (fun i -> li [] [txt "%s" i])
          )
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
    [ article [] [
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
