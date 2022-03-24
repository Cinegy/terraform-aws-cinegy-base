output "directory_service" {
  value = aws_directory_service_directory.ad
}

output "ad_join_doc" {
 value = element(concat(aws_ssm_document.ad_join_doc, tolist([""])), 0)
}

