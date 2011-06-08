begin
  require 'rest-client'
  require 'json'
rescue LoadError => e
  nil
end
require 'yaml'

class Puppet::Provider::Opsview < Puppet::Provider
  def create
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      if val = resource.should(property)
        @property_hash[property] = val
      end
    end
  end

  def delete
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  private

  def put(body)
    self.class.put(body)
  end

  def self.put(body)
    url = [ config["url"], "config/#{@req_type.downcase}" ].join("/")
    begin
      response = RestClient.put url, body, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json
    rescue
      raise Puppet::Error, "Error communicating with Opsview: " + $!
    end

    begin
      responseJson = JSON.parse(response)
    rescue
      raise "Could not parse the JSON response from Opsview: " + response
    end

    begin
      reload_opsview
    rescue => e
      raise "Was not able to reload Opsview: " + e
    end
  end

  def config
    self.class.config
  end

  def self.config
    @config ||= get_config
  end

  def self.get_config
    config_file = "/etc/puppet/opsview.conf"
    # Load the Opsview config
    begin
      conf = YAML.load_file(config_file)
    rescue
      raise(Puppet::DevError, "Could not parse YAML configuration file " + config_file + " " + $!)
    end

    if conf["username"].nil? or conf["password"].nil? or conf["url"].nil?
      raise(Puppet::DevError, "Config file must contain URL, username, and password fields.")
    end

    conf
  end

  def token
    self.class.token
  end

  def self.token
    @token ||= get_token
  end

  def self.get_token
    post_body = { "username" => config["username"],
                  "password" => config["password"] }.to_json

    url = [ config["url"], "login" ].join("/")

    begin
      response = RestClient.post url, post_body, :content_type => :json
    rescue
      raise "Error communicating with Opsview: " + $!
    end

    case response.code
    when 200
      Puppet.debug "Response code: 200"
    else
      raise "Was not able to login to Opsview to grab the token."
    end

    received_token = JSON.parse(response)['token']
    received_token
  end

  def reload_opsview
    self.class.reload_opsview
  end

  def self.reload_opsview
    url = [ config["url"], "reload" ].join("/")

    begin
      response = RestClient.post url, '', :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json
    rescue
      raise "Error communicating with Opsview: " + $!
    end

    case response.code
    when 200
      Puppet.debug "Reloaded Opsview"
    when 401
      raise "Login failed: " + response.code
    when 409
      Puppet.info "Opsview reload already in progress"
    else
      raise "Was not able to reload Opsview: " + response.code
    end
  end

  def get_resource(name = nil)
    self.class.get_resource(name)
  end

  def get_resources
    self.class.get_resources
  end

  def self.get_resource(name = nil)
    if name.nil?
      raise "Did not specify a node to look up."
    else
      url = URI.escape( [ config["url"], "config/#{@req_type.downcase}?s.name=#{name}" ].join("/") )
    end

    begin
      response = RestClient.get url, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json
    rescue
      raise "Error communicating with Opsview: " + $!
    end

    begin
      responseJson = JSON.parse(response)
    rescue
      raise "Could not parse the JSON response from Opsview: " + response
    end

    obj = responseJson['list'][0]

    obj
  end

  def self.get_resources
    url = [ config["url"], "config/#{@req_type.downcase}" ].join("/")

    begin
      response = RestClient.get url, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json
    rescue
      raise "Error communicating with Opsview: " + $!
    end

    begin
      responseJson = JSON.parse(response)
    rescue
      raise "Could not parse the JSON response from Opsview: " + response
    end

    objs = responseJson["list"]

    objs
  end
end
