FROM ruby

RUN apt-get update && apt-get -y install openssl sed grep mktemp curl git

ENV LANG C.UTF-8
COPY entrypoint.sh /
COPY dnsimple_hook.rb Gemfile Gemfile.lock /github/workspace/ 

RUN chmod +x /entrypoint.sh && cd /github/workspace && bundle install 
RUN git clone https://github.com/lukas2511/dehydrated /checkout/dehydrated
RUN cp /checkout/dehydrated/dehydrated /github/workspace/ && chmod +x /github/workspace/dehydrated

ENTRYPOINT ["/entrypoint.sh"]
