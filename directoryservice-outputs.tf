output "directory_service_id" {
  value = aws_directory_service_directory.ad.id
}

output "directory_service_default_doc_name" {
  value = aws_ssm_document.directory_service_default_doc.name
}

