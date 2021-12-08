FROM ruby:alpine
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
# hadolint ignore=DL3018
RUN apk add --no-cache --virtual=.build-dependencies gcc make musl-dev \
  && bundle install \
  && rm -rf /root/.bundle/cache \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -regex ".*\.[cho]" -delete \
  && apk del --purge .build-dependencies
WORKDIR /work
VOLUME /work
ENTRYPOINT ["rubocop"]
