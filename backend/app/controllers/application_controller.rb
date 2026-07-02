class ApplicationController < ActionController::API
  include SetLocale
  include SubdomainTenant
end
