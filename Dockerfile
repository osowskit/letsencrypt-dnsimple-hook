FROM ruby:2.5.1-alpine3.7

RUN apt-get update && apt-get -y install openssl sed grep mktemp curl git

ENV LANG C.UTF-8


RUN git clone https://github.com/lukas2511/dehydrated
COPY dnsimple_hook.rb Gemfile Gemfile.lock entrypoint.sh ./ 
RUN cp dehydrated/dehydrated ./dehydrated
RUN chmod +x /entrypoint.sh && chmod +x /dehydrated.sh && bundle install

ENTRYPOINT ["/entrypoint.sh"]
