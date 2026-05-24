# ============ FILE: README.md ============
# 💊 ObatLansia — Pengingat Minum Obat Lansia

Aplikasi web berbasis microservice untuk membantu caregiver dan keluarga memantau dan mengelola jadwal minum obat lansia.

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────┐
│                    INTERNET / CLIENT                     │
└────────────────────────┬────────────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │  Frontend (React)   │  App Engine :8080
              └──────┬──────────────┘
                     │
        ┌────────────┼────────────┐
        │                         │
┌───────▼──────┐         ┌────────▼────────┐
│ Auth Service │         │  Med. Service   │
│  (Node.js)   │         │   (FastAPI)     │
│  CR :8001    │         │   CR :8002      │
└───────┬──────┘         └────────┬────────┘
        │                         │
        └────────────┬────────────┘
                     │
          ┌──────────▼──────────┐
          │   Cloud SQL MySQL   │
          │  auth_db │ med_db   │
          └─────────────────────┘
                     │
          ┌──────────▼──────────┐
          │  Google Cloud GCS   │
          │  (foto avatar/obat) │
          └─────────────────────┘
```

---

## 📁 Struktur Proyek

```
obat-lansia/
├── auth-service/          # Node.js + Express + JWT
├── medication-service/    # Python + FastAPI + SQLAlchemy
├── frontend/              # React + Vite + TailwindCSS
├── database/              # SQL scripts (DDL + seed data)
├── docker-compose.yml     # Local development
├── cloudbuild.yaml        # CI/CD pipeline
├── deploy.sh              # Deploy script
└── README.md
```

---

## ⚙️ Setup Local Development

### Prerequisites
- Node.js 18+
- Python 3.11+
- Docker + Docker Compose
- MySQL 8.0 (atau gunakan Docker)

### 1. Clone dan Setup

```bash
git clone <repo-url>
cd obat-lansia
```

### 2. Jalankan dengan Docker Compose (Cara Mudah)

```bash
# Salin env file
cp auth-service/.env.example auth-service/.env
cp medication-service/.env.example medication-service/.env
cp frontend/.env.example frontend/.env

# Jalankan semua service
docker-compose up --build

# Akses aplikasi:
# Frontend : http://localhost:8080
# Auth API : http://localhost:8001
# Med API  : http://localhost:8002
```

### 3. Setup Manual (Tanpa Docker)

#### Database
```bash
mysql -u root -p < database/auth_db.sql
mysql -u root -p < database/medication_db.sql
```

#### Auth Service
```bash
cd auth-service
cp .env.example .env
# Edit .env sesuai konfigurasi lokal
npm install
npm run dev
# Berjalan di http://localhost:8001
```

#### Medication Service
```bash
cd medication-service
cp .env.example .env
# Edit .env sesuai konfigurasi lokal
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload
# Berjalan di http://localhost:8002
# Docs: http://localhost:8002/docs
```

#### Frontend
```bash
cd frontend
cp .env.example .env
# Edit VITE_AUTH_SERVICE_URL dan VITE_MEDICATION_SERVICE_URL
npm install
npm run dev
# Berjalan di http://localhost:5173
```

### 4. Akun Demo

| Email | Password | Role |
|-------|----------|------|
| admin@obatlansia.com | password123 | Admin |
| siti.caregiver@obatlansia.com | password123 | Caregiver |
| budi.family@obatlansia.com | password123 | Keluarga |

---

## ☁️ Deploy ke Google Cloud Platform

### Prerequisites
- GCP Project aktif dengan billing enabled
- `gcloud` CLI terinstall dan login
- Docker terinstall

### Step 1: Setup GCP Project

```bash
# Login ke GCP
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Aktifkan APIs
gcloud services enable cloudbuild.googleapis.com run.googleapis.com \
  appengine.googleapis.com sqladmin.googleapis.com storage.googleapis.com \
  artifactregistry.googleapis.com secretmanager.googleapis.com
```

### Step 2: Setup Cloud SQL (MySQL 8.0)

```bash
# Buat instance Cloud SQL
gcloud sql instances create obatlansia-db \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=asia-southeast2

# Set password root
gcloud sql users set-password root --instance=obatlansia-db --password=YOUR_DB_PASSWORD

# Buat databases
gcloud sql databases create auth_db --instance=obatlansia-db
gcloud sql databases create medication_db --instance=obatlansia-db

# Import SQL schema + seed data
gcloud sql import sql obatlansia-db gs://YOUR_BUCKET/auth_db.sql --database=auth_db
gcloud sql import sql obatlansia-db gs://YOUR_BUCKET/medication_db.sql --database=medication_db
```

### Step 3: Setup Google Cloud Storage

```bash
# Buat bucket
gsutil mb -l asia-southeast2 gs://obat-lansia-bucket

# Set bucket public (untuk foto)
gsutil iam ch allUsers:objectViewer gs://obat-lansia-bucket

