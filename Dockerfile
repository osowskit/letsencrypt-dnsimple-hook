FROM ruby

RUN apt-get update && apt-get -y install openssl sed grep mktemp curl git

ENV LANG C.UTF-8
COPY dnsimple_hook.rb Gemfile Gemfile.lock entrypoint.sh ./ 

RUN chmod +x /entrypoint.sh && bundle install 
RUN git clone https://github.com/lukas2511/dehydrated ./checkout/dehydrated

RUN pwd && ls

ENTRYPOINT ["/entrypoint.sh"]
