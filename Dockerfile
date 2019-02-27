FROM ruby:alpine
RUN apk update \
  && apk add --no-cache --virtual=.build-dependencies gcc make musl-dev \
  && gem install rubocop \
  && apk del .build-dependencies
WORKDIR /work
VOLUME /work
ENTRYPOINT ["rubocop"]
