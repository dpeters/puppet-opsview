#
# Major refactor by Christian Paredes <christian.paredes@sbri.org>
# Original file by Devon Peters
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

Puppet::Type.type(:opsview_servicecheck).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'servicecheck'

  mk_resource_methods

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    resources.each do |name, resource|
      if result = get_resource(name)
        result[:ensure] = :present
        resource.provider = new(result)
      else
        resource.provider = new(:ensure => :absent)
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all servicechecks.  Expensive query.
    servicechecks = get_resources

    servicechecks["list"].each do |servicecheck|
      p = { :name         => servicecheck["name"],
            :description  => servicecheck["description"],
            :servicegroup => servicecheck["servicegroup"]["name"],
            :args         => servicecheck["args"],
            :full_json    => servicecheck,
            :ensure       => :present }
      # optional properties
      if defined? servicecheck["plugin"]["name"]
        p[:plugin] = servicecheck["plugin"]["name"]
      end
      if defined? servicecheck["dependencies"]
        p[:dependencies] = servicecheck["dependencies"].collect{ |dp| dp["name"] }
      end
      if defined? servicecheck["check_period"]["name"]
        p[:check_period] = servicecheck["check_period"]["name"]
      end
      [:check_interval, :check_attempts, :retry_check_interval,
       :invertresults, :notification_options, :notification_period,
       :notification_interval, :flap_detection_enabled
      ].each do |prop|
        p[prop] = servicecheck[prop.id2name] if defined? servicecheck[prop.id2name]
      end

      providers << new(p)
    end

    providers
  end

  def create
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      if val = resource.should(property)
        @property_hash[property] = val
      end
    end
  end

  def delete
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  # Apply the changes to Opsview
  def flush
    if @servicecheck_json
      @updated_json = @servicecheck_json.dup
    else
      @updated_json = default_servicecheck
    end
 
    # Update the servicecheck's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["name"] = @resource[:name]
    @updated_json["dependencies"] = []
    if @property_hash[:dependencies]
      @property_hash[:dependencies].each do |dep|
        @updated_json["dependencies"] << {:name => dep}
      end
    end
    if not @property_hash[:servicegroup].to_s.empty?
      @updated_json["servicegroup"]["name"] = @property_hash[:servicegroup]
    end
    if not @property_hash[:plugin].to_s.empty?
      @updated_json["plugin"]["name"] = @property_hash[:plugin]
    end
    if not @property_hash[:check_period].to_s.empty?
      @updated_json["check_period"]["name"] = @property_hash[:check_period]
    end
    [:check_interval, :check_attempts, :retry_check_interval,
     :args, :invertresults, :notification_options,
     :notification_period, :notification_interval, :flap_detection_enabled
    ].each do |property|
      if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end
  
    # Flush changes:
    put 'servicecheck', @updated_json.to_json

    @property_hash.clear
    @servicecheck_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the servicecheck if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @servicecheck_json = args[0][:full_json]
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

    @servicecheck_properties = @property_hash.dup
  end

  # Return the current state of the servicecheck in Opsview.
  def servicecheck_properties
    @servicecheck_properties.dup
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

  def default_servicecheck
    json = '
     {
         "name" : "Puppet - Unknown",
         "description" : "Puppet - Unknown",
         "keywords" : [],
         "servicegroup" : {
            "name" : "Puppet - Unknown"
         },
         "dependencies" : [
            {
               "name" : "Opsview Agent"
            }
         ],
         "check_period" : {
            "name" : "24x7"
         },
         "check_interval" : "5",
         "check_attempts" : "3",
         "retry_check_interval" : "1",
         "plugin" : {
            "name" : "check_nrpe"
         },
         "args" : "",
         "invertresults" : "0",
         "notification_options" : "w,c,r",
         "notification_period" : null,
         "notification_interval" : null,
         "flap_detection_enabled" : "1",
         "checktype" : {
            "name" : "Active Plugin"
         }
     }'

    JSON.parse(json.to_s)
  end
end
