FROM ruby:3.1

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client yarn

WORKDIR /app

COPY . .

RUN gem install bundler && bundle install
RUN yarn install --check-files

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
