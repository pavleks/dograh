# Railway Deployment Guide - Fully Independent Dograh

This guide explains how to deploy the fully independent Dograh AI platform on Railway.app with **zero dependencies** on Dograh's services.

## Prerequisites

1. **Railway Account**: Sign up at https://railway.app
2. **AI Provider API Keys**: You'll need keys from:
   - OpenAI (LLM): https://platform.openai.com/api-keys
   - ElevenLabs (TTS): https://elevenlabs.io/app/settings/api-keys
   - Deepgram (STT): https://console.deepgram.com/
3. **Optional**: Twilio or Vonage account for phone calling

## Deployment Architecture

Railway deployment consists of **4 services**:
1. **PostgreSQL** - Managed database (Railway provides this)
2. **Redis** - Managed cache (Railway provides this)
3. **API** - FastAPI backend
4. **UI** - Next.js frontend

Note: MinIO is not needed on Railway - we'll use local storage or Railway volumes.

## Step-by-Step Deployment

### 1. Create New Project on Railway

1. Go to https://railway.app/new
2. Click "Deploy from GitHub repo"
3. Select your fork: `pavleks/dograh`
4. Select branch: `claude/fully-independent-011CV2BJhcLN4sVZzRDUFRcb`

### 2. Add PostgreSQL Database

1. In your Railway project, click "+ New"
2. Select "Database" → "PostgreSQL"
3. Railway will automatically create a database with a connection string
4. Copy the `DATABASE_URL` from the PostgreSQL service variables

### 3. Add Redis Database

1. Click "+ New" again
2. Select "Database" → "Redis"
3. Railway will provide a `REDIS_URL`
4. Copy the connection string

### 4. Deploy API Service

1. Click "+ New" → "GitHub Repo"
2. Select your forked repo and branch
3. Railway will auto-detect the Dockerfile
4. Go to **Settings** → **Root Directory** → Set to `/` (root)
5. Go to **Settings** → **Dockerfile Path** → Set to `api/Dockerfile`
6. Click **Variables** and add:

```bash
# Core Configuration
ENVIRONMENT=production
LOG_LEVEL=INFO
DEPLOYMENT_MODE=oss

# Database (use Railway's PostgreSQL connection string)
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Redis (use Railway's Redis connection string)
REDIS_URL=${{Redis.REDIS_URL}}

# Storage - Disable AWS S3, use local storage
ENABLE_AWS_S3=false

# Privacy Settings - NO TELEMETRY
ENABLE_TELEMETRY=false
ENABLE_TRACING=false

# AI Provider Keys - REQUIRED (replace with your keys)
OPENAI_API_KEY=sk-proj-your-openai-key-here
ELEVENLABS_API_KEY=sk_your-elevenlabs-key-here
DEEPGRAM_API_KEY=your-deepgram-key-here

# Optional: Additional AI Providers
# GROQ_API_KEY=gsk_your-groq-key
# GOOGLE_API_KEY=AIzaSy-your-google-key
# CARTESIA_API_KEY=your-cartesia-key

# Optional: Telephony (if you want phone calling)
# Configured via UI after deployment
```

7. Click **Deploy**

### 5. Deploy UI Service

1. Click "+ New" → "GitHub Repo" again
2. Select same repo and branch
3. Go to **Settings** → **Root Directory** → Set to `/` (root)
4. Go to **Settings** → **Dockerfile Path** → Set to `ui/Dockerfile`
5. Click **Variables** and add:

```bash
# Backend URL (use Railway's API service URL)
BACKEND_URL=https://${{API.RAILWAY_PUBLIC_DOMAIN}}
NEXT_PUBLIC_BACKEND_URL=https://${{API.RAILWAY_PUBLIC_DOMAIN}}

# Node Environment
NODE_ENV=production
NEXT_PUBLIC_NODE_ENV=oss
NEXT_PUBLIC_AUTH_PROVIDER=local
NEXT_PUBLIC_DEPLOYMENT_MODE=oss

# Privacy Settings - NO TELEMETRY
ENABLE_TELEMETRY=false
NEXT_PUBLIC_ENABLE_POSTHOG=false

# Next.js telemetry
NEXT_TELEMETRY_DISABLED=1
```

6. Click **Deploy**

### 6. Configure Public URLs

1. Go to API service → **Settings** → **Networking**
2. Click "Generate Domain" to get a public URL
3. Go to UI service → **Settings** → **Networking**
4. Click "Generate Domain" to get a public URL
5. Copy the UI domain - this is your application URL!

### 7. Update API Backend URL (if needed)

After both services are deployed:
1. Copy the API service's public domain
2. Go to UI service → **Variables**
3. Update `BACKEND_URL` and `NEXT_PUBLIC_BACKEND_URL` to the actual API domain
4. Redeploy the UI service

## Environment Variables Reference

### API Service - Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection | `${{Postgres.DATABASE_URL}}` |
| `REDIS_URL` | Redis connection | `${{Redis.REDIS_URL}}` |
| `OPENAI_API_KEY` | OpenAI API key | `sk-proj-xxx` |
| `ELEVENLABS_API_KEY` | ElevenLabs API key | `sk_xxx` |
| `DEEPGRAM_API_KEY` | Deepgram API key | `xxx` |

