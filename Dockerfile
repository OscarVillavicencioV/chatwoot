FROM ruby:3.1

# Instala dependencias del sistema
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client yarn

ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=dummy_placeholder # Este valor será reemplazado por una variable de entorno en Railway

WORKDIR /app

COPY . .

RUN gem install bundler && bundle install --without development test
RUN yarn install --check-files
RUN bundle exec rake assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
