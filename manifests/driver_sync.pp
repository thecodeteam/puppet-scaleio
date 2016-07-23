# Sync ScaleIO drivers

define scaleio::driver_sync(
  $driver,                # string - scini | xcache
  $ftp      = 'default',  # string - 'default' or FTP with user and password
) {
  $ftp_url = $ftp ? {
    'default' => 'ftp://QNzgdxXix:Aw3wFAwAq3@ftp.emc.com',
    default   => $ftp
  }

  $ftp_split = split($ftp_url, '@')
  $ftp_host = $ftp_split[1]
  $ftp_proto_split = split($ftp_split[0], '://')
  $ftp_proto = $ftp_proto_split[0]
  $ftp_creds = split($ftp_proto_split[1], ':')

  notify { "FTP to use for ${driver} driver: ${ftp_url}, ${ftp_host}, ${ftp_proto}, ${ftp_creds[0]}, ${ftp_creds[1]}": }

  $sync_conf = {
    repo_address        => "${ftp_proto}://${ftp_host}",
    repo_user           => $ftp_creds[0],
    repo_password       => $ftp_creds[1],
    local_dir           => "/bin/emc/scaleio/${driver}_sync/driver_cache/",
    module_sigcheck     => 1,
    emc_public_gpg_key  => "/bin/emc/scaleio/${driver}_sync/RPM-GPG-KEY-ScaleIO",
    repo_public_rsa_key => "/bin/emc/scaleio/${driver}_sync/${driver}_repo_key.pub",
    sync_pattern        => '.*',
  }
  $sync_keys = keys($sync_conf)

  file { "Ensure sync directory present: ":
    ensure  => directory,
    path    => "/bin/emc/scaleio/${driver}_sync",
    mode    => '0755',
  } ->
  file { "/bin/emc/scaleio/${driver}_sync/RPM-GPG-KEY-ScaleIO":
    ensure => present,
    source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  } ->
  exec { "scaleio ${driver} repo public key":
    command => "ssh-keyscan ${ftp_host} | grep ssh-rsa > /bin/emc/scaleio/${driver}_sync/${driver}_repo_key.pub",
    path    => ['/bin/', '/usr/bin', '/sbin'],
    onlyif  => "echo '${ftp_proto}' | grep -q sftp",
  } ->
  file { "Ensure sync config present: ":
    ensure  => file,
    path    => "/bin/emc/scaleio/${driver}_sync/driver_sync.conf",
  } ->
  config_sync { $sync_keys:
    driver => $driver,
    config => $sync_conf,
  } ->
  exec { "${driver} sync and update":
    command => 'update_driver_cache.sh && verify_driver.sh',
    unless  => ["test ! -f /bin/emc/scaleio/${driver}_sync/verify_driver.sh", 'verify_driver.sh'],
    path    => ["/bin/emc/scaleio/${driver}_sync/", '/bin/', '/usr/bin', '/sbin'],
    notify  => Service["${driver}"],
  }
}

define config_sync($driver, $config) {
  file_line { "config_sync ${title}":
    ensure  => present,
    path    => "/bin/emc/scaleio/${driver}_sync/driver_sync.conf",
    match   => "^${title}",
    line    => "${title}=${config[$title]}",
  }
}

