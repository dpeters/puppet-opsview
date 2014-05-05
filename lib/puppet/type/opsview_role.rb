Puppet::Type.newtype(:opsview_role) do
  @doc = "Manages roles in an Opsview monitoring system."

  ensurable

  newparam(:name, :namevar => true) do
  end
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the
      role is updated."
    defaultto :false
  end
  newproperty(:role) do
    desc "The name of this role."
    defaultto { @resource[:name] }
  end
  newproperty(:description) do
    desc "Short description of this role."
  end
  newproperty(:all_hostgroups, :boolean => true) do
    desc "Whether or not this role has access to all hostgroups.  Defaults
      to true."
   defaultto [true]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end

  end
  newproperty(:all_servicegroups, :boolean => true) do
    desc "Whether or not this role has access to all servicegroups.  Defaults
      to true."
    defaultto [true]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end

  end
  newproperty(:all_keywords, :boolean => true) do
    desc "Whether or not this role has access to all keywords.  Defaults
      to false."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end
  newproperty(:access_hostgroups, :array_matching => :all) do
    desc "Array of hostgroups that this role can access."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:access_servicegroups, :array_matching => :all) do
    desc "Array of servicegroups that this role can access."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:access_keywords, :array_matching => :all) do
    desc "Array of keywords that this role can access."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:accesses, :array_matching => :all) do
    desc "Array of access properties defined for this role."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:hostgroups, :array_matching => :all) do
    desc "Array of hostgroups that this role can configure, if CONFIGUREHOSTS
      is defined in accesses."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
end
