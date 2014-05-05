Puppet::Type.newtype(:opsview_monitored) do
  @doc = "Monitors the node from an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the host is updated"
    defaultto :false
  end

  newproperty(:hostgroup) do
    desc "Opsview hostgroup"
  end

  newproperty(:ip) do
    desc "Node IP address or name"
  end

  newproperty(:hosttemplates, :array_matching => :all) do
    desc "Array of Opsview host templates that should be applied to this node"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  newproperty(:servicechecks, :array_matching => :all) do
    desc "Array of Opsview service checks that should be applied to this node"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  
  newproperty(:keywords, :array_matching => :all) do
    desc "Array of Opsview keywords should be applied to this node"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  
  newproperty(:monitored_by) do
    desc "The Opsview server that monitors this node"
  end

  newproperty(:notification_interval) do
    desc "Host notification interval"
    defaultto '0'
  end
  
  newproperty(:parents, :array_matching => :all) do
    desc "Array of parents for this node"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  newproperty(:enable_snmp) do
    desc "Whether or not SNMP is enabled for the host"
    defaultto "0" 
  end

  newproperty(:snmp_community) do
    desc "SNMP community string for SNMP protocol 1 and 2c"
    defaultto "public" 
  end

  newproperty(:snmp_version) do
    desc "SNMP protocol version"
    defaultto "3" 
  end

  newproperty(:snmp_port) do
    desc "SNMP port"
    defaultto "161" 
  end

  newproperty(:snmpv3_username) do
    desc "SNMP v3 username"
    defaultto ""
  end

  newproperty(:snmpv3_authpassword) do
    desc "SNMP v3 Auth Password (should be 8 chars)"
    defaultto ""
  end

  newproperty(:snmpv3_authprotocol) do
    desc "SNMP v3 Auth Protocol (md5 or sha)"

    newvalue :md5
    newvalue :sha

    defaultto :md5
  end

  newproperty(:snmpv3_privpassword) do
    desc "SNMP v3 Priv Password (should be 8 chars)"
    defaultto ""
  end

  newproperty(:snmpv3_privprotocol) do
    desc "SNMP v3 Priv Protocol (des, aes or aes128)"

    newvalue :des
    newvalue :aes
    newvalue :aes128

    defaultto :des
  end

  newproperty(:snmp_max_msg_size) do
    desc "SNMP message size (default, 1Kio, 2Kio, 4Kio, 8Kio, 16Kio, 42Kio, 64Kio)"
    newvalue :default
    newvalue :"1Kio"
    newvalue :"2Kio"
    newvalue :"4Kio"
    newvalue :"8Kio"
    newvalue :"16Kio"
    newvalue :"32Kio"
    newvalue :"64Kio"

    defaultto :default
  end

  newproperty(:tidy_ifdescr_level) do
    desc "Set level of removing common words from ifDescr strings"

    newvalue :off
    newvalue :"level1"
    newvalue :"level2"
    newvalue :"level3"
  
    defaultto :off
  end

  newproperty(:snmp_extended_throughput_data) do
    desc "Whether or not to gather extended data from interfaces (the unicast, multicasdt, broadcast stats)"
  end

  newproperty(:icon_name) do
    desc "Icon to set for the device"
  end

  newproperty(:check_command) do
    desc "Host check command"
  end

  newproperty(:hostattributes, :array_matching => :all) do
    desc "Array of host attribute key pairs for this node"
    defaultto []

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end

    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  autorequire(:opsview_hostgroup) do
    [self[:hostgroup]]
  end

  autorequire(:opsview_hosttemplate) do
    self[:hosttemplates]
  end

  autorequire(:opsview_servicecheck) do
    self[:servicechecks]
  end
  
  autorequire(:opsview_monitored) do
    self[:parents]
  end
  
  autorequire(:opsview_keyword) do
    self[:keywords]
  end
end
