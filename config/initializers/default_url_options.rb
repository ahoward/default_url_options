#
# getting relative links in rails mailers is not hard, although people love to
# make it out to be.  the basic concept is quite easy:
#
# 1) start with some reasonable defaults.  these will be used in testing and
# from the console
#
# 2) dynamically configure these defaults on the first request seen.
#
# all we require to do this is a smart hash and simple before_filter.  save
# this file as 'config/intiializers/deafult_url_options.rb' and add this
# before filter to your application_controller.rb
#
# class ApplicationController < ActionController::Base
#
#   before_filter :configure_default_url_options!
#
#   protected
#     def configure_default_url_options!
#       DefaultUrlOptions.configure!(request)
#     end
# end
#
# with this approach you will always generate absolute links for mailers and,
# when those emails are triggered from an http request they will be sent
# pointing back to that server.  note that this also means emails sent in
# development will correctly point back to http://0.0.0.0:3000, etc.

DefaultUrlOptions = HashWithIndifferentAccess.new

def DefaultUrlOptions.configure!(request = {})
  default_url_options = DefaultUrlOptions
  return if configured?

  if request.is_a?(Hash)
    host = request[:host] || request['host']
    port = request[:port] || request['port']
    protocol = request[:protocol] || request['protocol']
  else
    host = request.host
    port = request.port
    protocol = DefaultUrlOptions.protocol
    # protocol = request.protocol
  end

  host.gsub!(/^www\./, '') if host

  default_url_options[:protocol] = protocol
  default_url_options[:host] = host
  default_url_options[:port] = port unless(port==80 or port=='80')

# force action_mailer to not lick balls
#
  Rails.configuration.action_mailer.default_url_options = default_url_options
  ActionMailer::Base.default_url_options = default_url_options
  
  default_url_options.keys.each{|key| default_url_options.delete(key) unless default_url_options[key]}
  default_url_options
ensure
  configured!
end

def DefaultUrlOptions.configured!
  @configured ||= 0
  @configured += 1
end

def DefaultUrlOptions.configured
  @configured ||= 0
end

def DefaultUrlOptions.configured=(value)
  @configured = Integer(value) 
end

def DefaultUrlOptions.configured?
  @configured ||= 0
  @configured != 0
end

def DefaultUrlOptions.protocol
  DefaultUrlOptions[:protocol]
end

def DefaultUrlOptions.host
  DefaultUrlOptions[:host]
end

def DefaultUrlOptions.port
  DefaultUrlOptions[:port]
end

def DefaultUrlOptions.to_yaml(*args, &block)
  Hash.new.update(self).to_yaml(*args, &block)
end

DefaultUrlOptions.configure!(
  :protocol => 'http',
  :host => 'default.domain.com'
)

DefaultUrlOptions.configured = 0 # lie so first request re-initializes
