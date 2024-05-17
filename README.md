# url-lookup-service

Fast REST service to verify safety of URLs

# Purpose

This service handles HTTP GET requests like the following:

`GET /v1/urlinfo/{resource_url_with_query_string}`

and returns a response indicating whether the URL is safe or not.
The response is JSON formatted, and uses the value 'safe' with a boolean result
 to indicate whether the URL is safe or not.
(There may be other values, which can be ignored.)

For example, the output would simply be:
`{"safe":true}`
or
`{"safe":false}`


# Instructions

The script ./do in the top level directory is used for common tasks such
as compilation, testing, and ...

Simply run the script without arguments to see the subcommands that are supported
and their options.

To run the service locally, run:

`./do run`

And then the service can be reached at `http://localhost:8000`.


The API is documented using the OpenAPI standard, and can be found in the file docs/openapi.json

While the service is running, you can also see the API documented,
  and test requests, at `http://localhost:8000/docs`
