Opsview Module
--------------

Right now, the module only contains libraries to handle all of the REST
requests to a given Opsview server.  You will need to create
/etc/puppet/opsview.conf with the following format on each client that you wish
to connect with an Opsview server:

url: http://foo/bar
username: foobar
password: foobaz

The libraries are heavily based off of the original Opsview libraries, with
contributions by Devon Peters.

I can't guarantee that these libraries work quite yet.

Please file bugs via the issue tracker above.

Changes
-------

1. Use rest-client library instead of net/http.  This allows us to authenticate
clients over HTTPS and, overall, abstract a lot of the HTTP calls to the
server.

2. Create a subclass called "Puppet::Provider::Opsview" with default methods
that may be overridden by any of the providers.  The class contains methods
that actually hook into the server - thus, in the provider Ruby files (in
particular, the flush method) is reduced quite a bit, and we don't need to
explicitly define a function that reads in token information from the Opsview
server. 

3. Rename variables and methods, so they don't use camel case.

List of things to do
--------------------

1. Separate out a few get/set methods from Puppet::Provider::Opsview - put them
in util/ instead.

Authors
-------

Devon Peters (original author of every other provider library except for
opsview_monitored.rb)
Christian Paredes <christian.paredes@sbri.org>
