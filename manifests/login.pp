# Login to ScaleIO cluster
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::login(
  $password,  # string - Password to login into ScaleIO cluster
)
{
  scaleio::cmd { "${title} login":
    action      => 'login',
    ref         => 'password',
    value       => $password,
    scope_ref   => 'username',
    scope_value => 'admin',
    retry       => 5,
  }
}



