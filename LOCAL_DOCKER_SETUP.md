# Local Docker Setup - Step by Step Guide

This guide will walk you through launching Dograh on your local machine using Docker.

## Prerequisites

Before starting, make sure you have:
- [ ] Docker installed on your machine
- [ ] Docker Compose installed (usually comes with Docker)
- [ ] At least 10GB free disk space
- [ ] Your own API keys for AI services (OpenAI, Deepgram, ElevenLabs)

### Checking Prerequisites

```bash
# Check Docker is installed
docker --version
# Expected: Docker version 20.x or higher

# Check Docker Compose is installed
docker compose version
# Expected: Docker Compose version 2.x or higher

# Check Docker is running
docker ps
# Should show a list (even if empty) without errors
```

If any of these fail, install Docker first: https://docs.docker.com/get-docker/

---

## Step 1: Navigate to the Dograh Directory

```bash
# If you're already in the dograh directory, skip this step
cd /path/to/dograh

# Verify you're in the right place
ls -la
# You should see: docker-compose.yaml, api/, ui/, pipecat/, etc.
```

---

## Step 2: Create Your Environment File

The `.env` file contains all configuration settings, including your API keys.

```bash
# Copy the example file
cp .env.example .env

# Open it for editing (choose your preferred editor)
nano .env
# or
vim .env
# or
code .env  # if you have VS Code
```

---

## Step 3: Edit the .env File

Here's what you need to configure:

### Required Settings

```bash
# ============================================
# DATABASE (leave as-is for local testing)
# ============================================
DATABASE_URL=postgresql+asyncpg://postgres:postgres@postgres:5432/postgres

# ============================================
# REDIS (leave as-is for local testing)
# ============================================
REDIS_URL=redis://:redissecret@redis:6379

# ============================================
# AI SERVICES - ADD YOUR KEYS HERE!
# ============================================
# Get from: https://platform.openai.com/api-keys
OPENAI_API_KEY=sk-proj-xxxYOURKEYHERExxx

# Get from: https://elevenlabs.io/app/settings/api-keys
ELEVENLABS_API_KEY=sk_xxxYOURKEYHERExxx

# Get from: https://console.deepgram.com/project/xxxx/settings/api-keys
DEEPGRAM_API_KEY=xxxYOURKEYHERExxx

# ============================================
# PRIVACY SETTINGS (leave as-is)
# ============================================
ENABLE_TELEMETRY=false
# MPS_API_URL should NOT be set (or leave empty)

# ============================================
# STORAGE (leave as-is for local testing)
# ============================================
MINIO_ENABLED=true
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
AWS_S3_BUCKET=dograh
AWS_REGION=us-east-1
S3_ENDPOINT_URL=http://minio:9000
```

### Save and Exit

- In **nano**: Press `Ctrl+X`, then `Y`, then `Enter`
- In **vim**: Press `Esc`, type `:wq`, press `Enter`
- In **VS Code**: Press `Ctrl+S` (or `Cmd+S` on Mac)

---

## Step 4: Build the Docker Images

This step compiles the application into Docker containers. It takes 10-15 minutes the first time.

```bash
# Make the build script executable
chmod +x build-docker-images.sh

# Run the build script
./build-docker-images.sh
```

**What you'll see:**
```
Building Docker images for Dograh (Fully Independent)
======================================================
Building API image...
[+] Building 456.7s (23/23) FINISHED
...
Building UI image...
[+] Building 234.5s (18/18) FINISHED
...
✅ Both images built successfully!
```

**This may take 10-15 minutes on first build.** Go get a coffee! ☕

### If Build Fails

If you see errors:

```bash
# Clean up Docker
docker system prune -a

# Try again
./build-docker-images.sh
```

---

## Step 5: Start the Infrastructure Services

Start PostgreSQL, Redis, and MinIO first:

```bash
docker compose up -d postgres redis minio
```

**What you'll see:**
```
[+] Running 3/3
 ✔ Container dograh-postgres-1  Started
 ✔ Container dograh-redis-1     Started
 ✔ Container dograh-minio-1     Started
```

**Wait 10 seconds** for services to initialize:
```bash
sleep 10
```

### Verify Services Started

```bash
docker compose ps
```

