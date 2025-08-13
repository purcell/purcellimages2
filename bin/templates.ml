open Dream_html
open HTML

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
        style [ type_ "text/css" ] "%s" [%blob "site.css"];
        script [ defer; string_attr "data-domain" "purcellimages.com"; src "https://plausible.io/js/script.js" ] "";
      ] @ extra_head);
    body [] [
      header [] [
        nav [] [
          ul [ class_ "horizontal" ] [
            li [ class_ "primary" ] [ a [href "/"] [txt "Steve Purcell Photography"] ];
            li [] [ a [href "/galleries"] [txt "Galleries"] ];
          ]
        ]
      ];
      section [ id "contents" ] contents;
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
    [ script [ async; lang "javascript" ] "%s" [%blob "nav.js"];
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
