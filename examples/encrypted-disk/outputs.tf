output "location" {
  description = "The deployment region."
  value       = module.disk.location
}

output "resource_group_name" {
  description = "The name of the Resource Group."
  value       = module.disk.resource_group_name
}
