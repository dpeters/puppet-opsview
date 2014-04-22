Puppet::Type.newtype(:opsview_contact) do
  @doc = "Manages contacts in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the
      contact is updated"
    defaultto :false
  end
  newproperty(:fullname) do
    desc "Full name of the user"
  end
  newproperty(:description) do
    desc "Short description for the contact"
  end
  newproperty(:role) do
    desc "The role that the user is in.  Defaults are:
      Administrator
      View all, change none
      View all, change some
      View some, change none
      View some, change some"
  end
  newproperty(:encrypted_password) do
    desc "The user's encrypted password.  Defaults to \"password\" if not
      specified."
  end
  newproperty(:language) do
    desc "The user's language"
  end
  newproperty(:variables) do
    desc "A hash containing the contact notification variables and their values.  Example:
    ...
    variables => { 'EMAIL' => 'someone@example.com', 'PAGER' => '555-1234' },
    ..."
    validate do |value|
      unless value.nil? or value.is_a? Hash
        raise Puppet::Error, "the opsview_contact 'variables' property must be a Hash, not #{value.class}"
      end
    end
    # Only check for variables that are being defined in the manifest. Opsview
    # will automatically add all available variables to every contact, and this
    # allows us to only care about the variables we defined in the manifest.
    def insync?(is)
      is.delete_if {|k, v| true if not @should[0].has_key?(k)} if is.is_a? Hash
      super(is)
    end
  end
  # HACK: The following *8x5 and *24x7 properties are hard-coded into this
  #       provider since we can't manage notificationprofile objects via the
  #       API, as separate things. This is the best option I could come up
  #       with for now, and since we only use these two profile types (8x5
  #       and 24x7) it should work.
  newproperty(:notificationmethods8x5, :array_matching => :all) do
    desc "An array of notificationmethods for the 8x5 notification profile."
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:notificationmethods24x7, :array_matching => :all) do
    desc "An array of notificationmethods for the 24x7 notification profile."
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:service_notification_options8x5) do
    desc "The service notification options for the 8x5 notification profile."
  end
  newproperty(:service_notification_options24x7) do
    desc "The service notification options for the 24x7 notification profile."
  end
  newproperty(:host_notification_options8x5) do
    desc "The host notification options for the 8x5 notification profile."
  end
  newproperty(:host_notification_options24x7) do
    desc "The host notification options for the 24x7 notification profile."
  end
  # Hostgroups
  newproperty(:hostgroups8x5, :array_matching => :all) do
    desc "An array of hostgroups for the 8x5 notification profile."
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:hostgroups24x7, :array_matching => :all) do
    desc "An array of hostgroups for the 24x7 notification profile."
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:allhostgroups8x5, :boolean => true) do
    desc "A boolean defining whether or not all hostgroups will have 8x5
      notifications for this contact."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end
  newproperty(:allhostgroups24x7, :boolean => true) do
    desc "A boolean defining whether or not all hostgroups will have 24x7
      notifications for this contact."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end
  # Servicegroups
  newproperty(:servicegroups8x5, :array_matching => :all) do
    desc "An array of servicegroups for the 8x5 notification profile."
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:servicegroups24x7, :array_matching => :all) do
    desc "An array of servicegroups for the 24x7 notification profile."
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:allservicegroups8x5, :boolean => true) do
    desc "A boolean defining whether or not all servicegroups will have 8x5
      notifications for this contact."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end
  newproperty(:allservicegroups24x7, :boolean => true) do
    desc "A boolean defining whether or not all servicegroups will have 24x7
      notifications for this contact."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end

  autorequire(:opsview_hostgroup) do
    hostgroups = []
    if not self[:hostgroups8x5].to_s.empty?
      hostgroups += self[:hostgroups8x5]
    end
    if not self[:hostgroups24x7].to_s.empty?
      hostgroups += self[:hostgroups24x7]
    end
    hostgroups
  end
  autorequire(:opsview_servicegroup) do
    servicegroups = []
    if not self[:servicegroups8x5].to_s.empty?
      servicegroups += self[:servicegroups8x5]
    end
    if not self[:servicegroups24x7].to_s.empty?
      servicegroups += self[:servicegroups24x7]
    end
    servicegroups
  end
  autorequire(:opsview_role) do
    [self[:role]]
  end
  autorequire(:opsview_notificationmethod) do
    nms = []
    if not self[:notificationmethods8x5].to_s.empty?
      nms += self[:notificationmethods8x5]
    end
    if not self[:notificationmethods24x7].to_s.empty?
      nms += self[:notificationmethods24x7]
    end
    nms
  end
end
