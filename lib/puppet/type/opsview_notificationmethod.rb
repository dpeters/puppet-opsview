Puppet::Type.newtype(:opsview_notificationmethod) do
  @doc = "Manages notificationmethods in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end
  
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the
          notificationmethod is updated"
  end
  
  newproperty(:master) do
    desc "Whether or not this is enabled on the master"
  end

  newproperty(:active) do
    desc "Whether or not this is Active"
  end

  newproperty(:command) do
    desc "The command to run when this method is used"
  end
  
  newproperty(:contact_variables) do
    desc "Comman delimited string of variables that are used by this notification method"
  end
  
end