**Expected output:**
```
NAME                  STATUS    PORTS
dograh-postgres-1     Up        0.0.0.0:5432->5432/tcp
dograh-redis-1        Up        0.0.0.0:6379->6379/tcp
dograh-minio-1        Up        0.0.0.0:9000-9001->9000-9001/tcp
```

All should show **"Up"**.

---

## Step 6: Start the Application Services

Now start the API and UI:

```bash
docker compose up -d api ui
```

**What you'll see:**
```
[+] Running 2/2
 ✔ Container dograh-api-1  Started
 ✔ Container dograh-ui-1   Started
```

### Check Everything is Running

```bash
docker compose ps
```

**Expected output:**
```
NAME                  STATUS    PORTS
dograh-api-1          Up        0.0.0.0:8000->8000/tcp
dograh-ui-1           Up        0.0.0.0:3010->3010/tcp
dograh-postgres-1     Up        0.0.0.0:5432->5432/tcp
dograh-redis-1        Up        0.0.0.0:6379->6379/tcp
dograh-minio-1        Up        0.0.0.0:9000-9001->9000-9001/tcp
```

All should show **"Up"**.

---

## Step 7: Check the Logs

Make sure there are no errors:

```bash
# Check API logs
docker compose logs api | tail -50
```

**Look for:**
- ✅ "Application startup complete" or similar
- ✅ "Connected to database"
- ✅ "MPS_API_URL not configured. Skipping..." (this is good!)
- ❌ No ERROR messages

```bash
# Check UI logs
docker compose logs ui | tail -50
```

**Look for:**
- ✅ "ready - started server on 0.0.0.0:3000"
- ❌ No ERROR messages

---

## Step 8: Verify Independence

Check that there are NO connections to Dograh services:

```bash
# Should output: "✅ No MPS connections"
docker compose logs api | grep -i "services.dograh.com" && echo "❌ Found MPS connection!" || echo "✅ No MPS connections"

# Should output: "✅ No Sentry telemetry"
docker compose logs api | grep -i "sentry" && echo "❌ Found Sentry!" || echo "✅ No Sentry telemetry"

# Should output: "✅ No Chatwoot widget"
docker compose logs ui | grep -i "chat.dograh.com" && echo "❌ Found Chatwoot!" || echo "✅ No Chatwoot widget"
```

All three should show ✅ (green checks).

---

## Step 9: Test the API

```bash
# Health check
curl http://localhost:8000/api/v1/health
```

**Expected output:**
```json
{"status":"healthy"}
```

If you get this, the API is working! 🎉

### If API Doesn't Respond

```bash
# Check if API container is running
docker compose ps api

# Check API logs for errors
docker compose logs api

# Restart API
docker compose restart api
```

---

## Step 10: Open the UI in Your Browser

Open your web browser and go to:

**http://localhost:3010**

You should see the Dograh login/signup page!

### What to Check

- ✅ Page loads without errors
- ✅ No Chatwoot widget in bottom-right corner
- ✅ Open browser console (F12) - no errors about services.dograh.com

---

## Step 11: Create Your First User

Click **"Sign Up"** or use the API:

```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123!",
    "full_name": "Admin User",
    "organization_name": "My Organization"
  }'
```

**Expected output:**
```json
{
  "id": "...",
  "email": "admin@example.com",
  "full_name": "Admin User",
  ...
}
```

### Verify No MPS Auto-Key Attempt

```bash
docker compose logs api | grep "MPS_API_URL not configured"
```

**Expected output:**
```
MPS_API_URL not configured. Skipping auto-key generation. Users must configure their own AI provider keys.
```

This confirms you're running independently! ✅

---

## Step 12: Log In and Explore

1. Go to **http://localhost:3010**
2. Log in with your email and password
3. You should see the Dograh dashboard!

### Next Steps in the UI

- Configure your AI provider keys in Settings
- Create your first workflow
- Test with a phone call (requires Twilio/Vonage setup)

---

## 🎉 Success!

If you've made it here, you have:

✅ Built Docker images locally
✅ Started all services successfully
✅ Verified no connections to Dograh services
✅ Created a user account
✅ Logged into the UI

**Your Dograh instance is now running fully independently!**

---

## Common Issues & Solutions

### Issue: "Port already in use"

