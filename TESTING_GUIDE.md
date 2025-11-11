# Testing Guide - Fully Independent Dograh

This guide helps you test the fully independent deployment to ensure it works as expected without any Dograh service dependencies.

## 🎯 What We're Testing

The fully independent branch should:
- ✅ Run without connecting to Dograh's services (services.dograh.com)
- ✅ Have telemetry disabled by default
- ✅ Not load Chatwoot widget
- ✅ Not attempt auto-key generation from MPS
- ✅ Work with your own AI provider keys
- ✅ Build Docker images successfully
- ✅ Deploy to Railway (or other platforms)

---

## 📋 Pre-Testing Checklist

### 1. Verify Branch
```bash
git branch --show-current
# Should show: claude/verify-sourcecode-present-011CV2BJhcLN4sVZzRDUFRcb
# or: claude/fully-independent-011CV2BJhcLN4sVZzRDUFRcb

git log --oneline -5
# Should show recent commits about independent deployment
```

### 2. Verify Submodules
```bash
git submodule status
# Should show pipecat with a commit hash (not empty)

ls -la pipecat/src/pipecat/
# Should show Python files, not empty directory
```

### 3. Check Configuration Files
```bash
# Check key configuration changes
grep -n "ENABLE_TELEMETRY" docker-compose.yaml
grep -n "MPS_API_URL" api/constants.py
grep -n "CHATWOOT" ui/Dockerfile
```

---

## 🧪 Test 1: Configuration Verification

### Check Telemetry is Disabled
```bash
# Should show false by default
grep "ENABLE_TELEMETRY" docker-compose.yaml

# Expected output:
# ENABLE_TELEMETRY: "${ENABLE_TELEMETRY:-false}"
```

### Check MPS is Optional
```bash
# Should show empty default
grep "MPS_API_URL" api/constants.py

# Expected output:
# MPS_API_URL = os.getenv("MPS_API_URL", "")
```

### Check Chatwoot is Removed
```bash
# Should be commented out
grep -A2 "CHATWOOT" ui/Dockerfile

# Expected output (commented):
# # ENV NEXT_PUBLIC_CHATWOOT_URL=""
# # ENV NEXT_PUBLIC_CHATWOOT_TOKEN=""
```

**Result:** ✅ / ❌

---

## 🧪 Test 2: Local Docker Build

### Prerequisites
- Docker installed
- 10GB free disk space
- Internet connection (for downloading dependencies)

### Build Images
```bash
# Build both API and UI images
./build-docker-images.sh

# This should take 10-20 minutes on first build
```

### Verify Images
```bash
# Check images were created
docker images | grep dograh-independent

# Expected output:
# dograh-independent/api    latest   [image-id]   X minutes ago   ~800MB
# dograh-independent/ui     latest   [image-id]   X minutes ago   ~400MB
```

**Result:** ✅ / ❌

---

## 🧪 Test 3: Environment Configuration

### Create .env file
```bash
cp .env.example .env
```

### Edit .env with your keys
```bash
# Required - Database
DATABASE_URL=postgresql+asyncpg://postgres:password@postgres:5432/dograh

# Required - Redis
REDIS_URL=redis://:password@redis:6379

# Required - AI Services (use your own keys)
OPENAI_API_KEY=sk-proj-...
ELEVENLABS_API_KEY=sk_...
DEEPGRAM_API_KEY=...

# Optional - Object Storage
MINIO_ENABLED=true
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
AWS_S3_BUCKET=dograh
AWS_REGION=us-east-1

# Important - Telemetry DISABLED
ENABLE_TELEMETRY=false

# Important - No MPS connection
# MPS_API_URL should NOT be set or set to empty
```

**Result:** ✅ / ❌

---

## 🧪 Test 4: Start Services

### Start infrastructure services first
```bash
# Start postgres, redis, minio
docker compose up -d postgres redis minio

# Wait 10 seconds for services to initialize
sleep 10

# Check services are running
docker compose ps
```

### Start application services
```bash
# Start API and UI
docker compose up -d api ui

# Check logs for errors
docker compose logs api | tail -50
docker compose logs ui | tail -50
```

### Verify no Dograh service connections
```bash
# Check API logs - should NOT see services.dograh.com
docker compose logs api | grep -i "services.dograh.com" || echo "✅ No MPS connections"

# Check for telemetry attempts - should NOT see sentry
docker compose logs api | grep -i "sentry" || echo "✅ No Sentry telemetry"

# Check UI logs - should NOT see chat.dograh.com
docker compose logs ui | grep -i "chat.dograh.com" || echo "✅ No Chatwoot widget"
```

