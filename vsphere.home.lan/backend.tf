terraform {
  backend "gcs" {
    bucket  = "homelab_tf_state"
    prefix  = "terraform/state/vcenter"
  }
}