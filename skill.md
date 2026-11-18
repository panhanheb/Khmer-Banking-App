# PROJECT: KHMER DIGITAL BANKING SYSTEM

Act as a Senior Software Architect, Senior Flutter Developer, Fintech Product Designer, Backend Engineer, Database Architect, and Cybersecurity Engineer.

Your mission is to design and develop a complete, professional, scalable Khmer Digital Banking Application for the Cambodian market.

The application must provide a realistic digital banking experience, with a modern interface, secure financial operations, comprehensive backend services, and an administrative management platform.

## 1. Project Overview

Project Name: Khmer Digital Bank

Target Market: Cambodia

Supported Languages:
- Khmer (ភាសាខ្មែរ)
- English

Currency:
- Cambodian Riel (KHR)
- US Dollar (USD)

Platform:
- Android
- iOS
- Web Admin Dashboard

Design inspiration:
- Modern Cambodian digital banking applications
- Premium fintech applications
- iOS 26 Liquid Glass design
- Material Design 3

Create an original brand identity, logo, typography, color system, and user experience.

## 2. Mobile Application Features

### A. Authentication and Account Security
- User registration
- Login with phone number
- Email authentication
- PIN authentication
- Biometric authentication (Face ID / Fingerprint)
- OTP verification
- Forgot password
- Reset password
- Device management
- Session management
- Change transaction PIN
- Account lock and unlock
- Multi-factor authentication

### B. Home Dashboard
Create a premium banking dashboard containing:
- Personalized greeting
- User profile
- Total account balance
- Hide/show balance
- USD and KHR balance
- Quick action buttons
- Recent transactions
- Bank account cards
- Monthly spending summary
- Notifications
- Promotional banners

Quick actions:
- Transfer
- Scan QR
- Deposit
- Withdraw
- Pay Bills
- Top Up
- Transaction History

### C. Bank Accounts
- Open a bank account
- Personal account
- Savings account
- Multiple currency accounts
- Account details
- Account number
- Account status
- Account balance
- Account statements
- Download PDF statements
- Account transaction history

### D. Money Transfer
Implement a complete transfer workflow:

- Transfer between own accounts
- Transfer to other bank customers
- Internal bank transfers
- Interbank transfers
- Transfer by phone number
- Transfer by account number
- Transfer by QR code
- Transfer to saved beneficiaries

Transfer workflow:
1. Select source account
2. Select recipient
3. Enter transfer amount
4. Select currency
5. Enter description
6. Review transfer details
7. Confirm with transaction PIN or biometric authentication
8. Process transaction
9. Display transaction receipt

Include transaction limits, fees, exchange rates, and transfer status.

### E. QR Payment System
- Generate personal payment QR
- Scan payment QR
- Merchant QR payments
- Customer-to-customer QR payments
- Dynamic QR codes
- Payment confirmation
- Payment history
- Digital receipts

Use a configurable KHQR-compatible integration architecture. Do not claim official Bakong or KHQR compatibility without an authorized integration.

### F. Bill Payments
Support configurable biller integrations:
- Electricity
- Water
- Internet
- Mobile phone
- Education
- Insurance
- Government services

Features:
- Select biller
- Enter customer reference
- Validate bill
- Display bill amount
- Confirm payment
- Generate receipt
- Save payment history

### G. Mobile Top-Up
- Smart
- Cellcard
- Metfone
- Other configurable telecom operators

Features:
- Select operator
- Select phone number
- Select package
- Enter top-up amount
- Confirm payment
- Transaction receipt

### H. Cards Management
- Debit cards
- Virtual cards
- Card details
- Card activation
- Freeze/unfreeze cards
- Change card PIN
- Card transaction history
- Card spending limits

### I. Transaction Management
- Transaction history
- Search transactions
- Filter by date
- Filter by transaction type
- Filter by currency
- Transaction details
- Transaction reference
- Download receipt
- Pending transactions
- Successful transactions
- Failed transactions
- Reversed transactions

