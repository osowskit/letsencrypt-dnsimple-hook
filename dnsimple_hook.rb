#!/usr/bin/env ruby
require 'dnsimple'
require 'resolv'
$stdout.sync = true

debug = true
DNSIMPLE_API_TOKEN = ENV["DNSIMPLE_API_TOKEN"]
@dns = Resolv::DNS.new

if debug
  @client = Dnsimple::Client.new(base_url: "https://api.sandbox.dnsimple.com", access_token: DNSIMPLE_API_TOKEN)
else
  @client = Dnsimple::Client.new(access_token: DNSIMPLE_API_TOKEN)
end

# This function has two purposes
# * Divide your FQDN into first level domain and subdomain
# * Ensure that you are able to control that first level domain via your DNSimple account
#
# It iterates over DNSimple domains looking for a domain match
#
# Note: This verification fails if you own the domain `foo.com` and you attempt to verify `e-foo.com`
def find_domain(account_id, full_domain_name)
  
  domains = @client.domains.list_domains(account_id).data

  domains.each do |domain|
    domain_name = domain.name
    if full_domain_name.include? domain_name
      return {"domain_name" => domain_name, "subdomain_name" => full_domain_name.chomp(".#{domain_name}"};
    end
  end
  
  # if you don't can't control the domain, then no need to go on further
  exit
end

# This function returns the result of a specific text string(the challenge) 
# being stored in a DNS TXT record for a domain(challenge_fqdn)
def verify_record(challenge_fqdn, challenge)
   @dns.each_resource(challenge_fqdn, Resolv::DNS::Resource::IN::TXT) { |resp|
     return resp.strings[0] == txt_challenge      
    }
  false
end
  
def setup_dns(account_id, domain, subdomain_name, txt_challenge)
  acme_domain = "_acme-challenge."+subdomain_name

  begin
    @client.zones.create_record(account_id, domain, name: acme_domain, type: "TXT", ttl: 60, content: txt_challenge)
    puts "waiting for domain propogation"

    until verify_record(acme_domain +"."+ domain, txt_challenge)
     print "."
     sleep 10;
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
        
        // part of me wants to replace this with a much simpler method
        domain_hash = find_domain(account_id, full_domain_name)

        setup_dns(account_id, domain_hash["domain_name"], domain_hash["subdomain_name"] , txt_challenge)
      elsif hook_stage == "clean_challenge"
        full_domain_name = ARGV[1]
        txt_challenge = ARGV[3]
        delete_dns(full_domain_name, txt_challenge)
      end
end
