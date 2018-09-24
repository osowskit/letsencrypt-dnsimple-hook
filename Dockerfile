FROM ruby

RUN apt-get update && apt-get -y install openssl sed grep mktemp curl git

ENV LANG C.UTF-8
COPY dnsimple_hook.rb Gemfile Gemfile.lock entrypoint.sh ./ 

RUN git clone https://github.com/lukas2511/dehydrated && chmod +x /entrypoint.sh && bundle install 

RUN chmod +x dehydrated/dehydrated

RUN ls
RUN ls /dehydrated

ENTRYPOINT ["/entrypoint.sh"]
