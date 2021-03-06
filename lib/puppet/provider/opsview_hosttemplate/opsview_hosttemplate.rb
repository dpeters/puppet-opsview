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

Puppet::Type.type(:opsview_hosttemplate).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'hosttemplate'

  mk_resource_methods

  def self.hosttemplate_map(hosttemplate)
    p = { :name           => hosttemplate["name"],
          :hosttemplate   => hosttemplate["name"],
          :description    => hosttemplate["description"],
          :servicechecks  => hosttemplate["servicechecks"].collect { |sc| sc["name"] },
          # managementurls as read from Opsview is a list of hashes, where each hash
          # has "name" and "url" key. Assign this list directly to :managementurls
          :managementurls => hosttemplate["managementurls"],
          :full_json      => hosttemplate,
          :ensure         => :present }

    # Process optional properties here

    p

  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if hosttemplate = resources[provider.name]
        hosttemplate.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all hosttemplates.  Expensive query.
    hosttemplates = get_resources

    hosttemplates.each do |hosttemplate|
      providers << new(hosttemplate_map(hosttemplate))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @hosttemplate_json
      @updated_json = @hosttemplate_json.dup
    else
      @updated_json = default_hosttemplate
    end
 
    # Update the hosttemplate's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["name"] = @resource[:name]
    @updated_json["description"] = @property_hash[:description]
    @updated_json["servicechecks"] = []
    if @property_hash[:servicechecks]
      @property_hash[:servicechecks].each do |sc|
        @updated_json["servicechecks"] << { :name => sc }
      end
    end

    # If managementurls are set in the manifest update the JSON content for the
    # managementurls object with a list of hashes where each hash has a "name"
    # and an "url" key.
    if not @property_hash[:managementurls].empty?
      @property_hash[:managementurls].each do |mu|
        @updated_json["managementurls"] << { "name" => mu["name"], "url" => mu["url"] }
      end
    else
      @updated_json["managementurls"] = []
    end
  
    # Flush changes:
    put @updated_json.to_json

    if defined? @resource[:reload_opsview]
      if @resource[:reload_opsview].to_s == "true"
        Puppet.notice "Configured to reload opsview"
        do_reload_opsview
      else
        Puppet.notice "Configured NOT to reload opsview"
      end
    end

    @property_hash.clear
    @hosttemplate_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the hosttemplate if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @hosttemplate_json = args[0][:full_json]
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

    @hosttemplate_properties = @property_hash.dup
  end

  # Return the current state of the hosttemplate in Opsview.
  def hosttemplate_properties
    @hosttemplate_properties.dup
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

  def default_hosttemplate
    json = '
     {
        "name" : "Puppet - Unknown",
        "description" : "puppet unknown",
        "servicechecks" : [
           {
              "name" : "Puppet - Unknown",
              "exception" : null,
              "timed_exception" : null
           }
        ],
        "managementurls" : []
     }'

    JSON.parse(json.to_s)
  end
end