```bash
# Check what's using the port
sudo lsof -i :8000  # API port
sudo lsof -i :3010  # UI port
sudo lsof -i :5432  # PostgreSQL port

# Stop the conflicting service or change ports in docker-compose.yaml
```

### Issue: "Cannot connect to Docker daemon"

```bash
# Start Docker (Linux)
sudo systemctl start docker

# Start Docker (Mac)
open -a Docker

# Verify Docker is running
docker ps
```

### Issue: "Database connection failed"

```bash
# Check PostgreSQL is running
docker compose ps postgres

# Check logs
docker compose logs postgres

# Restart database
docker compose restart postgres

# Wait 10 seconds and restart API
sleep 10
docker compose restart api
```

### Issue: "API keys not working"

```bash
# Verify keys are in .env
cat .env | grep API_KEY

# Make sure there are no quotes around the keys
# Bad:  OPENAI_API_KEY="sk-xxx"
# Good: OPENAI_API_KEY=sk-xxx

# Restart services to pick up changes
docker compose restart api ui
```

### Issue: "Out of disk space"

```bash
# Clean up Docker
docker system prune -a
docker volume prune

# Check disk space
df -h
```

### Issue: "Build takes too long or hangs"

```bash
# Stop all containers
docker compose down

# Clean Docker cache
docker builder prune -a

# Try building one service at a time
docker compose build api
docker compose build ui
```

---

## Useful Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f api
docker compose logs -f ui

# Last 50 lines
docker compose logs api | tail -50
```

### Restart Services
```bash
# All services
docker compose restart

# Specific service
docker compose restart api
docker compose restart ui
```

### Stop Everything
```bash
# Stop all services
docker compose down

# Stop and remove volumes (fresh start)
docker compose down -v
```

### Start Everything
```bash
# Start all services
docker compose up -d

# Start and view logs
docker compose up
```

### Check Status
```bash
# List running containers
docker compose ps

# Check resource usage
docker stats
```

---

## What's Running?

| Service | URL | Purpose |
|---------|-----|---------|
| UI | http://localhost:3010 | Web interface |
| API | http://localhost:8000 | Backend API |
| API Docs | http://localhost:8000/docs | Interactive API documentation |
| PostgreSQL | localhost:5432 | Database |
| Redis | localhost:6379 | Cache & queues |
| MinIO | http://localhost:9000 | Object storage (S3-compatible) |
| MinIO Console | http://localhost:9001 | MinIO admin interface |

---

## Environment Variables Reference

### Required for Operation
- `DATABASE_URL` - PostgreSQL connection
- `REDIS_URL` - Redis connection
- `OPENAI_API_KEY` - For LLM (GPT-4, etc.)
- `ELEVENLABS_API_KEY` - For text-to-speech
- `DEEPGRAM_API_KEY` - For speech-to-text

### Privacy Controls
- `ENABLE_TELEMETRY=false` - No telemetry (default)
- `MPS_API_URL=` - No MPS connection (leave empty)

### Optional
- `TWILIO_ACCOUNT_SID` - For phone calls
- `TWILIO_AUTH_TOKEN` - For phone calls
- `VONAGE_API_KEY` - Alternative to Twilio
- `VONAGE_API_SECRET` - Alternative to Twilio

---

## Next Steps

1. **Configure AI Keys** - Add your provider keys in the UI Settings
2. **Create Workflows** - Use the visual workflow builder
3. **Set Up Telephony** - Configure Twilio or Vonage for calls
4. **Read Documentation**:
   - [ARCHITECTURE.md](ARCHITECTURE.md) - How it works
   - [PIPECAT_EXPLAINED.md](PIPECAT_EXPLAINED.md) - Real-time streaming
   - [THIRD_PARTY_CONNECTIONS.md](THIRD_PARTY_CONNECTIONS.md) - External services

---

## Getting Help

If you're still stuck:

1. Check logs: `docker compose logs`
2. Verify .env file has correct values
3. Check Docker is running: `docker ps`
4. Try a fresh start:
   ```bash
   docker compose down -v
   docker compose up -d postgres redis minio
   sleep 10
   docker compose up -d api ui
   ```

5. Check the full [TESTING_GUIDE.md](TESTING_GUIDE.md) for more detailed troubleshooting
