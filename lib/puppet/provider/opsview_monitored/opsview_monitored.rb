#
# Major refactor by Christian Paredes <christian.paredes@sbri.org>
#

# This file is part of the Opsview puppet module
#
# Copyright (C) 2010 Opsera Ltd.
#
# The Opsview puppet module is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
require File.join(File.dirname(__FILE__), '..', 'opsview')

begin
  require 'json'
rescue LoadError => e
  Puppet.info "You need the `json` gem for communicating with Opsview servers."
end
begin
  require 'rest-client'
rescue LoadError => e
  Puppet.info "You need the `rest-client` gem for communicating wtih Opsview servers."
end

require 'puppet'
# Config file parsing
require 'yaml'

Puppet::Type.type(:opsview_monitored).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'host'

  mk_resource_methods

  def self.node_map(node)
    p = { :name          => node["name"],
          :ip            => node["ip"],
          :hostgroup     => node["hostgroup"]["name"],
          :servicechecks => node["servicechecks"].collect{ |sc| sc["name"] },
          :hosttemplates => node["hosttemplates"].collect{ |ht| ht["name"] },
          :keywords      => node["keywords"].collect{ |kw| kw["name"] },
          :enable_snmp   => node["enable_snmp"],
          :snmp_community   => node["snmp_community"],
          :snmp_version   => node["snmp_version"],
          :snmp_port   => node["snmp_port"],
          :snmpv3_authpassword => node["snmpv3_authpassword"],
          :snmpv3_authprotocol => node["snmpv3_authprotocol"],
          :snmpv3_privpassword => node["snmpv3_privpassword"],
          :snmpv3_privprotocol => node["snmpv3_privprotocol"],
          :snmpv3_username => node["snmpv3_username"],
          :tidy_ifdescr_level => node["tidy_ifdescr_level"],
          :full_json     => node,
          :ensure        => :present }
          
