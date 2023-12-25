provider "google" {
  credentials = file("terraform.json")
  project     = "takeoff-task-3"
  region      = "us-central1"  # Change to your desired region
}
