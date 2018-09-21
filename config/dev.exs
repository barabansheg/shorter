use Mix.Config

config :link,
    db_url: System.get_env("DB_URL") || "mongodb://localhost:27017/urls"