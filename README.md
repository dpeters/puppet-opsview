Stable release download
=======================

If you're looking for stable releases, you can download this module at
the [Puppet Forge](http://forge.puppetlabs.com/devon/opsview).

Introduction
=============

Right now, the module only contains libraries to handle all of the REST
requests to a given Opsview server.  You will need to create
/etc/puppet/opsview.conf with the following format on each client that you wish
to connect with an Opsview server:

    url: http://example.com/rest
    username: foobar
    password: foobaz

Please file bugs via the issue tracker above.

Prerequisites
=============

* Puppet (of course :))  Tested most recently with puppet 2.7.9
* rest-client, json gems.

Puppet Types in this Module
===========================

* opsview_attribute
* opsview_contact
* opsview_hostgroup
* opsview_hosttemplate
* opsview_keyword
* opsview_monitored
* opsview_notificationmethod
* opsview_role
* opsview_servicecheck
* opsview_servicegroup

List of things to do
====================

1. Separate out a few get/set methods from Puppet::Provider::Opsview - put them
in a utility module instead.

2. Clean up Puppet::Provider::Opsview in general.  Cull any class/instance
methods we don't need (there's lots of duplication.)

3. Add default providers so that Puppet runs don't fail when there's no rest-client / json gems to use.

Contributors
=======

* Devon Peters &lt;devon.peters@gmail.com&gt;
* Christian Paredes &lt;christian.paredes@sbri.org&gt;
* Duncan Ferguson &lt;duncs&gt;
* Amos Shapira &lt;amosshapira&gt;
* John Kinsella &lt;jlk&gt;
