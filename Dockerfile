FROM docker.io/library/ruby:4.0.9-slim-trixie AS builder
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y --no-install-recommends install build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && bundle install \
  && rm -rf /root/.bundle/cache \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -regex ".*\.[cho]" -delete

FROM docker.io/library/ruby:4.0.9-slim-trixie
# TODO: Remove package upgrades once base image includes apt and libapt-pkg7.0 >= 3.0.4 (CVE-2026-109518)
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y --no-install-recommends --only-upgrade install apt libapt-pkg7.0 \
  && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/bundle /usr/local/bundle
WORKDIR /work
VOLUME /work
# nobody:nogroup
USER 65534:65534
ENV HOME=/tmp
ARG SOURCE_COMMIT
LABEL org.opencontainers.image.revision=$SOURCE_COMMIT
ENTRYPOINT ["rubocop"]
