# Expense Tracker - Project Handoff Document

**Last Updated:** January 1, 2026  
**Status:** Feature Complete - Ready for Polish & Testing Phase  
**Tech Stack:** Node.js/Express + React + PostgreSQL

---

## Project Overview

A full-featured expense tracking application with YNAB-style envelope budgeting, multi-user households, role-based access control, and super admin management.

### Key Features
- **Envelope Budgeting System** (YNAB-style) - The core feature
- **Multi-tenant Architecture** - Households with multiple users
- **Three User Roles** - Regular, Admin, Super Admin
- **Complete CRUD** - Transactions, Accounts, Categories, Budgets, Allocations
- **Super Admin Dashboard** - Manage all households, plans, and users

---

## Architecture

### Backend (`/server`)
- **Framework:** Express.js
- **Database:** PostgreSQL
- **Auth:** JWT tokens
- **Port:** 3000

**Key Files:**
- `src/app.js` - Main Express app
- `src/config/database.js` - PostgreSQL connection
- `src/middleware/auth.js` - Authentication & role checks
- `src/controllers/` - Business logic
- `src/routes/` - API endpoints

### Frontend (`/web-admin`)
- **Framework:** React 18 + Vite
- **State Management:** React Query (TanStack Query)
- **Routing:** React Router v6
- **Styling:** Tailwind CSS
- **Icons:** Lucide React
- **Port:** 5173

**Key Files:**
- `src/App.jsx` - Routes and layout
- `src/context/AuthContext.jsx` - Authentication state
- `src/components/layout/AppLayout.jsx` - Main layout with navigation
- `src/pages/` - All page components
- `src/services/api.js` - API client

### Database Schema
- `households` - Multi-tenant container
- `users` - With role (regular/admin/super_admin)
- `accounts` - Bank accounts
- `categories` - Expense/income categories
- `transactions` + `transaction_lines` - Dual-entry bookkeeping
- `budgets` - Monthly spending limits
- `allocations` - Envelope budgeting (NEW!)
- `transaction_allocations` - Links transactions to envelopes
- `subscription_plans` - Pricing tiers
- `invitations` - User invite system

---

## User Roles & Access

### 1. Regular User
**Access:** Own household data only  
**Features:**
- Dashboard - Overview and quick stats
- Transactions - Create/edit/delete with auto-deduction from envelopes
- Accounts - Manage bank accounts
- Categories - Organize expenses/income
- Budgets - Set monthly spending limits
- **Allocations - YNAB-style envelope budgeting (PRIMARY FEATURE)**
- Reports - Charts and analytics
- Settings - Profile and preferences

### 2. Admin (Household Admin)
**Access:** Own household + admin features  
**Additional Features:**
- Admin Panel - Manage household users
- Invite users via email (needs implementation)
- View user quotas and limits

**Test Account:**
- Email: `samer@example.com`
- Household: Samer Family
- Password: (your password)

### 3. Super Admin (Platform Owner)
**Access:** ALL households + system management  
**Features:**
- Super Admin Dashboard - System stats, all households
- Households Page - CRUD households, view details
- Plans Page - CRUD subscription plans
- Users Page - View all users across households

**Test Account:**
- Email: `admin@expensetracker.com`
- Household: Platform Administration
- Password: (same as regular user)

---

## Envelope Budgeting System (Allocations)

**This is the PRIMARY feature - spent the most time on this.**

### Concept
Based on YNAB (You Need A Budget) methodology:
1. User creates allocations (budgets) per category per month
2. User allocates income to envelopes (funding)
3. Expenses automatically deduct from envelopes
4. User can move money between envelopes

