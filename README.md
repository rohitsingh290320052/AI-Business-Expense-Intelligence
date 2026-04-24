# 💰 ExpenseStory — AI Business Expense Intelligence

> **CFO-level financial intelligence in your pocket. Built for Indian SMBs & solopreneurs.**

---

## 🌟 What Makes This Resume-Worthy

| Feature | Technology Used |
|---|---|
| AI Receipt Scanner | Gemini 1.5 Flash Vision API |
| Auto-categorization | LLM Prompt Engineering |
| Tax Deduction Detection | Indian GST/IT Act Rules via AI |
| Anomaly Detection | Behavioral Pattern Analysis |
| CFO Monthly Reports | Multi-step LLM Chain |
| Cash Flow Prediction | AI Forecasting |
| Interactive CFO Chat | Conversational AI with Context |
| Beautiful Dark UI | Custom Design System + Animations |
| Local DB | Isar (ultra-fast NoSQL) |
| Charts | FL Chart + Percent Indicator |

---

## 🚀 Setup Instructions

### 1. Prerequisites
```bash
flutter --version  # Needs Flutter 3.16+
dart --version     # Needs Dart 3.1+
```

### 2. Get a Free Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com)
2. Click "Get API Key" → Create API Key
3. Copy your key

### 3. Configure API Key
Create a `.env` file in the root:
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

Or pass it as a build argument (recommended for production):
```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### 4. Install Dependencies
```bash
flutter pub get
dart run build_runner build
```

### 5. Run the App
```bash
# Android
flutter run

# iOS
flutter run --release

# Build APK
flutter build apk --release --dart-define=GEMINI_API_KEY=your_key
```

---

## 📱 App Screens

### 🏠 Dashboard
- Monthly spending hero card with gold gradient
- Interactive 7-day spending chart
- Category breakdown with donut chart
- Anomaly alerts (red highlighted expenses)
- Quick action buttons: Scan Receipt, Add Manual, AI Report

### ➕ Add Expense
- **AI Receipt Scanner** — point camera at any receipt → auto-fills everything
- **Manual Entry** with "Get AI Insights" button
- Category chips (10 categories with emojis)
- Payment method selector (UPI, Card, Cash, Net Banking)
- Tax deductible toggle with AI-suggested reason
- AI Insight card appears after analysis

### 📊 Reports
- Horizontal bar chart for category breakdown
- Spending Health Score (0-100) with color indicator
- Generate AI CFO Report button
- Executive Summary from AI
- Cash Flow Prediction for next month
- Numbered CFO Recommendations

### 🤖 AI CFO Chat
- Conversational interface with typing animation
- Pre-loaded suggestion chips
- Full expense context sent to AI
- India-specific advice (GST, IT Act, UPI, etc.)
- Animated typing dots indicator

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry + bottom nav shell
├── theme/
│   └── app_theme.dart           # Design system (colors, typography, gradients)
├── models/
│   └── expense.dart             # Isar DB models (Expense, MonthlyReport)
├── services/
│   └── ai_service.dart          # All Gemini AI integrations
├── screens/
│   ├── dashboard_screen.dart    # Main overview
│   ├── add_expense_screen.dart  # Add/scan expense
│   ├── reports_screen.dart      # Monthly CFO report
│   └── cfo_chat_screen.dart     # AI chat interface
└── widgets/
    ├── glass_card.dart          # Reusable card component
    ├── stat_chip.dart           # Quick action chips
    └── spending_ring.dart       # Donut chart widget
```

---

## 🎨 Design System

**Aesthetic:** Luxury Dark — Deep midnight blacks with electric gold accents

| Token | Value |
|---|---|
| Background | `#0A0A0F` |
| Surface | `#12121A` |
| Card | `#1E1E2E` |
| Gold | `#E8B84B` |
| Teal | `#00D4AA` |
| Display Font | Cormorant Garamond |
| UI Font | Space Grotesk |
| Body Font | Inter |

---

## 💡 Startup Potential

- **Market:** 63M+ MSMEs in India with zero CFO support
- **Monetization:** ₹499/month per business (freemium → paid)
- **Integrations:** Razorpay, Stripe, GST portal, Tally
- **Moat:** AI learns your business spending personality over time
- **Expansion:** Team expenses, multi-currency, accountant access

---

## 🔧 Production Additions (Next Steps)

- [ ] Isar database integration (replace in-memory list)
- [ ] Firebase Auth (phone OTP for Indian users)
- [ ] Razorpay subscription billing
- [ ] GST report generation (PDF export)
- [ ] WhatsApp receipt forwarding
- [ ] Multi-business account support
- [ ] Tally & Zoho Books integration
- [ ] Widget for home screen spending summary

---

**Built with Flutter + Gemini AI | Designed for India's 63M SMBs**
