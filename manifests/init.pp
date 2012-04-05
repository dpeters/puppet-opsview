class opsview($url, $username, $password)
{
  file { '/etc/puppet/opsview.conf':
    ensure  => present,
    content => template('opsview/etc/puppet/opsview.conf.erb'),
    mode    => '0644', # TODO: consider stricter permissions
  }
}
