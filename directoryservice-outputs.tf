output "directory_service" {
  value = aws_directory_service_directory.ad
}

output "ad_join_doc" {
  value = aws_ssm_document.ad_join_doc
}

