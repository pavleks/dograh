# Third-Party Connections Analysis

This document provides a comprehensive analysis of all third-party connections in the Dograh AI platform.

## Executive Summary

Dograh can operate in two modes:
1. **Default Mode**: Includes telemetry and Dograh's managed services for convenience
2. **Fully Independent Mode**: Zero connections to Dograh services, using only standard providers

## Outbound Connections

### AI/ML Service Providers

#### Language Model (LLM) Providers
- **OpenAI** - `api.openai.com` - GPT models
- **Groq** - `api.groq.com` - Fast inference
- **Google AI** - `generativelanguage.googleapis.com` - Gemini models
- **Azure OpenAI** - User-provided endpoint
- **Dograh MPS** - `services.dograh.com` - Optional managed service

#### Text-to-Speech (TTS) Providers
- **Deepgram** - `api.deepgram.com`
- **OpenAI TTS** - `api.openai.com`
- **ElevenLabs** - `api.elevenlabs.io`
- **Dograh MPS TTS** - `services.dograh.com` - Optional

#### Speech-to-Text (STT) Providers
- **Deepgram STT** - `api.deepgram.com`
- **OpenAI Whisper** - `api.openai.com`
- **Cartesia STT** - `api.cartesia.ai`
- **Dograh MPS STT** - `services.dograh.com` - Optional

### Telephony Providers
- **Twilio** - `api.twilio.com` - Voice calls, SMS
- **Vonage (Nexmo)** - `api.nexmo.com` - Voice calls

### Integration & OAuth Services
- **Nango** - `api.nango.dev` - OAuth integration platform (Slack, Google Sheets)
- **Google Sheets API** - `sheets.googleapis.com` - Campaign data source

### Observability & Analytics

#### Enabled by Default (⚠️ Sends Data to Dograh)
- **Sentry** - `sentry.io` - Error tracking
  - Hardcoded DSN in docker-compose.yaml
  - Enabled when ENABLE_TELEMETRY=true (default)
  - Sends: Stack traces, errors, request data

#### Optional (Disabled by Default)
- **Langfuse** - User-configurable - LLM tracing
- **SigNoz** - `ingest.us.signoz.cloud` - OpenTelemetry metrics
- **PostHog** - `posthog.com` - Product analytics

### Storage Services
- **AWS S3** - `s3.amazonaws.com` - Cloud storage (optional)
- **MinIO** - Local storage (default)

### Support & Communication
- **Chatwoot** - `chat.dograh.com` - Customer support widget
  - ⚠️ Hardcoded in ui/Dockerfile
  - Loads external JavaScript in every user's browser

### Authentication
- **Stack Auth** - `api.stack-auth.com` - SaaS mode only
- **Local Auth** - OSS mode (default)

### WebRTC Media
- **LiveKit** - User-configurable - Real-time audio/video (optional)

## Inbound Connections (Webhooks)

### Telephony Webhooks
- **Twilio**: `/api/v1/telephony/twilio/status-callback/{workflow_run_id}`
- **Vonage**: `/api/v1/telephony/vonage/status-callback/{workflow_run_id}`

### Integration Webhooks
- **Nango**: `/api/v1/integration/webhook` - OAuth integration events

### WebSocket Endpoints
- `/api/v1/rtc-offer` - WebRTC signaling
- `/api/v1/telephony/stasis-rtp-ws` - Asterisk RTP
- `/api/v1/looptalk/ws` - AI testing personas

## Dograh Service Dependencies

### 1. Sentry Error Tracking (⚠️ ENABLED BY DEFAULT)

**Location:** `docker-compose.yaml:95,136`

```yaml
SENTRY_DSN: "https://3acdb63d5f1f70430953353b82de61e0@o4509486225096704.ingest.us.sentry.io/4510152922693632"
ENABLE_TELEMETRY: "${ENABLE_TELEMETRY:-true}"
```

**Data Sent:**
- All application errors and exceptions
- Stack traces with source code context
- User request data
- Environment variables
- Performance metrics

**To Disable:**
```bash
ENABLE_TELEMETRY=false
```

### 2. Chatwoot Widget (⚠️ HARDCODED IN DOCKERFILE)

**Location:** `ui/Dockerfile:37-38`

