defmodule VisitJsonRedisTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @tag redis_test: true
  test "Connection" do
    VisitJson.TestHelpers.clear_redis_links()
    time = :os.system_time(:second)

    {:ok, links} = VisitJson.Redix.get_links(0, time)

    assert length(links) == 0
  end

  @tag inserts: true
  test "Inserts" do
    tests = [
      %{input: ["ya.ru", "google.ru"], from: 0, to: :current_time, length: 2},
      %{input: ["ya.ru", "ya.ru", "google.ru"], from: 0, to: :current_time, length: 2},
    ]

    Enum.each(
      tests,
      fn elem ->
        VisitJson.TestHelpers.clear_redis_links()
        time = if elem.to == :current_time do
          :os.system_time(:second)
        else
          elem.to
        end

        VisitJson.Redix.insert_domains_by_time(elem.input, time)
        {:ok, links} = VisitJson.Redix.get_links(elem.from, time)

        assert length(links) == elem.length
      end
    )
  end

  test "Complex insert" do
    tests = [
      %{
        inputs: [
          %{data: ["ya.ru", "google.ru"], insert_time: 50},
          %{data: ["funbox.ru"], insert_time: 75},
          %{data: ["ya.ru"], insert_time: 100}
        ],
        from: 55,
        to: 105,
        waiting: 2
      },
      %{
        inputs: [
          %{data: ["ya.ru", "google.ru"], insert_time: 50},
          %{data: ["funbox.ru"], insert_time: 75},
          %{data: ["ya.ru"], insert_time: 100}
        ],
        from: 0,
        to: 110,
        waiting: 3
      }
    ]

    Enum.each(
      tests,
      fn elem ->
        VisitJson.TestHelpers.clear_redis_links()

        Enum.each(
          elem.inputs,
          fn elem ->
            VisitJson.Redix.insert_domains_by_time(elem.data, elem.insert_time)
          end
        )

        time = if elem.to == :current_time do
          :os.system_time(:second)
        else
          elem.to
        end

        {:ok, links} = VisitJson.Redix.get_links(elem.from, time)

        assert length(links) == elem.waiting
      end
    )
  end
end