### API Service - Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENABLE_TELEMETRY` | Enable Sentry/analytics | `false` |
| `ENABLE_TRACING` | Enable Langfuse tracing | `false` |
| `ENABLE_AWS_S3` | Use AWS S3 for storage | `false` |
| `GROQ_API_KEY` | Groq AI API key | - |
| `GOOGLE_API_KEY` | Google AI API key | - |
| `CARTESIA_API_KEY` | Cartesia STT key | - |

### UI Service - Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `BACKEND_URL` | API service URL (internal) | `https://api-xxx.railway.app` |
| `NEXT_PUBLIC_BACKEND_URL` | API service URL (public) | `https://api-xxx.railway.app` |

## Storage Configuration

Railway doesn't need MinIO. Choose one of:

### Option 1: Local Storage (Default)
- Set `ENABLE_AWS_S3=false` in API service
- Files stored in Railway volumes (persistent)
- Suitable for low-traffic deployments

### Option 2: AWS S3
- Set `ENABLE_AWS_S3=true` in API service
- Add these variables:
  ```bash
  AWS_ACCESS_KEY_ID=your-aws-key
  AWS_SECRET_ACCESS_KEY=your-aws-secret
  S3_BUCKET=your-bucket-name
  S3_REGION=us-east-1
  ```

## Telephony Configuration (Optional)

To enable phone calling, configure via the UI after deployment:

1. Go to your deployed UI URL
2. Navigate to **Configure Telephony**
3. Choose **Twilio** or **Vonage**
4. Enter your credentials

No need to set these in Railway environment variables - they're stored in the database.

## Health Checks

Railway will automatically monitor your services. Health check endpoints:

- API: `https://your-api-domain.railway.app/api/v1/health`
- UI: `https://your-ui-domain.railway.app/`

## Troubleshooting

### API Service Won't Start

**Issue**: API service crashes on startup

**Solutions**:
1. Check logs: Railway dashboard → API service → Logs
2. Verify `DATABASE_URL` and `REDIS_URL` are correctly set
3. Ensure AI provider keys are valid
4. Check that `DATABASE_URL` starts with `postgresql+asyncpg://`

### UI Can't Connect to API

**Issue**: UI shows "Network Error" or can't load data

**Solutions**:
1. Verify API service is running (check Railway dashboard)
2. Check `NEXT_PUBLIC_BACKEND_URL` matches API public domain
3. Ensure API domain is accessible (test in browser)
4. Redeploy UI after updating backend URL

### Database Connection Errors

**Issue**: `connection to server failed`

**Solutions**:
1. Use Railway's provided `DATABASE_URL` variable reference: `${{Postgres.DATABASE_URL}}`
2. Don't copy/paste the URL - use the variable reference
3. Make sure PostgreSQL service is running

### Missing API Keys

**Issue**: "Missing API key for provider X"

**Solutions**:
1. Go to Railway → API service → Variables
2. Add all required keys: `OPENAI_API_KEY`, `ELEVENLABS_API_KEY`, `DEEPGRAM_API_KEY`
3. Redeploy API service after adding keys

## Cost Estimation

Railway costs (approximate):
- **Hobby Plan**: $5/month + usage
- **PostgreSQL**: ~$0.000463/GB-hour (~$5/month for 15GB)
- **Redis**: ~$0.000231/GB-hour (~$2.50/month for 15GB)
- **API Service**: Depends on CPU/RAM usage
- **UI Service**: Depends on traffic

Plus external costs:
- OpenAI API: Pay-per-use
- ElevenLabs: $5-$99/month depending on plan
- Deepgram: Pay-per-use
- Twilio: Pay-per-call (if using telephony)

## Monitoring

Railway provides:
- Real-time logs for all services
- Resource usage metrics (CPU, RAM, Network)
- Deployment history
- Custom health checks

No external monitoring (Sentry, PostHog) is enabled by default in this fully independent deployment.

## Updating Your Deployment

To deploy new changes:

1. Push to your GitHub branch
2. Railway will automatically detect and redeploy
3. Or manually trigger: Railway dashboard → Service → Deploy

## Security Best Practices

1. ✅ **API Keys**: Store in Railway environment variables (never commit to git)
2. ✅ **Database**: Use Railway's managed Postgres (automatic backups)
3. ✅ **HTTPS**: Railway provides SSL certificates automatically
4. ✅ **Environment**: Set `NODE_ENV=production`
5. ✅ **Telemetry**: Keep `ENABLE_TELEMETRY=false` for privacy

## Next Steps After Deployment

1. **Create Your First Workflow**:
   - Open your UI URL
   - Click "Create Workflow"
   - Follow the onboarding

2. **Configure AI Services**:
   - Go to Settings → Service Configurations
   - Verify your provider keys are working
   - Test with a sample call

3. **Set Up Telephony** (Optional):
   - Configure Telephony → Add Provider
   - Enter Twilio or Vonage credentials
   - Get a phone number for inbound/outbound calls

## Support

- Documentation: [THIRD_PARTY_CONNECTIONS.md](./THIRD_PARTY_CONNECTIONS.md)
- Railway Docs: https://docs.railway.app
- GitHub Issues: https://github.com/pavleks/dograh/issues

## Privacy Note

This deployment is **fully independent** with:
- ❌ No Sentry error tracking
- ❌ No PostHog analytics
- ❌ No Chatwoot widget
- ❌ No Dograh MPS services
- ✅ Complete data sovereignty
- ✅ All data stays in your Railway project

Perfect for privacy-conscious deployments and organizations requiring complete control.