#:snmp_max_msg_size => node["snmp_max_msg_size"],

    # optional properties
    if defined? node["parents"]
      p[:parents] = node["parents"].collect{ |prnt| prnt["name"] }
    end
    if defined? node["keywords"]
      p[:keywords] = node["keywords"].collect{ |kw| kw["name"] }
    end
    if defined? node["monitored_by"]["name"]
      p[:monitored_by] = node["monitored_by"]["name"]
    end
    if defined? node["snmp_max_msg_size"]
      case node["snmp_max_msg_size"].to_s
        when "0" then 
          p[:snmp_max_msg_size] = "default"
        when "1023" then 
          p[:snmp_max_msg_size] = "1Kio"
        when "2047" then 
          p[:snmp_max_msg_size] = "2Kio"
        when "4095" then 
          p[:snmp_max_msg_size] = "4Kio"
        when "8191" then 
          p[:snmp_max_msg_size] = "8Kio"
        when "16383" then 
          p[:snmp_max_msg_size] = "16Kio"
        when "32767" then 
          p[:snmp_max_msg_size] = "32Kio"
        when "65535" then 
          p[:snmp_max_msg_size] = "64Kio"
      end
    end
    if defined? node["tidy_ifdescr_level"]
      case node["tidy_ifdescr_level"].to_s
        when "0" then
          p[:tidy_ifdescr_level] = "off"
        when "1" then 
          p[:tidy_ifdescr_level] = "level1"
        when "2" then 
          p[:tidy_ifdescr_level] = "level2"
        when "3" then 
          p[:tidy_ifdescr_level] = "level3"
      end
    end
    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if node = resources[provider.name]
        node.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all nodes.  Expensive query.
    nodes = get_resources

    nodes.each do |node|
      providers << new(node_map(node))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @node_json
      @updated_json = @node_json.dup
    else
      @updated_json = default_node
    end
 
    @property_hash.delete(:groups)
    @node_properties.delete(:groups)
 
    # Update the node's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["hostgroup"]["name"] = @property_hash[:hostgroup]
    @updated_json["name"] = @resource[:name]
    @updated_json["ip"] = @property_hash[:ip]

    @updated_json["enable_snmp"] = @property_hash[:enable_snmp]
    @updated_json["snmp_community"] = @property_hash[:snmp_community]
    @updated_json["snmp_version"] = @property_hash[:snmp_version]
    @updated_json["snmp_port"] = @property_hash[:snmp_port]
    @updated_json["snmpv3_authpassword"] = @property_hash[:snmpv3_authpassword]
    @updated_json["snmpv3_authprotocol"] = @property_hash[:snmpv3_authprotocol]
    @updated_json["snmpv3_privpassword"] = @property_hash[:snmpv3_privpassword]
    @updated_json["snmpv3_privprotocol"] = @property_hash[:snmpv3_privprotocol]
    @updated_json["snmpv3_username"] = @property_hash[:snmpv3_username]

    case @property_hash[:snmp_max_msg_size].to_s
      when "default" then 
        @updated_json["snmp_max_msg_size"] = 0
      when "1Kio" then 
        @updated_json["snmp_max_msg_size"] = 1023
      when "2Kio" then 
        @updated_json["snmp_max_msg_size"] = 2047
      when "4Kio" then 
        @updated_json["snmp_max_msg_size"] = 4095
      when "8Kio" then 
        @updated_json["snmp_max_msg_size"] = 8191
      when "16Kio" then 
        @updated_json["snmp_max_msg_size"] = 16383
      when "32Kio" then 
        @updated_json["snmp_max_msg_size"] = 32767
      when "64Kio" then 
        @updated_json["snmp_max_msg_size"] = 65535
    end

    case @property_hash[:tidy_ifdescr_level].to_s
      when "off" then
        @updated_json["tidy_ifdescr_level"] = 0
      when "level1" then
        @updated_json["tidy_ifdescr_level"] = 1
      when "level2" then
        @updated_json["tidy_ifdescr_level"] = 2
      when "level3" then
        @updated_json["tidy_ifdescr_level"] = 3
    end

    @updated_json["hosttemplates"] = []
    if @property_hash[:hosttemplates]
      @property_hash[:hosttemplates].each do |ht|
        @updated_json["hosttemplates"] << {:name => ht}
      end
    end

    @updated_json["servicechecks"] = []
    if @property_hash[:servicechecks]
      @property_hash[:servicechecks].each do |sc|
        @updated_json["servicechecks"] << {:name => sc}
      end
    end
    
    @updated_json["keywords"] = []
    if @property_hash[:keywords]
      @property_hash[:keywords].each do |kw|
        @updated_json["keywords"] << {:name => kw}
      end
    end
    
    @updated_json["parents"] = []
    if @property_hash[:parents]
      @property_hash[:parents].each do |pa|
        @updated_json["parents"] << {:name => pa}
      end
    end
    
    if not @property_hash[:monitored_by].to_s.empty?
      @updated_json["monitored_by"]["name"] = @property_hash[:monitored_by]
    end
  
    put @updated_json.to_json

    @property_hash.clear
    @node_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the node if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @node_json = args[0][:full_json]
    end

    @property_hash = @property_hash.inject({}) do |result, ary|
      param, values = ary

      # Skip any attributes we don't manage.
      next result unless self.class.resource_type.validattr?(param)

      paramclass = self.class.resource_type.attrclass(param)

      unless values.is_a?(Array)
        result[param] = values
        next result
      end

      # Only use the first value if the attribute class doesn't manage
      # arrays of values.
      if paramclass.superclass == Puppet::Parameter or paramclass.array_matching == :first
        result[param] = values[0]
      else
        result[param] = values
      end

      result
    end

    @node_properties = @property_hash.dup
  end

  # Return the current state of the node in Opsview.
  def node_properties
    @node_properties.dup
  end

  # Return (and look up if necessary) the desired state.
  def properties
    if @property_hash.empty?
      @property_hash = query || {:ensure => :absent}
      if @property_hash.empty?
        @property_hash[:ensure] = :absent
      end
    end
    @property_hash.dup
  end

  def default_node
    json = '
     {
       "flap_detection_enabled" : "1",
       "snmpv3_privprotocol" : null,
       "hosttemplates" : [],
       "keywords" : [],
       "check_period" : {
          "name" : "24x7"
       },
       "hostattributes" : [],
       "notification_period" : {
          "name" : "24x7"
       },
       "notification_options" : "u,d,r",
       "name" : "puppet-unknown",
       "rancid_vendor" : null,
       "snmp_community" : "public",
       "hostgroup" : {
          "name" : "From Puppet - Unknown"
       },
       "enable_snmp" : "0",
       "monitored_by" : {
          "name" : "Master Monitoring Server"
       },
       "alias" : "Puppet Managed Host",
       "uncommitted" : "0",
       "parents" : [],
       "icon" : {
          "name" : "LOGO - Opsview"
       },
       "retry_check_interval" : "1",
       "ip" : "localhost",
       "use_mrtg" : "0",
       "servicechecks" : [],
       "use_rancid" : "0",
       "nmis_node_type" : "router",
       "snmp_version" : "2c",
       "snmp_max_msg_size" : "default",
       "tidy_ifdescr_level" : "off",
       "snmpv3_authpassword" : "",
       "use_nmis" : "0",
       "rancid_connection_type" : "ssh",
       "snmpv3_authprotocol" : null,
       "rancid_username" : null,
       "rancid_password" : null,
       "check_command" : {
          "name" : "ping"
       },
       "check_attempts" : "2",
       "check_interval" : "0",
       "notification_interval" : "60",
       "snmp_port" : "161",
       "snmpv3_username" : "",
       "snmpv3_privpassword" : "",
       "other_addresses" : ""
     }'

    JSON.parse(json.to_s)
  end
end
