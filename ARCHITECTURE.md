# Dograh Architecture Overview

## Is Dograh using Pipecat as backend?

**Short Answer:** Dograh uses **Pipecat as the real-time voice processing engine**, not as the entire backend. Think of it as Dograh's "voice brain" - Pipecat handles the real-time audio streaming and AI orchestration, while Dograh provides the workflow builder, UI, database, and business logic.

## Architecture Breakdown

### 🏗️ The Stack

```
┌─────────────────────────────────────────────────┐
│              DOGRAH PLATFORM                     │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────┐         ┌─────────────────┐  │
│  │   UI Layer   │         │   API Layer     │  │
│  │   (Next.js)  │◄───────►│   (FastAPI)     │  │
│  │              │         │                 │  │
│  │ - Workflow   │         │ - REST APIs     │  │
│  │   Builder    │         │ - WebSockets    │  │
│  │ - Dashboard  │         │ - Auth          │  │
│  │ - Settings   │         │ - DB Logic      │  │
│  └──────────────┘         └────────┬────────┘  │
│                                     │           │
│                            ┌────────▼────────┐  │
│                            │  Pipecat Engine │  │
│                            │  (Real-time AI) │  │
│                            │                 │  │
│                            │ - Audio Pipeline│  │
│                            │ - STT/TTS/LLM  │  │
│                            │ - Streaming     │  │
│                            └─────────────────┘  │
│                                                  │
├─────────────────────────────────────────────────┤
│         Infrastructure Layer                     │
│                                                  │
│  PostgreSQL  │  Redis  │  MinIO/S3             │
└─────────────────────────────────────────────────┘
```

## What is Pipecat?

**Pipecat** is an **open-source Python framework** for building real-time voice and multimodal AI agents. It's developed by Pipecat AI (separate from Dograh).

- **Repository:** https://github.com/pipecat-ai/pipecat
- **Purpose:** Real-time voice AI orchestration
- **License:** Open source (BSD 2-Clause)
- **Used by:** Multiple voice AI platforms, not just Dograh

### Pipecat's Role in Dograh

Pipecat acts as the **real-time voice processing engine** that:

1. **Manages Audio Streams**
   - Receives audio from WebRTC, phone calls, or WebSockets
   - Buffers and synchronizes audio frames
   - Handles bidirectional audio flow

2. **Orchestrates AI Services**
   - Sends audio to STT (Speech-to-Text) services
   - Forwards text to LLM (Language Model) services
   - Converts responses to audio via TTS (Text-to-Speech)
   - Streams audio back to the user in real-time

3. **Provides Pipeline Architecture**
   - Modular "processor" components
   - Frame-based processing (audio frames, text frames, etc.)
   - Event-driven architecture
   - Low-latency streaming

## What Dograh Adds on Top of Pipecat

Dograh is **much more than just Pipecat**. It's a complete platform that uses Pipecat as one component:

### 1. **Visual Workflow Builder** (UI)
- Drag-and-drop interface for creating conversation flows
- Node-based workflow editor
- Conditional logic and branching
- Variable extraction and templating

### 2. **Business Logic Layer** (API)
- **Workflow Management** (`api/services/workflow/`)
  - Graph-based workflow execution
  - State management
  - Node transitions
  - Variable handling

- **Telephony Integration** (`api/services/telephony/`)
  - Twilio integration
  - Vonage integration
  - Phone number management
  - Call routing

- **Campaign Management** (`api/services/campaign/`)
  - Bulk calling campaigns
  - Google Sheets integration
  - Call scheduling
  - Retry logic

- **Analytics & Reporting** (`api/services/reports/`)
  - Call transcripts
  - Usage metrics
  - Cost tracking
  - Performance analytics

### 3. **Database Layer**
- PostgreSQL for persistent data
- User management
- Organization/team management
- Workflow storage
- Call history
- Configuration management

### 4. **Authentication & Authorization**
- Multi-tenant architecture
- User/organization isolation
- API key management
- Role-based access control

### 5. **AI Service Abstraction**
- Support for multiple LLM providers (OpenAI, Groq, Google, Azure)
- Support for multiple TTS providers (Deepgram, ElevenLabs, OpenAI)
- Support for multiple STT providers (Deepgram, Cartesia, OpenAI)
- Provider switching without code changes

### 6. **Testing Tools**
- LoopTalk: AI personas for testing voice agents
- Automated conversation testing
- Quality assurance workflows

## How They Work Together

### During a Voice Call:

```
1. User calls phone number
         ↓
2. Twilio/Vonage forwards to Dograh API
         ↓
3. Dograh API creates workflow instance
         ↓
4. Dograh initializes Pipecat pipeline with:
   - Selected STT service
   - Selected LLM service
   - Selected TTS service
   - Workflow graph/logic
         ↓
5. Pipecat handles real-time audio streaming:
   - Receives audio chunks
   - Converts to text (STT)
   - Sends to LLM
   - Converts response to audio (TTS)
   - Streams back to user
         ↓
6. Dograh PipecatEngine orchestrates:
   - Node transitions in workflow
   - Variable extraction
   - Business logic execution
   - Database updates
         ↓
7. Call completes, Dograh stores:
   - Transcript
   - Recording
   - Call metadata
   - Usage metrics
```

