# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary A plan created with bolt plan new.
# @param targets The targets to run on.
# @param gpg_key_url The URL of the GPG key to import for package verification.
# @param repo_url The URL of the repository RPM to install.
# @param pkg_name The name of the package to install.
# @param r10k_config The R10K configuration file content.
#
plan ov_deploy::server (
  TargetSpec $targets = ['primary', 'compilers'],
  String $gpg_key_url = 'https://s3.osuosl.org/openvox-yum/GPG-KEY-openvox.pub',
  String $repo_url    = 'https://s3.osuosl.org/openvox-yum/openvox8-release-el-9.noarch.rpm',
  String $pkg_name    = 'openvox-server',
  String $r10k_config = @("EOF")
    ---
    pool_size: 6
    deploy:
      generate_types: true
      exclude_spec: true
    cachedir: "/opt/puppetlabs/puppet/cache/r10k"
    sources:
      puppet:
        basedir: "/etc/puppetlabs/code/environments"
        remote: https://github.com/zoojar/control-repo.git
    | EOF
) {
  $primary = get_target('primary').name
  unless run_command('hostname', $targets, 'catch_errors' => true).ok() {
    fail_plan('Unable to connect to targets')
  }
  unless run_command('/usr/bin/yum --version', $targets, 'catch_errors' => true).ok() {
    fail_plan('Unsupported targets')
  }
  run_command("/usr/bin/curl -LO ${gpg_key_url}", $targets, "Installing gpg key ${gpg_key_url}", 'catch_errors' => true)
  run_command("/usr/bin/rpm -Uvh ${repo_url}", $targets, "Installing gpg key ${gpg_key_url}", 'catch_errors' => true)
  run_command("/usr/bin/yum -y install ${pkg_name}", $targets, 'Installing server', 'catch_errors' => true)
  run_command('/opt/puppetlabs/puppet/bin/gem install r10k', $targets, 'Installing r10k')
  run_command('/opt/puppetlabs/puppet/bin/puppet resource package git ensure=installed', $targets, 'Ensuring git installed')
  run_command('mkdir -p /etc/puppetlabs/r10k', $targets, 'Configuring r10k')
  write_file($r10k_config, '/etc/puppetlabs/r10k/r10k.yaml', $targets)
  run_command('/opt/puppetlabs/puppet/bin/r10k deploy environment -m', $targets, 'Deploying code via r10k')
  run_command("/opt/puppetlabs/puppet/bin/puppet config set server ${primary} --section agent", $targets, 'Setting server in agent config')
  run_command("/opt/puppetlabs/puppet/bin/puppet config set ca_server ${primary} --section main", $targets, 'Setting ca_server in agent config')
  $ca_conf_content = @("EOF")
    puppetlabs.services.ca.certificate-authority-disabled-service/certificate-authority-disabled-service
    puppetlabs.trapperkeeper.services.watcher.filesystem-watch-service/filesystem-watch-service
    | EOF
  write_file($ca_conf_content, '/etc/puppetlabs/puppetserver/services.d/ca.cfg', 'compilers')
  get_targets('compilers').each | $compiler | {
    $webserver_conf = @("EOF")
      webserver: {
        access-log-config: /etc/puppetlabs/puppetserver/request-logging.xml
        client-auth: want
        ssl-host: 0.0.0.0
        ssl-port: 8140
        ssl-cert: /etc/puppetlabs/puppet/ssl/certs/${compiler.name}.pem
        ssl-key: /etc/puppetlabs/puppet/ssl/private_keys/${compiler.name}.pem
        ssl-ca-cert: /etc/puppetlabs/puppet/ssl/certs/ca.pem
        ssl-crl-path: /etc/puppetlabs/puppet/ssl/crl.pem
      }
      | EOF
    write_file($webserver_conf, '/etc/puppetlabs/puppetserver/conf.d/webserver.conf', $compiler)
  }
  run_command('/opt/puppetlabs/puppet/bin/puppet resource service puppetserver ensure=running', 'primary', 'Ensuring puppetserver service running')
  get_targets('compilers').each | $compiler | {
    run_command("/opt/puppetlabs/puppet/bin/puppet ssl bootstrap --server=${primary} --waitforcert 0", $compiler, 'Requesting cert', 'catch_errors' => true)
    run_command("/opt/puppetlabs/bin/puppetserver ca sign --certname ${compiler.name}", 'primary', 'Signing cert')
  }
  run_command('/opt/puppetlabs/puppet/bin/puppet resource service puppetserver ensure=running', 'compilers', 'Starting puppetserver')
  ctrl::do_until('interval' => 5) || {
    run_command('/opt/puppetlabs/bin/puppet agent -t', ['primary', 'compilers'], 'Running puppet on primary & compilers', 'catch_errors' => true).ok()
  }
}
