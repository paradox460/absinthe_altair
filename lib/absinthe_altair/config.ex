defmodule AbsintheAltair.Config do
  @moduledoc """
  Handles configuration resolution and JavaScript initialization for the
  Altair GraphQL Client plug.

  Any snake_case Elixir option key is automatically converted to its camelCase
  JavaScript equivalent (e.g. `:initial_query` becomes `initialQuery`). This
  means all [Altair configuration properties](https://altairgraphql.dev/api/core/config/classes/AltairConfig)
  are supported — not just a hardcoded subset.

  Configuration values can be static strings/maps or `{module, function}` tuples
  that are resolved at request time. Functions may accept zero arguments or one
  argument (the `Plug.Conn`).
  """

  @internal_keys [:altair_version, :schema, :absinthe_plug_config]

  @doc """
  Resolves all dynamic configuration values and builds the template config map.

  Returns a map with `:base_url` and `:init_options_js` keys ready for the
  EEx template.
  """
  @spec resolve_options(map(), Plug.Conn.t()) :: map()
  def resolve_options(opts, conn) do
    resolved =
      opts
      |> Map.drop(@internal_keys)
      |> Map.new(fn {k, v} -> {k, resolve_value(v, conn)} end)

    %{
      base_url: AbsintheAltair.Assets.cdn_base_url(opts[:altair_version]),
      init_options_js: build_init_options(resolved)
    }
  end

  @doc """
  Resolves a configuration value. Static values pass through unchanged.
  `{module, function}` tuples are called with the conn (arity 1) or without
  arguments (arity 0).
  """
  @spec resolve_value(term(), Plug.Conn.t()) :: term()
  def resolve_value({mod, fun}, conn) when is_atom(mod) and is_atom(fun) do
    Code.ensure_loaded!(mod)

    cond do
      function_exported?(mod, fun, 1) -> apply(mod, fun, [conn])
      function_exported?(mod, fun, 0) -> apply(mod, fun, [])
      true -> raise ArgumentError, "#{inspect(mod)}.#{fun}/0 or /1 is not exported"
    end
  end

  def resolve_value(value, _conn), do: value

  @doc """
  Converts a snake_case atom to a camelCase string.

  The special key `:endpoint_url` is converted to `"endpointURL"` to match
  Altair's expected casing.

  ## Examples

      iex> AbsintheAltair.Config.to_js_key(:initial_query)
      "initialQuery"

      iex> AbsintheAltair.Config.to_js_key(:endpoint_url)
      "endpointURL"

  """
  @spec to_js_key(atom()) :: String.t()
  def to_js_key(:endpoint_url), do: "endpointURL"

  def to_js_key(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> camelize()
  end

  @doc """
  Builds a JavaScript object literal string for `AltairGraphQL.init()`.

  String values are escaped and quoted. Map values are JSON-encoded.
  A nil `endpoint_url` produces an unquoted JS expression using `window.location`.
  Nil/absent options are omitted.
  """
  @spec build_init_options(map()) :: String.t()
  def build_init_options(config) do
    pairs =
      config
      |> Enum.sort_by(fn {k, _} -> Atom.to_string(k) end)
      |> Enum.map(fn {key, value} -> js_pair(key, value) end)
      |> Enum.reject(&is_nil/1)

    case pairs do
      [] -> "{}"
      _ -> "{\n#{Enum.join(pairs, ",\n")}\n    }"
    end
  end

  @doc """
  Escapes a string for safe interpolation inside a JavaScript single-quoted string.
  """
  @spec js_escape(String.t()) :: String.t()
  def js_escape(string) when is_binary(string) do
    string
    |> String.replace("\\", "\\\\")
    |> String.replace("'", "\\'")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("</", "<\\/")
  end

  defp js_pair(:endpoint_url, nil) do
    "      endpointURL: window.location.origin + window.location.pathname"
  end

  defp js_pair(key, value) when is_binary(value) and value != "" do
    "      #{to_js_key(key)}: '#{js_escape(value)}'"
  end

  defp js_pair(key, value) when is_map(value) and map_size(value) > 0 do
    "      #{to_js_key(key)}: #{JSON.encode!(value)}"
  end

  defp js_pair(key, value) when is_boolean(value) do
    "      #{to_js_key(key)}: #{value}"
  end

  defp js_pair(key, value) when is_number(value) do
    "      #{to_js_key(key)}: #{value}"
  end

  defp js_pair(key, value) when is_list(value) and value != [] do
    "      #{to_js_key(key)}: #{JSON.encode!(value)}"
  end

  defp js_pair(_key, _value), do: nil

  defp camelize(string) do
    [first | rest] = String.split(string, "_")
    Enum.join([first | Enum.map(rest, &String.capitalize/1)])
  end
end
