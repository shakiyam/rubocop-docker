FROM ghcr.io/ruby/ruby:3.2-jammy
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
RUN bundle install && rm -rf /root/.bundle/cache
WORKDIR /work
VOLUME /work
ENV HOME /tmp
ENTRYPOINT ["rubocop"]
