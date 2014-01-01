#

# This file is part of the Opsview puppet module
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

Puppet::Type.type(:opsview_attribute).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'attribute'

  mk_resource_methods

  def self.attribute_map(attribute)
    p = { :name      => attribute["name"],
          :attribute => attribute["name"],
          :full_json => attribute,
          :ensure    => :present }

    # optional properties
    if defined? attribute["value"]["name"]
      p[:value] = attribute["value"]["name"]
    end
    if defined? attribute["arg1"]["name"]
      p[:arg1] = attribute["arg1"]["name"]
    end
    if defined? attribute["arg2"]["name"]
      p[:arg2] = attribute["arg2"]["name"]
    end
    if defined? attribute["arg3"]["name"]
      p[:arg3] = attribute["arg3"]["name"]
    end
    if defined? attribute["arg4"]["name"]
      p[:arg4] = attribute["arg4"]["name"]
    end

    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if attribute = resources[provider.name]
        attribute.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all attributes.  Expensive query.
    attributes = get_resources

    attributes.each do |attribute|
      providers << new(attribute_map(attribute))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @attribute_json
      @updated_json = @attribute_json.dup
    else
      @updated_json = default_attribute
    end
 
    # Update the attribute's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    if not @property_hash[:value].to_s.empty?
      @updated_json["value"] = @property_hash[:value]
    end
    if not @property_hash[:arg1].to_s.empty?
      @updated_json["arg1"] = @property_hash[:arg1]
    end
    if not @property_hash[:arg2].to_s.empty?
      @updated_json["arg2"] = @property_hash[:arg2]
    end
    if not @property_hash[:arg3].to_s.empty?
      @updated_json["arg3"] = @property_hash[:arg3]
    end
    if not @property_hash[:arg4].to_s.empty?
      @updated_json["arg4"] = @property_hash[:arg4]
    end
    @updated_json["name"] = @resource[:attribute]
  
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
    @attribute_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the attribute if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @attribute_json = args[0][:full_json]
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

    @attribute_properties = @property_hash.dup
  end

  # Return the current state of the attribute in Opsview.
  def attribute_properties
    @attribute_properties.dup
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

  def default_attribute
    json = '
     {
       "value" :  "",
       "name" : "puppet-unknown",
       "arg1" :  "",
       "arg2" :  "",
       "arg3" :  "",
       "arg4" :  ""
     }'

    JSON.parse(json.to_s)
  end
end
