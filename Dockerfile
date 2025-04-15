FROM public.ecr.aws/docker/library/ruby:3.4.3-slim-bookworm AS builder
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y install --no-install-recommends build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && bundle install \
  && rm -rf /root/.bundle/cache \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -regex ".*\.[cho]" -delete

FROM public.ecr.aws/docker/library/ruby:3.4.3-slim-bookworm
COPY --from=builder /usr/local/bundle /usr/local/bundle
WORKDIR /work
VOLUME /work
USER nobody:nogroup
ENV HOME=/tmp
ENTRYPOINT ["rubocop"]
