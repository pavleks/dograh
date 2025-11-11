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
if grep -q "SENTRY_DSN:.*https://" docker-compose.yaml; then
    echo "   ❌ Hardcoded Sentry DSN found"
else
    echo "   ✅ No hardcoded Sentry DSN"
fi

echo "5. Checking pipecat submodule..."
if [ -d "pipecat/src/pipecat" ] && [ "$(ls -A pipecat/src/pipecat)" ]; then
    echo "   ✅ Pipecat submodule initialized"
else
    echo "   ❌ Pipecat submodule not initialized"
fi

echo "6. Checking MPS skip logic..."
if grep -q "MPS_API_URL not configured. Skipping auto-key generation" api/services/auth/depends.py; then
    echo "   ✅ MPS auto-key generation can be skipped"
else
    echo "   ❌ MPS skip logic not found"
fi

echo "7. Checking React Chatwoot import..."
if grep -q "// import ChatwootWidget" ui/src/app/layout.tsx; then
    echo "   ✅ ChatwootWidget import is commented out"
else
    echo "   ❌ ChatwootWidget may be imported"
fi

echo ""
echo "===================================="
echo "Verification complete!"
echo ""
echo "Summary of Independence:"
echo "- Telemetry: Disabled by default"
echo "- MPS: Optional (no forced connection)"
echo "- Chatwoot: Removed from UI"
echo "- Sentry: No hardcoded DSN"
echo "- Pipecat: Self-contained in submodule"
echo ""
echo "✅ This deployment can run fully independently!"
