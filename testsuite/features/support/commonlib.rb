# Copyright (c) 2013-2023 SUSE LLC.
# Licensed under the terms of the MIT license.

require 'tempfile'
require 'yaml'

# return current URL
def current_url
  driver.current_url
end

# generate temporary file on the controller
def generate_temp_file(name, content)
  Tempfile.open(name) do |file|
    file.write(content)
    return file.path
  end
end

# If we for example
#  - start a reposync in reposync/srv_sync_channels.feature
#  - then kill it in reposync/srv_wait_for_reposync.feature
#  - then restart it later on in init_clients/sle_minion.feature
# then the channel will be in an inconsistent state.
#
# This function computes a list of reposyncs to avoid killing, because they might be involved in bootstrapping.
#
# This is a safety net only, the best thing to do is to not start the reposync at all.
def compute_channels_to_leave_running
  # keep the repos needed for the auto-installation tests
  do_not_kill = CHANNEL_TO_SYNCH_BY_OS_VERSION['default']
  [$minion, $build_host, $ssh_minion].each do |node|
    next unless node
    os_version = node.os_version
    os_family = node.os_family
    next unless os_family == 'sles'
    log "Can't build list of reposyncs to leave running" unless %w[15-SP2 15-SP3 15-SP4].include? os_version
    do_not_kill += CHANNEL_TO_SYNCH_BY_OS_VERSION[os_version]
  end
  do_not_kill.uniq
end

def count_table_items
  # count table items using the table counter component
  items_label_xpath = "//span[contains(text(), 'Items ')]"
  raise unless (items_label = find(:xpath, items_label_xpath).text)
  items_label.split('of ')[1].strip
end

def product
  _product_raw, code = $server.run('rpm -q patterns-uyuni_server', check_errors: false)
  return 'Uyuni' if code.zero?
  _product_raw, code = $server.run('rpm -q patterns-suma_server', check_errors: false)
  return 'SUSE Manager' if code.zero?
  raise 'Could not determine product'
end

def product_version
  product_raw, code = $server.run('rpm -q patterns-uyuni_server', check_errors: false)
  m = product_raw.match(/patterns-uyuni_server-(.*)-.*/)
  return m[1] if code.zero? && !m.nil?
  product_raw, code = $server.run('rpm -q patterns-suma_server', check_errors: false)
  m = product_raw.match(/patterns-suma_server-(.*)-.*/)
  return m[1] if code.zero? && !m.nil?
  raise 'Could not determine product version'
end

def use_salt_bundle
  # Use venv-salt-minion in Uyuni, or SUMA Head, 4.2 and 4.3
  $product == 'Uyuni' || %w[head 4.3 4.2].include?($product_version)
end

# create salt pillar file in the default pillar_roots location
def inject_salt_pillar_file(source, file)
  dest = '/srv/pillar/' + file
  return_code = file_inject($server, source, dest)
  raise 'File injection failed' unless return_code.zero?
  # make file readeable by salt
  $server.run("chgrp salt #{dest}")
  return_code
end

# WARN: It's working for /24 mask, but couldn't not work properly with others
def get_reverse_net(net)
  a = net.split('.')
  a[2] + '.' + a[1] + '.' + a[0] + '.in-addr.arpa'
end

# Repeatedly executes a block raising an exception in case it is not finished within timeout seconds
# or retries attempts, whichever comes first.
# Exception will optionally contain the specified message and the result from the last block execution, if any, in case
# report_result is set to true
#
# Implementation works around https://bugs.ruby-lang.org/issues/15886
def repeat_until_timeout(timeout: DEFAULT_TIMEOUT, retries: nil, message: nil, report_result: false)
  last_result = nil
  Timeout.timeout(timeout) do
    # HACK: Timeout.timeout might not raise Timeout::Error depending on the yielded code block
    # Pitfalls with this method have been long known according to the following articles:
    # https://rnubel.svbtle.com/ruby-timeouts
    # https://vaneyckt.io/posts/the_disaster_that_is_rubys_timeout_method
    # At the time of writing some of the problems described have been addressed.
    # However, at least https://bugs.ruby-lang.org/issues/15886 remains reproducible and code below
    # works around it by adding an additional check between loops
    start = Time.new
    attempts = 0
    while (Time.new - start <= timeout) && (retries.nil? || attempts < retries)
      last_result = yield
      attempts += 1
    end

    detail = format_detail(message, last_result, report_result)
    raise "Giving up after #{attempts} attempts#{detail}" if attempts == retries
    raise "Timeout after #{timeout} seconds (repeat_until_timeout)#{detail}"
  end
