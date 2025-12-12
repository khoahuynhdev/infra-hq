output "vm_id" {
  description = "The ID of the virtual machine domain"
  value       = libvirt_domain.vm.id
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = libvirt_domain.vm.name
}

output "vm_vcpu" {
  description = "Number of vCPUs allocated"
  value       = libvirt_domain.vm.vcpu
}

output "vm_memory" {
  description = "Memory allocated in MiB"
  value       = libvirt_domain.vm.memory
}

output "storage_pool_name" {
  description = "Name of the storage pool"
  value       = libvirt_pool.vm_pool.name
}

output "disk_volume_name" {
  description = "Name of the VM disk volume"
  value       = libvirt_volume.vm_disk.name
}

output "disk_volume_path" {
  description = "Path to the VM disk volume"
  value       = libvirt_volume.vm_disk.path
}
