output "curl_command_to_test_api_endpoint" {
  value       = "curl -f http://${module.alb.dns_name}/time_in_epoch"
  description = "This is a curl command which can be used to hit the API endpoint"
}