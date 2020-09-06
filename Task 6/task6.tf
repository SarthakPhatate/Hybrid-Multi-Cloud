provider "aws"{
  region = "ap-south-1"
  profile = "sarthakphatate"
}

provider "kubernetes" {
  config_context_cluster = "minikube"
}
