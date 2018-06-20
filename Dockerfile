FROM elixir:latest

ADD mix.exs /src/
ADD lib/ /src/lib
ADD config/ /src/config

WORKDIR /src

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile

ENTRYPOINT ["mix", "run", "--no-halt"]
EXPOSE 8080
