# Protection Domain configuration
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::protection_domain (
  $sio_name,                          # string - Name of protection domain
  $ensure               = 'present',  # present|absent - Add or remove protection domain
  $ensure_properties    = 'present',  # present|absent - Add or remove protection domain properties
  $fault_sets           = undef,      # [string] - Array of fault sets
  $storage_pools        = undef,      # [string] - Array of storage pools
  $zero_padding_policy  = undef,      # 'enable'|'disable'
  )
{
  scaleio::cmd {"Protection domain ${title} ${ensure}":
    action => $ensure,
    entity => 'protection_domain',
    value  => $sio_name,}
  if $fault_sets {
    $fs_resources = suffix($fault_sets, ',1')
    scaleio::cmd {$fs_resources:
      action          => $ensure_properties,
      entity          => 'fault_set',
      value_in_title  => true,
      scope_entity    => 'protection_domain',
      scope_value     => $sio_name,
      require         => Scaleio::Cmd["Protection domain ${title} ${ensure}"],
    }
  }
  if $storage_pools {
    $sp_resources = suffix($storage_pools, ',2')
    scaleio::cmd {$sp_resources:
      action          => $ensure_properties,
      entity          => 'storage_pool',
      value_in_title  => true,
      scope_entity    => 'protection_domain',
      scope_value     => $sio_name,
      require         => Scaleio::Cmd["Protection domain ${title} ${ensure}"],
    }
    if $zero_padding_policy {
      $sp_zp_resources = suffix($storage_pools, ',3')
      scaleio::cmd {$sp_zp_resources:
        action          => 'modify_zero_padding_policy',
        ref             => 'storage_pool_name',
        value_in_title  => true,
        scope_entity    => 'protection_domain',
        scope_value     => $sio_name,
        extra_opts      => "--${zero_padding_policy}_zero_padding",
        require         => Scaleio::Cmd[$sp_resources],
      }
    }
  }

  # TODO:
  # set_sds_network_limits
}
