defmodule VisitJson.Helpers do
  @moduledoc false

  def get_domains_from_links(links) do
    Enum.map(links, fn link -> get_domain_from_link(link) end)
  end

  def get_domain_from_link(link) do
    authority = URI.parse(link).authority

    authority = if authority == nil do
      URI.parse("//" <> link).authority
    else
      authority
    end

    authority
    # www.ru.domain.com
    |> String.split(".")
      # get last 2 elems - domain.com
    |> Enum.take(-2)
    |> Enum.join(".")
  end
end
