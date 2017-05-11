defmodule SSDB.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ssdb,
      version: "0.3.1",
      elixir: ">= 1.0.0",
      deps: deps(),
      description: description(),
      source_url: "https://github.com/lidashuang/ssdb-elixir",
      homepage_url: "https://github.com/lidashuang/ssdb-elixir",
      docs: [main: "SSDB", extras: ["README.md"]],
      package: package()
    ]
  end

  def application do
    [applications: []]
  end

  defp description do
    "SSDB client for Elixir"
  end

  defp deps do
    [{:ex_doc, "~> 0.14", only: :dev, runtime: false}]
  end

  defp package do
    [
      contributors: ["lidashuang"],
      maintainers: ["lidashuang"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/lidashuang/ssdb-elixir"}
    ]
  end
end