### J. Notifications
- Transfer notifications
- Payment notifications
- Login notifications
- Security alerts
- Promotions
- System announcements
- Push notifications

### K. User Profile
- Personal information
- Profile picture
- Khmer name
- English name
- Phone number
- Email
- Nationality
- KYC verification status
- Change password
- Change PIN
- Language settings
- Theme settings
- Privacy settings
- Logout

### L. KYC Verification
- Identity verification
- National ID / Passport
- Document upload
- Selfie verification
- Personal information
- Address information
- Verification status
- KYC review workflow

## 3. Backend Architecture

Build a secure RESTful backend using:

- Java 21+
- Spring Boot 3+
- Spring Security
- Spring Data JPA
- PostgreSQL
- Redis
- JWT authentication
- Refresh token rotation
- WebSocket for real-time notifications
- Docker
- Docker Compose
- OpenAPI / Swagger

Architecture:
- Clean Architecture principles
- Domain-Driven Design
- Modular monolith initially
- Microservice-ready structure
- Repository pattern
- Service layer
- DTO pattern
- Dependency injection
- Centralized exception handling
- Structured logging

Backend modules:
1. Authentication
2. User Management
3. Account Management
4. KYC Management
5. Wallet Management
6. Transactions
7. Money Transfer
8. QR Payments
9. Bill Payments
10. Mobile Top-Up
11. Card Management
12. Notifications
13. Exchange Rates
14. Reports
15. Audit Logs
16. Admin Management

## 4. Database Design

Use PostgreSQL.

Create normalized database schemas for:

- users
- user_profiles
- user_devices
- roles
- permissions
- user_roles
- bank_accounts
- account_balances
- account_holders
- beneficiaries
- transactions
- transaction_entries
- transfers
- payment_requests
- qr_payments
- bill_payments
- mobile_topups
- bank_cards
- kyc_documents
- notifications
- exchange_rates
- transaction_limits
- audit_logs
- refresh_tokens
- admin_users

IMPORTANT FINANCIAL REQUIREMENTS:
- Never use floating-point numbers for money.
- Use NUMERIC/DECIMAL for monetary amounts.
- Implement double-entry accounting.
- Ensure atomic financial transactions.
- Use database transactions and appropriate locking.
- Implement idempotency keys.
- Prevent duplicate transfers.
- Maintain immutable financial ledger records.
- Support reconciliation.
- Keep a complete audit trail.

## 5. Admin Dashboard

Build a professional web administration dashboard.

Dashboard modules:
- Overview
- Total customers
- Active accounts
- Total deposits
- Total withdrawals
- Transfer volume
- Daily transaction statistics
- Revenue and fees
- Transaction monitoring
- Customer management
- KYC approval
- Account management
- Suspicious transaction monitoring
- Fraud alerts
- Exchange rate management
- Billers management
- Mobile operators management
- Notifications management
- Reports
- Staff management
- Role-based permissions
- Audit logs
- System configuration

Include:
- Data visualization
- Interactive charts
- Advanced tables
- Search and filtering
- Export CSV / Excel / PDF
- Pagination
- Date-range filtering

## 6. UI/UX Design System

Create a premium, modern fintech experience.

Visual direction:
- Premium banking
- Minimalist
- Elegant
- Trustworthy
- Professional
- Clean layouts
- Smooth animations

Color palette:
- Primary: Deep Navy #101B35
- Secondary: Royal Blue #2457D6
- Accent: Gold #D8AE58
- Background: #F5F7FB
- Surface: #FFFFFF
- Success: #16A36A
- Error: #DC3545

Typography:
- Khmer: Noto Sans Khmer
- English: Inter

Design requirements:
- Responsive layouts
- Light and dark themes
- Consistent spacing
- Reusable components
- Rounded cards
- Premium shadows
- Subtle gradients
- Skeleton loading
- Empty states
- Error states
- Success states
- Smooth page transitions
- Haptic feedback
- Accessible color contrast

