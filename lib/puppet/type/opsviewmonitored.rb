Puppet::Type.newtype(:opsviewmonitored) do
  @doc = "Monitors the node from an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reloadopsview) do
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
end
