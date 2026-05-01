# AbsintheAltair

A [Plug](https://hexdocs.pm/plug) for embedding the [Altair GraphQL Client](https://altairgraphql.dev) into Phoenix and [Absinthe](https://hexdocs.pm/absinthe) applications.

Altair is a feature-rich GraphQL IDE with support for subscriptions, file uploads, query collections, environments, and more. This library serves the Altair single-page application directly from your Elixir app, loading assets from CDN.

## Installation

Add `absinthe_altair` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_altair, "~> 2026.4.2"}
  ]
end
```

## Usage

Add a `forward` to your Phoenix router:

```elixir
# lib/my_app_web/router.ex
scope "/" do
  forward "/altair", AbsintheAltair, endpoint_url: "/api/graphql"

  forward "/api/graphql", Absinthe.Plug, schema: MyAppWeb.Schema
end
```

Then visit `http://localhost:4000/altair` in your browser.

### With Subscriptions

```elixir
forward "/altair", AbsintheAltair,
  endpoint_url: "/api/graphql",
  subscriptions_endpoint: "ws://localhost:4000/socket/websocket",
  subscriptions_protocol: "graphql-ws"
```

### With Dynamic Headers

Configuration values can be `{module, function}` tuples resolved at request time. The function may accept a `Plug.Conn` argument (arity 1) or no arguments (arity 0):

```elixir
forward "/altair", AbsintheAltair,
  endpoint_url: "/api/graphql",
  initial_headers: {MyAppWeb.AltairHelpers, :default_headers}

# In lib/my_app_web/altair_helpers.ex
defmodule MyAppWeb.AltairHelpers do
  def default_headers(conn) do
    %{"Authorization" => "Bearer " <> (conn.assigns[:token] || "")}
  end
end
```

### Dual-Mode (UI + API on Same Path)

When `:schema` is set and `absinthe_plug` is available as a dependency, non-HTML requests (e.g. `Accept: application/json`) are delegated to `Absinthe.Plug`:

```elixir
forward "/graphql", AbsintheAltair,
  schema: MyAppWeb.Schema,
  endpoint_url: "/graphql"
```

Requests with `Accept: text/html` get the Altair UI; all other requests are handled as GraphQL API calls.

## Configuration Reference

Any [Altair configuration property](https://altairgraphql.dev/api/core/config/classes/AltairConfig) can be passed as a snake_case atom option. Keys are automatically converted to camelCase for JavaScript (e.g. `:initial_query` becomes `initialQuery`). The table below lists common options — it is not exhaustive.

| Option | Type | Default | Description |
|---|---|---|---|
| `:endpoint_url` | `binary \| {mod, fun}` | `nil` | GraphQL endpoint URL. When `nil`, defaults to `window.location` in the browser. |
| `:subscriptions_endpoint` | `binary \| {mod, fun}` | `nil` | WebSocket URL for subscriptions. |
| `:subscriptions_protocol` | `binary` | `nil` | Protocol: `"ws"`, `"graphql-ws"`, `"graphql-sse"`, `"app-sync"`, or `"action-cable"`. |
| `:initial_query` | `binary` | `""` | Pre-populated GraphQL query. |
| `:initial_variables` | `binary` | `""` | Pre-populated variables. |
| `:initial_headers` | `map \| {mod, fun}` | `%{}` | Default request headers. |
| `:initial_settings` | `map` | `nil` | Altair application settings. |
| `:altair_version` | `binary` | `"8.5.2"` | `altair-static` npm package version to load from CDN. |
| `:schema` | `atom` | `nil` | Absinthe schema module. Enables API delegation for non-HTML requests when `absinthe_plug` is available. |
| `:page_title` | `binary` | `"Altair GraphQL Client"` | Title for the HTML page. |


For the full list of supported Altair options, see the [AltairConfig API reference](https://altairgraphql.dev/api/core/config/classes/AltairConfig).

## How It Works

The plug serves an HTML page with a `<base href>` pointing to the `altair-static` distribution on [jsDelivr CDN](https://www.jsdelivr.com/package/npm/altair-static). All of Altair's JavaScript, CSS, fonts, and image assets are loaded from the CDN relative to this base URL. Configuration is passed to the Altair SPA in its init function.

No local static files are needed. The tradeoff is that an internet connection is required for the browser to load Altair's assets.

## License

```
Copyright (c) 2026 Jeffrey Sandberg

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
