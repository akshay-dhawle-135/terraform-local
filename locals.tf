locals {
  identity_api_suffix = "v1/event/identity"
  authorization_suffix = "oauth2/token"
  identity_connection = {
    name        = "identity-connection"
    description = "Http connection for identity events"
    authorization_endpoint = "oauth_url"
    http_method = "POST"
  }
  identity_api_destination = {
    name                             = "identity-api-destination"
    description                      = "Identity API destination"
    endpoint                         = "https://bf38-157-66-146-194.ngrok-free.app/ping"
    http_method                      = "GET"
    invocation_rate_limit_per_second = 100
  }
  rule_identity_create = {
    name = "identity-create-rule"
    event_pattern = {
      detail_type = ["identity-created"]
    }
  }
}