## Key Files & Their Roles

### Pipecat Integration Layer

| File | Purpose |
|------|---------|
| `api/services/pipecat/pipeline_builder.py` | Builds Pipecat pipelines |
| `api/services/pipecat/service_factory.py` | Creates AI service instances |
| `api/services/pipecat/transport_setup.py` | Configures audio transports |
| `api/services/workflow/pipecat_engine.py` | Dograh's workflow logic on top of Pipecat |

### Dograh-Specific Logic

| Directory | Purpose |
|-----------|---------|
| `api/services/workflow/` | Workflow graph execution |
| `api/services/telephony/` | Phone call handling |
| `api/services/campaign/` | Bulk calling campaigns |
| `api/routes/` | REST API endpoints |
| `ui/src/` | Visual workflow builder |

## Pipecat Submodule

Dograh uses a **forked version** of Pipecat:

```bash
# In .gitmodules
[submodule "pipecat"]
    path = pipecat
    url = https://github.com/dograh-hq/pipecat.git
```

### Why a Fork?

The fork includes **Dograh-specific services**:
- `pipecat/src/pipecat/services/dograh/llm.py`
- `pipecat/src/pipecat/services/dograh/tts.py`
- `pipecat/src/pipecat/services/dograh/stt.py`

These connect to Dograh's managed AI services (services.dograh.com) when using the default setup. **In the fully independent branch, these are optional.**

## Comparison: Pipecat vs Dograh

| Feature | Pipecat | Dograh |
|---------|---------|--------|
| **Purpose** | Voice AI framework | Complete voice agent platform |
| **Scope** | Real-time audio processing | End-to-end workflow management |
| **User Interface** | Code-based | Visual workflow builder |
| **Telephony** | Transport abstraction | Full Twilio/Vonage integration |
| **Database** | None | PostgreSQL with full schema |
| **Authentication** | None | Multi-tenant auth system |
| **Campaigns** | None | Bulk calling, scheduling |
| **Analytics** | None | Transcripts, reports, metrics |
| **Deployment** | Python package | Full-stack application |
| **Use Case** | Build custom voice agents | Ready-to-use voice platform |

## Analogy

Think of it like this:

- **Pipecat** = React (a framework/library)
- **Dograh** = Next.js Admin Dashboard (complete application using React)

Or:

- **Pipecat** = Express.js (web framework)
- **Dograh** = Full CMS like WordPress (complete application using Express)

## Can You Use Pipecat Without Dograh?

**Yes!** Pipecat is a standalone framework. You can build your own voice agents using just Pipecat.

**Example:**
```python
from pipecat.pipeline.pipeline import Pipeline
from pipecat.services.openai.llm import OpenAILLMService
from pipecat.services.deepgram.tts import DeepgramTTSService

# Build your own pipeline
pipeline = Pipeline([
    stt_service,
    llm_service,
    tts_service,
    transport
])
```

## Can You Use Dograh Without Pipecat?

**No.** Pipecat is core to Dograh's real-time voice processing. Removing it would require replacing the entire voice engine.

However, Dograh **abstracts** Pipecat's complexity, so you don't need to understand Pipecat to use Dograh.

## Dependencies in docker-compose

When you run Dograh:

```yaml
services:
  api:
    # Includes Pipecat installed as Python package
    # RUN pip install ./pipecat[cartesia,deepgram,openai,...]

  # Pipecat is NOT a separate service
  # It runs inside the API service
```

Pipecat is installed as a **Python dependency** inside the API container, not as a separate microservice.

## Summary

**Dograh Architecture:**
- **UI Layer:** Next.js workflow builder
- **API Layer:** FastAPI with business logic
- **Voice Engine:** **Pipecat** (real-time audio/AI orchestration)
- **Data Layer:** PostgreSQL, Redis, MinIO/S3
- **Telephony:** Twilio/Vonage integration
- **AI Services:** OpenAI, Deepgram, ElevenLabs, etc.

**Pipecat's Role:**
- Real-time audio streaming
- STT/TTS/LLM orchestration
- Low-latency pipeline processing
- Frame-based architecture

**Dograh's Value-Add:**
- Visual workflow builder
- Multi-tenant platform
- Campaign management
- Telephony integration
- Analytics and reporting
- Testing tools (LoopTalk)
- User management
- Production-ready deployment

## Further Reading

- **Pipecat Documentation:** https://docs.pipecat.ai
- **Pipecat GitHub:** https://github.com/pipecat-ai/pipecat
- **Dograh Documentation:** See other .md files in this repository

## License Note

Both Dograh and Pipecat use the **BSD 2-Clause License**, which is why Dograh can use and modify Pipecat freely.
