Puppet::Type.newtype(:opsview_keyword) do
  @doc = "Manages keywords in an Opsview monitoring system."

  ensurable

  newparam(:name, :namevar => true) do
  end
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the
      keyword is updated."
    defaultto :false
  end
  newproperty(:keyword) do
    desc "The name of this keyword."
    defaultto { @resource[:name] }
  end
  newproperty(:description) do
    desc "Short description of this keyword."
  end
  newproperty(:viewport, :boolean => true) do
    desc "Whether or not the viewport for this keyword is enabled."
    defaultto [true]
    munge do |value|
      value = value ? "1" : "0"
    end
  end
  newproperty(:all_hosts, :boolean => true) do
    desc "Whether or not this keyword is applied to all hosts.  Defaults to false."
    defaultto [false]
    munge do |value|
      value = value ? "1" : "0"
    end
  end
  newproperty(:all_servicechecks, :boolean => true) do
    desc "Whether or not this keyword is applied to all servicechecks.  Defaults to false."
    defaultto [false]
    munge do |value|
      value = value ? "1" : "0"
    end
  end
  newproperty(:style) do
    desc "The viewport display style to use for this keyword.  Available styles:
      * errors_and_host_cells
      * group_by_host
      * group_by_service
      * host_summary
      * performance"
  end
  newproperty(:hosts, :array_matching => :all) do
    desc "Array of hosts to apply this keyword to"
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:servicechecks, :array_matching => :all) do
    desc "Array of servicechecks to apply this keyword to"
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:roles, :array_matching => :all) do
    desc "Array of roles which can view this keyword"
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  
  autorequire(:opsview_servicecheck) do
    [self[:servicechecks]]
  end
  autorequire(:opsview_monitored) do
    [self[:hosts]]
  end
end
