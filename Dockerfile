FROM ruby:2.5-alpine
MAINTAINER gwu@vmware.com

RUN apt-get update && apt-get install -y \ 
  build-essential \ 
  nodejs

RUN mkdir -p /app 
WORKDIR /app

COPY VERSION Gemfile *.gemspec ./ 
RUN gem install bundler && bundle install --jobs 20 --retry 5
