Puppet::Type.newtype(:opsview_servicecheck) do
  @doc = "Manages servicechecks in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the
          servicecheck is updated"
  end
  newproperty(:description) do
    desc "Short description for the servicecheck"
  end
  newproperty(:servicegroup) do
    desc "The servicegroup that this servicecheck belongs to.  This
          servicegroup must be defined in puppet."
  end
  newproperty(:dependencies, :array_matching => :all) do
    desc "Array of dependencies for this servicecheck"
  end
  newproperty(:keywords, :array_matching => :all) do
    desc "Array of keywords for this servicecheck"
  end
  
  [:check_period, :check_interval, :check_attempts, :retry_check_interval,
   :plugin, :args, :invertresults, :notification_options,
   :notification_period, :notification_interval, :flap_detection_enabled,
   :volatile, :stalking].each do |property|
    newproperty(property) do
      desc "General opsview servicecheck parameter"
    end
  end
  
  autorequire(:opsview_servicegroup) do
    [self[:servicegroup]]
  end
  
  autorequire(:opsview_keyword) do
    [self[:keywords]]
  end
  
end