**Result:** ✅ / ❌

---

## 🧪 Test 5: API Health Check

### Check API is responding
```bash
# Health endpoint
curl http://localhost:8000/api/v1/health

# Expected output:
# {"status":"healthy"}

# API docs
curl -I http://localhost:8000/docs

# Expected: 200 OK
```

### Check database connection
```bash
# API should have run migrations
docker compose logs api | grep -i "migration"

# Expected to see migration logs
```

**Result:** ✅ / ❌

---

## 🧪 Test 6: UI Accessibility

### Check UI is serving
```bash
# Home page
curl -I http://localhost:3010/

# Expected: 200 OK

# Check Chatwoot widget is NOT loaded
curl http://localhost:3010/ | grep -i "chatwoot" || echo "✅ No Chatwoot"
```

### Open in browser
```
http://localhost:3010
```

**Check for:**
- ✅ Page loads successfully
- ✅ No Chatwoot widget in bottom-right
- ✅ No console errors about services.dograh.com
- ✅ Login page appears

**Result:** ✅ / ❌

---

## 🧪 Test 7: User Registration

### Create first user
```bash
# Use the UI at http://localhost:3010/signup
# Or use API:

curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!",
    "full_name": "Test User",
    "organization_name": "Test Org"
  }'
```

### Verify no MPS auto-key attempt
```bash
# Check logs - should see skip message
docker compose logs api | grep -i "MPS_API_URL not configured"

# Expected output:
# "MPS_API_URL not configured. Skipping auto-key generation..."
```

**Result:** ✅ / ❌

---

## 🧪 Test 8: Network Isolation Test

### Monitor outbound connections during startup
```bash
# On Linux, you can use tcpdump (requires root)
sudo tcpdump -i any -n host services.dograh.com or host chat.dograh.com or host sentry.io

# Then start services
docker compose restart

# Should see NO traffic to:
# - services.dograh.com (MPS)
# - chat.dograh.com (Chatwoot)
# - *.sentry.io (Telemetry)
```

**Alternative: Check DNS queries**
```bash
# Check /etc/hosts or DNS logs
# Should not resolve Dograh domains
```

**Result:** ✅ / ❌

---

## 🧪 Test 9: Workflow Creation Test

### Prerequisites
- Logged in user
- AI API keys configured

### Create a simple workflow
1. Navigate to Workflows
2. Create new workflow
3. Add nodes (Message, LLM, etc.)
4. Save workflow

### Verify no external calls
```bash
# Watch logs during workflow creation
docker compose logs -f api

# Should NOT see:
# - Calls to services.dograh.com
# - Telemetry events
```

**Result:** ✅ / ❌

---

## 🧪 Test 10: Voice Call Test (Advanced)

### Prerequisites
- Twilio account (or test without actual call)
- Phone number configured
- AI keys configured

### Test workflow execution
This tests the Pipecat integration without Dograh services.

```bash
# Check Pipecat is working
docker compose logs api | grep -i "pipecat"

# Should see Pipecat initialization without errors
```

**Full call test (optional):**
1. Configure Twilio webhook to your API
2. Make a test call
3. Verify call connects and AI responds

**Result:** ✅ / ❌

---

## 🧪 Test 11: Docker Image Distribution

### Save images
```bash
./save-docker-images.sh

# Check tar files created
ls -lh docker-images/

# Expected files:
# dograh-independent-api-latest.tar.gz (~300MB)
# dograh-independent-ui-latest.tar.gz (~150MB)
```

### Load images (on another machine or after cleanup)
```bash
# Clean existing images
docker rmi dograh-independent/api:latest
docker rmi dograh-independent/ui:latest

# Load from tar files
./load-docker-images.sh

# Verify images loaded
docker images | grep dograh-independent
```

**Result:** ✅ / ❌

---

## 🧪 Test 12: Railway Deployment (Optional)

### Prerequisites
- Railway account
- Railway CLI installed

### Deploy to Railway
```bash
# Login
railway login

# Create project
railway init

# Add services using Railway dashboard
# Follow RAILWAY_DEPLOYMENT.md

# Deploy
railway up
```

### Verify deployment
```bash
# Check service URLs
railway status

# Test API
curl https://your-api.railway.app/api/v1/health

# Test UI
curl https://your-ui.railway.app/
```

**Result:** ✅ / ❌

---

