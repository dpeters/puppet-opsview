Puppet::Type.newtype(:opsview_monitored) do
  @doc = "Monitors the node from an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the host is updated"
  end

  newproperty(:hostgroup) do
    desc "Opsview hostgroup"
  end

  newproperty(:ip) do
    desc "Node IP address or name"
  end

  newproperty(:hosttemplates, :array_matching => :all) do
    desc "Array of Opsview host templates that should be applied to this node"
  end

  newproperty(:servicechecks, :array_matching => :all) do
    desc "Array of Opsview service checks that should be applied to this node"
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
end
