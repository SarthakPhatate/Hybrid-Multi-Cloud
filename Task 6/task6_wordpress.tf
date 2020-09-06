resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress"
    labels = {
      App = "task6"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "task6"
      }
    }
    template {
      metadata {
        labels = {
          App = "task6"
        }
      }
      spec {
        container {
          image = "wordpress"
          name  = "wp"

          port {
            container_port = 80
          }
            }
          }
        }
      }
    }

resource "kubernetes_service" "WP" {
  metadata {
    name = "wordpress"
  }
  spec {
    selector = {
      App = kubernetes_deployment.wordpress.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}
