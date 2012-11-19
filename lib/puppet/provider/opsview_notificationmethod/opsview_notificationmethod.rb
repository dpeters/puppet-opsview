#
# And made original again by Devon Peters
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

Puppet::Type.type(:opsview_notificationmethod).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'notificationmethod'

  mk_resource_methods

  def self.notificationmethod_map(nm)
    p = { :name               => nm["name"],
          :command            => nm["command"],
          :full_json          => nm,
          :ensure             => :present }
    # optional properties
    if defined? nm["master"]
      p[:master] = nm["master"]
    end
    if defined? nm["active"]
      p[:active] = nm["active"]
    end
    if defined? nm["contact_variables"]
      p[:contact_variables] = nm["contact_variables"]
    end
    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if notificationmethod = resources[provider.name]
        notificationmethod.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all notificationmethods.  Expensive query.
    notificationmethods = get_resources

    notificationmethods.each do |notificationmethod|
      providers << new(notificationmethod_map(notificationmethod))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @notificationmethod_json
      @updated_json = @notificationmethod_json.dup
    else
      @updated_json = default_notificationmethod
    end
 
    # Update the notificationmethod's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["name"] = @resource[:name]
    if not @property_hash[:master].to_s.empty?
      @updated_json["master"] = @property_hash[:master]
    end
    if not @property_hash[:active].to_s.empty?
      @updated_json["active"] = @property_hash[:active]
    end
    if not @property_hash[:command].to_s.empty?
      @updated_json["command"] = @property_hash[:command]
    end
    if not @property_hash[:contact_variables].to_s.empty?
      @updated_json["contact_variables"] = @property_hash[:contact_variables]
    end
  
    # Flush changes:
    put @updated_json.to_json

    if defined? @resource[:reload_opsview]
      if @resource[:reload_opsview].to_s == "1"
        Puppet.notice "Configured to reload opsview"
        do_reload_opsview
      else
        Puppet.notice "Configured NOT to reload opsview"
      end
    end

    @property_hash.clear
    @notificationmethod_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the notificationmethod if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @notificationmethod_json = args[0][:full_json]
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

    @notificationmethod_properties = @property_hash.dup
  end

  # Return the current state of the notificationmethod in Opsview.
  def notificationmethod_properties
    @notificationmethod_properties.dup
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

  def default_notificationmethod
    json = '
     {
         "master" : "0",
         "name" : "Puppet - Unknown",
         "active" : "1",
         "command" : "notify_by_email",
         "contact_variables" : "EMAIL"
     }'

    JSON.parse(json.to_s)
  end
end
