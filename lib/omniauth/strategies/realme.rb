# frozen_string_literal: true

require 'omniauth'
require 'ruby-saml'

module OmniAuth
  module Strategies
    class Realme
      include OmniAuth::Strategy
      autoload :AuthRequest, 'omniauth/strategies/realme/auth_request'

      # Fixed OmniAuth options
      option :provider, 'realme'

      def request_phase
        req = OneLogin::RubySaml::Authrequest.new
        redirect req.create(saml_settings, 'SigAlg' => 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256')
      end

      def callback_phase
        response = ::OneLogin::RubySaml::Response.new(request.params['SAMLResponse'], settings: saml_settings)

        if response.is_valid?
          session[:uid] = response.nameid
        else
          authorize_failure
        end

        @raw_info = response
        super
      end

      private

      def saml_settings
        idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
        settings = idp_metadata_parser.parse(File.read(options.fetch('idp_service_metadata')))

          settings.issuer                         = options.fetch('issuer')
          settings.assertion_consumer_service_url = options.fetch('assertion_consumer_service_url')
          settings.private_key                    = options.fetch('private_key')
          settings.authn_context                  = options.fetch('auth_strenght', 'urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:ac:classes:LowStrength')
          settings.protocol_binding                   = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
          settings.assertion_consumer_service_binding = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
          settings.soft = false

          settings.security[:authn_requests_signed] = true

          settings
      end
    end
  end
end

OmniAuth.config.add_camelization 'realme', 'Realme'