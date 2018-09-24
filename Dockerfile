FROM ruby

RUN apt-get update && apt-get -y install openssl sed grep mktemp curl git

ENV LANG C.UTF-8
COPY entrypoint.sh dnsimple_hook.rb Gemfile Gemfile.lock / 

RUN chmod +x /entrypoint.sh && bundle install && git clone https://github.com/lukas2511/dehydrated /checkout/dehydrated && cp /checkout/dehydrated/dehydrated /dehydrated && chmod +x /dehydrated

ENTRYPOINT ["/entrypoint.sh"]
