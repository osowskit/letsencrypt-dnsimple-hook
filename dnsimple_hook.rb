#!/usr/bin/env ruby
require 'dnsimple'
require 'resolv'
require 'public_suffix'
$stdout.sync = true

debug = true
DNSIMPLE_API_TOKEN = ENV["DNSIMPLE_API_TOKEN"]
@dns = Resolv::DNS.new

if debug
  @client = Dnsimple::Client.new(base_url: "https://api.sandbox.dnsimple.com", access_token: DNSIMPLE_API_TOKEN)
else
  @client = Dnsimple::Client.new(access_token: DNSIMPLE_API_TOKEN)
end

# This function ensures that you are able to control that first level
# domain via your DNSimple account
def verify_domain_control(account_id, domain_name)
  domains = @client.domains.list_domains(account_id).data
  domains.each do |domain|
    dns_simple_domain_name = domain.name
    if dns_simple_domain_name.eql? domain_name
      puts 'verified domain control'
      return
    end
  end
  
  # Stop execution of this script if the API key can't control
  # this domain
  exit
end

# This function returns the result of a specific text string(the challenge) 
# being stored in a DNS TXT record for a domain(challenge_fqdn)
def verify_record(challenge_fqdn, challenge)

  @dns.each_resource(challenge_fqdn, Resolv::DNS::Resource::IN::TXT) { |resp|
    if resp.strings[0] == challenge
      return true
    end
  }
  return false
end
  
def setup_dns(account_id, domain, subdomain_name, txt_challenge)
  acme_domain = "_acme-challenge."+subdomain_name

  begin
    @client.zones.create_record(account_id, domain, name: acme_domain, type: "TXT", ttl: 60, content: txt_challenge)
    puts "waiting for domain propogation"

    until verify_record(acme_domain +"."+ domain, txt_challenge)
     print "."
     sleep 10
    end
  rescue Dnsimple::RequestError => text
    # Catch Error 'Zone record already exists'
    puts text
  end
  puts
end

def delete_dns(domain, txt_challenge)
  puts "Challenge complete. Leave TXT record in place to allow easier future refreshes."
end

if __FILE__ == $0
  hook_stage = ARGV[0]

  account = @client.accounts.list
  account_id = account.data[0].id

  if hook_stage == "deploy_challenge"
    full_domain_name = ARGV[1]
    txt_challenge = ARGV[3]

    # Split domain for DNSimple API
    ps_domain = PublicSuffix.parse(full_domain_name)
    domain_name = ps_domain.domain
    subdomain_name = ps_domain.trd

    # Search for domain in DNSimple or stop script
    verify_domain_control(account_id, domain_name)

    # Add TXT record and verify the record exists via API
    # before continuing
    setup_dns(account_id, domain_name, subdomain_name, txt_challenge)
  elsif hook_stage == "clean_challenge"
    full_domain_name = ARGV[1]
    txt_challenge = ARGV[3]
    delete_dns(full_domain_name, txt_challenge)
  end
end
