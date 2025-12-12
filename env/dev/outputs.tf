# Outputs for all created VMs

output "vm_ids" {
  description = "Map of VM names to their IDs"
  value       = { for k, v in module.libvirt_domain : k => v.vm_id }
}

output "vm_names" {
  description = "Map of VM keys to their actual names"
  value       = { for k, v in module.libvirt_domain : k => v.vm_name }
}

output "vm_info" {
  description = "Detailed information about all VMs"
  value = {
    for k, v in module.libvirt_domain : k => {
      id     = v.vm_id
      name   = v.vm_name
      vcpu   = v.vm_vcpu
      memory = v.vm_memory
      disk   = v.disk_volume_path
    }
  }
}
