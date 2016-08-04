# SDS configuration
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::sds (
  $sio_name,                                    # string - SDS name
  $ensure               = 'present',            # present|absent - Add or remove SDS to cluster
  $ensure_properties    = 'present',            # present|absent - Add or remove SDS properties
  $protection_domain    = undef,                # string - Protection domain to specify when adding to cluster
  $fault_set            = undef,                # string - Fault set
  $port                 = undef,                # int - SDS Port
  $ips                  = undef,                # string - List of SDS IPs
  $ip_roles             = undef,                # string - List of all|sdc_only|sds_only like 'all,sdc_only,sds_only'
  $storage_pools        = undef,                # string - One or List of storage pools if needed to assign different pools for devices
  $device_paths         = undef,                # string - List of device paths in the same order as pools above
  $performance_profile  = 'high_performance',   # string - performance profile for SDS: default or high_performance
  $rfcache_devices      = undef,                # string - comma separated list of rfcache devices
  )
{
  # verify input parameters
  $pools_count        = $storage_pools  ? { false => 0, default => count(split($storage_pools, ',')) }
  $device_paths_count = $device_paths   ? { false => 0, default => count(split($device_paths, ',')) }
  if $pools_count > 1 {
    if $pools_count != $device_paths_count {
      fail("Number of storage pools should be either 1 or equal to number of storage devices: pools_count=${pools_count}, device_paths_count=${device_paths_count}")
    }
  } else {
      if ($pools_count != 0 and $device_paths_count == 0) or ($pools_count == 0 and $device_paths_count != 0) {
        fail("Either storage pools or device paths are not provided: pools_count=${pools_count}, device_paths_count=${device_paths_count}")
      }
  }
  $ips_count      = $ips      ? { false   => 0, default => count(split($ips, ',')) }
  $ip_roles_count = $ip_roles ? { false   => 0, default => count(split($ip_roles, ',')) }
  if $ips_count != $ip_roles_count {
    fail("Number of ips should be equal to the number of ips roles: ips_count=${ips_count}, ip_roles_count=${ip_roles_count}")
  }

  $sds_resource_title = "SDS ${title} ${ensure}"
  if $ensure == 'absent' {
    scaleio::cmd {$sds_resource_title:
      action => $ensure,
      entity => 'sds',
      value  => $sio_name,
    }
  }
  else {
    $role_opts = $ip_roles ? {undef => '', default => "--sds_ip_role ${ip_roles}" }
    $storage_pool_opts = $storage_pools ? {undef => '', default => "--storage_pool_name ${storage_pools}" }
    $device_path_opts = $device_paths ? {undef => '', default => "--device_path ${device_paths}" }
    $fault_set_opts = $fault_set ? {undef => '', default => "--fault_set_name ${fault_set}" }
    $port_opts = $port ? {undef => '', default => "--sds_port ${port}" }
    scaleio::cmd {$sds_resource_title:
      action       => $ensure,
      entity       => 'sds',
      value        => $sio_name,
      scope_entity => 'protection_domain',
      scope_value  => $protection_domain,
      extra_opts   => "--sds_ip ${ips} ${port_opts} ${role_opts} ${storage_pool_opts} ${device_path_opts} ${fault_set_opts}"}

    if $ips {
      $ip_array = split($ips, ',')

      if $ensure_properties == 'present' {
        $ip_resources = suffix($ip_array, ",${sio_name}1")
        scaleio::cmd {$ip_resources:
          action         => 'add_sds_ip',
          ref            => 'new_sds_ip',
          value_in_title => true,
          scope_entity   => 'sds',
          scope_value    => $sio_name,
          unless_query   => 'query_sds --sds_ip',
          require        => Scaleio::Cmd[$sds_resource_title] }

        if $ip_roles {
          $ips_with_roles = hash(flatten(zip($ip_array, split($ip_roles, ','))))
          $ip_role_resources = suffix($ip_array, ",${sio_name}2")
          $role_existence_string = {'all'=>'All', 'sdc_only'=>'SDC Only', 'sds_only'=>'SDS Only'}
          scaleio::cmd {$ip_role_resources:
            action                => 'modify_sds_ip_role',
            ref                   => 'sds_ip_to_modify',
            value_in_title        => true,
            scope_entity          => 'sds',
            scope_value           => $sio_name,
            paired_ref            => 'new_sds_ip_role',
            paired_hash           => $ips_with_roles,
            unless_query          => "query_sds --sds_name ${sio_name} | grep",
            unless_query_ext      => ' | grep',
            unless_query_ext_hash => $role_existence_string,
            require               => Scaleio::Cmd[$sds_resource_title] }
        }
      }
      elsif $ensure_properties == 'absent' {
        $ip_del_resources = suffix($ip_array, ",${sio_name}3")
        scaleio::cmd {$ip_del_resources:
          action         => 'remove_sds_ip',
          ref            => 'sds_ip_to_remove',
          value_in_title => true,
          scope_entity   => 'sds',
          scope_value    => $sio_name,
          require        => Scaleio::Cmd[$sds_resource_title] }
      }
    }

    if $device_paths {
      $device_array = split($device_paths, ',')

      if $ensure_properties == 'present' {
        #generate pools for devices if provided one pool
        #otherwise just use provided array
        $device_paths_tmp = join($device_array, ',')
        $sp_array_tmp = split($storage_pools, ',')
        if count($sp_array_tmp) == 1 {
          $storage_pools_array = values(hash(split(regsubst("${device_paths_tmp},", ',', ",${sp_array_tmp[0]},", 'G'), ',')))
        } else {
          $storage_pools_array = split($storage_pools, ',')
        }
        $device_resources = suffix($device_array, ",${sio_name}4")
        $devices_with_pools = hash(flatten(zip($device_array, $storage_pools_array)))
        scaleio::cmd {$device_resources:
          action         => 'add_sds_device',
          ref            => 'device_path',
          value_in_title => true,
          scope_entity   => 'sds',
          scope_value    => $sio_name,
          paired_ref     => 'storage_pool_name',
          paired_hash    => $devices_with_pools,
          unless_query   => "query_sds --sds_name ${sio_name} | grep",
          require        => Scaleio::Cmd[$sds_resource_title] }
      }
      elsif $ensure_properties == 'absent' {
        $device_del_resources = suffix($device_array, ",${sio_name}5")
        scaleio::cmd {$device_del_resources:
          action         => 'remove_sds_device',
          ref            => 'device_path',
          value_in_title => true,
          scope_entity   => 'sds',
          scope_value    => $sio_name,
          require        => Scaleio::Cmd[$sds_resource_title] }
      }
    }

    if $rfcache_devices {
      if $ensure_properties == 'present' {
        $rfcache_action = 'enable'
        $rfcache_device_action = 'add'
      } else {
        $rfcache_action = 'disable'
        $rfcache_device_action = 'remove'
      }
      $rfcache_devices_resources = suffix(split($rfcache_devices, ','), ",${sio_name}6")
      $rfcache_resource_name = "sds ${sio_name} rfcache ${rfcache_action}"
      scaleio::cmd {$rfcache_resource_name:
        action       => "${rfcache_action}_sds_rfcache",
        scope_entity => 'sds',
        scope_value  => $sio_name,
        require      => Scaleio::Cmd[$sds_resource_title],
      }
      if $rfcache_device_action == 'add' {
        scaleio::cmd {$rfcache_devices_resources:
          action         => "${rfcache_device_action}_sds_rfcache_device",
          ref            => 'rfcache_device_path',
          value_in_title => true,
          scope_entity   => 'sds',
          scope_value    => $sio_name,
          unless_query   => "query_sds --sds_name ${sio_name} | grep",
          require        => Scaleio::Cmd[$rfcache_resource_name],
        }
      } else {
        scaleio::cmd {$rfcache_devices_resources:
          action         => "${rfcache_device_action}_sds_rfcache_device",
          ref            => 'rfcache_device_path',
          value_in_title => true,
          scope_entity   => 'sds',
          scope_value    => $sio_name,
          onlyif_query   => "query_sds --sds_name ${sio_name} | grep",
          require        => Scaleio::Cmd[$rfcache_resource_name],
        }
      }
    }

    #Apply profile high_performance
    $mdm_opts = $::mdm_ips ? {
      undef   => '',
      default => "--mdm_ip ${::mdm_ips}"}
    exec { "Apply high_performance profile for ${sds_resource_title}":
      command => "scli ${mdm_opts} --set_performance_parameters --sds_name ${sio_name} --apply_to_mdm --profile ${performance_profile}",
      path    => '/bin:/usr/bin',
      require => Scaleio::Cmd[$sds_resource_title]
    }
  }

  # TODO:
  # rmcache -size/enable/disable
  # num_of_io_buffers
  # port (only one is supported, multiple ports are not planned)
}
