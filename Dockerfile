FROM ruby

RUN apt-get update && apt-get -y install openssl sed grep mktemp curl git

ENV LANG C.UTF-8
COPY dnsimple_hook.rb Gemfile Gemfile.lock entrypoint.sh /github/workspace/ 

RUN cd /github/workspace && chmod +x /github/workspace/entrypoint.sh && bundle install 
RUN git clone https://github.com/lukas2511/dehydrated /checkout/dehydrated
RUN cp /checkout/dehydrated/dehydrated /github/workspace/ && chmod +x /github/workspace/dehydrated

RUN pwd && ls && /github/workspace/dehydrated

ENTRYPOINT ["/entrypoint.sh"]
