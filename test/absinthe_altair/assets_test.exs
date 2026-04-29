defmodule AbsintheAltair.AssetsTest do
  use ExUnit.Case, async: true

  alias AbsintheAltair.Assets

  test "cdn_base_url/1 returns versioned CDN URL" do
    assert Assets.cdn_base_url("8.5.2") ==
             "https://cdn.jsdelivr.net/npm/altair-static@8.5.2/build/dist/"
  end

  test "cdn_base_url/0 uses default version" do
    url = Assets.cdn_base_url()
    assert String.contains?(url, Assets.default_version())
    assert String.ends_with?(url, "/build/dist/")
  end

  test "default_version/0 returns a version string" do
    version = Assets.default_version()
    assert is_binary(version)
    assert version =~ ~r/^\d+\.\d+\.\d+$/
  end
end
