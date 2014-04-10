Puppet::Type.newtype(:opsview_servicegroup) do
  @doc = "Manages servicegroups in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end
  
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the servicegroup is updated"
    defaultto :false
  end
  
  newproperty(:servicegroup) do
    desc "This servicegroup"
    defaultto { @resource[:name] }
  end
  
end