rescue Timeout::Error
  raise "Timeout after #{timeout} seconds (Timeout.timeout)#{format_detail(message, last_result, report_result)}"
end

def format_detail(message, last_result, report_result)
  formatted_message = "#{': ' unless message.nil?}#{message}"
  formatted_result = "#{', last result was: ' unless last_result.nil?}#{last_result}" if report_result
  "#{formatted_message}#{formatted_result}"
end

def click_button_and_wait(locator = nil, **options)
  click_button(locator, options)
  begin
    raise 'Timeout: Waiting AJAX transition (click link)' unless has_no_css?('.senna-loading', wait: 5)
  rescue StandardError, Capybara::ExpectationNotMet => e
    STDOUT.puts e.message # Skip errors related to .senna-loading element
  end
end

def click_link_and_wait(locator = nil, **options)
  click_link(locator, options)
  begin
    raise 'Timeout: Waiting AJAX transition (click link)' unless has_no_css?('.senna-loading', wait: 5)
  rescue StandardError, Capybara::ExpectationNotMet => e
    STDOUT.puts e.message # Skip errors related to .senna-loading element
  end
end

def click_link_or_button_and_wait(locator = nil, **options)
  click_link_or_button(locator, options)
  begin
    raise 'Timeout: Waiting AJAX transition (click link)' unless has_no_css?('.senna-loading', wait: 5)
  rescue StandardError, Capybara::ExpectationNotMet => e
    STDOUT.puts e.message # Skip errors related to .senna-loading element
  end
end

# Capybara Node Element extension to override click method, clicking and then waiting for ajax transition
module CapybaraNodeElementExtension
  def click
    super
    begin
      raise 'Timeout: Waiting AJAX transition (click link)' unless has_no_css?('.senna-loading', wait: 5)
    rescue StandardError, Capybara::ExpectationNotMet => e
      STDOUT.puts e.message # Skip errors related to .senna-loading element
    end
  end
end

def find_and_wait_click(*args, **options, &optional_filter_block)
  element = find(*args, options, &optional_filter_block)
  element.extend(CapybaraNodeElementExtension)
end

def get_client_type(name)
  if name.include? '_client'
    'traditional'
  else
    'salt'
  end
end

def suse_host?(name)
  (name.include? 'sle') || (name.include? 'opensuse') || (name.include? 'ssh')
end

def rh_host?(name)
  (name.include? 'rhlike') || (name.include? 'centos') || (name.include? 'alma') || (name.include? 'rocky')
end

def deb_host?(name)
  (name.include? 'deblike') || (name.include? 'debian') || (name.include? 'ubuntu')
end

def repository_exist?(repo)
  $api_test.auth.login('admin', 'admin')
  repo_list = $api_test.channel.software.list_user_repos
  $api_test.auth.logout
  repo_list.include? repo
end

def generate_repository_name(repo_url)
  repo_name = repo_url.strip
  repo_name.delete_prefix! 'http://download.suse.de/ibs/SUSE:/Maintenance:/'
  repo_name.delete_prefix! 'http://download.suse.de/download/ibs/SUSE:/Maintenance:/'
  repo_name.delete_prefix! 'http://download.suse.de/download/ibs/SUSE:/'
  repo_name.gsub!('/', '_')
  repo_name.gsub!(':', '_')
  repo_name[0...64] # HACK: Due to the 64 characters size limit of a repository label
end

def extract_logs_from_node(node)
  os_family = node.os_family
  node.run('zypper --non-interactive install tar') if os_family =~ /^opensuse/
  node.run('journalctl > /var/log/messages', check_errors: false) # Some clients might not support systemd
  node.run("tar cfvJP /tmp/#{node.full_hostname}-logs.tar.xz /var/log/ || [[ $? -eq 1 ]]")
  `mkdir logs` unless Dir.exist?('logs')
  code = file_extract(node, "/tmp/#{node.full_hostname}-logs.tar.xz", "logs/#{node.full_hostname}-logs.tar.xz")
  raise 'Download log archive failed' unless code.zero?
end

def get_uptime_from_host(host)
  node = get_target(host)
  uptime, _return_code = node.run('cat /proc/uptime') # run code on node only once, to get uptime
  seconds = Float(uptime.split[0]) # return only the uptime in seconds, as a float
  minutes = (seconds / 60.0) # 60 seconds; the .0 forces a float division
  hours = (minutes / 60.0) # 60 minutes
  days = (hours / 24.0) # 24 hours
  { seconds: seconds, minutes: minutes, hours: hours, days: days }
end

def web_driver_session_reset
  page.reset! if Capybara::Session.instance_created?
rescue NoMethodError
  log 'The browser session could not be cleaned.'
ensure
  visit Capybara.app_host
end
