locals {
  files = [
    { name = "test1.txt", content = "bonjour-" },
    { name = "bonjour8.txt", content = "bonjour-" },
    { name = "setune1.txt", content = "bonjour-" },
    { name = "salut67.txt", content = "bonjour-" },
    { name = "dixittague45.py", content = "bonjour-" },
    { name = "herbanumer.txt", content = "bonjour-" }
  ]
}

resource "random_string" "random" {
  count   = length(local.files)
  length  = 6
  special = false
  upper   = true
  lower   = true
}

resource "local_file" "files" {
  count    = length(local.files)
  filename = local.files[count.index].name
  content  = "${local.files[count.index].content}${random_string.random[count.index].result}"
}
