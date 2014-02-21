Puppet::Type.newtype(:opsview_attribute) do
  @doc = "Manages attributes in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the attribute is updated"
  end
  
  newproperty(:attribute) do
    desc "The name of the attribute to manage"
    defaultto { @resource[:name] }
  end
  
  newproperty(:value) do
    desc "Optional default attribute value."
  end

  newproperty(:arg1) do
    desc "Optional argument 1 value."
  end

  newproperty(:arg2) do
    desc "Optional argument 2 value."
  end

  newproperty(:arg3) do
    desc "Optional argument 3 value."
  end

  newproperty(:arg4) do
    desc "Optional argument 4 value."
  end

end
