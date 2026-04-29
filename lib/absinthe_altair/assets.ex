defmodule AbsintheAltair.Assets do
  @moduledoc """
  Manages CDN URLs for the Altair GraphQL Client static assets.
  """

  @default_version "8.5.2"
  @cdn_base "https://cdn.jsdelivr.net/npm/altair-static@"

  @doc """
  Returns the CDN base URL for the Altair static distribution.

  The returned URL points to the `build/dist/` directory of the `altair-static`
  npm package. When used as an HTML `<base href>`, all relative asset references
  (JS, CSS, fonts, chunks) resolve automatically from the CDN.
  """
  @spec cdn_base_url(String.t()) :: String.t()
  def cdn_base_url(version \\ @default_version) do
    "#{@cdn_base}#{version}/build/dist/"
  end

  @doc """
  Returns the default altair-static version.
  """
  @spec default_version() :: String.t()
  def default_version, do: @default_version
end
