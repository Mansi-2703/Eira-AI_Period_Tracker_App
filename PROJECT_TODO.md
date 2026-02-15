# 🌸 HerCycle – TODO & Roadmap

AI-powered menstrual cycle tracking app using Flutter + Django + LSTM

---

## ✅ PHASE A: FOUNDATION (COMPLETED)

### A1. Project Setup
- [x] Flutter project initialized
- [x] Django backend initialized
- [x] Django REST Framework configured
- [x] Virtual environment created
- [x] API base structure finalized
- [x] Git-ready folder structure

---

### A2. Authentication System
- [x] User registration API
- [x] Login API with JWT
- [x] Token generation using SimpleJWT
- [x] Secure token storage in Flutter
- [x] Auth-protected endpoints
- [x] Login flow tested from Flutter

---

## ✅ PHASE B: CORE TRACKING & AI (MOSTLY COMPLETED)

---

### B1. Cycle Tracking
#### Backend
- [x] Cycle model (start_date, cycle_length, period_length)
- [x] User-linked cycle records
- [x] Unique constraint (user + start_date)
- [x] Cycle create API
- [x] Cycle data persisted correctly

#### Frontend
- [x] Add Cycle screen
- [x] Date picker for last period
- [x] Cycle length input
- [x] Period length input
- [x] Default sensible values (28 / 5)
- [x] Save cycle → backend
- [x] Navigation after save

---

### B2. Prediction Engine
- [x] Rule-based prediction (average cycle)
- [x] LSTM-based prediction (≥6 cycles)
- [x] Automatic model selection
- [x] Predicted next period date
- [x] Current menstrual phase logic
- [x] Fertile window calculation
- [x] Cycle day calculation
- [x] Prediction API secured
- [x] Prediction API tested

---

### B2.3 Confidence Scoring
- [x] Base confidence from cycle count
- [x] Rule-based vs LSTM confidence differentiation
- [x] Confidence returned to frontend
- [x] Display confidence percentage in UI

---

### B2.4 Quiz → Confidence Boost
#### Backend
- [x] MenstrualHealthProfile model
- [x] One-to-one mapping with User
- [x] Quiz submission API
- [x] Quiz score computation utility
- [x] Quiz scores integrated into prediction confidence
- [x] Profile creation & update working

#### Frontend
- [x] Quiz submission flow
- [x] Quiz saved to backend
- [x] Confidence updated after quiz

---

## 🟡 PHASE C: UI & UX POLISH (IN PROGRESS)

---

### C1. Home Screen Improvements
- [x] Prediction card UI
- [x] Phase display
- [x] Confidence display
- [x] Add Cycle CTA
- [ ] Show “Why this prediction?” explanation
- [ ] Visual phase indicators (color-coded)
- [ ] Friendly insight text under prediction

---

### C2. Quiz UX Enhancements
- [ ] Multi-step quiz UI
- [ ] Progress indicator (e.g. “3 of 10”)
- [ ] Reassuring micro-copy
- [ ] Ability to skip & resume later
- [ ] Better grouping of questions
- [ ] Validation & gentle error handling

---

## ❌ PHASE D: SMART HEALTH INSIGHTS (NOT STARTED)

---

### D1. Health Risk Flags
- [ ] Heavy flow + long duration → anemia risk
- [ ] Irregular cycle → hormonal imbalance risk
- [ ] Severe pain → endometriosis flag
- [ ] Long cycles → possible PCOS flag
- [ ] Fatigue + dizziness → iron deficiency hint

---

### D2. Personalized Insights Engine
- [ ] “Your last 3 cycles were longer than usual”
- [ ] “Ovulation window approaching”
- [ ] “Your cycle regularity has improved”
- [ ] “Prediction confidence increased after quiz”
- [ ] Friendly, non-diagnostic language

---

## ❌ PHASE E: DATA VISUALIZATION (NOT STARTED)

---

### E1. Cycle History
- [ ] Cycle timeline view
- [ ] Past periods list
- [ ] Cycle length trend graph

---

### E2. Calendar View
- [ ] Period days marked
- [ ] Fertile window highlight
- [ ] Predicted next period highlight
- [ ] Color-coded phases

---

## ❌ PHASE F: DATABASE & DEPLOYMENT (NOT STARTED)

---

### F1. PostgreSQL Migration
- [ ] Configure PostgreSQL locally
- [ ] Update Django DB settings
- [ ] Migrate existing models
- [ ] Test all APIs on PostgreSQL

> PostgreSQL setup steps + env var guidance now live in `backend/README.md`; requirements include `psycopg2-binary`.

> WARNING: the backend now refuses to start without the `DJANGO_DB_*` vars pointing to a Postgres instance—SQLite is no longer supported by default.

---

### F2. Deployment
- [ ] Backend deployment (Render / Railway / AWS)
- [ ] Environment variables setup
- [ ] Production-ready settings
- [ ] Debug turned off
- [ ] Allowed hosts configured

---

### F3. App Release Prep
- [ ] Production API base URL
- [ ] App icon & splash screen
- [ ] App name finalization
- [ ] Privacy policy & consent text
- [ ] Release APK build

---

## 📌 OPTIONAL / FUTURE ENHANCEMENTS
- [ ] Notifications (period reminder)
- [ ] Symptom logging
- [ ] Export cycle data
- [ ] Partner mode
- [ ] Wearable data integration

---

## 📊 PROJECT STATUS
- Core backend: ✅ COMPLETE
- AI prediction: ✅ COMPLETE
- Quiz intelligence: ✅ COMPLETE
- App flow: 🟡 STABLE
- UX polish: 🟡 IN PROGRESS
- Insights & deployment: ❌ PENDING

**Overall Completion: ~75%**

---

🌸 _HerCycle is already a strong AI-backed health app. The remaining work is polish, insights, and production readiness._