# Enable CORS
cat > cors.json << 'EOF'
[{"origin":["*"],"method":["GET","PUT","POST"],"responseHeader":["Content-Type"],"maxAgeSeconds":3600}]
EOF
gsutil cors set cors.json gs://obat-lansia-bucket
```

### Step 4: Store Secrets di Secret Manager

```bash
# Simpan secrets
echo -n "YOUR_DB_HOST" | gcloud secrets create DB_HOST --data-file=-
echo -n "YOUR_DB_PASSWORD" | gcloud secrets create DB_PASSWORD --data-file=-
echo -n "your_super_secret_jwt_key_32chars_minimum" | gcloud secrets create JWT_SECRET --data-file=-
```

### Step 5: Deploy Semua Service

```bash
chmod +x deploy.sh
./deploy.sh YOUR_PROJECT_ID asia-southeast2
```

### Step 6: Setup Cloud Build Trigger (CI/CD)

```bash
# Hubungkan repository ke Cloud Build
gcloud builds triggers create github \
  --repo-name=obat-lansia \
  --repo-owner=YOUR_GITHUB_USERNAME \
  --branch-pattern='^main$' \
  --build-config=cloudbuild.yaml
```

---

## 📡 API Endpoints

### Auth Service (Base: `/api/auth`)

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/register` | ❌ | Daftar akun baru |
| POST | `/login` | ❌ | Login, return JWT |
| POST | `/logout` | ✅ | Logout (blacklist token) |
| GET | `/profile` | ✅ | Get profil user login |
| PUT | `/profile` | ✅ | Update profil + foto avatar |
| GET | `/users` | ✅ Admin | List semua user |
| DELETE | `/users/:id` | ✅ Admin | Hapus user |

### Medication Service (Base: `/api`)

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/patients` | Tambah data lansia |
| GET | `/patients` | List semua lansia |
| GET | `/patients/:id` | Detail lansia |
| PUT | `/patients/:id` | Update + upload foto |
| DELETE | `/patients/:id` | Hapus data lansia |
| POST | `/medications` | Tambah data obat |
| GET | `/medications` | List semua obat |
| PUT | `/medications/:id` | Update + upload foto |
| DELETE | `/medications/:id` | Hapus data obat |
| POST | `/prescriptions` | Tambah resep |
| GET | `/prescriptions/patient/:id` | Resep per lansia |
| PUT | `/prescriptions/:id` | Update resep |
| POST | `/reminders` | Buat jadwal reminder |
| GET | `/reminders/patient/:id` | Reminder per lansia |
| PUT | `/reminders/:id` | Update reminder |
| DELETE | `/reminders/:id` | Hapus reminder |
| POST | `/logs` | Catat status minum obat |
| GET | `/logs/patient/:id` | Riwayat log per lansia |
| GET | `/dashboard/stats` | Statistik dashboard |

### Format Response

```json
{
  "success": true,
  "message": "Success",
  "data": { ... },
  "meta": { "total": 10, "page": 1, "limit": 10, "totalPages": 1 }
}
```

---

## 🔐 Environment Variables

### Auth Service
| Variable | Contoh | Deskripsi |
|----------|--------|-----------|
| PORT | 8001 | Port service |
| DB_HOST | localhost | Host MySQL |
| DB_PORT | 3306 | Port MySQL |
| DB_USER | root | User MySQL |
| DB_PASSWORD | password | Password MySQL |
| DB_NAME | auth_db | Nama database |
| JWT_SECRET | secret32chars | Secret JWT (min 32 char) |
| JWT_EXPIRES_IN | 24h | Durasi token |
| GCS_BUCKET_NAME | obat-lansia-bucket | Nama bucket GCS |
| GCP_PROJECT_ID | my-project | ID project GCP |
| CORS_ORIGIN | http://localhost:5173 | Origin CORS |

### Medication Service
| Variable | Contoh | Deskripsi |
|----------|--------|-----------|
| PORT | 8002 | Port service |
| DB_HOST | localhost | Host MySQL |
| DB_NAME | medication_db | Nama database |
| JWT_SECRET | secret32chars | Secret JWT (sama dengan auth) |
| GCS_BUCKET_NAME | obat-lansia-bucket | Nama bucket GCS |

### Frontend
| Variable | Contoh | Deskripsi |
|----------|--------|-----------|
| VITE_AUTH_SERVICE_URL | http://localhost:8001/api/auth | URL Auth Service |
| VITE_MEDICATION_SERVICE_URL | http://localhost:8002/api | URL Medication Service |

---

## 🛠️ Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Auth Service | Node.js 18, Express 4, JWT, bcryptjs, Sequelize |
| Medication API | Python 3.11, FastAPI, SQLAlchemy, Pydantic |
| Frontend | React 18, Vite, TailwindCSS, Axios, Recharts |
| Database | MySQL 8.0 (Cloud SQL) |
| Storage | Google Cloud Storage |
| Container | Docker, Docker Compose |
| CI/CD | Google Cloud Build |
| Hosting | Cloud Run (backend), App Engine (frontend) |

---

## 📝 License

MIT License — Feel free to use and modify.
