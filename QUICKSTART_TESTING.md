# Quick Start - Testing the Fully Independent Branch

This is a fast-track guide to test the fully independent Dograh deployment in under 30 minutes.

## ✅ What's Already Verified

I've already verified these configurations are correct:

```
✅ Telemetry disabled by default
✅ MPS is optional (empty default)
✅ Chatwoot widget removed
✅ No hardcoded Sentry DSN
✅ Pipecat submodule initialized
✅ MPS auto-key generation can be skipped
✅ ChatwootWidget import commented out
```

**Result: This deployment can run fully independently! ✨**

---

## 🚀 Option 1: Quick Verification Test (2 minutes)

Just want to verify the independence configurations? Run this:

```bash
# Make sure you're on the correct branch
git branch --show-current

# Run verification script
./verify-independence.sh
```

You should see all ✅ green checks.

---

## 🐳 Option 2: Local Docker Test (15-20 minutes)

Test the full stack running locally with Docker.

### Step 1: Prepare Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env and add your AI API keys
nano .env  # or use any editor
```

**Required variables in .env:**
```bash
# Database (default values work for local testing)
DATABASE_URL=postgresql+asyncpg://postgres:postgres@postgres:5432/postgres
REDIS_URL=redis://:redissecret@redis:6379

# AI Services - ADD YOUR OWN KEYS HERE
OPENAI_API_KEY=sk-proj-your-key-here
ELEVENLABS_API_KEY=sk_your-key-here
DEEPGRAM_API_KEY=your-key-here

# Ensure telemetry is OFF (should be default)
ENABLE_TELEMETRY=false

# Ensure MPS is not configured (leave empty or comment out)
# MPS_API_URL=
```

### Step 2: Build Docker Images (10-15 mins)

```bash
# Build both API and UI images
./build-docker-images.sh

# This will take 10-15 minutes on first build
# Subsequent builds are faster due to caching
```

### Step 3: Start Services

```bash
# Start infrastructure services first
docker compose up -d postgres redis minio

# Wait 10 seconds for initialization
sleep 10

# Start application services
docker compose up -d api ui

# Check all services are running
docker compose ps
```

### Step 4: Verify No Dograh Connections

```bash
# Check API logs - should NOT see services.dograh.com
docker compose logs api | grep -i "services.dograh.com" && echo "❌ Found MPS connection!" || echo "✅ No MPS connections"

# Check for telemetry - should NOT see sentry
docker compose logs api | grep -i "sentry" && echo "❌ Found Sentry!" || echo "✅ No Sentry telemetry"

# Check UI logs - should NOT see chat.dograh.com
docker compose logs ui | grep -i "chat.dograh.com" && echo "❌ Found Chatwoot!" || echo "✅ No Chatwoot widget"
```

### Step 5: Test Application

```bash
# Test API health
curl http://localhost:8000/api/v1/health
# Expected: {"status":"healthy"}

# Test UI
curl -I http://localhost:3010/
# Expected: 200 OK
```

**Open in browser:**
- API Docs: http://localhost:8000/docs
- UI: http://localhost:3010

### Step 6: Test User Registration

Create a test user to verify MPS auto-key generation is skipped:

```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!",
    "full_name": "Test User",
    "organization_name": "Test Org"
  }'
```

Then check the logs:

```bash
docker compose logs api | grep -i "MPS_API_URL not configured"
# Expected: "MPS_API_URL not configured. Skipping auto-key generation..."
```

✅ **Success!** User created without connecting to Dograh services.

---

## ☁️ Option 3: Railway Deployment Test (10 minutes)

Deploy to Railway cloud platform.

### Prerequisites
- Railway account (https://railway.app)
- Railway CLI installed: `npm i -g @railway/cli`

### Step 1: Login to Railway

```bash
railway login
```

### Step 2: Create New Project

```bash
# Initialize Railway project
railway init

# Link to your Railway account
railway link
```

### Step 3: Add Services

Go to Railway dashboard and add:

1. **PostgreSQL** (from Railway templates)
2. **Redis** (from Railway templates)
3. **API Service** (from this repo)
4. **UI Service** (from this repo)

### Step 4: Configure Environment Variables

For API service, add:
```
OPENAI_API_KEY=sk-proj-xxx
ELEVENLABS_API_KEY=sk_xxx
DEEPGRAM_API_KEY=xxx
ENABLE_TELEMETRY=false
# No MPS_API_URL = fully independent!
```

For UI service, add:
```
BACKEND_URL=${{api.RAILWAY_PUBLIC_DOMAIN}}
NEXT_PUBLIC_BACKEND_URL=https://${{api.RAILWAY_PUBLIC_DOMAIN}}
```

### Step 5: Deploy

```bash
# Deploy API
railway up --service api

# Deploy UI
railway up --service ui
```

### Step 6: Verify

```bash
# Get service URLs
railway status

