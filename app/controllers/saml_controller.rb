class SamlController < ApplicationController
  include OktaSaml::SessionsHelper

  skip_before_filter :okta_authenticate!, :okta_logout

  def init
    request = Onelogin::Saml::Authrequest.new
    redirect_to(request.create(saml_settings))
  end

  def consume
    response = Onelogin::Saml::Response.new(params[:SAMLResponse])
    response.settings = saml_settings
    if response.is_valid?
      sign_in(OktaUser.new({:email => response.name_id}))
      redirect_to redirect_url
    else
      render :text => "Failure"
    end
  end

  def logout
    sign_out
    redirect_to redirect_url
    # request = Onelogin::Saml::Logoutrequest.new
    # settings = saml_settings
    # settings.name_identifier_value = "mike@hoitomt.com"
    # redirect_to(request.create(settings))
  end

  private

  def saml_settings
    settings = Onelogin::Saml::Settings.new

    settings.assertion_consumer_service_url = saml_consume_url(host: request.host)
    settings.issuer                         = "http://#{request.port == 80 ? request.host : request.host_with_port}"
    settings.idp_sso_target_url             = SAML_SETTINGS[:idp_sso_target_url]
    settings.idp_slo_target_url             = SAML_SETTINGS[:idp_sso_target_url]
    settings.idp_cert_fingerprint           = SAML_SETTINGS[:idp_cert_fingerprint]
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"
    # Optional for most SAML IdPs
    settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"

    settings
  end

  def redirect_url
    session[:redirect_url]
  end

  # Rails override to handle unverified post requests from Okta
  def handle_unverified_request
  end

end