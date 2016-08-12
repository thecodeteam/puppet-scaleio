# Configure ScaleIO cluster nodes, and cluster parameters.
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::cluster (
  $ensure                             = 'present',  # present|absent - Create or destroy cluster
  $cluster_mode                       = undef,      # number - 1|3|5 - Cluster mode
  $slave_names                        = undef,      # string - List of MDM slaves to add or remove
  $tb_names                           = undef,      # string - List of tiebreakers to add or remove
  $slave_names_to_replace             = undef,      # string - List of MDM slaves to replace in case of restore
  $tb_names_to_replace                = undef,      # string - List of tiebreakers to replace in case of restore
  $password                           = undef,      # string - Current password
  $new_password                       = undef,      # string - New password
  $license_file_path                  = undef,      # string - Path to license file
  $performance_profile                = undef,      # string - Performance profile for SDC: default or high_performance
  $capacity_high_alert_threshold      = undef,      # number - Percent of consumed storage space for high priority alert,
                                                    #          should be used toghether with capacity_critical_alert_threshold
  $capacity_critical_alert_threshold  = undef,      # number - Percent of consumed storage space for critical priority alert,
                                                    #          should be used toghether with capacity_high_alert_threshold
  $client_password                    = undef,      # string - The password for the user created for ScaleIO clients
                                                    #          with role FontEndConfigure
  )
{
  if $cluster_mode {
    # Cluster mode changed
    $action = $ensure ? {'absent' => 'remove', default => 'add'}
    scaleio::cmd {"switch cluster mode ${ensure}":
      action       => 'switch_cluster_mode',
      ref          => 'cluster_mode',
      value        => "${cluster_mode}_node",
      extra_opts   => "--${action}_slave_mdm_name ${slave_names} --${action}_tb_name ${tb_names} --i_am_sure",
      unless_query => 'query_cluster | grep -A 1 "Cluster:" | grep'
    }
  }
  if $slave_names_to_replace or $tb_names_to_replace {
    $add_slave_opts = $slave_names ? {
      undef       => '',
      default     => "--add_slave_mdm_name ${slave_names}"
    }
    $add_tb_opts = $tb_names ? {
      undef       => '',
      default     => "--add_tb_name ${tb_names}"
    }
    $remove_slave_opts = $slave_names_to_replace ? {
      undef       => '',
      default     => "--remove_slave_mdm_name ${slave_names_to_replace}"
    }
    $remove_tb_opts = $tb_names_to_replace ? {
      undef       => '',
      default     => "--remove_tb_name ${tb_names_to_replace}"
    }
    scaleio::cmd {"replace cluster nodes ${add_slave_opts} ${remove_slave_opts} ${add_tb_opts} ${remove_tb_opts}":
      action     => 'replace_cluster_mdm',
      extra_opts => "${add_slave_opts} ${remove_slave_opts} ${add_tb_opts} ${remove_tb_opts} --allow_leave_failed --i_am_sure",
    }
  }
  if $new_password {
    scaleio::cmd {'set password':
      action              => 'set_password',
      ref                 => 'new_password',
      value               => $new_password,
      scope_ref           => 'old_password',
      scope_value         => $password,
      approve_certificate => ''
    }
  }
  if $license_file_path {
    scaleio::cmd {'set license':
      action => 'set_license',
      ref    => 'license_file',
      value  => $license_file_path}
  }
  $mdm_opts = $::mdm_ips ? {
    undef   => '',
    default => "--mdm_ip ${::mdm_ips}"
  }
  if $performance_profile {
    exec { 'Apply high_performance profile for all':
      command => "scli ${mdm_opts} --set_performance_parameters --all_sdc --all_sds --apply_to_mdm --profile ${performance_profile}",
      path    => '/bin:/usr/bin',
    }
  }
  if $capacity_high_alert_threshold and $capacity_critical_alert_threshold {
      $opt_h = "--capacity_high_threshold ${capacity_high_alert_threshold}"
      $opt_c = "--capacity_critical_threshold ${capacity_critical_alert_threshold}"
      exec { 'Set capacity allert thresholds':
        command => "scli ${mdm_opts} --set_capacity_alerts_threshold ${opt_h} ${opt_c} --all_storage_pools --system_default",
        path    => '/bin:/usr/bin',
      }
  }

  # TODO:
  # Users, Volumes, Certificates, Caches
  # Password can be changed only with current password - can be done by resetting with only new password

  # this block must be last block. it can change current login.
  if $client_password {
    $user = 'scaleio_client'
    file { '/root/create_client_user.sh':
      ensure => $ensure,
      source => 'puppet:///modules/scaleio/create_client_user.sh',
      mode   => '0700',
      owner  => 'root',
      group  => 'root',
    } ->
    exec { 'create_client_user':
      unless  => "scli --query_user --username ${user}",
      command => "/root/create_client_user.sh ${user} ${client_password} ${::mdm_ips}",
      path    => '/bin:/usr/bin',
    }
  }
}
