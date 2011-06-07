require 'rest-client'
require 'json'
require 'yaml'

class Puppet::Provider::Opsview < Puppet::Provider
  private

  def self.config
    unless @@config
      config_file = "/etc/puppet/opsview.conf"
      # Load the Opsview config
      begin
        @@config = YAML.load_file(config_file)
      rescue
        raise(Puppet::DevError, "Could not parse YAML configuration file " + config_file + " " + $!)
      end

      if @@config["username"].nil? or @@config["password"].nil? or @@config["url"].nil?
        raise(Puppet::DevError, "Config file must contain URL, username, and password fields.")
      end
    end
    @@config
  end

  def self.url(req_type)
    case req_type.downcase
    when "login"
      url = [ config["url"], "login" ].join("/")
    when "node"
      url = [ config["url"], "config/host" ].join("/")
    when "hosttemplate"
      url = [ config["url"], "config/hosttemplate" ].join("/")
    when "contact"
      url = [ config["url"], "config/contact" ].join("/")
    when "hostgroup"
      url = [ config["url"], "config/hostgroup" ].join("/")
    when "role"
      url = [ config["url"], "config/role" ].join("/")
    when "servicecheck"
      url = [ config["url"], "config/servicecheck" ].join("/")
    when "servicegroup"
      url = [ config["url"], "config/servicegroup" ].join("/")
    else
      raise(Puppet::DevError, "self.url needs to be extended to handle the req_type you've given: " + req_type)
    end
    url
  end

  def self.token
    @@token ||= get_token
  end

  def self.get_token
    post_body = { "username" => config["username"],
                  "password" => config["password"] }.to_json

    begin
      response = RestClient.post url('login'), post_body, :content_type => :json
    rescue
      raise "Error communicating with Opsview: " + $!
    end

    case response.code
    when 200
      Puppet.debug "Response code: 200"
    else
      raise "Was not able to login to Opsview to grab the token."
    end

    @@token = JSON.parse(response)['token']
  end

  def self.reload_opsview
    url = [ config["url"], "reload" ].join("/")

    get_cookies = { :x_opsview_username => config["username"],
                    :x_opsview_token    => token }

    begin
      response = RestClient.get url, { :cookies => get_cookies }, :content_type => :json, :accept => :json
    rescue
      raise "Error communicating with Opsview: " + $!
    end

    case response.code
    when "200"
      Puppet.debug "Reloaded Opsview"
    else
      raise "Was not able to reload Opsview!"
    end
  end

  def self.get(req_type, name = nil)
    get_cookies = { :x_opsview_username => config["username"],
                    :x_opsview_token    => token }

    if name.nil?
      full_url = url(req_type)
    else
      full_url = URI.escape("#{url(req_type)}?s.name=#{name}")
    end

    begin
      response = RestClient.get full_url, { :cookies => get_cookies }, :content_type => :json, :accept => :json
    rescue
      raise "Error communicating with Opsview: " + $!
    end

    begin
      responseJson = JSON.parse(response)
    rescue
      raise "Could not parse the JSON response from Opsview: " + response
    end

    responseJson
  end

  def self.put(req_type, body)
    put_cookies = { :x_opsview_username => config["username"],
                    :x_opsview_token    => token }

    begin
      response = RestClient.put url(req_type), body, { :cookies => put_cookies }, :content_type => :json, :accept => :json
    rescue
      raise "Error communicating with Opsview: " + $!
    end

    begin
      responseJson = JSON.parse(response)
      reload_opsview
    rescue
      raise "Could not parse the JSON response from Opsview: " + response
    end
  end
end
