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
# TODO: Remove package upgrades once base image includes zlib1g >= 1:1.3.dfsg+really1.3.1-1+deb13u1 (CVE-2026-76844, CVE-2026-85091)
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y --no-install-recommends --only-upgrade install zlib1g \
  && rm -rf /var/lib/apt/lists/*
# TODO: Remove json cleanup once base image includes json >= 2.19.9 (CVE-2026-33210, CVE-2026-54696)
RUN rm -f /usr/local/lib/ruby/gems/*/specifications/default/json-*.gemspec \
  && ruby_lib=$(ruby -e 'puts RbConfig::CONFIG["rubylibdir"]') \
  && ruby_arch=$(ruby -e 'puts RbConfig::CONFIG["rubyarchdir"]') \
  && rm -r "$ruby_lib/json.rb" "$ruby_lib/json" "$ruby_arch/json"
COPY --from=builder /usr/local/bundle /usr/local/bundle
WORKDIR /work
VOLUME /work
# nobody:nogroup
USER 65534:65534
ENV HOME=/tmp
ARG SOURCE_COMMIT
LABEL org.opencontainers.image.revision=$SOURCE_COMMIT
ENTRYPOINT ["rubocop"]
