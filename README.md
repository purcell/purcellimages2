# Source for [purcellimages.com](https://www.purcellimages.com)

This site was originally written in PHP, and ran for almost two
decades without code changes until it went offline as part of a server
change.

Fortunately, I had a backup of the original PostgreSQL database, which
also included all the images.

Restoring the site was not a priority, and was quite daunting because
it relied on Apache redirects etc, and I had no intention of running
Apache in 2025.

I finally decided I could live with a very minimal version. I
considered generating a static site with something like Hugo, but
finally decided to use [Ocaml](https://ocaml.org) as an excuse to try
the [Dream web framework](https://aantron.github.io/dream/). Dream
provides everything necessary, including templating and PostgreSQL
bindings.

## Development flow

A Nix flake provides all the necessry build tools.

In one terminal, I run `dune build --watch`, and then when the editor (Emacs in my case)
runs `ocamllsp`, that will connect to Dune.

In another terminal, I run the resulting web server like this:

    echo ./_build/default/bin/site.exe| entr -r ./_build/default/bin/site.exe

This restarts the web server every time the program has been rebuilt.
