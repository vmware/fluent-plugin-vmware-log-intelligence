FROM ruby:2.5
MAINTAINER slk@vmware.com

RUN apt-get update && apt-get install -y \
  build-essential \
  nodejs

RUN mkdir -p /app

COPY ./ /app/
WORKDIR /app
RUN gem build fluent-plugin-vmware-log-intelligence.gemspec

RUN gem install bundler && bundle install --jobs 20 --retry 5
RUN gem install fluent-plugin-vmware-log-intelligence
RUN gem list

RUN find ! -name 'dev-docker-build.sh' ! -name 'dev-docker-run.sh' ! -name '*.gem' -delete