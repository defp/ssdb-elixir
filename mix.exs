defmodule SSDB.Mixfile do
  use Mix.Project

  def project do
    [app: :ssdb_elixir,
     version: "0.2.2",
     elixir: "~> 0.14.2",
     deps: deps,
     description: description,
     source_url: "https://github.com/lidashuang/ssdb_elixir",
     package: package ]
  end

  def application do
    [applications: []]
  end

  defp description do
    "SSDB client for Elixir"
  end

  defp deps do
    []
  end

  defp package do
    [contributors: ["lidashuang"],
     licenses: ["Apache 2.0"],
     links: %{"Github" => "https://github.com/lidashuang/ssdb_elixir"}]
  end
end