### Database Fields
\`\`\`sql
allocations {
  allocated_amount  -- Budget/goal (e.g., $400 for groceries)
  available_amount  -- Money IN envelope (funded)
  spent_amount      -- Money taken OUT of envelope
  balance           -- available_amount - spent_amount
}
\`\`\`

### User Flow
1. **Plan:** Create allocation (e.g., Groceries: $400/month)
2. **Fund:** Allocate income to envelope (put $400 into Groceries envelope)
3. **Spend:** Create expense transaction → auto-deducts from envelope
4. **Track:** View balance, transactions per envelope
5. **Adjust:** Move money between envelopes as needed

### Key Files
**Backend:**
- `server/src/controllers/allocationsController.js` - All allocation logic
- `server/src/controllers/transactionsController.js` - Auto-deduction on line 360-395

**Frontend:**
- `web-admin/src/pages/allocations/AllocationsPage.jsx` - Main page
- `web-admin/src/components/allocations/AllocationCard.jsx` - Envelope display
- `web-admin/src/components/allocations/FundIncomeModal.jsx` - Income allocation
- `web-admin/src/components/allocations/MoveMoneyModal.jsx` - Move between envelopes
- `web-admin/src/components/allocations/AllocationTransactionsModal.jsx` - View envelope transactions

---

## Known Issues & TODOs

### Critical Bugs to Fix
1. **Preferences Loop** - Removed PreferencesProvider due to infinite loop
   - Currently using localStorage fallback
   - Need to fix React Query caching issue
   - Files affected: `src/context/PreferencesContext.jsx` (deleted), `src/context/AuthContext.jsx` (line 40)

2. **Email Invites Not Working**
   - Backend endpoint exists but email sending not implemented
   - Need to add email service (SendGrid/Mailgun/Nodemailer)
   - File: `server/src/controllers/invitationsController.js`

### UI Polish Needed
1. Loading states inconsistent across pages
2. Error messages could be more user-friendly
3. Mobile responsiveness needs testing
4. Form validation could be stricter

### Missing Features (Low Priority)
1. Forgot password flow
2. Email verification
3. Two-factor authentication
4. Export data (CSV/PDF)
5. Bulk import transactions
6. Recurring transactions
7. Account reconciliation
8. Multi-currency support (basic structure exists)

---

## Recent Changes (Last Session)

### Super Admin System (Completed Dec 31, 2024)
- Created super_admin role in database
- Built 4 super admin pages (Dashboard, Households, Plans, Users)
- Conditional navigation based on user role
- Dynamic menu positioning for dropdowns

### Envelope Budgeting Enhancements (Completed Dec 30, 2024)
- Auto-deduct from envelopes when creating expense transactions
- Auto-restore to envelopes when deleting transactions
- Move money between envelopes
- View transactions per envelope
- Fund income modal with auto-fill

### Bug Fixes (Completed Dec 31, 2024)
- Fixed infinite preferences loop (temporary solution)
- Removed subscription API calls (not implemented)
- Fixed menu positioning on Households page
- Added all features to Plan modal

---

## How to Run

### Backend
\`\`\`bash
cd ~/projects/expense-tracker/server
npm run dev
# Runs on http://192.168.86.22:3000
\`\`\`

### Frontend
\`\`\`bash
cd ~/projects/expense-tracker/web-admin
npm run dev
# Runs on http://192.168.86.22:5173
\`\`\`

### Database
\`\`\`bash
psql -U samer -d expense_tracker -h localhost
# Password: (your postgres password)
\`\`\`

---

## API Endpoints

### Authentication
- POST `/api/auth/register` - Create account
- POST `/api/auth/login` - Login
- GET `/api/auth/me` - Get current user

### Transactions
- GET `/api/transactions` - List transactions
- POST `/api/transactions` - Create (auto-deducts from allocations)
- PUT `/api/transactions/:id` - Update
- DELETE `/api/transactions/:id` - Delete (auto-restores to allocations)

### Allocations (Envelope Budgeting)
- GET `/api/allocations?month=YYYY-MM-01` - Get allocations for month
- POST `/api/allocations` - Create/update allocation
- POST `/api/allocations/fund` - Fund envelopes with income
- POST `/api/allocations/move` - Move money between envelopes
- GET `/api/allocations/:id/transactions` - View transactions per envelope
- DELETE `/api/allocations/:id` - Delete allocation

### Super Admin
- GET `/api/super-admin/households` - All households with stats
- GET `/api/super-admin/households/:id` - Household details
- PUT `/api/super-admin/households/:id/plan` - Assign plan
- PUT `/api/super-admin/households/:id/status` - Suspend/activate
- GET `/api/super-admin/plans` - All subscription plans
- POST `/api/super-admin/plans` - Create plan
- PUT `/api/super-admin/plans/:id` - Update plan

*(Full API documentation available at `GET /api` endpoint)*

---

## Testing Checklist

### Phase 1: Core Functionality
- [ ] Login/Logout (all 3 user types)
- [ ] Create household account
- [ ] Create transactions
- [ ] View dashboard
- [ ] Allocations workflow (create → fund → spend → view)

### Phase 2: Envelope Budgeting (CRITICAL)
- [ ] Create allocation (budget)
- [ ] Fund allocation with income
- [ ] Auto-deduct when creating expense
- [ ] Auto-restore when deleting transaction
- [ ] Move money between envelopes
- [ ] View transactions per envelope
- [ ] Balance calculations correct
- [ ] Overspending detection

### Phase 3: Admin Features
- [ ] Invite user to household
- [ ] Remove user from household
- [ ] View user quotas

### Phase 4: Super Admin
- [ ] View all households
- [ ] Create/edit subscription plans
- [ ] Assign plan to household
- [ ] Suspend/activate household
- [ ] View all users

### Phase 5: Edge Cases
- [ ] Delete account with transactions
- [ ] Delete category used in allocations
- [ ] Negative balances
- [ ] Large numbers (millions)
- [ ] Special characters in names
- [ ] Concurrent edits

### Phase 6: UI/UX
- [ ] Mobile responsiveness
- [ ] Loading states
- [ ] Error messages
- [ ] Empty states
- [ ] Tooltips and help text
- [ ] Keyboard navigation

---

## Performance Considerations

### Database Queries
- Most queries are indexed (check `server/src/config/schema.sql`)
- Transaction listing could be slow with 10,000+ transactions
- Consider pagination for large datasets

### Frontend
- React Query caches API responses (5 min stale time)
- Large allocation lists could benefit from virtualization
- Image uploads not implemented (future feature)

---

## Security Notes

### Implemented
- ✅ JWT authentication
- ✅ Password hashing (bcrypt)
- ✅ Role-based access control
- ✅ Input validation
- ✅ SQL injection protection (parameterized queries)

### Missing
- ❌ Rate limiting
- ❌ CSRF protection
- ❌ XSS sanitization (basic React protection only)
- ❌ HTTPS (using HTTP in dev)
- ❌ Security headers
- ❌ API key rotation

---

## Deployment Readiness

### Not Ready For Production
- No environment variables (.env file in repo)
- No Docker containers
- No CI/CD pipeline
- No automated tests
- No monitoring/logging
- No backup strategy
- Database credentials hardcoded

### Would Need
1. Environment variable management
2. HTTPS setup
3. Database backups
4. Error tracking (Sentry)
5. Rate limiting
6. Email service integration
7. Payment processing (Stripe)
8. Terms of service / Privacy policy

---

## Code Quality

### Good Practices
- ✅ Consistent naming conventions
- ✅ Commented complex logic
- ✅ Separated concerns (controllers/routes/services)
- ✅ Error handling in controllers

### Could Improve
- ⚠️ No automated tests
- ⚠️ Some large functions (500+ lines)
- ⚠️ Duplicate code in modals
- ⚠️ Console.logs left in production code
- ⚠️ Magic numbers (should be constants)

---

## Important Context for Claude Code

### Design Decisions Made
1. **Multi-tenant via household_id** - Every table has household_id for isolation
2. **Soft deletes** - is_deleted flag instead of actual deletion
3. **Dual-entry bookkeeping** - transactions + transaction_lines
4. **React Query for state** - No Redux, using server state caching
5. **No global preferences context** - Using localStorage due to loop bug

### Common Patterns
- Controllers always check `req.user.householdId` for data isolation
- Modals follow: isOpen → useEffect → validate → submit pattern
- API calls wrapped in React Query hooks
- Authentication via `authenticateToken` middleware

### Watch Out For
- PreferencesContext causes infinite loop (currently disabled)
- Subscription API not implemented (calls commented out)
- Some features reference "plan_features" table (not fully implemented)
- Email sending stubbed out

---

## Next Steps (Priority Order)

1. **Fix Preferences Loop Bug** (HIGH)
   - Root cause: React Query cache invalidation
   - Temporary fix: localStorage
   - Need: Proper caching strategy

2. **Test Envelope Budgeting** (HIGH)
   - This is the main feature
   - Test all workflows thoroughly
   - Fix any calculation bugs

3. **Email Invites** (MEDIUM)
   - Add email service
   - Send actual invitation emails
   - Test invite flow

4. **UI Polish** (MEDIUM)
   - Consistent loading states
   - Better error messages
   - Mobile testing

5. **Documentation** (LOW)
   - User guide
   - API documentation
   - Setup instructions

---

## Questions to Ask

Before making changes, consider:
- Does this affect the envelope budgeting system? (critical feature)
- Will this break multi-tenancy? (household isolation)
- Does this require database migration?
- Will existing data need updating?
- Are there security implications?

---

## Useful Commands

\`\`\`bash
# Database backup
pg_dump -U samer expense_tracker > backup.sql

# Database restore
psql -U samer expense_tracker < backup.sql

# View all households
psql -U samer expense_tracker -c "SELECT id, name, plan_status FROM households;"

# Check user roles
psql -U samer expense_tracker -c "SELECT email, role FROM users;"
\`\`\`

---

## Contact & Handoff

**Developer:** Samer  
**Date Built:** December 2024 - January 2026  
**Total Development Time:** ~40 hours  
**Lines of Code:** ~15,000  

**Ready for:** Testing, polishing, and small feature additions  
**Not ready for:** Production deployment  

---

Good luck with the polish & testing phase! The envelope budgeting system is the crown jewel - make sure that works flawlessly.
