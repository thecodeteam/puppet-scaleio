# MDM configuration
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::mdm (
  $name,                                # string - MDM name
  $ensure                 = 'present',  # present|absent - Install or remove standby MDM in cluster
  $ensure_properties      = 'present',  # present|absent - Change or remove properties in MDM
  $role                   = 'manager',  # 'manager'|'tb' - Specify role of the MDM when adding to cluster
  $port                   = undef,      # int - Specify port when adding to cluster
  $ips                    = undef,      # string - Specify IPs when adding to cluster
  $management_ips         = undef,      # string - Specify management IPs for cluster or change later
  )
{
  if $ensure == 'present' {
    $management_ip_opts = $management_ips ? {undef => '', default => "--new_mdm_management_ip ${management_ips}" }
    $port_opts = $port ? {undef => '', default => "--new_mdm_port ${port}" }
    cmd {"MDM ${title} ${ensure}":
      action       => 'add_standby_mdm',
      ref          => 'new_mdm_name',
      value        => $name,
      scope_ref    => 'mdm_role',
      scope_value  => $role,
      extra_opts   => "--new_mdm_ip ${ips} ${port_opts} ${management_ip_opts} --force_clean --i_am_sure",
      unless_query => 'query_cluster | grep'
    }
  }
  elsif $ensure == 'absent' {
    cmd {"MDM ${title} ${ensure}":
      action        => 'remove_standby_mdm',
      ref           => 'remove_mdm_name',
      value         => $name,
      onlyif_query  => 'query_cluster | grep'
    }
  }

  if $management_ips {
    cmd {"properties ${title} ${ensure_properties}":
      action        => 'modify_management_ip',
      ref           => 'target_mdm_name',
      value         => $name,
      extra_opts    => "--new_mdm_management_ip ${management_ips}",
      unless_query  => "query_cluster | grep -B 1 \"Management IPs: ${management_ips}\" | grep",
      require       => Cmd["MDM ${title} ${ensure}"]
    }
  }

  # TODO:
  # allow_asymmetric_ips, allow_duplicate_management_ips
}
