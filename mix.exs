defmodule Exbackoff.Mixfile do
  use Mix.Project

  @version "0.0.4"

  def project do
    [app: :exbackoff,
     version: @version,
     elixir: "~> 1.2",
     description: description(),
     package: package(),
     source_url: "https://github.com/mingchuno/exbackoff",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     docs: [extras: ["README.md"], main: "readme",
              source_ref: "v#{@version}",
              source_url: "https://github.com/mingchuno/exbackoff"]
    ]
  end

  defp description do
    """
    Simple exponential backoffs in Elixir.
    """
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:excheck, "~> 0.3.2", only: :test},
      {:earmark, "~> 0.2", only: :docs},
      {:ex_doc, "~> 0.11", only: :docs},
      {:inch_ex, "~> 0.5", only: :docs},
      {:triq, github: "krestenkrab/triq", only: :test}
    ]
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["MC Or"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mingchuno/exbackoff"}]
  end
end
