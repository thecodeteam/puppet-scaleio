#!/opt/puppet/bin/ruby

require "trollop"
require "json"
require "timeout"
require "pathname"

puppet_dir = File.join(Pathname.new(__FILE__).parent.parent,'lib','puppet')
require "%s/scaleio/transport" % [puppet_dir]

@opts = Trollop::options do
  opt :server, "ScaleIO gateway", :type => :string, :required => true
  opt :port, "ScaleIO gateway port", :default => 443
  opt :username, "ScaleIO gateway username", :type => :string, :required => true
  opt :password, "ScaleIO gateway password", :type => :string, :default => ENV["PASSWORD"], :required => true
  opt :timeout, "ScaleIO gateway connection timeout", :type => :integer, :default => 300, :required => false
  opt :output, "Location of the file where facts file needs to be created", :type => :string, :required => false
end

def collect_scaleio_facts
  facts = {}
  facts[:scaleio_systems] = scaleio_systems
  scaleio_systems.each do |scaleio_system|
    facts[scaleio_system["id"]] = {:sds => [], :sdc => [], :protection_domains => []}
    facts[scaleio_system["id"]][:sds] = scaleio_sds(scaleio_system)
    facts[scaleio_system["id"]][:sdc] = scaleio_sdc(scaleio_system)
    facts[scaleio_system["id"]][:protection_domains] = protection_domains(scaleio_system)
    facts[scaleio_system["id"]][:volumes] = scaleio_volumes(scaleio_system)
    facts[scaleio_system["id"]][:fault_sets] = scaleio_faultsets(scaleio_system)
    facts[scaleio_system["id"]][:protection_domains].each do |protection_domain|
      facts[scaleio_system["id"]][protection_domain["id"]] ||= {}
      facts[scaleio_system["id"]][protection_domain["id"]][:storage_pools] = storage_pools(scaleio_system, protection_domain)
      facts[scaleio_system["id"]][protection_domain["id"]][:storage_pools].each do |storage_pool|
        facts[scaleio_system["id"]][protection_domain["id"]][storage_pool["id"]] ||= {}
        facts[scaleio_system["id"]][protection_domain["id"]][storage_pool["id"]][:disks] = disks(storage_pool)
      end
    end
  end
  facts
end

def scaleio_systems
  url = transport.get_url("/api/types/System/instances")
  transport.post_request(url, {}, "get") || []
end

def scaleio_sds(scaleio_system)
  sds_url = "/api/types/Sds/instances?systemId=%s" % [scaleio_system["id"]]
  url = transport.get_url(sds_url)
  transport.post_request(url, {}, "get") || []
end

def scaleio_sdc(scaleio_system)
  sdc_url = "/api/types/Sdc/instances?systemId=%s" % [scaleio_system["id"]]
  url = transport.get_url(sdc_url)
  transport.post_request(url, {}, "get") || []
end

def protection_domains(scaleio_system)
  pd_url = "/api/types/ProtectionDomain/instances?systemId=%s" % [scaleio_system["id"]]
  url = transport.get_url(pd_url)
  transport.post_request(url, {}, "get") || []
end

def storage_pools(scaleio_system, protection_domain)
  sp_url = "/api/types/StoragePool/instances?systemId=%s&protectiondomainId=%s" % [scaleio_system["id"], protection_domain["id"]]
  url = transport.get_url(sp_url)
  transport.post_request(url, {}, "get") || []
end

def disks(storage_pool)
  sp_url = "/api/types/Device/instances?storagepoolId=%s" % [storage_pool["id"]]
  url = transport.get_url(sp_url)
  transport.post_request(url, {}, "get") || []
end

def scaleio_volumes(scaleio_system)
  volume_url = "/api/types/Volume/instances?systemId=%s" % [scaleio_system["id"]]
  url = transport.get_url(volume_url)
  transport.post_request(url, {}, "get") || []
end

def scaleio_faultsets(scaleio_system)
  faultset_url = "/api/types/FaultSet/instances?systemId=%s" % [scaleio_system["id"]]
  url = transport.get_url(faultset_url)
  transport.post_request(url, {}, "get") || []
end

def transport
  @transport ||= Puppet::ScaleIO::Transport.new(@opts)
end

def scaleio_cookie
  @scaleio_cookie ||= transport.get_scaleio_cookie
end

facts = {}
begin
  Timeout.timeout(@opts[:timeout]) do
    facts = collect_scaleio_facts.to_json
  end
rescue Timeout::Error
  puts "Timed out trying to gather ScaleIO Inventory"
  exit 1
rescue Exception => e
  puts "#{e}\n#{e.backtrace.join("\n")}"
  exit 1
else
  if facts.empty?
    puts "Could not get updated facts"
    exit 1
  else
    puts "Successfully gathered inventory."
    if @opts[:output]
      File.write(@opts[:output], JSON.pretty_generate(JSON.parse(facts)))
    else
      results ||= {}
      scaleio_cache = "/opt/Dell/ASM/cache"
      Dir.mkdir(scaleio_cache) unless Dir.exists? scaleio_cache
      file_path = File.join(scaleio_cache, "#{opts[:server]}.json")
      File.write(file_path, results) unless results.empty?
    end
  end
end
