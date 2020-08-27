output "directory_service_id" {
  value = aws_directory_service_directory.ad.id
}

output "ad_join_doc_name" {
  value = aws_ssm_document.ad_join_doc.name
}