# Test API
curl https://your-api.up.railway.app/api/v1/health

# Test UI in browser
open https://your-ui.up.railway.app
```

**Check logs for independence:**
```bash
railway logs --service api | grep -i "services.dograh.com" || echo "✅ No MPS"
railway logs --service api | grep -i "sentry" || echo "✅ No telemetry"
```

---

## 📦 Option 4: Docker Image Distribution Test (5 minutes)

Test saving and loading images for offline distribution.

### Step 1: Save Images

```bash
# Save both images to tar.gz files
./save-docker-images.sh

# Check files created
ls -lh docker-images/
# Expected:
# dograh-independent-api-latest.tar.gz (~300MB)
# dograh-independent-ui-latest.tar.gz (~150MB)
```

### Step 2: Clean Images

```bash
# Remove images from Docker
docker rmi dograh-independent/api:latest
docker rmi dograh-independent/ui:latest

# Verify removed
docker images | grep dograh-independent || echo "✅ Images removed"
```

### Step 3: Load Images

```bash
# Load from tar files
./load-docker-images.sh

# Verify loaded
docker images | grep dograh-independent
# Should show both API and UI images
```

### Step 4: Transfer Test (Optional)

```bash
# These files can be:
# - Copied to USB drive
# - Uploaded to internal server
# - Distributed via GitHub Releases
# - Used in air-gapped environments

# Example: Copy to USB
cp docker-images/*.tar.gz /mnt/usb/
```

---

## 🎯 Expected Results

After any of the above tests, you should have:

### ✅ Independence Verified
- No connections to `services.dograh.com` (MPS)
- No connections to `chat.dograh.com` (Chatwoot)
- No connections to `*.sentry.io` (telemetry)
- No connections to `*.posthog.com` (analytics)

### ✅ Functionality Verified
- API responds to health checks
- UI loads successfully
- User registration works (without MPS auto-keys)
- Database connections work
- Redis connections work

### ✅ Privacy Verified
- Telemetry disabled by default
- No data sent to Dograh servers
- You control all AI provider keys
- Full data sovereignty

---

## 🐛 Quick Troubleshooting

### "Pipecat module not found"
```bash
git submodule update --init --recursive
docker compose build api
```

### "Database connection failed"
```bash
docker compose logs postgres
docker compose restart api
```

### "Port already in use"
```bash
# Check what's using the port
sudo lsof -i :8000  # API
sudo lsof -i :3010  # UI

# Stop the conflicting service or change ports in docker-compose.yaml
```

### "Docker build fails - no space"
```bash
docker system prune -a
docker volume prune
```

### "API keys not working"
```bash
# Verify keys are in .env
cat .env | grep API_KEY

# Restart to pick up changes
docker compose restart api
```

---

## 📊 Test Results Checklist

Mark your progress:

- [ ] **Configuration Verification** - Run `./verify-independence.sh`
- [ ] **Docker Build** - Images built successfully
- [ ] **Services Start** - All containers running
- [ ] **API Health** - Returns healthy status
- [ ] **UI Loads** - No Chatwoot widget visible
- [ ] **User Registration** - Works without MPS
- [ ] **No MPS Connections** - Logs confirm independence
- [ ] **No Telemetry** - No Sentry/PostHog traffic
- [ ] **Image Distribution** - Save/load works

---

## 📚 Detailed Testing

For comprehensive testing including workflow creation, voice calls, and network isolation:

See **[TESTING_GUIDE.md](TESTING_GUIDE.md)** for the complete 12-test suite.

---

## 🎉 Success!

If you've completed any of the above options and all checks pass, congratulations!

**You have a fully independent Dograh deployment that:**
- Runs entirely under your control
- Connects only to AI providers YOU choose
- Sends no data to Dograh servers
- Maintains complete privacy and data sovereignty

---

## 📖 Next Steps

1. **Deploy to Production**
   - See [RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md) for cloud deployment
   - Or use Docker Compose on your own servers

2. **Configure AI Providers**
   - Add your OpenAI, Deepgram, ElevenLabs keys
   - Or use alternative providers (Groq, Azure, etc.)

3. **Create Workflows**
   - Use the visual workflow builder
   - Test with LoopTalk AI personas

4. **Set Up Telephony**
   - Configure Twilio or Vonage
   - Create phone numbers
   - Start making/receiving calls

---

## 🆘 Need Help?

- **Documentation**: Check other .md files in this repo
- **Issues**: https://github.com/pavleks/dograh/issues (if applicable)
- **Logs**: Always check `docker compose logs` first

---

## 🔐 Security Note

This fully independent branch:
- ✅ No telemetry or tracking
- ✅ No automatic connections to Dograh services
- ✅ You own and control all data
- ✅ You choose which AI providers to use
- ✅ Suitable for privacy-sensitive deployments
- ✅ Can run in air-gapped environments (with saved Docker images)

**You have complete control!** 🎊
