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

Puppet::Type.type(:opsview_role).provide :opsview, :parent => Puppet::Provider::Opsview do

  mk_resource_methods

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    resources.each do |name, resource|
      if result = get 'role', name
        result[:ensure] = :present
        resource.provider = new(result)
      else
        resource.provider = new(:ensure => :absent)
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all roles.  Expensive query.
    roles = get 'role'

    roles["list"].each do |role|
      p = { :name      => role["name"],
            :role      => role["name"],
            :full_json => role,
            :ensure    => :present }

      [:description, :all_hostgroups, :all_servicegroups,
       :all_keywords].each do |property|
        if defined? role[property.id2name]
          p[property] = role[property.id2name]
        end
      end
      [:access_hostgroups, :access_servicegroups, :access_keywords, :accesses,
       :hostgroups].each do |property|
        if defined? role[property.id2name]
          p[property] = role[property.id2name].collect { |item| item["name"] }
        end
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
    if @role_json
      @updated_json = @role_json.dup
    else
      @updated_json = default_role
    end
 
    # Update the role's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["name"] = @resource[:name]
    [:description, :all_hostgroups, :all_servicegroups,
     :all_keywords].each do |property|
      if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end
    [:access_hostgroups, :access_servicegroups, :access_keywords, :accesses,
     :hostgroups].each do |property|
      if not @property_hash[property].to_s.empty?
        @property_hash[property].each do |item|
          @updated_json[property.id2name] << {:name => item}
        end
      end
    end
  
    # Flush changes:
    put 'role', @updated_json.to_json

    @property_hash.clear
    @role_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the role if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @role_json = args[0][:full_json]
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

    @role_properties = @property_hash.dup
  end

  # Return the current state of the role in Opsview.
  def role_properties
    @role_properties.dup
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

  def default_role
    json = '
    {
       "name" : "Puppet - Unknown",
       "description" : "",
       "all_hostgroups" : "1",
       "all_servicegroups" : "1",
       "all_keywords" : "0",
       "access_hostgroups" : [],
       "access_servicegroups" : [],
       "access_keywords" : [],
       "accesses" : [
          {
             "name" : "NOTIFYSOME"
          },
          {
             "name" : "PASSWORDSAVE"
          },
          {
             "name" : "VIEWALL"
          }
       ],
       "hostgroups" : []
    }'

    JSON.parse(json.to_s)
  end
end
