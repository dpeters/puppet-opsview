Puppet::Type.newtype(:opsview_monitored) do
  @doc = "Monitors the node from an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the host is updated"
  end

  newproperty(:obj_id) do
    desc "Opsview's internal Object ID"
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
  
  newproperty(:keywords, :array_matching => :all) do
    desc "Array of Opsview keywords should be applied to this node"
  end
  
  newproperty(:monitored_by) do
    desc "The Opsview server that monitors this node"
  end
  
  newproperty(:parents, :array_matching => :all) do
    desc "Array of parents for this node"
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
