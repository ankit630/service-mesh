# Istio Architecture Diagrams

## Service Mesh Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      ISTIO CONTROL PLANE                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                        ISTIOD                          │    │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────────────┐   │    │
│  │  │   PILOT   │  │  GALLEY   │  │      CITADEL      │   │    │
│  │  │(Traffic   │  │(Config    │  │   (Security &     │   │    │
│  │  │Mgmt)      │  │Mgmt)      │  │   Certificate     │   │    │
│  │  │           │  │           │  │   Management)     │   │    │
│  │  └───────────┘  └───────────┘  └───────────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ Configuration & Certificates
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DATA PLANE                               │
│                                                                 │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │   FRONTEND      │              │    BACKEND      │          │
│  │   ┌─────────┐   │              │   ┌─────────┐   │          │
│  │   │  App    │   │              │   │  App    │   │          │
│  │   │Container│   │              │   │Container│   │          │
│  │   └─────────┘   │              │   └─────────┘   │          │
│  │   ┌─────────┐   │     HTTP     │   ┌─────────┐   │          │
│  │   │ Envoy   │◄──┼──────────────┼──►│ Envoy   │   │          │
│  │   │Sidecar  │   │   (mTLS)     │   │Sidecar  │   │          │
│  │   │ Proxy   │   │              │   │ Proxy   │   │          │
│  │   └─────────┘   │              │   └─────────┘   │          │
│  └─────────────────┘              └─────────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Before vs After Istio

### Before Istio (Traditional Microservices)
```
┌─────────────┐                    ┌─────────────┐
│  Frontend   │                    │   Backend   │
│             │                    │             │
│ ┌─────────┐ │       HTTP         │ ┌─────────┐ │
│ │   App   │ ├────────────────────┤ │   App   │ │
│ └─────────┘ │    (Plain Text)    │ └─────────┘ │
│             │                    │             │
└─────────────┘                    └─────────────┘

Issues:
❌ No traffic encryption by default
❌ No traffic metrics/observability  
❌ No traffic policies (retries, timeouts)
❌ No load balancing intelligence
❌ Security policies mixed with business logic
❌ Difficult to implement canary deployments
```

### After Istio (Service Mesh)
```
┌─────────────────────┐              ┌─────────────────────┐
│     Frontend Pod    │              │     Backend Pod     │
│                     │              │                     │
│ ┌─────────┐         │              │         ┌─────────┐ │
│ │   App   │         │              │         │   App   │ │
│ │Container│         │              │         │Container│ │
│ └────┬────┘         │              │         └────┬────┘ │
│      │              │              │              │      │
│      ▼              │              │              ▼      │
│ ┌─────────┐         │    mTLS     │         ┌─────────┐ │
│ │ Envoy   │◄────────┼──────────────┼────────►│ Envoy   │ │
│ │ Proxy   │         │ (Encrypted) │         │ Proxy   │ │
│ └─────────┘         │              │         └─────────┘ │
│      ▲              │              │              ▲      │
└──────┼──────────────┘              └──────────────┼──────┘
       │                                            │
       └────────────────────────────────────────────┘
                            │
                            ▼
                  ┌─────────────────┐
                  │ ISTIO CONTROL   │
                  │     PLANE       │
                  │ (Configuration, │
                  │ Certificates,   │
                  │ Policies)       │
                  └─────────────────┘

Benefits:
✅ Automatic mTLS encryption
✅ Rich metrics and distributed tracing
✅ Traffic policies (retries, circuit breakers)
✅ Intelligent load balancing
✅ Security policies as configuration  
✅ Easy canary deployments and A/B testing
```

## Traffic Flow with Istio

```
1. External Request
          │
          ▼
┌─────────────────┐
│ Istio Gateway   │ ◄── Traffic Entry Point
│ (Envoy Proxy)   │
└─────────────────┘
          │
          ▼
┌─────────────────┐
│ Virtual Service │ ◄── Routing Rules
│ (Route Config)  │
└─────────────────┘
          │
          ▼
┌─────────────────┐
│ Destination Rule│ ◄── Load Balancing, Circuit Breakers
│ (Traffic Policy)│
└─────────────────┘
          │
          ▼
┌─────────────────┐
│   Frontend      │
│   Service       │ ◄── Target Service
│   (Pods)        │
└─────────────────┘
          │
          ▼
┌─────────────────┐
│   Backend       │
│   Service       │ ◄── Downstream Service
│   (Pods)        │
└─────────────────┘
```

## Istio Components Deep Dive