Support complete Khmer and English localization.

## 7. Flutter Architecture

Use Flutter and Dart.

Recommended stack:
- Flutter
- Dart
- flutter_bloc
- go_router
- Dio
- Freezed
- json_serializable
- get_it
- flutter_secure_storage
- local_auth
- cached_network_image
- flutter_localizations

Architecture:
Feature-first Clean Architecture.

Each feature should contain:
- data/
- domain/
- presentation/

Separate:
- Models
- Entities
- Repositories
- Use Cases
- Data Sources
- BLoCs
- Events
- States
- Pages
- Widgets

Use BLoC for predictable state management.

Create reusable components:
- AppButton
- AppTextField
- BalanceCard
- AccountCard
- TransactionItem
- CurrencySelector
- PinInput
- OTPInput
- AppBottomNavigation
- LoadingWidget
- ErrorWidget
- EmptyStateWidget
- ConfirmationBottomSheet

## 8. Security Requirements

Security is the highest priority.

Implement:
- TLS communication
- Secure credential storage
- Multi-factor authentication
- Strong password policies
- Rate limiting
- Brute-force protection
- Device registration
- Session expiration
- Role-based access control
- Transaction authorization
- Transaction limits
- Idempotency protection
- Fraud monitoring
- Audit logging
- Data encryption
- Sensitive data masking
- Secure API validation
- OWASP security practices

Never store plaintext passwords, PINs, OTPs, or sensitive credentials.

Never trust the mobile client for account balances or transaction authorization.

Use server-side validation for every financial operation.

## 9. Testing

Create:
- Unit tests
- Widget tests
- Integration tests
- API tests
- Repository tests
- Authentication tests
- Transfer tests
- Payment tests
- Security tests
- Database transaction tests

Important scenarios:
- Insufficient balance
- Duplicate transfer request
- Invalid OTP
- Expired session
- Invalid transaction PIN
- Network interruption
- Concurrent transactions
- Failed payment
- Transaction rollback

## 10. DevOps and Deployment

Provide:
- Dockerfiles
- Docker Compose
- PostgreSQL configuration
- Redis configuration
- Environment variables
- Database migrations
- CI/CD pipeline
- Development environment
- Staging environment
- Production deployment architecture
- Monitoring
- Backup and recovery

Never commit secrets or production credentials.

## 11. Development Workflow

Build the project step by step.

Phase 1: Requirements and system architecture.

Phase 2: UI/UX design system and screen designs.

Phase 3: Database schema and backend foundation.

Phase 4: Authentication and user management.

Phase 5: Account management and balances.

Phase 6: Transactions and money transfers.

Phase 7: QR payments and bill payments.

Phase 8: Notifications and user profile.

Phase 9: Admin dashboard.

Phase 10: Security, testing, and optimization.

Phase 11: Deployment and documentation.

## 12. Expected Deliverables

Provide:
1. Complete system architecture diagram.
2. Flutter project folder structure.
3. Spring Boot project folder structure.
4. PostgreSQL ER diagram.
5. Database migrations.
6. REST API documentation.
7. Complete Flutter source code.
8. Complete backend source code.
9. Admin dashboard source code.
10. Authentication implementation.
11. Transaction and accounting implementation.
12. Testing implementation.
13. Docker configuration.
14. Installation instructions.
15. Development documentation.
16. Deployment documentation.

## FINAL INSTRUCTION

Work as a professional fintech engineering team.

Do not create only static UI screens or fake banking functionality.

Build working features with real API integration, database persistence, validation, security, and comprehensive error handling.

For any feature requiring real banking infrastructure, licensed payment services, KHQR/Bakong connectivity, card networks, or regulated financial operations, create a well-defined integration interface and clearly identify the external authorization and credentials required.

Use mock services only for development and testing. Clearly distinguish simulated transactions from real financial transactions.

Prioritize correctness, financial integrity, security, maintainability, and user experience.

Start with the complete architecture, database design, and implementation roadmap before writing the code.