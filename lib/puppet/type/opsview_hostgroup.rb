Puppet::Type.newtype(:opsview_hostgroup) do
  @doc = "Manages hostgroups in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the hostgroup is updated"
  end
  
  newproperty(:hostgroup) do
    desc "The name of the hostgroup to manage"
    defaultto { @resource[:name] }
  end
  
  newproperty(:parent) do
    desc "Parent hostgroup.  Any defined parent's will be autorequired."
  end

  # Autorequire parent hostgroup
  autorequire(:opsview_hostgroup) do
    if @resource.include? [:parent]
      @resource[:parent]
    else
      nil
    end
  end

end