```dockerfile
ENV NEXT_PUBLIC_CHATWOOT_URL="https://chat.dograh.com"
ENV NEXT_PUBLIC_CHATWOOT_TOKEN="3fkFx2mCEjNHjM9gaNc4A82X"
```

**Impact:**
- Every browser loads JavaScript from chat.dograh.com
- Widget visible on all pages
- Baked into Docker image at build time

**To Disable:**
- Remove from Dockerfile and rebuild
- Or comment out `<ChatwootWidget />` in `ui/src/app/layout.tsx:48`

### 3. Dograh MPS Auto-Key Generation (⚠️ AUTO-CONNECTS ON SIGNUP)

**Location:** `api/services/auth/depends.py:218-224,91-97`

**What Happens:**
- On new user signup, calls `services.dograh.com`
- Creates auto-generated API key for AI services
- Sets Dograh MPS as default provider

**Data Sent:**
- User provider ID
- Organization ID
- Timestamp

**To Disable:**
- Set `MPS_API_URL=""` or configure your own AI provider keys

## Running Fully Independent

### Configuration for Zero Dograh Connections

```bash
# docker-compose.yaml or .env
ENABLE_TELEMETRY=false
MPS_API_URL=""

# Required: Set your own AI provider keys
OPENAI_API_KEY=sk-proj-your-key
ELEVENLABS_API_KEY=sk_your-key
DEEPGRAM_API_KEY=your-key

# Optional providers
GROQ_API_KEY=gsk_your-key
GOOGLE_API_KEY=AIzaSy-your-key
```

### Rebuild UI Without Chatwoot

**Option 1 - Modify Dockerfile:**
```dockerfile
# ui/Dockerfile - Remove lines 37-38
# ENV NEXT_PUBLIC_CHATWOOT_URL="https://chat.dograh.com"
# ENV NEXT_PUBLIC_CHATWOOT_TOKEN="3fkFx2mCEjNHjM9gaNc4A82X"
```

**Option 2 - Remove from Layout:**
```typescript
// ui/src/app/layout.tsx:48
// <ChatwootWidget />
```

Then rebuild:
```bash
docker build -t dograh-ui:independent ./ui
```

## Default AI Providers (Without MPS)

**File:** `api/services/configuration/defaults.py:21-25`

```python
_DEFAULTS = {
    "llm": (ServiceProviders.OPENAI, OpenAILLMService),
    "tts": (ServiceProviders.ELEVENLABS, ElevenlabsTTSConfiguration),
    "stt": (ServiceProviders.DEEPGRAM, DeepgramSTTConfiguration),
}
```

When you set standard API keys, these providers are used instead of Dograh MPS.

## Privacy Considerations

### Data Flows to External Services

1. **Voice Audio** → TTS/STT providers (Deepgram, OpenAI, etc.)
2. **Conversation Transcripts** → LLM providers (OpenAI, Groq, Google)
3. **Call Metadata** → Telephony providers (Twilio, Vonage)
4. **Errors** → Sentry (if ENABLE_TELEMETRY=true)
5. **Analytics** → PostHog (if NEXT_PUBLIC_ENABLE_POSTHOG=true)

### Minimal Data Exposure Setup

For maximum privacy:
- Set `ENABLE_TELEMETRY=false`
- Use self-hosted LLM/TTS/STT (or trusted providers with DPAs)
- Disable PostHog
- Remove Chatwoot widget
- Use local MinIO instead of AWS S3
- Self-host LiveKit for WebRTC

## Comparison: Default vs Independent

| Feature | Default Setup | Fully Independent |
|---------|---------------|-------------------|
| Error reporting | Sends to Dograh Sentry | Disabled |
| Support widget | Loads from chat.dograh.com | Removed |
| AI service keys | Auto-generated from services.dograh.com | Your own providers |
| Analytics | Optional (disabled) | Disabled |
| Storage | Local MinIO | Local MinIO |
| Database | Local PostgreSQL | Local PostgreSQL |
| External dependencies | 3 Dograh services | 0 Dograh services |

## Conclusion

**Default Mode Benefits:**
- Instant setup with auto-generated keys
- Support widget for user help
- Error monitoring for debugging

**Independent Mode Benefits:**
- Zero data sent to Dograh
- Full control over all services
- No external dependencies on Dograh infrastructure
- Complete privacy and sovereignty

The codebase is designed to support both modes. This document helps users make informed decisions about which mode to use.
