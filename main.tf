variable "functions" {
  default = {
    "create_function" = {
      name     = "create_function"
      zip_file = "create.zip"
      entry_point = "CreateEmployee"
      
    }
    "delete_function" = {
      name     = "delete_function"
      zip_file = "delete.zip"
      entry_point = "DeleteEmployee"
    }
    "update_function" = {
      name     = "update_function"
      zip_file = "update.zip"
      entry_point = "PartialUpdateEmployee"
    }
  }
}

resource "google_storage_bucket" "functions_bucket1" {
  name     = "function_foreach_bucket"
  location = "us-central1"  # Change to your desired location
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_object" "function_zips" {
  for_each = var.functions

  name   = "function_${each.key}_zip"
  bucket = google_storage_bucket.functions_bucket1.name
  source = each.value["zip_file"]
}

# resource "google_cloudfunctions_function" "functions" {
#   for_each = var.functions

#   name        = each.value["name"]
#   description = "Cloud Function - ${each.value["name"]}"
#   runtime     = "go121"
#   source_archive_bucket = google_storage_bucket.functions_bucket1.name
#   source_archive_object = google_storage_bucket_object.function_zips[each.key].name
#   entry_point = each.value["entry_point"]    # Update with your function entry point
#   trigger_http = true
#   service_account_email = "fire-246@takeoff-task-3.iam.gserviceaccount.com"

#   available_memory_mb = 256
#   timeout            = 60
  
# }
resource "google_cloudfunctions2_function" "functions_gen2" {
#  depends_on = [
#    google_cloud_run_service_iam_binding.default
# ]

  for_each = var.functions  # Use your variable for defining multiple functions

  name        = each.value["name"]
  location    = "us-central1"
  description = "Cloud Function - ${each.value["name"]}"

  build_config {
    runtime     = "go121"  # Specify the desired Go runtime
    entry_point = each.value["entry_point"]  # Update with your function entry point

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket1.name
        object = google_storage_bucket_object.function_zips[each.key].name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = "fire-246@takeoff-task-3.iam.gserviceaccount.com"
  }
}


# resource "google_cloudfunctions_function_iam_member" "invoker" {
#   for_each = var.functions  # Apply IAM bindings for each created Cloud Function
  
#   cloud_function = each.value.name
#   project        = "takeoff-task-3"
#   role           = "roles/cloudfunctions.invoker"
#   member         = "allUsers"
# }

resource "google_cloud_run_service_iam_member" "default" {
 for_each = var.functions  # Use for_each with the Cloud Functions resource
  
  location = google_cloudfunctions2_function.functions_gen2[each.key].location
  # Access the specific instance's location attribute
  service  = each.value.name      # Assuming 'name' is used as a unique identifier for Cloud Functions
  role     = "roles/run.invoker"
  member   = "allUsers"
}