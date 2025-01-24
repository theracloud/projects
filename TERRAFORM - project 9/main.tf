variable "num_files" {
  description = "Number of local files to create"
  type        = number
  default     = 3
}

resource "local_file" "example_file" {
  count    = var.num_files
  content  = "This is the content for file number ${count.index + 1}"
  filename = "${path.module}/file_${count.index + 1}.txt"
}

output "local_file_names" {
  description = "List of created local file names"
  value       = local_file.example_file[*].filename
}
