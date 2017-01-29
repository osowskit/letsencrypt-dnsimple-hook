#!/usr/bin/env ruby

require 'resolv'
require 'uri'
require 'net/http'
require 'openssl'
require 'JSON'
debug = true

if debug
  DNSIMPLE_TOKEN = # DNS Sandbox Token
else
  DNSIMPLE_TOKEN = # DNS Production Token
end

if debug
  @api_host = "https://api.sandbox.dnsimple.com/v2"
else
  @api_host = "https://api.dnsimple.com/v2"
end

def get(url)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(url)
  request["authorization"] = "Bearer #{DNSIMPLE_TOKEN}"
  request["accept"] = 'application/json'
  request["cache-control"] = 'no-cache'

  response = http.request(request)
  return JSON.parse(response.body)
end

def post(url, domain, challenge_txt)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Post.new(url)
  request["authorization"] = "Bearer #{DNSIMPLE_TOKEN}"
  request["accept"] = 'application/json'
  request["cache-control"] = 'no-cache'
  request["content-type"] = 'application/json'

  json_body = {
    name: "_acme-challenge.#{domain}",
    type: "TXT",
    content: "#{challenge_txt}",
  }.to_json

  puts json_body
  request.body = json_body

  response = http.request(request)
  return JSON.parse(response.body)
end

def find_domain(account_id, full_domain_name)

  return_val = {
    "domain_name" => "",
    "subdomain_name" => ""
   }

  # Get top level registered domains
  url = URI("#{@api_host}/#{account_id}/domains")
  response = get(url)

  domains = response['data']
  domains.each do |domain|
    domain_name = domain["name"]
    if full_domain_name.include? domain_name
      return_val["domain_name"] = domain_name
      return_val["subdomain_name"] = full_domain_name.chomp(".#{domain_name}")
    end
  end
  return_val
end

def setup_dns(domain, txt_challenge)
  resolved = false;
  singleLoop = false;
  dns = Resolv::DNS.new;
  acme_domain = "_acme-challenge."+domain;
  puts "Checking for pre-existing TXT record for the domain: \"#{acme_domain}\"."

  until resolved
    dns.each_resource(acme_domain, Resolv::DNS::Resource::IN::TXT) { |resp|
     if resp.strings[0] == txt_challenge
       puts "Found #{resp.strings[0]}. match."
       resolved = true;
     else
       puts "Found #{resp.strings[0]}. no match."
     end
    }

    if !resolved
     if !singleLoop
       puts "Create TXT record for the domain: \"#{acme_domain}\". TXT record:"
       puts "\"#{txt_challenge}\""
       puts "Press enter when DNS has been updated..."
       $stdin.readline()
       singleLoop = true
     end

     puts "Didn't find a match for #{txt_challenge}";
     puts "Waiting to retry...";
     sleep 30;
    end
  end
end

def delete_dns(domain, txt_challenge)
  puts "Challenge complete. Leave TXT record in place to allow easier future refreshes."
end

if __FILE__ == $0
  hook_stage = ARGV[0]
  full_domain_name = ARGV[1]
  txt_challenge = ARGV[3]

  url = URI("#{@api_host}/accounts")
  response = get(url)

  account_id = response['data'][0]['id']

  #verify if account has domain
  puts domain_hash = find_domain(account_id, full_domain_name)

  #assert value


  if hook_stage == "deploy_challenge"
    domain_name = domain_hash["domain_name"]
    url = URI("#{@api_host}/#{account_id}/zones/#{domain_name}/records")

    puts response = post(url, domain_hash["subdomain_name"], txt_challenge)
    #setup_dns(domain, txt_challenge)
  elsif hook_stage == "clean_challenge"
    puts "clean"
    delete_dns(full_domain_name, txt_challenge)
  end

end
