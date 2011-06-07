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

Puppet::Type.type(:opsview_contact).provide :opsview, :parent => Puppet::Provider::Opsview do

  mk_resource_methods

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    resources.each do |name, resource|
      if result = get('contact', name)
        result[:ensure] = :present
        resource.provider = new(result)
      else
        resource.provider = new(:ensure => :absent)
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all contacts.  Expensive query.
    contacts = get 'contact'

    contacts["list"].each do |contact|
      p = { :name      => contact["name"],
            :full_json => contact,
            :ensure    => :present }

      # optional properties
      [:fullname, :description, :encrypted_password, :language].each do |prop|
        p[prop] = contact[prop.id2name] if defined? contact[prop.id2name]
      end

      contact["variables"].each do |variable|
        if variable["name"] == "EMAIL"
          p[:email] = variable["value"]
        end
      end
      if defined? contact["notificationprofiles"]
        contact["notificationprofiles"].each do |profile|
          if profile["name"] == "8x5"
            p[:hostgroups8x5] = profile["hostgroups"].collect{ |hg| hg["name"] }
            p[:allhostgroups8x5] = profile["all_hostgroups"]
          elsif profile["name"] == "24x7"
            p[:hostgroups24x7] = profile["hostgroups"].collect{ |hg| hg["name"] }
            p[:allhostgroups24x7] = profile["all_hostgroups"]
          end
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
    if @contact_json
      @updated_json = @contact_json.dup
    else
      @updated_json = default_contact
    end
 
    # Update the contact's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["name"] = @resource[:name]
    [:fullname, :description, :encrypted_password, :language].each do |property|
      if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end
    if not @property_hash[:email].to_s.empty?
      v = []
      @updated_json["variables"].each do |variable|
        if variable["name"] == "EMAIL"
          variable["value"] = @property_hash[:email]
        end
        v << variable
      end
      @updated_json["variables"] = v
    end
    if not @property_hash[:role].to_s.empty?
      @updated_json["role"]["name"] = @property_hash[:role]
    end
    # Update @updated_json["notificationprofiles"]
    update_notificationprofiles
  
    # Flush changes:
    put 'contact', @updated_json.to_json

    @property_hash.clear
    @contact_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the contact if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @contact_json = args[0][:full_json]
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

    @contact_properties = @property_hash.dup
  end

  # Return the current state of the contact in Opsview.
  def contact_properties
    @contact_properties.dup
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

  def default_contact
    json = '
     {
        "name" : "puppet",
        "fullname" : "",
        "description" : "",
        "encrypted_password" : "$apr1$HTQogYE7$09TNcZWa/WzoBXdUF6Iyr1",
        "realm" : "local",
        "language" : "",
        "role" : {
           "name" : "View all, change none"
        },
        "variables" : [
           {
              "value" : "",
              "name" : "EMAIL"
           },
           {
              "value" : "1",
              "name" : "RSS_COLLAPSED"
           },
           {
              "value" : "1440",
              "name" : "RSS_MAXIMUM_AGE"
           },
           {
              "value" : "30",
              "name" : "RSS_MAXIMUM_ITEMS"
           }
        ],
        "notificationprofiles" : [
           {
              "name" : "24x7",
              "host_notification_options" : "u,d,r,f",
              "notificationmethods" : [
                 { "name" : "Email" }
              ],
              "servicegroups" : [],
              "all_servicegroups" : "1",
              "all_hostgroups" : "0",
              "keywords" : [],
              "service_notification_options" : "w,c,r,u,f",
              "hostgroups" : [],
              "notification_level" : "1",
              "notification_period" : {
                 "name" : "24x7"
              }
           },
           {
              "name" : "8x5",
              "host_notification_options" : "u,d,r,f",
              "notificationmethods" : [
                 { "name" : "Email" }
              ],
              "servicegroups" : [],
              "all_servicegroups" : "1",
              "all_hostgroups" : "0",
              "keywords" : [],
              "service_notification_options" : "w,c,r,u,f",
              "hostgroups" : [],
              "notification_level" : "1",
              "notification_period" : {
                 "name" : "workhours"
              }
           }
        ]
    }'

    JSON.parse(json.to_s)
  end

  # return the nested array->hash->array data structure required for
  # notificationprofiles.
  def update_notificationprofiles
    # This will only modify/affect the 8x5 and 24x7 profiles
    ["8x5", "24x7"].each do |profile_name|
      hg_sym = profile_name.sub(/^/, 'hostgroups').to_sym
      allhg_sym = profile_name.sub(/^/, 'allhostgroups').to_sym
      if not @property_hash[hg_sym].to_s.empty?
        notificationprofiles = []
        @updated_json["notificationprofiles"].each do |profile|
          if profile["name"] == profile_name
            # Set the all_hostgroups parameter, if set
            if not @property_hash[allhg_sym].to_s.empty?
              profile["all_hostgroups"] = @property_hash[allhg_sym]
            end
            # Set hostgroups to an array of name->hostgroup hashes
            profile["hostgroups"] = []
            @property_hash[hg_sym].each do |hg|
              profile["hostgroups"] << {:name => hg}
            end
          end
          # Append this profile to the array of hashes, whether we changed it
          # or not
          notificationprofiles << profile
        end
        @updated_json["notificationprofiles"] = notificationprofiles
      else
        # Process the allhostgroups* if hostgroups* is empty
        if not @property_hash[allhg_sym].to_s.empty?
          notificationprofiles = []
          @updated_json["notificationprofiles"].each do |profile|
            if profile["name"] == profile_name
              profile["all_hostgroups"] = @property_hash[allhg_sym]
            end
            notificationprofiles << profile
          end
          @updated_json["notificationprofiles"] = notificationprofiles
        end
      end
    end
  end
end
