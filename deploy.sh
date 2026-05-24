#!/bin/bash
# ============ FILE: deploy.sh ============
# Script deploy semua service ObatLansia ke GCP
# Usage: ./deploy.sh <PROJECT_ID> <REGION>
# Example: ./deploy.sh my-gcp-project asia-southeast2

set -e

# ─── Configuration ───────────────────────────────────────────────
PROJECT_ID="${1:-your-gcp-project-id}"
REGION="${2:-asia-southeast2}"
AUTH_SERVICE="obatlansia-auth-service"
MED_SERVICE="obatlansia-medication-service"
REPO="obatlansia"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

echo "=================================================="
echo " ObatLansia — Deploy to GCP"
echo "=================================================="
echo " Project  : $PROJECT_ID"
echo " Region   : $REGION"
echo " Timestamp: $TIMESTAMP"
echo "=================================================="

# ─── Set project ─────────────────────────────────────────────────
gcloud config set project "$PROJECT_ID"

# ─── Enable required APIs ─────────────────────────────────────────
echo "[1/8] Enabling GCP APIs..."
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  appengine.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  --project="$PROJECT_ID"

# ─── Create Artifact Registry repo ───────────────────────────────
echo "[2/8] Creating Artifact Registry repository..."
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker \
  --location="$REGION" \
  --description="ObatLansia Docker images" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Repository already exists."

# ─── Configure Docker ─────────────────────────────────────────────
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

AUTH_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${AUTH_SERVICE}:${TIMESTAMP}"
MED_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${MED_SERVICE}:${TIMESTAMP}"

# ─── Build & Push Auth Service ────────────────────────────────────
echo "[3/8] Building Auth Service..."
docker build -t "$AUTH_IMAGE" ./auth-service
echo "[4/8] Pushing Auth Service..."
docker push "$AUTH_IMAGE"

# ─── Build & Push Medication Service ─────────────────────────────
echo "[5/8] Building Medication Service..."
docker build -t "$MED_IMAGE" ./medication-service
echo "[6/8] Pushing Medication Service..."
docker push "$MED_IMAGE"

# ─── Deploy Auth Service to Cloud Run ─────────────────────────────
echo "[7/8] Deploying Auth Service to Cloud Run..."
gcloud run deploy "$AUTH_SERVICE" \
  --image="$AUTH_IMAGE" \
  --region="$REGION" \
  --platform=managed \
  --allow-unauthenticated \
  --port=8001 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --set-env-vars="NODE_ENV=production,PORT=8001" \
  --project="$PROJECT_ID"

AUTH_URL=$(gcloud run services describe "$AUTH_SERVICE" \
  --region="$REGION" --project="$PROJECT_ID" \
  --format="value(status.url)")
echo " Auth Service URL: $AUTH_URL"

# ─── Deploy Medication Service to Cloud Run ──────────────────────
echo "[7/8] Deploying Medication Service to Cloud Run..."
gcloud run deploy "$MED_SERVICE" \
  --image="$MED_IMAGE" \
  --region="$REGION" \
  --platform=managed \
  --allow-unauthenticated \
  --port=8002 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --set-env-vars="PORT=8002" \
  --project="$PROJECT_ID"

MED_URL=$(gcloud run services describe "$MED_SERVICE" \
  --region="$REGION" --project="$PROJECT_ID" \
  --format="value(status.url)")
echo " Medication Service URL: $MED_URL"

# ─── Deploy Frontend to App Engine ───────────────────────────────
echo "[8/8] Building & Deploying Frontend to App Engine..."
cd frontend
npm ci
VITE_AUTH_SERVICE_URL="${AUTH_URL}/api/auth" \
VITE_MEDICATION_SERVICE_URL="${MED_URL}/api" \
npm run build

gcloud app deploy app.yaml --quiet --project="$PROJECT_ID"
cd ..

FRONTEND_URL="https://${PROJECT_ID}.appspot.com"

echo ""
echo "=================================================="
echo " ✅ Deploy selesai!"
echo "=================================================="
echo " Auth Service    : $AUTH_URL"
echo " Med Service     : $MED_URL"
echo " Frontend        : $FRONTEND_URL"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Set environment secrets di Cloud Run (DB_HOST, DB_PASSWORD, JWT_SECRET)"
echo "2. Setup Cloud SQL dan jalankan migration"
echo "3. Buat GCS bucket: gsutil mb -l $REGION gs://obat-lansia-bucket"
echo "4. Set bucket public: gsutil iam ch allUsers:objectViewer gs://obat-lansia-bucket"
