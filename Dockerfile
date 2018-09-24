FROM ruby

RUN apt-get update && apt-get -y install openssl sed grep mktemp curl git

ENV LANG C.UTF-8
COPY entrypoint.sh dnsimple_hook.rb /
COPY Gemfile Gemfile.lock /workspace/ 

RUN chmod +x /entrypoint.sh && cd /workspace && bundle install 
RUN git clone https://github.com/lukas2511/dehydrated /checkout/dehydrated
RUN cp /checkout/dehydrated/dehydrated /workspace/ && chmod +x /workspace/dehydrated

ENTRYPOINT ["/entrypoint.sh"]
