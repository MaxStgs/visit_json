defmodule VisitJson.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # *mark* Is it fine code? I used port twice
    port = Application.fetch_env!(:visit_json, :port)
    redis_port = Application.fetch_env!(:visit_json, :redis_port)
    
    children = [
      # Starts a worker by calling: VisitJson.Worker.start_link(arg)
      # {VisitJson.Worker, arg}
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: VisitJson.Endpoint,
        options: [port: port]
      ),
      {Redix, name: :redix, port: redis_port}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VisitJson.Supervisor]
    IO.puts "Server started at localhost:#{port}/"
    Supervisor.start_link(children, opts)
  end
end
