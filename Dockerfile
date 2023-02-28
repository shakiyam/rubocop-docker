FROM ghcr.io/ruby/ruby:3.2-jammy
ENV GEM_HOME=/usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
RUN bundle install \
  && rm -rf /root/.bundle/cache \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -regex ".*\.[cho]" -delete
WORKDIR /work
VOLUME /work
ENV HOME /tmp
ENTRYPOINT ["rubocop"]
