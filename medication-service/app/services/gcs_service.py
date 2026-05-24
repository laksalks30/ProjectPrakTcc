# ============ FILE: medication-service/app/services/gcs_service.py ============
from google.cloud import storage
import uuid
import os
from dotenv import load_dotenv

load_dotenv()

GCS_BUCKET_NAME = os.getenv("GCS_BUCKET_NAME", "obat-lansia-bucket")
GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID", "local-dev-project")

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB


def get_storage_client():
    """Get Google Cloud Storage client."""
    try:
        client = storage.Client(project=GCP_PROJECT_ID)
        return client
    except Exception as e:
        print(f"GCS client error: {e}")
        return None


async def upload_file_to_gcs(file_content: bytes, filename: str, content_type: str, folder: str = "photos") -> str:
    """Upload file to Google Cloud Storage and return public URL."""
    try:
        # Validate file
        ext = os.path.splitext(filename)[1].lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise ValueError(f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}")

        if len(file_content) > MAX_FILE_SIZE:
            raise ValueError("File size exceeds 5MB limit")

        unique_filename = f"{folder}/{uuid.uuid4()}{ext}"

        # Try to use GCS
        client = get_storage_client()
        if not client:
            # Fallback to local storage
            print("📁 Using local storage for local development (no GCP credentials found).")
            upload_dir = "static/uploads"
            os.makedirs(upload_dir, exist_ok=True)
            local_filename = f"{uuid.uuid4()}{ext}"
            local_filepath = os.path.join(upload_dir, local_filename)
            
            print(f"💾 Saving file to: {os.path.abspath(local_filepath)}")
            with open(local_filepath, "wb") as f:
                f.write(file_content)
            
            public_url = f"http://localhost:8002/static/uploads/{local_filename}"
            print(f"✅ File saved successfully")
            print(f"🔗 Public URL: {public_url}")
            return public_url

        # Upload to GCS
        print(f"☁️  Uploading to Google Cloud Storage...")
        bucket = client.bucket(GCS_BUCKET_NAME)
        blob = bucket.blob(unique_filename)
        blob.upload_from_string(file_content, content_type=content_type)

        try:
            blob.make_public()
        except Exception as e:
            print(f"⚠️  Could not make file public: {e}")

        public_url = f"https://storage.googleapis.com/{GCS_BUCKET_NAME}/{unique_filename}"
        print(f"✅ File uploaded to GCS: {public_url}")
        return public_url

    except Exception as e:
        print(f"❌ Error uploading file: {str(e)}")
        import traceback
        traceback.print_exc()
        raise


async def delete_file_from_gcs(file_url: str) -> bool:
    """Delete file from Google Cloud Storage or local storage."""
    try:
        if not file_url:
            return False

        # Handle local files
        if "localhost:8002/static/uploads" in file_url:
            print(f"🗑️  Deleting local file: {file_url}")
            # Extract filename from URL
            local_filename = file_url.split("/static/uploads/")[-1]
            local_filepath = os.path.join("static/uploads", local_filename)
            
            if os.path.exists(local_filepath):
                os.remove(local_filepath)
                print(f"✅ Local file deleted: {local_filepath}")
                return True
            else:
                print(f"⚠️  Local file not found: {local_filepath}")
                return False

        # Handle GCS files
        if GCS_BUCKET_NAME not in file_url:
            return False

        filename = file_url.split(f"{GCS_BUCKET_NAME}/")[1]
        if not filename:
            return False

        client = get_storage_client()
        if not client:
            return False

        bucket = client.bucket(GCS_BUCKET_NAME)
        blob = bucket.blob(filename)

        if blob.exists():
            blob.delete()
            print(f"✅ Deleted file from GCS: {filename}")
            return True
        return False
    except Exception as e:
        print(f"❌ Error deleting file: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
