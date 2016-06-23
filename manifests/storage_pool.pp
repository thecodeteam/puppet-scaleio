# Storage Pool configuration
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::storage_pool (
  $name,                                        # string - Storage pool name
  $ensure                         = 'present',  # present|absent - Add or remove storage pool
  $protection_domain              = undef,      # string - Protection domain name
  $checksum_mode                  = undef,      # 'enable'|'disable'
  $rfcache_usage                  = undef,      # 'use'|'dont_use' - cache on SSD (xCache)
  $rmcache_usage                  = undef,      # 'use'|'dont_use' - RAM cache
  $rmcache_write_handling_mode    = undef,      # 'cached'|'passthrough'
  $scanner_mode                   = undef,      # 'enable'|'disable' ('enable' uses 'device_only' mode)
  $spare_percentage               = undef,      # int
  $zero_padding_policy            = undef,      # 'enable'|'disable'
  )
{
  if $scanner_mode == 'enable' {
    $scaner_mode_opts = '--scanner_mode device_only'
  } else {
    $scaner_mode_opts = undef
  }
  cmd {"storage pool ${name} ${ensure}":
    action        => $ensure,
    entity        => 'storage_pool',
    value         => $name,
    scope_entity  => 'protection_domain',
    scope_value   => $protection_domain} ->

  set { "storage pool ${name} set_checksum_mode":
    is_defined  => $checksum_mode,
    change      => "--${checksum_mode}_checksum",
    pd          => $protection_domain,
    sp          => $name,
  } ->
  set { "storage pool ${name} modify_zero_padding_policy":
    is_defined   => $zero_padding_policy,
    change       => "--${zero_padding_policy}_zero_padding",
    pd           => $protection_domain,
    sp           => $name,
    unless_query => "query_storage_pool --protection_domain_name ${protection_domain} --storage_pool_name ${name} | grep -B 1000 'Zero padding is ${zero_padding_policy}' | grep -q ",
  } ->
  set { "storage pool ${name} set_rmcache_write_handling_mode":
    is_defined => $rmcache_write_handling_mode,
    change     => "--rmcache_write_handling_mode ${rmcache_write_handling_mode} --i_am_sure",
    pd         => $protection_domain,
    sp         => $name,
  } ->
  set { "storage pool ${name} set_rmcache_usage":
    is_defined  => $rmcache_usage,
    change      => "--${rmcache_usage}_rmcache --i_am_sure",
    pd          => $protection_domain,
    sp          => $name
  } ->
  set { "storage pool ${name} set_rfcache_usage":
    is_defined  => $rfcache_usage,
    change      => "--${rfcache_usage}_rfcache --i_am_sure",
    pd          => $protection_domain,
    sp          => $name
  } ->
  set { "storage pool ${name} modify_spare_policy":
    is_defined => $spare_percentage,
    change     => "--spare_percentage ${spare_percentage} --i_am_sure",
    pd         => $protection_domain,
    sp         => $name,
  } ->
  set { "storage pool ${name} ${scanner_mode}_background_device_scanner":
    is_defined => $scanner_mode,
    change     => $scaner_mode_opts,
    pd         => $protection_domain,
    sp         => $name,
  }
}

define scaleio::set($is_defined, $change = ' ', $pd = undef, $sp = undef, $unless_query = undef)
{
  if $is_defined {
    $action = split($title, ' ') # action is 4st word in title
    cmd {$title:
      action        => $action[3],
      ref           => 'storage_pool_name',
      value         => $sp,
      scope_entity  => 'protection_domain',
      scope_value   => $pd,
      extra_opts    => $change,
      unless_query  => $unless_query,
    }
  }
}