### Control Plane (Istiod)
```
┌─────────────────────────────────────────┐
│                ISTIOD                   │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │    PILOT    │ │     GALLEY      │    │
│  │             │ │                 │    │
│  │• Service    │ │• Configuration  │    │
│  │  Discovery  │ │  Validation     │    │
│  │• Traffic    │ │• Configuration  │    │
│  │  Config     │ │  Distribution   │    │
│  │• Load       │ │                 │    │
│  │  Balancing  │ │                 │    │
│  └─────────────┘ └─────────────────┘    │
│                                         │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │   CITADEL   │ │     MIXER       │    │
│  │             │ │   (DEPRECATED)  │    │
│  │• Identity   │ │                 │    │
│  │• Cert Mgmt  │ │• Telemetry      │    │
│  │• Security   │ │• Policy         │    │
│  │  Policies   │ │  Enforcement    │    │
│  └─────────────┘ └─────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### Data Plane (Envoy Proxies)
```
┌─────────────────────────────────────────┐
│              ENVOY PROXY                │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │   FILTERS   │ │    LISTENERS    │    │
│  │             │ │                 │    │
│  │• HTTP       │ │• Port 15001     │    │
│  │• TCP        │ │  (Inbound)      │    │
│  │• Auth       │ │• Port 15006     │    │
│  │• Rate Limit │ │  (Outbound)     │    │
│  │• Metrics    │ │• Admin Port     │    │
│  └─────────────┘ └─────────────────┘    │
│                                         │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │  CLUSTERS   │ │    ROUTES       │    │
│  │             │ │                 │    │
│  │• Service    │ │• Path-based     │    │
│  │  Endpoints  │ │• Header-based   │    │
│  │• Health     │ │• Weight-based   │    │
│  │  Checking   │ │• Fault          │    │
│  │• Load       │ │  Injection      │    │
│  │  Balancing  │ │                 │    │
│  └─────────────┘ └─────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

## Security Model

```
┌─────────────────────────────────────────┐
│            ISTIO SECURITY               │
├─────────────────────────────────────────┤
│                                         │
│  Identity (Service Accounts)            │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │  Frontend   │ │    Backend      │    │
│  │    Pod      │ │      Pod        │    │
│  │             │ │                 │    │
│  │ SA: default │ │ SA: backend-sa  │    │
│  └─────────────┘ └─────────────────┘    │
│         │                 │             │
│         ▼                 ▼             │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │   X.509     │ │     X.509       │    │
│  │Certificate  │ │  Certificate    │    │
│  │             │ │                 │    │
│  │Valid: 24hrs │ │  Valid: 24hrs   │    │
│  └─────────────┘ └─────────────────┘    │
│         │                 │             │
│         └─────────┬───────┘             │
│                   │                     │
│                   ▼                     │
│            ┌─────────────┐               │
│            │    mTLS     │               │
│            │ Connection  │               │
│            │             │               │
│            │• Identity   │               │
│            │  Verified   │               │
│            │• Traffic    │               │
│            │  Encrypted  │               │
│            └─────────────┘               │
│                                         │
└─────────────────────────────────────────┘
```

## Observability Stack

```
┌─────────────────────────────────────────┐
│           OBSERVABILITY TOOLS           │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │    KIALI    │ │   PROMETHEUS    │    │
│  │             │ │                 │    │
│  │• Service    │ │• Metrics        │    │
│  │  Graph      │ │  Collection     │    │
│  │• Traffic    │ │• Time Series    │    │
│  │  Flow       │ │  Database       │    │
│  │• Health     │ │• Alerting       │    │
│  │  Status     │ │                 │    │
│  └─────────────┘ └─────────────────┘    │
│                                         │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │   JAEGER    │ │    GRAFANA      │    │
│  │             │ │                 │    │
│  │• Distributed│ │• Dashboards     │    │
│  │  Tracing    │ │• Visualization  │    │
│  │• Request    │ │• Alerting       │    │
│  │  Flow       │ │• Multi-source   │    │
│  │• Latency    │ │                 │    │
│  │  Analysis   │ │                 │    │
│  └─────────────┘ └─────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

## Request Lifecycle

```
Step 1: Request Arrives
┌─────────────┐
│   Client    │──── HTTP Request ────┐
└─────────────┘                      │
                                     ▼
Step 2: Gateway Processing    ┌─────────────┐
                              │Istio Gateway│
                              │(Envoy Proxy)│
                              └─────────────┘
                                     │
                                     ▼
Step 3: Virtual Service       ┌─────────────┐
        Routing               │Virtual      │
                              │Service Rules│
                              └─────────────┘
                                     │
                                     ▼
Step 4: Destination Rule      ┌─────────────┐
        Processing            │Destination  │
                              │Rule Policies│
                              └─────────────┘
                                     │
                                     ▼
Step 5: Service Discovery     ┌─────────────┐
                              │   Service   │
                              │  Discovery  │
                              └─────────────┘
                                     │
                                     ▼
Step 6: Load Balancing        ┌─────────────┐
                              │Load Balance │
                              │  Selection  │
                              └─────────────┘
                                     │
                                     ▼
Step 7: mTLS Handshake        ┌─────────────┐
                              │Certificate  │
                              │ Validation  │
                              └─────────────┘
                                     │
                                     ▼
Step 8: Request Delivery      ┌─────────────┐
                              │Target Pod   │
                              │(App + Envoy)│
                              └─────────────┘
```