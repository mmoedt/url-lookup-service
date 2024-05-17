# url-lookup-service

Fast REST service to verify safety of URLs

# Purpose

This service handles HTTP GET requests like the following:

`GET /v1/urlinfo/{resource_url_with_query_string}`

and returns a response indicatig whether the URL is safe or not.


# Instructions

The script ./do in the top level directory is used for common tasks such
as compilation, testing, and ...

Simply run the script without arguments to see the subcommands that are supported
and their options.
