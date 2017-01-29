#!/usr/bin/env ruby
require 'dnsimple'

debug = true
DNSIMPLE_API_TOKEN = ENV["DNSIMPLE_API_TOKEN"]

if debug
  @client = Dnsimple::Client.new(base_url: "https://api.sandbox.dnsimple.com", access_token: DNSIMPLE_API_TOKEN)
else
  @client = Dnsimple::Client.new(access_token: DNSIMPLE_API_TOKEN)
end

# Iterate domain list to return Subdomain and Top-level domains
def find_domain(account_id, full_domain_name)

  return_val = {
    "domain_name" => "",
    "subdomain_name" => ""
   }

  domains = @client.domains.list_domains(account_id).data

  domains.each do |domain|
    domain_name = domain.name
    if full_domain_name.include? domain_name
      return_val["domain_name"] = domain_name
      return_val["subdomain_name"] = full_domain_name.chomp(".#{domain_name}")
    end
  end
  return_val
end

def setup_dns(account_id, domain, subdomain_name, txt_challenge)
  acme_domain = "_acme-challenge."+subdomain_name

  begin
    @client.zones.create_record(account_id, domain, name: acme_domain, type: "TXT", content: txt_challenge)
  rescue Dnsimple::RequestError => text
    # Catch Error 'Zone record already exists'
    puts text
  end
end

def delete_dns(domain, txt_challenge)
  puts "Challenge complete. Leave TXT record in place to allow easier future refreshes."
end

if __FILE__ == $0
  hook_stage = ARGV[0]
  full_domain_name = ARGV[1]
  txt_challenge = ARGV[3]

  account = @client.accounts.list
  account_id = account.data[0].id

  domain_hash = find_domain(account_id, full_domain_name)
  if domain_hash["domain_name"] != ""
    response = @client.domains.domain(account_id, domain_hash["domain_name"])

    if hook_stage == "deploy_challenge"
      puts "deploy"
      setup_dns(account_id, domain_hash["domain_name"], domain_hash["subdomain_name"] , txt_challenge)
    elsif hook_stage == "clean_challenge"
      puts "clean"
      delete_dns(full_domain_name, txt_challenge)
    end
  end
end
