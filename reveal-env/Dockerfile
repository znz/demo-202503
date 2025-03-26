FROM ruby:3.4.2
COPY Gemfile* config.ru /app/
WORKDIR /app
RUN bundle install
EXPOSE 9292
CMD [ "bundle", "exec", "rackup" ]