## 📊 Test Results Summary

| Test | Status | Notes |
|------|--------|-------|
| 1. Configuration Verification | ⬜ | |
| 2. Local Docker Build | ⬜ | |
| 3. Environment Configuration | ⬜ | |
| 4. Start Services | ⬜ | |
| 5. API Health Check | ⬜ | |
| 6. UI Accessibility | ⬜ | |
| 7. User Registration | ⬜ | |
| 8. Network Isolation | ⬜ | |
| 9. Workflow Creation | ⬜ | |
| 10. Voice Call Test | ⬜ | |
| 11. Docker Distribution | ⬜ | |
| 12. Railway Deployment | ⬜ | |

---

## 🐛 Common Issues

### Issue: "pipecat module not found"
```bash
# Submodule not initialized
git submodule update --init --recursive
```

### Issue: "Database connection failed"
```bash
# PostgreSQL not ready
docker compose logs postgres
docker compose restart api
```

### Issue: "Port already in use"
```bash
# Check what's using the port
sudo lsof -i :8000
sudo lsof -i :3010

# Stop conflicting service or change ports in .env
```

### Issue: "API keys not working"
```bash
# Verify keys are set in .env
cat .env | grep API_KEY

# Restart services to pick up changes
docker compose restart api
```

### Issue: "Docker build fails"
```bash
# Clean up and retry
docker system prune -a
./build-docker-images.sh
```

---

## ✅ Success Criteria

Your deployment is **fully independent** if:

1. ✅ No connections to `services.dograh.com`
2. ✅ No connections to `chat.dograh.com`
3. ✅ No connections to `*.sentry.io`
4. ✅ No connections to `*.posthog.com`
5. ✅ User registration works without MPS
6. ✅ Workflows can be created and executed
7. ✅ Voice calls work with your own AI keys
8. ✅ Docker images can be built and distributed
9. ✅ Can deploy to any cloud platform

---

## 🔍 Quick Verification Script

Run this script to check key configurations:

```bash
#!/bin/bash

echo "🔍 Dograh Independence Verification"
echo "===================================="
echo ""

echo "1. Checking telemetry setting..."
if grep -q "ENABLE_TELEMETRY.*false" docker-compose.yaml; then
    echo "   ✅ Telemetry disabled by default"
else
    echo "   ❌ Telemetry may be enabled"
fi

echo "2. Checking MPS configuration..."
if grep -q 'MPS_API_URL = os.getenv("MPS_API_URL", "")' api/constants.py; then
    echo "   ✅ MPS is optional (empty default)"
else
    echo "   ❌ MPS may be hardcoded"
fi

echo "3. Checking Chatwoot widget..."
if grep -q "# ENV NEXT_PUBLIC_CHATWOOT_URL" ui/Dockerfile; then
    echo "   ✅ Chatwoot is disabled"
else
    echo "   ❌ Chatwoot may be enabled"
fi

echo "4. Checking Sentry DSN..."
if ! grep -q "SENTRY_DSN.*https://" docker-compose.yaml; then
    echo "   ✅ No hardcoded Sentry DSN"
else
    echo "   ❌ Hardcoded Sentry DSN found"
fi

echo "5. Checking pipecat submodule..."
if [ -d "pipecat/src/pipecat" ] && [ "$(ls -A pipecat/src/pipecat)" ]; then
    echo "   ✅ Pipecat submodule initialized"
else
    echo "   ❌ Pipecat submodule not initialized"
fi

echo ""
echo "===================================="
echo "Verification complete!"
```

Save this as `verify-independence.sh` and run:
```bash
chmod +x verify-independence.sh
./verify-independence.sh
```

---

## 📚 Additional Resources

- **Architecture**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Third-party connections**: See [THIRD_PARTY_CONNECTIONS.md](THIRD_PARTY_CONNECTIONS.md)
- **Docker images**: See [DOCKER_IMAGES.md](DOCKER_IMAGES.md)
- **Railway deployment**: See [RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md)
- **Pipecat details**: See [PIPECAT_EXPLAINED.md](PIPECAT_EXPLAINED.md)

---

## 🆘 Getting Help

If tests fail:
1. Check logs: `docker compose logs`
2. Review configuration in `.env`
3. Verify AI API keys are valid
4. Check network connectivity
5. Ensure ports are not in use

For issues specific to independence:
- Verify you're on the correct branch
- Check no hardcoded Dograh URLs remain
- Confirm telemetry is disabled
- Verify MPS_API_URL is empty or not set
