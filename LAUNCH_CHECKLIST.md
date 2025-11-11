# 🚀 Launch Checklist - Local Docker

Follow these steps in order. Check off each step as you complete it.

---

## Before You Start

- [ ] Docker is installed (`docker --version`)
- [ ] Docker is running (`docker ps` works)
- [ ] You have 10GB+ free disk space
- [ ] You have AI API keys ready (OpenAI, Deepgram, ElevenLabs)

---

## Step-by-Step Launch

### 1️⃣ Prepare Environment

```bash
cd /path/to/dograh
cp .env.example .env
```

- [ ] Copied .env.example to .env

### 2️⃣ Add Your API Keys

```bash
nano .env
```

**Edit these lines:**
```bash
OPENAI_API_KEY=sk-proj-YOUR-KEY-HERE
ELEVENLABS_API_KEY=sk_YOUR-KEY-HERE
DEEPGRAM_API_KEY=YOUR-KEY-HERE
```

- [ ] Added OpenAI API key
- [ ] Added ElevenLabs API key
- [ ] Added Deepgram API key
- [ ] Saved and closed the file

**Where to get keys:**
- OpenAI: https://platform.openai.com/api-keys
- ElevenLabs: https://elevenlabs.io/app/settings/api-keys
- Deepgram: https://console.deepgram.com/

### 3️⃣ Build Images (10-15 minutes)

```bash
chmod +x build-docker-images.sh
./build-docker-images.sh
```

**Wait for:**
```
✅ Both images built successfully!
```

- [ ] API image built successfully
- [ ] UI image built successfully

### 4️⃣ Start Database & Cache

```bash
docker compose up -d postgres redis minio
sleep 10
```

- [ ] Started postgres, redis, minio
- [ ] Waited 10 seconds

### 5️⃣ Start Application

```bash
docker compose up -d api ui
```

- [ ] Started api and ui services

### 6️⃣ Check Everything Started

```bash
docker compose ps
```

**All should show "Up":**
- [ ] dograh-postgres-1
- [ ] dograh-redis-1
- [ ] dograh-minio-1
- [ ] dograh-api-1
- [ ] dograh-ui-1

### 7️⃣ Check Logs for Errors

```bash
docker compose logs api | tail -50
```

- [ ] No ERROR messages in API logs
- [ ] Saw "Application startup complete" (or similar)

```bash
docker compose logs ui | tail -50
```

- [ ] No ERROR messages in UI logs
- [ ] Saw "ready - started server"

### 8️⃣ Test API

```bash
curl http://localhost:8000/api/v1/health
```

**Expected:** `{"status":"healthy"}`

- [ ] API health check returns healthy

### 9️⃣ Open UI in Browser

Open: **http://localhost:3010**

- [ ] UI loads successfully
- [ ] No Chatwoot widget visible
- [ ] Login/signup page appears

### 🔟 Create First User

In browser, click "Sign Up" and create account, or:

```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123!",
    "full_name": "Admin User",
    "organization_name": "My Org"
  }'
```

- [ ] User created successfully
- [ ] Can log in

### 1️⃣1️⃣ Verify Independence

```bash
docker compose logs api | grep "MPS_API_URL not configured"
```

**Expected:** `MPS_API_URL not configured. Skipping auto-key generation...`

- [ ] Confirmed no MPS connection
- [ ] Confirmed no Sentry telemetry
- [ ] Confirmed no Chatwoot widget

---

## ✅ Success Criteria

If all checkboxes are checked, you have:

- ✅ Built Docker images
- ✅ Started all services
- ✅ API responding correctly
- ✅ UI accessible in browser
- ✅ Created user account
- ✅ Confirmed fully independent (no Dograh service connections)

## 🎉 You're Done!

Your Dograh instance is running at:
- **UI:** http://localhost:3010
- **API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs

---

## 🆘 Quick Troubleshooting

### Can't connect to Docker?
```bash
# Start Docker
sudo systemctl start docker  # Linux
open -a Docker              # Mac
```

### Port already in use?
```bash
# Check what's using the port
sudo lsof -i :8000
sudo lsof -i :3010
```

### Services won't start?
```bash
# Fresh restart
docker compose down
docker compose up -d postgres redis minio
sleep 10
docker compose up -d api ui
```

### Need to see logs?
```bash
docker compose logs -f api
docker compose logs -f ui
```

### API keys not working?
```bash
# Check they're set correctly
cat .env | grep API_KEY

# Restart services
docker compose restart api ui
```

### Want to start over?
```bash
# Stop and remove everything
docker compose down -v

# Start fresh from Step 4
```

---

## 📚 More Help

- **Detailed guide:** [LOCAL_DOCKER_SETUP.md](LOCAL_DOCKER_SETUP.md)
- **Full testing:** [TESTING_GUIDE.md](TESTING_GUIDE.md)
- **Quick start:** [QUICKSTART_TESTING.md](QUICKSTART_TESTING.md)

---

## 💡 Tips

- Use `docker compose logs -f` to watch logs in real-time
- Use `docker compose ps` to check service status
- Use `docker compose restart <service>` to restart a specific service
- The first build takes longest - subsequent builds are much faster
- All data is stored in Docker volumes - safe across restarts
