# Local values for standardized resource sizing
locals {
  # Disk sizes in bytes
  disk_sizes = {
    "10GB"  = 10737418240  # 10 * 1024 * 1024 * 1024
    "20GB"  = 21474836480  # 20 * 1024 * 1024 * 1024
    "50GB"  = 53687091200  # 50 * 1024 * 1024 * 1024
    "100GB" = 107374182400 # 100 * 1024 * 1024 * 1024
  }

  # CPU configurations
  cpus = {
    "small"  = 1
    "medium" = 2
    "large"  = 4
    "xlarge" = 8
  }

  # Memory configurations in MiB
  memory = {
    "512MB" = 512
    "1GB"   = 1024
    "2GB"   = 2048
    "4GB"   = 4096
    "8GB"   = 8192
    "16GB"  = 16384
    "32GB"  = 32768
  }
}
