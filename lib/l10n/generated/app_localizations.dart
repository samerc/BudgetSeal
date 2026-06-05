import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// Dialog/button cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Dialog/button delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Button save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Dialog confirm
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Button/tooltip edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Button add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// Button close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Button back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Button next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Button retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Button reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// Button done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Button confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Loading spinner text
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// Search field hint
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get commonSearchHint;

  /// Dropdown option none
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// Dismiss button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get commonGoBack;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Save Anyway'**
  String get commonSaveAnyway;

  /// Default error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// Expandable toggle
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get commonShowDetails;

  /// Expandable toggle
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get commonHideDetails;

  /// Button remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Button enable
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get commonEnable;

  /// Button change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// Button fund
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get commonFund;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get commonNoData;

  /// ErrorRetry message
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your data'**
  String get commonCouldntLoadData;

  /// ErrorRetry message
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load accounts'**
  String get commonCouldntLoadAccounts;

  /// Label for account field
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get commonAccount;

  /// Label for amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// Label for category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get commonCategory;

  /// Label for currency field
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get commonCurrency;

  /// Label for title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commonTitle;

  /// MaterialApp title / splash / lock
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal'**
  String get appName;

  /// Splash screen tagline
  ///
  /// In en, this message translates to:
  /// **'Budget with purpose'**
  String get appTagline;

  /// About screen tagline
  ///
  /// In en, this message translates to:
  /// **'Envelope budgeting, simplified.'**
  String get appTaglineAbout;

  /// Web sidebar logo abbreviation
  ///
  /// In en, this message translates to:
  /// **'PP'**
  String get appBrandAbbr;

  /// Bottom nav tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Bottom nav tab
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivity;

  /// Bottom nav tab
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get tabBudget;

  /// Bottom nav tab
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get tabReports;

  /// Bottom nav tab
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// Snackbar on double-back
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get navPressBackToExit;

  /// Web sidebar label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Web sidebar label
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// Web sidebar label
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// Web sidebar label
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// Web sidebar label
  ///
  /// In en, this message translates to:
  /// **'Envelopes'**
  String get navEnvelopes;

  /// Web sidebar label
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get navRecurring;

  /// Web sidebar label
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get navSubscriptions;

  /// Web sidebar label
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// Web sidebar connection label
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get navServerStatus;

  /// Web sidebar button
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get navSignOut;

  /// Transaction type label
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get typeIncome;

  /// Transaction type label
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get typeExpense;

  /// Transaction type label
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get typeTransfer;

  /// Filter chip
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get typeAll;

  /// First-visit hint banner title
  ///
  /// In en, this message translates to:
  /// **'Welcome to BudgetSeal!'**
  String get dashboardWelcomeTitle;

  /// First-visit hint banner body
  ///
  /// In en, this message translates to:
  /// **'This is your financial overview. Tap the quick actions below to start recording transactions.'**
  String get dashboardWelcomeBody;

  /// Header subtitle
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get dashboardHouseholdLabel;

  /// Fallback household name
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal'**
  String get dashboardDefaultName;

  /// Customize button tooltip
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get dashboardCustomizeTooltip;

  /// Search button tooltip
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get dashboardSearchTooltip;

  /// Quick action button
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get dashboardQuickTransfer;

  /// Quick action button
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get dashboardQuickFund;

  /// Quick action button
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get dashboardQuickSplit;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Your Money'**
  String get dashboardSectionYourMoney;

  /// Unallocated label
  ///
  /// In en, this message translates to:
  /// **'Ready to assign'**
  String get dashboardReadyToAssign;

  /// Unallocated subtitle
  ///
  /// In en, this message translates to:
  /// **'Money not yet in an envelope'**
  String get dashboardMoneyNotInEnvelope;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get dashboardSectionActivity;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Quick Templates'**
  String get dashboardQuickTemplates;

  /// Link text
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get dashboardRecent;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get dashboardNoTransactionsYet;

  /// Nudge banner
  ///
  /// In en, this message translates to:
  /// **'No transactions today — tap + to add one'**
  String get dashboardNoTransactionsToday;

  /// Net worth subtitle
  ///
  /// In en, this message translates to:
  /// **'Total across all accounts'**
  String get dashboardTotalAcrossAccounts;

  /// Mini stat label
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get dashboardLabelExpenses;

  /// Mini stat label
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get dashboardLabelNet;

  /// Donut chart center
  ///
  /// In en, this message translates to:
  /// **'spent'**
  String get dashboardSpent;

  /// Empty donut placeholder
  ///
  /// In en, this message translates to:
  /// **'No spending'**
  String get dashboardNoSpending;

  /// Toggle label
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get dashboardLast7Days;

  /// Toggle label
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dashboardThisMonth;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Envelopes'**
  String get dashboardEnvelopes;

  /// Envelope health status
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get dashboardOnTrack;

  /// Envelope health status
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get dashboardRunningLow;

  /// Envelope health status
  ///
  /// In en, this message translates to:
  /// **'Overspent'**
  String get dashboardOverspent;

  /// Budget insights header
  ///
  /// In en, this message translates to:
  /// **'Heads up'**
  String get dashboardHeadsUp;

  /// Budget insight "{name} is {amount} over its limit"
  ///
  /// In en, this message translates to:
  /// **'is {amount} over its limit'**
  String dashboardIsOverLimit(String amount);

  /// Budget insight "{name} has only {percent}% left"
  ///
  /// In en, this message translates to:
  /// **'has only {percent}% left'**
  String dashboardHasPercentLeft(String percent);

  /// Status card (under budget)
  ///
  /// In en, this message translates to:
  /// **'{amount} left of {total} budget'**
  String dashboardBudgetLeftOf(String amount, String total);

  /// Status card (over budget)
  ///
  /// In en, this message translates to:
  /// **'{amount} over {total} budget'**
  String dashboardBudgetOver(String amount, String total);

  /// Velocity line
  ///
  /// In en, this message translates to:
  /// **'Spending {amount}/day · ~{projected} by month end'**
  String dashboardSpendingPerDay(String amount, String projected);

  /// Age of money (singular)
  ///
  /// In en, this message translates to:
  /// **'Money sits 1 day before being spent'**
  String get dashboardMoneySits1Day;

  /// Age of money (plural)
  ///
  /// In en, this message translates to:
  /// **'Money sits {n} days before being spent'**
  String dashboardMoneySitsNDays(int n);

  /// Info dialog title
  ///
  /// In en, this message translates to:
  /// **'Age of Money'**
  String get dashboardAgeOfMoneyTitle;

  /// Info dialog content
  ///
  /// In en, this message translates to:
  /// **'This shows how long money sits in your accounts before you spend it.\\n\\nThink of it as a buffer:\\n\\n• Under 14 days — you\'re spending money almost as fast as it comes in\\n• 14–30 days — you have a small cushion, getting ahead\\n• 30–60 days — you\'re spending last month\'s income. Great!\\n• 60+ days — strong financial health, big safety net\\n\\nThe goal is to increase this number over time. The higher it is, the more financially secure you are.'**
  String get dashboardAgeOfMoneyExplanation;

  /// Global search hint
  ///
  /// In en, this message translates to:
  /// **'Search transactions, accounts...'**
  String get dashboardSearchPlaceholder;

  /// Search hint
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters'**
  String get dashboardTypeAtLeast2;

  /// Search empty state
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String dashboardNoResultsFor(String query);

  /// Search section header
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get dashboardSearchAccounts;

  /// Search section header
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get dashboardSearchCategories;

  /// Search section header
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get dashboardSearchTransactions;

  /// Fallback category name
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get dashboardOtherCategory;

  /// Bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Customize Dashboard'**
  String get customizeTitle;

  /// Instructions text
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Toggle to show/hide sections.'**
  String get customizeInstructions;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Status Card'**
  String get dashboardSectionStatusLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Budget status, velocity, age of money'**
  String get dashboardSectionStatusDesc;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Spending Overview'**
  String get dashboardSectionSpendingLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Donut chart with category breakdown'**
  String get dashboardSectionSpendingDesc;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardSectionQuickLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Expense, income, transfer, fund'**
  String get dashboardSectionQuickDesc;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Your Money'**
  String get dashboardSectionMoneyLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Net worth and envelope health'**
  String get dashboardSectionMoneyDesc;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Ready to Assign'**
  String get dashboardSectionUnallocatedLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Unallocated funds'**
  String get dashboardSectionUnallocatedDesc;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get dashboardSectionActivityLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Templates and recent transactions'**
  String get dashboardSectionActivityDesc;

  /// Net worth label on dashboard money card
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get dashboardNetWorth;

  /// Unallocated label on dashboard money card
  ///
  /// In en, this message translates to:
  /// **'Unallocated'**
  String get dashboardUnallocated;

  /// Shows count of other currencies
  ///
  /// In en, this message translates to:
  /// **'+ {count} other'**
  String dashboardOtherCount(int count);

  /// Button text when no transactions exist
  ///
  /// In en, this message translates to:
  /// **'Add your first expense'**
  String get dashboardAddFirstExpense;

  /// Tooltip for Fund quick action
  ///
  /// In en, this message translates to:
  /// **'Fund envelopes'**
  String get dashboardFundEnvelopesTooltip;

  /// Tooltip for Split quick action
  ///
  /// In en, this message translates to:
  /// **'Split a bill'**
  String get dashboardSplitBillTooltip;

  /// Spending insight when a category is higher
  ///
  /// In en, this message translates to:
  /// **'{category} spending is {percent}% higher than last month'**
  String dashboardCatSpendingHigher(String category, int percent);

  /// Spending insight when overall spending is lower
  ///
  /// In en, this message translates to:
  /// **'Spending is {percent}% lower than last month — nice!'**
  String dashboardSpendingLowerNice(int percent);

  /// Spending insight when overall spending is higher
  ///
  /// In en, this message translates to:
  /// **'Spending is {percent}% higher than last month'**
  String dashboardSpendingHigher(int percent);

  /// Spending insight when spending is normal
  ///
  /// In en, this message translates to:
  /// **'Spending is on track this month'**
  String get dashboardSpendingOnTrack;

  /// Generic quick action tooltip
  ///
  /// In en, this message translates to:
  /// **'Add {label}'**
  String dashboardAddLabel(String label);

  /// Accessibility label for spending donut chart
  ///
  /// In en, this message translates to:
  /// **'Spending chart, total {amount}, {count} categories'**
  String dashboardChartSemantic(String amount, int count);

  /// Accessibility label when no spending
  ///
  /// In en, this message translates to:
  /// **'No spending this period'**
  String get dashboardNoSpendingSemantic;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get txTitle;

  /// Hint banner title
  ///
  /// In en, this message translates to:
  /// **'Your transactions'**
  String get txIntroTitle;

  /// Hint banner body
  ///
  /// In en, this message translates to:
  /// **'Your transactions appear here grouped by date. Swipe left to delete, right to edit. Long-press for more options.'**
  String get txIntroBody;

  /// Bulk delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete selected?'**
  String get txDeleteSelectedTitle;

  /// Bulk delete dialog
  ///
  /// In en, this message translates to:
  /// **'Delete {count} transaction(s)? This will reverse any envelope deductions.'**
  String txDeleteSelectedContent(int count);

  /// Snackbar after bulk delete
  ///
  /// In en, this message translates to:
  /// **'{count} transaction(s) deleted'**
  String txNDeleted(int count);

  /// Selection mode bar
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String txNSelected(int count);

  /// Selection delete tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get txDeleteSelectedTooltip;

  /// Search field hint
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get txSearchHint;

  /// Close search tooltip
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get txCloseSearch;

  /// Filter button tooltip
  ///
  /// In en, this message translates to:
  /// **'Filter transactions'**
  String get txFilterTooltip;

  /// Search button tooltip
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get txSearchTooltip;

  /// Settings button tooltip
  ///
  /// In en, this message translates to:
  /// **'List settings'**
  String get txListSettingsTooltip;

  /// Quick-add bar placeholder
  ///
  /// In en, this message translates to:
  /// **'Type name and amount, e.g. Coffee 4.50'**
  String get txQuickAddHint;

  /// Quick-add send tooltip
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get txSendTooltip;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get txScrollTopTooltip;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Split Bill'**
  String get txSplitBillTooltip;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get txAddTooltip;

  /// Date range filter
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get txFromDate;

  /// Date range filter
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get txToDate;

  /// Amount range hint
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get txMinAmount;

  /// Amount range hint
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get txMaxAmount;

  /// Filter clear link
  ///
  /// In en, this message translates to:
  /// **'Clear advanced filters'**
  String get txClearFilters;

  /// Year picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get txSelectYear;

  /// Category filter chip
  ///
  /// In en, this message translates to:
  /// **'Filtered: {categoryName}'**
  String txFilteredCategory(String categoryName);

  /// Empty state with category filter
  ///
  /// In en, this message translates to:
  /// **'No {categoryName} transactions in {monthLabel}'**
  String txNoCategoryInMonth(String categoryName, String monthLabel);

  /// Empty state with filters
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get txNoMatching;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get txNoYet;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap + to record one'**
  String get txTapPlus;

  /// Empty state button
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction'**
  String get txAddFirst;

  /// Budget progress bar
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {budget} budget'**
  String txSpentOfBudget(String spent, String budget);

  /// Footer summary
  ///
  /// In en, this message translates to:
  /// **'Total cash flow: {amount} · {count} transaction(s)'**
  String txTotalCashFlow(String amount, int count);

  /// Semantics hint
  ///
  /// In en, this message translates to:
  /// **'Long press for options'**
  String get txLongPressHint;

  /// Multi-line display
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String txNItems(int count);

  /// Multi-line suffix
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String txNMore(int count);

  /// Context menu
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get txContextEdit;

  /// Context menu
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get txContextDuplicate;

  /// Delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get txDeleteTitle;

  /// Delete dialog content
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get txDeleteCannotUndo;

  /// Swipe-to-delete title
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get txDeleteShort;

  /// Swipe-to-delete content
  ///
  /// In en, this message translates to:
  /// **'Delete {label}? This will reverse any envelope deductions.'**
  String txDeleteWithReversal(String label);

  /// Multi-account label
  ///
  /// In en, this message translates to:
  /// **'{count} accounts'**
  String txNAccounts(int count);

  /// AppBar title editing
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get txFormEditTitle;

  /// AppBar title creating
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get txFormNewTitle;

  /// Note field hint
  ///
  /// In en, this message translates to:
  /// **'Add a note…'**
  String get txFormNoteHint;

  /// Title field hint
  ///
  /// In en, this message translates to:
  /// **'Title (e.g. Coffee, Groceries)'**
  String get txFormTitleHint;

  /// Template button tooltip
  ///
  /// In en, this message translates to:
  /// **'Use Template'**
  String get txFormUseTemplate;

  /// Auto-fill label
  ///
  /// In en, this message translates to:
  /// **'Auto-detected'**
  String get txFormAutoDetected;

  /// No category label
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get txFormNoCategory;

  /// Transfer source hint
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get txFormFromAccount;

  /// Transfer dest hint
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get txFormToAccount;

  /// Transfer exchange label
  ///
  /// In en, this message translates to:
  /// **'Destination receives:'**
  String get txFormDestReceives;

  /// Add line item button
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get txFormAddItem;

  /// Total label for multi-line
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get txFormTotal;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Select a source account'**
  String get txFormSelectSource;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Select a destination account'**
  String get txFormSelectDest;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Source and destination must differ'**
  String get txFormSourceDestDiffer;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get txFormEnterAmount;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Select an account for item {n}'**
  String txFormSelectAccountItem(int n);

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Select an account for the transaction'**
  String get txFormSelectAccount;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Enter an amount for item {n}'**
  String txFormEnterAmountItem(int n);

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Enter an amount for the transaction'**
  String get txFormEnterAmountTx;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Exchange rate not set'**
  String get txFormRateNotSetTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Save anyway, or go back to set the rate?'**
  String get txFormRateNotSetContent;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Possible Duplicate'**
  String get txFormDuplicateTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'A similar transaction with the same amount, category, and date already exists. Save anyway?'**
  String get txFormDuplicateContent;

  /// Success snackbar
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get txFormSaved;

  /// Success with envelope
  ///
  /// In en, this message translates to:
  /// **'Transaction saved · {envelopeName} envelope updated'**
  String txFormSavedEnvelope(String envelopeName);

  /// Error snackbar
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String txFormErrorSaving(String error);

  /// Receipt indicator
  ///
  /// In en, this message translates to:
  /// **'Receipt attached'**
  String get txFormReceiptAttached;

  /// Multiple receipts
  ///
  /// In en, this message translates to:
  /// **'{count} receipts attached'**
  String txFormNReceipts(int count);

  /// Add receipts tooltip
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get txFormAddMore;

  /// Receipt button
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get txFormScanReceipt;

  /// Gallery button
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get txFormGallery;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get txDetailTitle;

  /// Error state
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get txDetailNotFound;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Copied {amount}'**
  String txDetailCopied(String amount);

  /// Detail label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txDetailDate;

  /// Detail label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get txDetailTime;

  /// Detail label (multi)
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get txDetailAccounts;

  /// Detail label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get txDetailNote;

  /// Fallback
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get txDetailUnknownAccount;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'SPLIT ITEMS ({count})'**
  String txDetailSplitItems(int count);

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'LINE DETAIL'**
  String get txDetailLineDetail;

  /// Fallback
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get txDetailUncategorized;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'RELATED TRANSACTION'**
  String get txDetailRelatedSingle;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'RELATED TRANSACTIONS'**
  String get txDetailRelatedPlural;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Receipts ({count})'**
  String txDetailReceipts(int count);

  /// Section header no items
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get txDetailReceipt;

  /// Attach link
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get txDetailAttach;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No receipt attached'**
  String get txDetailNoReceipt;

  /// Delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get txDetailDeleteTitle;

  /// Delete dialog content
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?\\n\\nThis will reverse any envelope deductions and restore the balance. Ledger entries will be removed.\\n\\nThis cannot be undone.'**
  String get txDetailDeleteContent;

  /// Back confirmation title
  ///
  /// In en, this message translates to:
  /// **'Discard transaction?'**
  String get txAfDiscardTitle;

  /// Back confirmation content
  ///
  /// In en, this message translates to:
  /// **'You have an unsaved transaction. Are you sure you want to go back?'**
  String get txAfDiscardContent;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get txAfKeepEditing;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get txAfDiscard;

  /// Step 1 title
  ///
  /// In en, this message translates to:
  /// **'Enter Title'**
  String get txAfEnterTitle;

  /// Transfer note hint
  ///
  /// In en, this message translates to:
  /// **'Note (e.g. rent, savings)'**
  String get txAfTransferNoteHint;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get txAfEnterAmountButton;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get txAfSelectCategoryButton;

  /// Popup title
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get txAfSelectCategoryTitle;

  /// Search hint
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get txAfSearchCategories;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get txAfNewCategory;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get txAfEnterAmountTitle;

  /// Account label (transfer)
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get txAfFromAccount;

  /// Account label (transfer)
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get txAfToAccount;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get txAfTapToSelect;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get txAfAddAccount;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate Required'**
  String get txAfExchangeRateRequired;

  /// Exchange rate prompt
  ///
  /// In en, this message translates to:
  /// **'How many {sourceCurrency} per 1 {destCurrency}?'**
  String txAfHowManyPer(String sourceCurrency, String destCurrency);

  /// Rate hint
  ///
  /// In en, this message translates to:
  /// **'Tap to enter rate'**
  String get txAfTapToEnterRate;

  /// Conversion preview
  ///
  /// In en, this message translates to:
  /// **'Recipient gets = {amount}'**
  String txAfRecipientGets(String amount);

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Fetching rate for {currency}...'**
  String txAfFetchingRate(String currency);

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Enter an amount for this item first'**
  String get txAfEnterAmountFirst;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Please select an account'**
  String get txAfPleaseSelectAccount;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Please select a destination account'**
  String get txAfPleaseSelectDest;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Mixed transaction'**
  String get txAfMixedTitle;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add another item'**
  String get txAfAddAnother;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save Transfer'**
  String get txAfSaveTransfer;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save {count} Items'**
  String txAfSaveNItems(int count);

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get txAfAddTransaction;

  /// New button
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get catSheetNew;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get catSheetNameHint;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get catSheetAdd;

  /// Empty search
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get catSheetNoMatching;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No categories yet.\\nTap \"New\" above to create one.'**
  String get catSheetNoYet;

  /// Parent subtitle
  ///
  /// In en, this message translates to:
  /// **'{count} subcategories'**
  String catSheetNSubcategories(int count);

  /// Currency sheet section header
  ///
  /// In en, this message translates to:
  /// **'YOUR ACCOUNTS'**
  String get currencyYourAccounts;

  /// Currency sheet section header
  ///
  /// In en, this message translates to:
  /// **'RECENTLY USED'**
  String get currencyRecentlyUsed;

  /// Currency sheet section header
  ///
  /// In en, this message translates to:
  /// **'ALL CURRENCIES'**
  String get currencyAll;

  /// Dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get txWidgetSelectAccount;

  /// Per-item note hint
  ///
  /// In en, this message translates to:
  /// **'Item note…'**
  String get txWidgetItemNote;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Transaction List'**
  String get txListTitle;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Select Layout'**
  String get txListSelectLayout;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Date Banner Total'**
  String get txListDateBanner;

  /// Dropdown option
  ///
  /// In en, this message translates to:
  /// **'Day Total'**
  String get txListDayTotal;

  /// Dropdown option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get txListNone;

  /// Setting title
  ///
  /// In en, this message translates to:
  /// **'Account Label'**
  String get txListAccountLabel;

  /// Setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Show account name on each transaction'**
  String get txListAccountSubtitle;

  /// Setting title
  ///
  /// In en, this message translates to:
  /// **'Category Icon'**
  String get txListCategoryIcon;

  /// Setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Show category icon circle'**
  String get txListCategorySubtitle;

  /// Setting title
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get txListTime;

  /// Setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Show time of the transaction'**
  String get txListTimeSubtitle;

  /// Preview placeholder
  ///
  /// In en, this message translates to:
  /// **'Transaction Name'**
  String get txListPreviewName;

  /// Preview note
  ///
  /// In en, this message translates to:
  /// **'This is a note that is part of the transaction.'**
  String get txListPreviewNote;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Bill Splitter'**
  String get billTitle;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Scanning receipt...'**
  String get billScanning;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get billScanTooltip;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'Add items to split'**
  String get billEmptyTitle;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Scan a receipt or add items manually'**
  String get billEmptySubtitle;

  /// Primary button
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get billScanButton;

  /// Secondary button
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get billAddManually;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get billAddItem;

  /// Image source
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get billTakePhoto;

  /// Image source
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get billFromGallery;

  /// OCR failure snackbar
  ///
  /// In en, this message translates to:
  /// **'No text detected. Try a clearer photo.'**
  String get billNoText;

  /// OCR amount dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get billEnterAmount;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Keep as one'**
  String get billKeepAsOne;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get billSplit;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'WHO\'S SPLITTING?'**
  String get billWhosSplitting;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get billAddPerson;

  /// Toggle title
  ///
  /// In en, this message translates to:
  /// **'Split evenly'**
  String get billSplitEvenly;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'ASSIGN ITEMS'**
  String get billAssignItems;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get billItemName;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get billTip;

  /// Tip trailing
  ///
  /// In en, this message translates to:
  /// **''**
  String get billTipNone;

  /// Tip mode
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get billPercentage;

  /// Tip field label
  ///
  /// In en, this message translates to:
  /// **'Tip amount'**
  String get billTipAmount;

  /// Currency label
  ///
  /// In en, this message translates to:
  /// **'Bill currency'**
  String get billBillCurrency;

  /// Rate field hint
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get billRateHint;

  /// Summary label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get billTotal;

  /// Re-scan button
  ///
  /// In en, this message translates to:
  /// **'Re-scan'**
  String get billReScan;

  /// OCR summary
  ///
  /// In en, this message translates to:
  /// **'{detected} lines ({withPrice} with prices)'**
  String billNLines(int detected, int withPrice);

  /// Default person name
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get billMe;

  /// Step instruction
  ///
  /// In en, this message translates to:
  /// **'Step 1: Add items from your receipt — scan or enter manually.'**
  String get billStep1Desc;

  /// Step instruction
  ///
  /// In en, this message translates to:
  /// **'Step 2: Add people and assign items. Toggle \"Split evenly\" to divide the total equally.'**
  String get billStep2Desc;

  /// Step instruction
  ///
  /// In en, this message translates to:
  /// **'Step 3: Review the split, add tip, and confirm.'**
  String get billStep3Desc;

  /// Currency indicator
  ///
  /// In en, this message translates to:
  /// **'Bill in {currency}'**
  String billBillIn(String currency);

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get billExchangeRateTitle;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove person'**
  String get billRemovePersonTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'{name} has {count} item(s) assigned only to them. Reassign to someone else, or delete those items?'**
  String billRemovePersonContent(String name, int count);

  /// Dialog label
  ///
  /// In en, this message translates to:
  /// **'Reassign to:'**
  String get billReassignTo;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Delete items'**
  String get billDeleteItems;

  /// Split evenly subtitle
  ///
  /// In en, this message translates to:
  /// **'Each person pays {amount}'**
  String billEachPays(String amount);

  /// Split quantity dialog title
  ///
  /// In en, this message translates to:
  /// **'{qty} × {name}'**
  String billSplitQtyTitle(int qty, String name);

  /// Split quantity dialog content
  ///
  /// In en, this message translates to:
  /// **'Split into {qty} items ({amount} each)?'**
  String billSplitQtyContent(int qty, String amount);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Exchange rate not set'**
  String get billRateNotSetTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Bill is in {currency} but no rate was entered.\nThe transaction will be saved without conversion.'**
  String billRateNotSetContent(String currency);

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get billGoBackBtn;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get billContinueAnyway;

  /// Error snackbar
  ///
  /// In en, this message translates to:
  /// **'Could not save transaction. Please try again.'**
  String get txFormCouldNotSave;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get txTransactionDeleted;

  /// Snackbar action
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get txUndoAction;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get txNewTransactionSheet;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Could not load transaction'**
  String get txCouldNotLoad;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This will create {count} linked transactions:\n\n{summary}\n\nThey will appear as separate transactions but linked together.'**
  String txAfMixedContent(int count, String summary);

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Add another item ({count} items · {total})'**
  String txAfAnotherWithCount(int count, String total);

  /// Rate not set dialog content
  ///
  /// In en, this message translates to:
  /// **'{items} has no exchange rate to {baseCurrency}. The amount won\'t be included in your base currency totals.\n\nSave anyway, or go back to set the rate?'**
  String txFormRateNotSetBody(String items, String baseCurrency);

  /// Duplicate dialog content
  ///
  /// In en, this message translates to:
  /// **'A similar transaction already exists:'**
  String get txFormDuplicateSimilarExists;

  /// Duplicate dialog prompt
  ///
  /// In en, this message translates to:
  /// **'Save anyway?'**
  String get txFormDuplicateSaveAnyway;

  /// Fallback title for duplicate detection
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get txFormNoTitle;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get allocTitle;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Search envelopes'**
  String get allocSearchTooltip;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'How envelopes work'**
  String get allocHelpTooltip;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'How Envelopes Work'**
  String get allocHelpTitle;

  /// Help step
  ///
  /// In en, this message translates to:
  /// **'Create envelopes for each spending category'**
  String get allocHelpStep1;

  /// Help step
  ///
  /// In en, this message translates to:
  /// **'Set a monthly budget target for each'**
  String get allocHelpStep2;

  /// Help step
  ///
  /// In en, this message translates to:
  /// **'Fund envelopes when you get paid'**
  String get allocHelpStep3;

  /// Help step
  ///
  /// In en, this message translates to:
  /// **'Spend from envelopes — track what\'s left'**
  String get allocHelpStep4;

  /// Search hint
  ///
  /// In en, this message translates to:
  /// **'Search envelopes...'**
  String get allocSearchHint;

  /// Banner title
  ///
  /// In en, this message translates to:
  /// **'New period started'**
  String get allocNewPeriodStarted;

  /// Banner subtitle
  ///
  /// In en, this message translates to:
  /// **'{count} envelope(s) need review'**
  String allocNNeedReview(int count);

  /// Banner button
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get allocReview;

  /// Summary label
  ///
  /// In en, this message translates to:
  /// **'Budgeted'**
  String get allocBudgeted;

  /// Summary label
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get allocSpent;

  /// Summary label
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get allocRemaining;

  /// Banner label
  ///
  /// In en, this message translates to:
  /// **'Unallocated'**
  String get allocUnallocated;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Fund Envelopes'**
  String get allocFundEnvelopes;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get allocSectionSpending;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get allocSectionSavings;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get allocSectionFlexible;

  /// No description provided for @allocNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No envelopes match \"{query}\"'**
  String allocNoMatch(String query);

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Create envelope'**
  String get allocCreateTooltip;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No envelopes yet'**
  String get allocNoYet;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create an envelope to start budgeting.\nTap ? for help.'**
  String get allocCreateHelp;

  /// Empty state button
  ///
  /// In en, this message translates to:
  /// **'Create Envelope'**
  String get allocCreateButton;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'New Envelope'**
  String get allocNewEnvelope;

  /// Fallback name
  ///
  /// In en, this message translates to:
  /// **'Envelope'**
  String get allocFallbackName;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Edit Settings'**
  String get allocEditSettings;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get allocWithdrawMenu;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Revalue Balances'**
  String get allocRevalueMenu;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get allocArchiveMenu;

  /// Bottom button
  ///
  /// In en, this message translates to:
  /// **'Create Envelope'**
  String get allocCreateButtonDetail;

  /// Bottom button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get allocSaveChanges;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'NAME & ICON'**
  String get allocNameIconSection;

  /// TextField hint
  ///
  /// In en, this message translates to:
  /// **'Envelope name (e.g. Groceries)'**
  String get allocNameHint;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Remove icon'**
  String get allocRemoveIcon;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'ENVELOPE TYPE'**
  String get allocTypeSection;

  /// Type option
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get allocSpendingTitle;

  /// Type description
  ///
  /// In en, this message translates to:
  /// **'For recurring expenses like groceries or fuel. Set a monthly budget and spend from it.'**
  String get allocSpendingDesc;

  /// Type option
  ///
  /// In en, this message translates to:
  /// **'Saving (with goal)'**
  String get allocSavingGoalTitle;

  /// Type description
  ///
  /// In en, this message translates to:
  /// **'For a specific goal like taxes or vacation. Set a target and fund it over time.'**
  String get allocSavingGoalDesc;

  /// Type option
  ///
  /// In en, this message translates to:
  /// **'Saving (open)'**
  String get allocSavingOpenTitle;

  /// Type description
  ///
  /// In en, this message translates to:
  /// **'For general savings with no specific goal. Put money aside whenever you can.'**
  String get allocSavingOpenDesc;

  /// Info text
  ///
  /// In en, this message translates to:
  /// **'Envelopes don\'t move money between accounts. They help you plan how to use the money you already have.'**
  String get allocInfoBanner;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'PURPOSE'**
  String get allocPurposeSection;

  /// Chip label
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get allocSaving;

  /// Chip label
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get allocFlexible;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'CYCLE'**
  String get allocCycleSection;

  /// Help text
  ///
  /// In en, this message translates to:
  /// **'• Periodic: resets each month (e.g. groceries budget)\\n• Permanent: accumulates over time (e.g. emergency fund)'**
  String get allocPeriodicDesc;

  /// Chip label
  ///
  /// In en, this message translates to:
  /// **'Periodic'**
  String get allocPeriodic;

  /// Chip label
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get allocPermanent;

  /// Switch title
  ///
  /// In en, this message translates to:
  /// **'Rollover balance'**
  String get allocRolloverTitle;

  /// Switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Carry remaining funds to the next period'**
  String get allocRolloverSubtitle;

  /// Switch title
  ///
  /// In en, this message translates to:
  /// **'Auto-reset'**
  String get allocAutoResetTitle;

  /// Switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Reset automatically at period start'**
  String get allocAutoResetSubtitle;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'SAVINGS TARGET'**
  String get allocSavingsTargetSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'MONTHLY BUDGET'**
  String get allocMonthlyBudgetSection;

  /// Help text
  ///
  /// In en, this message translates to:
  /// **'How much do you want to save in this envelope?'**
  String get allocSavingsTargetHelp;

  /// Help text
  ///
  /// In en, this message translates to:
  /// **'How much do you want to spend in this envelope each month?'**
  String get allocMonthlyBudgetHelp;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get allocTargetAmount;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Budget amount'**
  String get allocBudgetAmount;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'LINKED CATEGORIES'**
  String get allocLinkedCategories;

  /// Help text
  ///
  /// In en, this message translates to:
  /// **'Expenses with these categories will debit this envelope.'**
  String get allocLinkedHelp;

  /// Warning banner
  ///
  /// In en, this message translates to:
  /// **'No categories linked. Tap + to link categories so expenses debit this envelope.'**
  String get allocNoCategoriesWarning;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Link Category'**
  String get allocLinkCategory;

  /// Balance hero label (savings)
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get allocSavedLabel;

  /// Balance hero label (spending)
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get allocAvailableLabel;

  /// Progress bar suffix
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get allocLeftSuffix;

  /// Fund sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'From your unallocated balance'**
  String get allocFromUnallocated;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Over-funding'**
  String get allocOverfundingTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Your unallocated balance will go negative. Continue anyway?'**
  String get allocOverfundingMsg;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Fund Anyway'**
  String get allocFundAnyway;

  /// Error snackbar
  ///
  /// In en, this message translates to:
  /// **'Could not fund: {error}'**
  String allocCouldNotFund(String error);

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'RECENT ACTIVITY'**
  String get allocRecentActivity;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get allocNoActivity;

  /// Ledger type
  ///
  /// In en, this message translates to:
  /// **'Funded'**
  String get allocLedgerFunded;

  /// Ledger type
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get allocLedgerSpent;

  /// Ledger type
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get allocLedgerAdjustment;

  /// Ledger type
  ///
  /// In en, this message translates to:
  /// **'Period Reset'**
  String get allocLedgerPeriodReset;

  /// Ledger type
  ///
  /// In en, this message translates to:
  /// **'Carried Forward'**
  String get allocLedgerCarried;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'SPENDING HISTORY'**
  String get allocSpendingHistory;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Withdraw from Savings'**
  String get allocWithdrawTitle;

  /// Sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Move money from this envelope back to Unallocated.'**
  String get allocWithdrawHelp;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Amount to withdraw'**
  String get allocWithdrawAmount;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get allocWithdrawButton;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'All categories are already linked to envelopes'**
  String get allocAllLinked;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Link a Category'**
  String get allocLinkTitle;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'No foreign-currency balances to revalue'**
  String get allocNoForeignBalances;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Revalue Foreign Balances'**
  String get allocRevalueTitle;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'balance in this envelope'**
  String get allocBalanceInEnvelope;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Original rate'**
  String get allocOriginalRate;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Original value'**
  String get allocOriginalValue;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'New rate'**
  String get allocNewRate;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get allocFetchButton;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'New value'**
  String get allocNewValue;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get allocGain;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get allocLoss;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Total adjustment'**
  String get allocTotalAdjustment;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Apply Revaluation'**
  String get allocApplyRevaluation;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Revaluation applied'**
  String get allocRevaluationApplied;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Archive Envelope'**
  String get allocArchiveTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This envelope will be hidden from all lists. Linked categories and transaction history will be preserved.\\n\\nYou can unarchive it later from Settings.'**
  String get allocArchiveMsg;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Envelope archived'**
  String get allocArchived;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Envelope'**
  String get allocDeleteTitle;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Archive Instead'**
  String get allocArchiveInstead;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get allocDeletePermanently;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Envelope Permanently'**
  String get allocDeleteNoLinkedTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This envelope has no linked categories. All ledger history will be removed.\\n\\nAre you sure? This cannot be undone.'**
  String get allocDeleteNoLinkedMsg;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Envelope created'**
  String get allocCreated;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Envelope updated'**
  String get allocUpdated;

  /// Allocation card prefix
  ///
  /// In en, this message translates to:
  /// **'Saved:'**
  String get allocSavedPrefix;

  /// Progress text
  ///
  /// In en, this message translates to:
  /// **'{pct}% saved'**
  String allocPercentSaved(double pct);

  /// No description provided for @allocFlexibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get allocFlexibleTitle;

  /// No description provided for @allocFlexibleDesc.
  ///
  /// In en, this message translates to:
  /// **'For anything else — set an optional target or leave it open. Accumulates over time.'**
  String get allocFlexibleDesc;

  /// No description provided for @allocCycleHelp.
  ///
  /// In en, this message translates to:
  /// **'• Periodic: resets each month (e.g. groceries budget)\n• Permanent: accumulates over time (e.g. emergency fund)'**
  String get allocCycleHelp;

  /// No description provided for @allocRolloverBalance.
  ///
  /// In en, this message translates to:
  /// **'Rollover balance'**
  String get allocRolloverBalance;

  /// No description provided for @allocRolloverDesc.
  ///
  /// In en, this message translates to:
  /// **'Carry remaining funds to the next period'**
  String get allocRolloverDesc;

  /// No description provided for @allocAutoReset.
  ///
  /// In en, this message translates to:
  /// **'Auto-reset'**
  String get allocAutoReset;

  /// No description provided for @allocAutoResetDesc.
  ///
  /// In en, this message translates to:
  /// **'Reset automatically at period start'**
  String get allocAutoResetDesc;

  /// No description provided for @allocMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY BUDGET'**
  String get allocMonthlyBudget;

  /// No description provided for @allocTargetOptional.
  ///
  /// In en, this message translates to:
  /// **'TARGET (OPTIONAL)'**
  String get allocTargetOptional;

  /// No description provided for @allocMonthlyBudgetDesc.
  ///
  /// In en, this message translates to:
  /// **'How much do you want to spend in this envelope each month?'**
  String get allocMonthlyBudgetDesc;

  /// No description provided for @allocTargetDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a target amount, or leave at zero for open-ended.'**
  String get allocTargetDesc;

  /// No description provided for @allocLinkedCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'LINKED CATEGORIES'**
  String get allocLinkedCategoriesSection;

  /// No description provided for @allocLinkedCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Expenses with these categories will debit this envelope.'**
  String get allocLinkedCategoriesDesc;

  /// No description provided for @allocNoCategoriesLinked.
  ///
  /// In en, this message translates to:
  /// **'No categories linked. Tap + to link categories so expenses debit this envelope.'**
  String get allocNoCategoriesLinked;

  /// No description provided for @allocAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get allocAvailable;

  /// No description provided for @allocPercentOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of {target}'**
  String allocPercentOfTarget(int percent, String target);

  /// No description provided for @allocAmountLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String allocAmountLeft(String amount);

  /// No description provided for @allocFund.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get allocFund;

  /// No description provided for @allocFundEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Fund {name}'**
  String allocFundEnvelope(String name);

  /// No description provided for @allocOverFundingTitle.
  ///
  /// In en, this message translates to:
  /// **'Over-funding'**
  String get allocOverFundingTitle;

  /// No description provided for @allocOverFundingMsg.
  ///
  /// In en, this message translates to:
  /// **'You\'re assigning {deficit} more than your available {available} unallocated balance.\n\nYour unallocated balance will go negative. Continue anyway?'**
  String allocOverFundingMsg(String deficit, String available);

  /// No description provided for @allocFundedNote.
  ///
  /// In en, this message translates to:
  /// **'Funded from Unallocated'**
  String get allocFundedNote;

  /// No description provided for @allocFundedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Funded {amount} to {name}'**
  String allocFundedSuccess(String amount, String name);

  /// No description provided for @allocFundError.
  ///
  /// In en, this message translates to:
  /// **'Could not fund envelope. Please try again.'**
  String get allocFundError;

  /// No description provided for @allocEntryFunded.
  ///
  /// In en, this message translates to:
  /// **'Funded'**
  String get allocEntryFunded;

  /// No description provided for @allocEntrySpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get allocEntrySpent;

  /// No description provided for @allocEntryAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get allocEntryAdjustment;

  /// No description provided for @allocEntryPeriodReset.
  ///
  /// In en, this message translates to:
  /// **'Period Reset'**
  String get allocEntryPeriodReset;

  /// No description provided for @allocEntryCarryForward.
  ///
  /// In en, this message translates to:
  /// **'Carried Forward'**
  String get allocEntryCarryForward;

  /// No description provided for @allocWithdrawDesc.
  ///
  /// In en, this message translates to:
  /// **'Move money from this envelope back to Unallocated.'**
  String get allocWithdrawDesc;

  /// No description provided for @allocWithdrawAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to withdraw'**
  String get allocWithdrawAmountLabel;

  /// No description provided for @allocWithdrawSuccess.
  ///
  /// In en, this message translates to:
  /// **'Withdrew {amount} to Unallocated'**
  String allocWithdrawSuccess(String amount);

  /// No description provided for @allocLinkCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Link a Category'**
  String get allocLinkCategoryTitle;

  /// No description provided for @allocSearchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get allocSearchCategories;

  /// No description provided for @allocNoMatchingCategories.
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get allocNoMatchingCategories;

  /// No description provided for @allocAllCategoriesLinked.
  ///
  /// In en, this message translates to:
  /// **'All categories are already linked to envelopes'**
  String get allocAllCategoriesLinked;

  /// No description provided for @allocRevalueForeignTitle.
  ///
  /// In en, this message translates to:
  /// **'Revalue Foreign Balances'**
  String get allocRevalueForeignTitle;

  /// No description provided for @allocFetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get allocFetch;

  /// No description provided for @allocRevalApplied.
  ///
  /// In en, this message translates to:
  /// **'Revaluation applied'**
  String get allocRevalApplied;

  /// No description provided for @allocRevalError.
  ///
  /// In en, this message translates to:
  /// **'Could not apply revaluation. Please try again.'**
  String get allocRevalError;

  /// No description provided for @allocFetchRateError.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch rate for {currency}'**
  String allocFetchRateError(String currency);

  /// No description provided for @allocDeleteLinkedWarning.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 category is} other{{count} categories are}} linked to this envelope ({names})'**
  String allocDeleteLinkedWarning(int count, String names);

  /// No description provided for @allocDeleteAndMore.
  ///
  /// In en, this message translates to:
  /// **' and {count} more'**
  String allocDeleteAndMore(int count);

  /// No description provided for @allocDeleteConsequences.
  ///
  /// In en, this message translates to:
  /// **'Deleting will:\n  • Unlink all categories from this envelope\n  • Remove all ledger history for this envelope\n\nConsider archiving instead to preserve history.'**
  String get allocDeleteConsequences;

  /// No description provided for @allocDeleteNoLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Envelope Permanently'**
  String get allocDeleteNoLinksTitle;

  /// No description provided for @allocDeleteNoLinksMsg.
  ///
  /// In en, this message translates to:
  /// **'This envelope has no linked categories. All ledger history will be removed.\n\nAre you sure? This cannot be undone.'**
  String get allocDeleteNoLinksMsg;

  /// No description provided for @allocDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete. Please try again.'**
  String get allocDeleteError;

  /// No description provided for @allocEnvelopeCreated.
  ///
  /// In en, this message translates to:
  /// **'Envelope created'**
  String get allocEnvelopeCreated;

  /// No description provided for @allocEnvelopeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Envelope updated'**
  String get allocEnvelopeUpdated;

  /// No description provided for @allocGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get allocGotIt;

  /// No description provided for @allocBaseCurrencyOnly.
  ///
  /// In en, this message translates to:
  /// **'{currency} envelopes only · {count} in other currencies'**
  String allocBaseCurrencyOnly(String currency, int count);

  /// No description provided for @allocHideOtherCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Hide other currencies'**
  String get allocHideOtherCurrencies;

  /// No description provided for @allocOtherCurrencies.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{+ 1 other currency} other{+ {count} other currencies}}'**
  String allocOtherCurrencies(int count);

  /// No description provided for @allocGoalsLoans.
  ///
  /// In en, this message translates to:
  /// **'Goals & Loans'**
  String get allocGoalsLoans;

  /// No description provided for @allocGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 goal} other{{count} goals}}'**
  String allocGoalsCount(int count);

  /// No description provided for @allocLoansCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 loan} other{{count} loans}}'**
  String allocLoansCount(int count);

  /// No description provided for @allocNEnvelopesNeedReset.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 envelope needs reset} other{{count} envelopes need reset}}'**
  String allocNEnvelopesNeedReset(int count);

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Fund Envelopes'**
  String get fundTitle;

  /// Error retry
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load envelopes'**
  String get fundError;

  /// No description provided for @fundCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load envelopes'**
  String get fundCouldntLoad;

  /// No description provided for @fundNoAllocations.
  ///
  /// In en, this message translates to:
  /// **'No allocations to fund.\nCreate allocations first.'**
  String get fundNoAllocations;

  /// No description provided for @fundHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How does funding work?'**
  String get fundHowTitle;

  /// No description provided for @fundStep1.
  ///
  /// In en, this message translates to:
  /// **'Check your unallocated balance — this is money you haven\'t assigned to any envelope yet.'**
  String get fundStep1;

  /// No description provided for @fundStep2.
  ///
  /// In en, this message translates to:
  /// **'Enter how much to put in each envelope, or use \"Quick Fill\" to auto-fill periodic envelopes up to their target.'**
  String get fundStep2;

  /// No description provided for @fundStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Fund All\" to move the money into your envelopes.'**
  String get fundStep3;

  /// No description provided for @fundAvailableToDistribute.
  ///
  /// In en, this message translates to:
  /// **'Available to distribute'**
  String get fundAvailableToDistribute;

  /// No description provided for @fundExceedsWarning.
  ///
  /// In en, this message translates to:
  /// **'Total exceeds available unallocated funds'**
  String get fundExceedsWarning;

  /// No description provided for @fundQuickFill.
  ///
  /// In en, this message translates to:
  /// **'Quick Fill'**
  String get fundQuickFill;

  /// No description provided for @fundQuickFillDesc.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{Auto-fill 1 periodic envelope up to its target} other{Auto-fill {count} periodic envelopes up to their target}}'**
  String fundQuickFillDesc(int count);

  /// No description provided for @fundAllAtTarget.
  ///
  /// In en, this message translates to:
  /// **'All periodic envelopes are at their target'**
  String get fundAllAtTarget;

  /// No description provided for @fundFunded.
  ///
  /// In en, this message translates to:
  /// **'Funded'**
  String get fundFunded;

  /// No description provided for @fundBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String fundBalance(String amount);

  /// No description provided for @fundFill.
  ///
  /// In en, this message translates to:
  /// **'Fill {amount}'**
  String fundFill(String amount);

  /// No description provided for @fundEnterAmounts.
  ///
  /// In en, this message translates to:
  /// **'Enter amounts to fund'**
  String get fundEnterAmounts;

  /// No description provided for @fundAllWithTotal.
  ///
  /// In en, this message translates to:
  /// **'Fund All  ({total})'**
  String fundAllWithTotal(String total);

  /// Warning dialog title
  ///
  /// In en, this message translates to:
  /// **'Over-funding'**
  String get fundOverfundingTitle;

  /// Warning dialog content
  ///
  /// In en, this message translates to:
  /// **'You\'re assigning {details}. Your unallocated balance will go negative.\\n\\nContinue anyway?'**
  String fundOverfundingMsg(String details);

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Fund Anyway'**
  String get fundAnyway;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Funded from Unallocated'**
  String get fundNote;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Allocations funded successfully'**
  String get fundSuccess;

  /// Error snackbar
  ///
  /// In en, this message translates to:
  /// **'Error funding allocations: {error}'**
  String fundErrorMsg(String error);

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get acctTitle;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get acctNoYet;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get acctTapPlus;

  /// Card header
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get acctTotalBalance;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get acctAddTooltip;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get acctNewTitle;

  /// Type option
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get acctTypeCash;

  /// Type option
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get acctTypeBank;

  /// Type option
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get acctTypeCredit;

  /// Type option
  ///
  /// In en, this message translates to:
  /// **'Digital wallet'**
  String get acctTypeDigital;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Adjust Balance'**
  String get acctAdjustBalance;

  /// No description provided for @acctHideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide Archived'**
  String get acctHideArchived;

  /// No description provided for @acctShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show Archived'**
  String get acctShowArchived;

  /// No description provided for @acctSortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get acctSortByName;

  /// No description provided for @acctSortByBalance.
  ///
  /// In en, this message translates to:
  /// **'Sort by balance'**
  String get acctSortByBalance;

  /// No description provided for @acctSortByType.
  ///
  /// In en, this message translates to:
  /// **'Sort by type'**
  String get acctSortByType;

  /// No description provided for @acctTravelWallet.
  ///
  /// In en, this message translates to:
  /// **'Travel wallet · {currency}'**
  String acctTravelWallet(String currency);

  /// No description provided for @acctArchived.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVED'**
  String get acctArchived;

  /// No description provided for @acctNoArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived accounts'**
  String get acctNoArchived;

  /// No description provided for @acctUnarchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Unarchive Account'**
  String get acctUnarchiveTitle;

  /// No description provided for @acctUnarchiveMsg.
  ///
  /// In en, this message translates to:
  /// **'Restore \"{name}\" to your active accounts?'**
  String acctUnarchiveMsg(String name);

  /// No description provided for @acctUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get acctUnarchive;

  /// No description provided for @acctUnarchived.
  ///
  /// In en, this message translates to:
  /// **'{name} unarchived'**
  String acctUnarchived(String name);

  /// No description provided for @acctCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get acctCurrentBalance;

  /// No description provided for @acctBackFromTrip.
  ///
  /// In en, this message translates to:
  /// **'Back from your trip?'**
  String get acctBackFromTrip;

  /// No description provided for @acctConvertBackDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert your remaining {currency} balance back and close this travel wallet.'**
  String acctConvertBackDesc(String currency);

  /// No description provided for @acctConvertBackClose.
  ///
  /// In en, this message translates to:
  /// **'Convert Back & Close'**
  String get acctConvertBackClose;

  /// No description provided for @acctSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get acctSettings;

  /// No description provided for @acctNameSection.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get acctNameSection;

  /// No description provided for @acctAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get acctAccountName;

  /// No description provided for @acctTypeSection.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get acctTypeSection;

  /// No description provided for @acctCurrencySection.
  ///
  /// In en, this message translates to:
  /// **'CURRENCY'**
  String get acctCurrencySection;

  /// No description provided for @acctSelectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select currency'**
  String get acctSelectCurrency;

  /// No description provided for @acctDecimalSection.
  ///
  /// In en, this message translates to:
  /// **'DECIMAL PLACES'**
  String get acctDecimalSection;

  /// No description provided for @acctDecimalAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto ({count})'**
  String acctDecimalAuto(int count);

  /// No description provided for @acctOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'OPENING BALANCE'**
  String get acctOpeningBalance;

  /// No description provided for @acctCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get acctCreateAccount;

  /// No description provided for @acctRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'RECENT TRANSACTIONS'**
  String get acctRecentTransactions;

  /// No description provided for @acctNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get acctNoTransactions;

  /// No description provided for @acctAdjustDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the actual balance of this account. An adjustment transaction will be created for the difference.'**
  String get acctAdjustDesc;

  /// No description provided for @acctCurrentBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current balance: {amount}'**
  String acctCurrentBalanceLabel(String amount);

  /// No description provided for @acctActualBalance.
  ///
  /// In en, this message translates to:
  /// **'Actual balance'**
  String get acctActualBalance;

  /// No description provided for @acctEnterRealBalance.
  ///
  /// In en, this message translates to:
  /// **'Enter the real balance'**
  String get acctEnterRealBalance;

  /// No description provided for @acctApplyAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Apply Adjustment'**
  String get acctApplyAdjustment;

  /// No description provided for @acctBalanceAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Balance adjustment'**
  String get acctBalanceAdjustment;

  /// No description provided for @acctBalanceAdjustedBy.
  ///
  /// In en, this message translates to:
  /// **'Balance adjusted by {amount}'**
  String acctBalanceAdjustedBy(String amount);

  /// No description provided for @acctConvertBack.
  ///
  /// In en, this message translates to:
  /// **'Convert Back'**
  String get acctConvertBack;

  /// No description provided for @acctConvertBackMsg.
  ///
  /// In en, this message translates to:
  /// **'Convert {amount} back to your account'**
  String acctConvertBackMsg(String amount);

  /// No description provided for @acctTransferTo.
  ///
  /// In en, this message translates to:
  /// **'Transfer to'**
  String get acctTransferTo;

  /// No description provided for @acctAmountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get acctAmountReceived;

  /// No description provided for @acctConvertArchive.
  ///
  /// In en, this message translates to:
  /// **'Convert & Archive'**
  String get acctConvertArchive;

  /// No description provided for @acctNoTransferTarget.
  ///
  /// In en, this message translates to:
  /// **'No account to transfer to'**
  String get acctNoTransferTarget;

  /// No description provided for @acctConvertedBack.
  ///
  /// In en, this message translates to:
  /// **'Converted back {amount} and archived'**
  String acctConvertedBack(String amount);

  /// No description provided for @acctSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get acctSomethingWrong;

  /// No description provided for @acctArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Account'**
  String get acctArchiveTitle;

  /// No description provided for @acctArchiveMsg.
  ///
  /// In en, this message translates to:
  /// **'This account will be hidden from all lists and dropdowns. Your transactions will be preserved.\n\nYou can unarchive it later from Settings.'**
  String get acctArchiveMsg;

  /// No description provided for @acctCannotDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete Account'**
  String get acctCannotDeleteTitle;

  /// No description provided for @acctCannotDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'This account has {count} transaction reference{count,plural, =1{} other{s}}. You can\'t delete it while it has transactions.\n\nWould you like to archive it instead? Archived accounts are hidden from lists but preserve all transaction history.'**
  String acctCannotDeleteMsg(int count);

  /// No description provided for @acctDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Permanently'**
  String get acctDeleteTitle;

  /// No description provided for @acctDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'This account has no transactions. Are you sure you want to permanently delete it? This cannot be undone.'**
  String get acctDeleteMsg;

  /// No description provided for @acctArchiveInstead.
  ///
  /// In en, this message translates to:
  /// **'Archive Instead'**
  String get acctArchiveInstead;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get catTitle;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get catAddTooltip;

  /// No description provided for @catTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String catTotal(int count);

  /// No description provided for @catExpenseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} expense'**
  String catExpenseCount(int count);

  /// No description provided for @catIncomeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} income'**
  String catIncomeCount(int count);

  /// No description provided for @catSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get catSearchHint;

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;

  /// No description provided for @catNoYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get catNoYet;

  /// No description provided for @catTapPlus.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create one'**
  String get catTapPlus;

  /// No description provided for @catNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get catNoMatch;

  /// No description provided for @catCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load categories'**
  String get catCouldntLoad;

  /// No description provided for @catSubcategories.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 subcategory} other{{count} subcategories}}'**
  String catSubcategories(int count);

  /// No description provided for @catSectionExpense.
  ///
  /// In en, this message translates to:
  /// **'EXPENSE'**
  String get catSectionExpense;

  /// No description provided for @catSectionIncome.
  ///
  /// In en, this message translates to:
  /// **'INCOME'**
  String get catSectionIncome;

  /// No description provided for @catEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get catEdit;

  /// No description provided for @catArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get catArchive;

  /// No description provided for @catUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get catUnarchive;

  /// No description provided for @catRestored.
  ///
  /// In en, this message translates to:
  /// **'Category restored'**
  String get catRestored;

  /// No description provided for @catArchived.
  ///
  /// In en, this message translates to:
  /// **'Category archived'**
  String get catArchived;

  /// No description provided for @catDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get catDeleteTitle;

  /// No description provided for @catDeleteNoTx.
  ///
  /// In en, this message translates to:
  /// **'This category has no transactions. Delete permanently?'**
  String get catDeleteNoTx;

  /// No description provided for @catDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get catDeleted;

  /// No description provided for @catNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get catNewTitle;

  /// No description provided for @catEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get catEditTitle;

  /// No description provided for @catName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catName;

  /// No description provided for @catParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get catParent;

  /// No description provided for @catNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get catNone;

  /// No description provided for @catCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get catCreate;

  /// No description provided for @catEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a category name'**
  String get catEnterName;

  /// No description provided for @catCreated.
  ///
  /// In en, this message translates to:
  /// **'Category created'**
  String get catCreated;

  /// No description provided for @catUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get catUpdated;

  /// No description provided for @commonArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get commonArchive;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Add recurring transaction'**
  String get recurringAddTooltip;

  /// Frequency label
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get freqDaily;

  /// Frequency label
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// Frequency label
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// Frequency label
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get freqYearly;

  /// Frequency (interval)
  ///
  /// In en, this message translates to:
  /// **'Every {n} days'**
  String freqEveryNDays(int n);

  /// Frequency (interval)
  ///
  /// In en, this message translates to:
  /// **'Every {n} weeks'**
  String freqEveryNWeeks(int n);

  /// Frequency (interval)
  ///
  /// In en, this message translates to:
  /// **'Every {n} months'**
  String freqEveryNMonths(int n);

  /// Frequency (interval)
  ///
  /// In en, this message translates to:
  /// **'Every {n} years'**
  String freqEveryNYears(int n);

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Bill Calendar'**
  String get billCalTitle;

  /// Day sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'{count} bill(s) due'**
  String billCalNDue(int count);

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get billCalUpcoming;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No upcoming bills'**
  String get billCalNoUpcoming;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get upcomingTitle;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No upcoming bills'**
  String get upcomingNoTitle;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create recurring transactions to see them here.'**
  String get upcomingNoSubtitle;

  /// Urgency label
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} day(s)'**
  String upcomingOverdue(int days);

  /// Urgency label
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get upcomingDueToday;

  /// Urgency label
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get upcomingDueTomorrow;

  /// Urgency label
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String upcomingDueInDays(int days);

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subTitle;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get subAddTooltip;

  /// Chip subtitle
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get subTotal;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subActive;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subCancelled;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No subscriptions'**
  String get subNoTitle;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Add a recurring transaction and mark it as a subscription'**
  String get subNoSubtitle;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Ending soon'**
  String get subEndingSoon;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get subPause;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get subResume;

  /// Fallback title
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get subUntitled;

  /// Error state
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription'**
  String get subDetailError;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'Subscription not found'**
  String get subDetailNotFound;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Annual cost: {amount}'**
  String subDetailAnnualCost(String amount);

  /// Detail label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get subDetailStatus;

  /// Detail label
  ///
  /// In en, this message translates to:
  /// **'Active since'**
  String get subDetailActiveSince;

  /// Detail label
  ///
  /// In en, this message translates to:
  /// **'Next billing'**
  String get subDetailNextBilling;

  /// Detail label
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get subDetailEndsOn;

  /// Detail label
  ///
  /// In en, this message translates to:
  /// **'Total paid (est.)'**
  String get subDetailTotalPaid;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'PRICE HISTORY'**
  String get subDetailPriceHistory;

  /// Date suffix
  ///
  /// In en, this message translates to:
  /// **'present'**
  String get subDetailPresent;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Change Cancel Date'**
  String get subDetailChangeCancel;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Set Cancellation Date'**
  String get subDetailSetCancel;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'PAST TRANSACTIONS'**
  String get subDetailPastTx;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get subDetailUpcoming;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'scheduled'**
  String get subDetailScheduled;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get subDetailCancelTitle;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get tmplTitle;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get tmplSortTooltip;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get tmplGroupTooltip;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Most used'**
  String get tmplSortMostUsed;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get tmplSortAz;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get tmplSortNewest;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Highest amount'**
  String get tmplSortHighest;

  /// Group option
  ///
  /// In en, this message translates to:
  /// **'No grouping'**
  String get tmplGroupNone;

  /// Group option
  ///
  /// In en, this message translates to:
  /// **'By type'**
  String get tmplGroupType;

  /// Group option
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get tmplGroupCategory;

  /// Search hint
  ///
  /// In en, this message translates to:
  /// **'Search templates...'**
  String get tmplSearchHint;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No templates found'**
  String get tmplNoTitle;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Save frequent transactions for quick re-use'**
  String get tmplNoSubtitle;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Add template'**
  String get tmplAddTooltip;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Use template'**
  String get tmplUse;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete template?'**
  String get tmplDeleteTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This template will be permanently removed.'**
  String get tmplDeleteMsg;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get tmplNewTitle;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Save a transaction you do often for quick re-use.'**
  String get tmplNewDesc;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get tmplTitleRequired;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get tmplCategoryOptional;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save Template'**
  String get tmplSaveButton;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Goals & Loans'**
  String get objTitle;

  /// Error state
  ///
  /// In en, this message translates to:
  /// **'Failed to load objectives'**
  String get objFailedToLoad;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No goals or loans yet'**
  String get objNoTitle;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a savings goal or track money you lent or borrowed.'**
  String get objNoSubtitle;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'GOALS'**
  String get objGoalsSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'LOANS'**
  String get objLoansSection;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Lent to {contact}'**
  String objLentTo(String contact);

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Borrowed from {contact}'**
  String objBorrowedFrom(String contact);

  /// Deadline text
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String objDue(String date);

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'New Objective'**
  String get objNewTitle;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get objNameRequired;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Objective created'**
  String get objCreated;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Objective updated'**
  String get objUpdated;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'No accounts available'**
  String get objNoAccounts;

  /// Sheet/button
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get objRecordPayment;

  /// Sheet/button
  ///
  /// In en, this message translates to:
  /// **'Add Funds'**
  String get objAddFunds;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Record Payment Received'**
  String get objRecordReceived;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Record Payment Sent'**
  String get objRecordSent;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save from Account'**
  String get objSaveFromAccount;

  /// Type chip
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get objGoalChip;

  /// Type chip
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get objLoanChip;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get objGoalName;

  /// Field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Emergency fund'**
  String get objGoalNameHint;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Loan name'**
  String get objLoanName;

  /// Field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Car loan'**
  String get objLoanNameHint;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get objPerson;

  /// Field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Ali, Bank, etc.'**
  String get objPersonHint;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get objDirection;

  /// Segment
  ///
  /// In en, this message translates to:
  /// **'I lent'**
  String get objILent;

  /// Segment
  ///
  /// In en, this message translates to:
  /// **'I borrowed'**
  String get objIBorrowed;

  /// InkWell label
  ///
  /// In en, this message translates to:
  /// **'Set a deadline (optional)'**
  String get objSetDeadline;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get objColorSection;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Objective'**
  String get objDeleteTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get objCannotUndo;

  /// Travel exchange screen title
  ///
  /// In en, this message translates to:
  /// **'Travel Exchange'**
  String get travelTitle;

  /// Travel exchange info banner
  ///
  /// In en, this message translates to:
  /// **'Exchange money for your trip. A temporary travel wallet will be created automatically.'**
  String get travelInfo;

  /// Travel exchange section label
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get travelFrom;

  /// Travel exchange dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get travelSelectAccount;

  /// Travel exchange section label
  ///
  /// In en, this message translates to:
  /// **'AMOUNT TO EXCHANGE'**
  String get travelAmountToExchange;

  /// Travel exchange section label
  ///
  /// In en, this message translates to:
  /// **'TRAVEL CURRENCY'**
  String get travelCurrencySection;

  /// Travel exchange currency picker label
  ///
  /// In en, this message translates to:
  /// **'Currency you receive'**
  String get travelCurrencyReceive;

  /// Travel exchange section label
  ///
  /// In en, this message translates to:
  /// **'AMOUNT RECEIVED'**
  String get travelAmountReceived;

  /// Travel exchange submit button
  ///
  /// In en, this message translates to:
  /// **'Exchange & Create Travel Wallet'**
  String get travelExchangeButton;

  /// Travel exchange reactivate dialog title
  ///
  /// In en, this message translates to:
  /// **'Existing Travel Wallet'**
  String get travelExistingWallet;

  /// Travel exchange reactivate dialog button
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get travelCreateNew;

  /// Travel exchange reactivate dialog button
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get travelReactivate;

  /// Period transition screen title
  ///
  /// In en, this message translates to:
  /// **'New Period'**
  String get periodNewTitle;

  /// Period transition error message
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load envelopes'**
  String get periodError;

  /// Period transition subheading
  ///
  /// In en, this message translates to:
  /// **'Resolve leftover balances'**
  String get periodResolveLeftovers;

  /// Period transition item count
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String periodNItems(int count);

  /// Period transition empty state title
  ///
  /// In en, this message translates to:
  /// **'No leftover balances to resolve'**
  String get periodNoLeftovers;

  /// Period transition empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'All periodic allocations have zero or negative balances.'**
  String get periodAllZero;

  /// Period transition submit button
  ///
  /// In en, this message translates to:
  /// **'Complete Period Transition'**
  String get periodCompleteButton;

  /// Period transition allocation type label
  ///
  /// In en, this message translates to:
  /// **'Rollover allocation'**
  String get periodRollover;

  /// Period transition allocation type label
  ///
  /// In en, this message translates to:
  /// **'Periodic allocation'**
  String get periodPeriodic;

  /// Period resolution option
  ///
  /// In en, this message translates to:
  /// **'Return to Unallocated'**
  String get periodReturnUnallocated;

  /// Period resolution option description
  ///
  /// In en, this message translates to:
  /// **'Balance returns to the pool'**
  String get periodReturnDesc;

  /// Period resolution option
  ///
  /// In en, this message translates to:
  /// **'Carry Forward'**
  String get periodCarryForward;

  /// Period resolution option description
  ///
  /// In en, this message translates to:
  /// **'Keep balance for next period'**
  String get periodCarryDesc;

  /// Period resolution option
  ///
  /// In en, this message translates to:
  /// **'Move to...'**
  String get periodMoveTo;

  /// Period resolution option description
  ///
  /// In en, this message translates to:
  /// **'Transfer to another allocation'**
  String get periodMoveDesc;

  /// Period resolution dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select allocation'**
  String get periodSelectAllocation;

  /// Leftover resolution screen title
  ///
  /// In en, this message translates to:
  /// **'Resolve Leftovers'**
  String get leftoverTitle;

  /// Leftover resolution missing args
  ///
  /// In en, this message translates to:
  /// **'No allocation specified.'**
  String get leftoverNoAllocation;

  /// Leftover resolution missing allocation
  ///
  /// In en, this message translates to:
  /// **'Allocation not found.'**
  String get leftoverNotFound;

  /// Leftover resolution section label
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get leftoverCurrentBalance;

  /// Leftover resolution empty balance
  ///
  /// In en, this message translates to:
  /// **'No balance'**
  String get leftoverNoBalance;

  /// Leftover resolution empty state
  ///
  /// In en, this message translates to:
  /// **'No positive balance to resolve.'**
  String get leftoverNoPositive;

  /// Leftover resolution section label
  ///
  /// In en, this message translates to:
  /// **'Currency to resolve'**
  String get leftoverCurrencyToResolve;

  /// Leftover resolution dropdown option
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get leftoverAllCurrencies;

  /// Leftover resolution section label
  ///
  /// In en, this message translates to:
  /// **'What to do with the leftover'**
  String get leftoverWhatToDo;

  /// Leftover resolution option
  ///
  /// In en, this message translates to:
  /// **'Leftover balance goes back to the pool'**
  String get leftoverReturnSubtitle;

  /// Leftover resolution option
  ///
  /// In en, this message translates to:
  /// **'Keep the balance for the next period'**
  String get leftoverKeepSubtitle;

  /// Leftover resolution option
  ///
  /// In en, this message translates to:
  /// **'Move to another allocation'**
  String get leftoverMoveTitle;

  /// Leftover resolution option
  ///
  /// In en, this message translates to:
  /// **'Transfer leftover to a different allocation'**
  String get leftoverMoveSubtitle;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get settingsMoreTitle;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get settingsToolsSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'AUTOMATION'**
  String get settingsAutomationSection;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your accounts and balances'**
  String get settingsAccountsSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage groups and categories'**
  String get settingsCategoriesSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Split bills & scan receipts'**
  String get settingsBillSplitterSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'View upcoming recurring bills'**
  String get settingsBillCalendarSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Bills due soon with urgency'**
  String get settingsUpcomingBillsSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Exchange currency for a trip'**
  String get settingsTravelSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'View and refresh currency rates'**
  String get settingsExchangeRatesSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your budget from a browser'**
  String get settingsWebCompanionSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage recurring transactions'**
  String get settingsRecurringSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Save frequent transactions'**
  String get settingsTemplatesSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Track recurring subscriptions'**
  String get settingsSubscriptionsSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Savings goals and debt tracking'**
  String get settingsGoalsSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'End period and resolve leftovers'**
  String get settingsPeriodSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Settings & Customization'**
  String get settingsCustomization;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Theme, font, data, preferences'**
  String get settingsCustomizationSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'About BudgetSeal'**
  String get settingsAbout;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get themeBlack;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Web theme toggle
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// Picker title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Auto-fill Settings'**
  String get autofillTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'When you pick a category, these fields are pre-filled from your last transaction with that category.'**
  String get autofillDesc;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get autofillAccount;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Use the same account as last time'**
  String get autofillAccountSub;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get autofillTitleToggle;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Copy the title from last time'**
  String get autofillTitleSub;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get autofillAmountToggle;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Copy the amount from last time'**
  String get autofillAmountSub;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get autofillCategoryToggle;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Remember last used category per account'**
  String get autofillCategorySub;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Override existing values'**
  String get autofillOverride;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Replace fields even if you already filled them'**
  String get autofillOverrideSub;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset Everything'**
  String get resetTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL your data:\\n\\n• All accounts and balances\\n• All transactions\\n• All envelopes and categories\\n• All settings\\n\\nThis cannot be undone. Are you absolutely sure?'**
  String get resetContent;

  /// Destructive button
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get resetButton;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Transaction Colors'**
  String get txColorsTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Choose a color for each transaction type. These colors are used throughout the app to visually distinguish income, expenses, and transfers.'**
  String get txColorsDesc;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get txColorsReset;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Household Name'**
  String get householdNameTitle;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Bill Calendar'**
  String get tileBillCalendar;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get tileUpcomingBills;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Travel Exchange'**
  String get tileTravelExchange;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get tileExchangeRates;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Web Companion'**
  String get tileWebCompanion;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get tileRecurring;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get tileTemplates;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get tileSubscriptions;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Goals & Loans'**
  String get tileGoalsLoans;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Period Transition'**
  String get tilePeriodTransition;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get syncTitle;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get syncNotConnected;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncSyncing;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Last sync failed'**
  String get syncLastFailed;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Not yet synced'**
  String get syncNotYet;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Connect a cloud provider to sync your data'**
  String get syncConnectPrompt;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Button / sheet title
  ///
  /// In en, this message translates to:
  /// **'Share Household'**
  String get syncShareHousehold;

  /// Button / dialog title
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get syncDisconnect;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'CONNECT A PROVIDER'**
  String get syncConnectSection;

  /// Note
  ///
  /// In en, this message translates to:
  /// **'Receipt sync coming soon for this provider'**
  String get syncReceiptComingSoon;

  /// Info text
  ///
  /// In en, this message translates to:
  /// **'OneDrive and Dropbox open the system file picker, which can access those services when their apps are installed on your device. Google Drive requires a Google Cloud project with OAuth configured.'**
  String get syncProviderInfo;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get syncConnectionFailed;

  /// Default error
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get syncFailedToConnect;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Your data will remain on your device, but automatic sync will stop. You can reconnect at any time.'**
  String get syncDisconnectMsg;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Share your BudgetSeal data with another person. They will be able to sync to the same file on Google Drive.'**
  String get syncShareDesc;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Their email address'**
  String get syncTheirEmail;

  /// Field hint
  ///
  /// In en, this message translates to:
  /// **'partner@gmail.com'**
  String get syncEmailHint;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Sharing...'**
  String get syncSharing;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Generate Invite Code'**
  String get syncGenerateInvite;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get syncInviteCode;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get syncShareCode;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get syncValidEmailError;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Sync Encryption'**
  String get syncEncryptionTitle;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Your sync file is encrypted with AES-256'**
  String get syncEncrypted;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Sync file is not encrypted'**
  String get syncNotEncrypted;

  /// Warning
  ///
  /// In en, this message translates to:
  /// **'Anyone with access to your Google Drive can read your financial data'**
  String get syncGdriveWarning;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Set Sync Password'**
  String get syncSetPasswordTitle;

  /// Dialog description
  ///
  /// In en, this message translates to:
  /// **'This password encrypts your sync file on Google Drive. You\'ll need the same password on any other device that syncs with this household.'**
  String get syncPasswordDesc;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get syncPasswordLabel;

  /// Field hint
  ///
  /// In en, this message translates to:
  /// **'Enter a strong password'**
  String get syncPasswordHint;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get syncConfirmPassword;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get syncSetPasswordButton;

  /// Snackbar error
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get syncPasswordsDontMatch;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Sync encryption enabled. Next sync will be encrypted.'**
  String get syncEncryptionEnabled;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove Encryption?'**
  String get syncRemoveEncryptionTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Future sync files will be unencrypted. Other devices will need to remove their password too.'**
  String get syncRemoveEncryptionMsg;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Sync encryption removed'**
  String get syncEncryptionRemoved;

  /// Provider name
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get providerGoogleDrive;

  /// Provider subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account'**
  String get providerGoogleDriveSub;

  /// Provider name
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get providerOnedrive;

  /// Provider subtitle
  ///
  /// In en, this message translates to:
  /// **'Requires the OneDrive app installed'**
  String get providerOnedriveSub;

  /// Provider name
  ///
  /// In en, this message translates to:
  /// **'Dropbox'**
  String get providerDropbox;

  /// Provider subtitle
  ///
  /// In en, this message translates to:
  /// **'Requires the Dropbox app installed'**
  String get providerDropboxSub;

  /// Provider name
  ///
  /// In en, this message translates to:
  /// **'Local File'**
  String get providerLocalFile;

  /// Provider subtitle
  ///
  /// In en, this message translates to:
  /// **'Pick any file on your device'**
  String get providerLocalFileSub;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'No sync file found'**
  String get syncNoFileFound;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Automatic Backups'**
  String get backupAutoTitle;

  /// Switch
  ///
  /// In en, this message translates to:
  /// **'Enable automatic backups'**
  String get backupEnable;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get backupDisabled;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get backupFrequency;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Every 6 hours'**
  String get backupEvery6h;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Every 12 hours'**
  String get backupEvery12h;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get backupDaily;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Every 3 days'**
  String get backupEvery3d;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get backupWeekly;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Keep last'**
  String get backupKeepLast;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'{n} backups'**
  String backupNBackups(int n);

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Manual Backup'**
  String get backupManualTitle;

  /// Help text
  ///
  /// In en, this message translates to:
  /// **'Export your database to share or store externally.'**
  String get backupExportDesc;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get backupExporting;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get backupExportShare;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreTitle;

  /// Help text
  ///
  /// In en, this message translates to:
  /// **'Pick a .db file to restore from.'**
  String get backupRestoreDesc;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Restore from File'**
  String get backupRestoreFromFile;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'LOCAL BACKUPS'**
  String get backupLocalSection;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backupRestoreDialogTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This will replace ALL current data with the backup. This cannot be undone. Continue?'**
  String get backupRestoreWarning;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Backup restored. Please restart the app.'**
  String get backupRestored;

  /// Error snackbar
  ///
  /// In en, this message translates to:
  /// **'Restore failed. The backup may be corrupted.'**
  String get backupRestoreFailed;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Database file not found'**
  String get backupDbNotFound;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Backup file too large (max 100MB)'**
  String get backupTooLarge;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file — not a valid database'**
  String get backupInvalid;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Import & Export'**
  String get ieTitle;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get ieImportCsv;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Import transactions from a bank CSV file'**
  String get ieImportCsvSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get ieExportCsv;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Export transactions as a spreadsheet'**
  String get ieExportCsvSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get ieExportReport;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Generate a printable monthly report'**
  String get ieExportReportSub;

  /// AppBar title for CSV export
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportDataTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Export Transactions'**
  String get exportTransTitle;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Export all your transactions as a CSV file. You can open it in Excel, Google Sheets, or any spreadsheet app.'**
  String get exportTransDesc;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReportTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get exportMonthlyTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Generate a printable HTML report for a selected month. Open it in a browser and use Print > Save as PDF.'**
  String get exportMonthlyDesc;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get exportGenerating;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Generate & Share'**
  String get exportGenerateShare;

  /// HTML section
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get exportSpendingByCat;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get notifDailyTitle;

  /// Switch
  ///
  /// In en, this message translates to:
  /// **'Enable daily reminder'**
  String get notifDailyEnable;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Remind me to log transactions'**
  String get notifDailyDisabled;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get notifTime;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Custom message (optional)'**
  String get notifCustomMessage;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Envelope Alerts'**
  String get notifEnvelopeTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a notification when envelopes are overspent. These check on app startup, at most once every 6 hours.'**
  String get notifEnvelopeDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get notifBillsTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a notification when recurring transactions are due within 2 days. Checks on app startup.'**
  String get notifBillsDesc;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get fxTitle;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh rates'**
  String get fxRefreshTooltip;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Could not fetch rates'**
  String get fxCouldNotFetch;

  /// Empty title
  ///
  /// In en, this message translates to:
  /// **'No rates available'**
  String get fxNoRates;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get fxCheckInternet;

  /// Info text
  ///
  /// In en, this message translates to:
  /// **'Rates are fetched from the internet and cached for 1 hour. They are auto-filled when creating transactions.'**
  String get fxCacheInfo;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get aboutShare;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContact;

  /// Share text
  ///
  /// In en, this message translates to:
  /// **'Check out BudgetSeal — envelope budgeting made simple!'**
  String get aboutShareText;

  /// Privacy notice
  ///
  /// In en, this message translates to:
  /// **'No tracking. Your data stays on your device.'**
  String get aboutPrivacy;

  /// Credit line
  ///
  /// In en, this message translates to:
  /// **'Made by Samer'**
  String get aboutCredit;

  /// Link label
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get aboutPrivacyTerms;

  /// Link label
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get aboutLicenses;

  /// Copyright line
  ///
  /// In en, this message translates to:
  /// **'© {year} Samer Cheaib. All rights reserved.'**
  String aboutLegalese(int year);

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsAppearanceSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get settingsDataSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get settingsPreferencesSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get settingsSecuritySection;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Recurring & Bills'**
  String get tileRecurringBills;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Bill Splitter'**
  String get tileBillSplitter;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Help Guide'**
  String get tileHelpGuide;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'How to use BudgetSeal'**
  String get settingsHelpSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get tileTheme;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get tileAccentColor;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get tileColors;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Income, expense & transfer'**
  String get tileColorsSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Entry Mode'**
  String get tileEntryMode;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Auto-fill'**
  String get tileAutofill;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Pre-fill fields from last transaction'**
  String get tileAutofillSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Start Screen'**
  String get tileStartScreen;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get tileFont;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get tileTextSize;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Transaction List'**
  String get tileTxList;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Layout, icons, date banner'**
  String get tileTxListSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get tileCloudSync;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Sync across devices'**
  String get tileCloudSyncSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Share Household'**
  String get tileShareHousehold;

  /// Tile subtitle when connected
  ///
  /// In en, this message translates to:
  /// **'Invite someone to share your data'**
  String get tileShareHouseholdConnected;

  /// Tile subtitle when not connected
  ///
  /// In en, this message translates to:
  /// **'Connect Cloud Sync first to share'**
  String get tileShareHouseholdDisconnected;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Set up Cloud Sync with Google Drive first to share your household.'**
  String get tileShareHouseholdSnackbar;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get tileBackupRestore;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Export or restore database'**
  String get tileBackupRestoreSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Import & Export'**
  String get tileImportExport;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'CSV import, export, and reports'**
  String get tileImportExportSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tileNotifications;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Daily reminder, envelope & bill alerts'**
  String get tileNotificationsSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Health Check'**
  String get tileHealthCheck;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Verify data integrity & repair'**
  String get tileHealthCheckSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Sync Receipts'**
  String get tileSyncReceipts;

  /// Subtitle when enabled
  ///
  /// In en, this message translates to:
  /// **'Upload receipt photos to cloud storage'**
  String get tileSyncReceiptsOn;

  /// Subtitle when disabled
  ///
  /// In en, this message translates to:
  /// **'Receipts are stored on this device only'**
  String get tileSyncReceiptsOff;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get tileBaseCurrency;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Period Start Day'**
  String get tilePeriodStartDay;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'The day of the month when a new budget period starts.'**
  String get tilePeriodStartDayDesc;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Currency Symbols'**
  String get tileCurrencySymbols;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Override how currencies are displayed'**
  String get tileCurrencySymbolsSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Number Format'**
  String get tileNumberFormat;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get tileDateFormat;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get tileBiometricLock;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint or face to open'**
  String get tileBiometricSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Reset Everything'**
  String get tileResetEverything;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Erase all data and start fresh'**
  String get tileResetSub;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Entry Mode'**
  String get entryModeTitle;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Choose how you add new transactions.'**
  String get entryModeDesc;

  /// Option title
  ///
  /// In en, this message translates to:
  /// **'Assisted (Step-by-step)'**
  String get entryModeAssisted;

  /// Option description
  ///
  /// In en, this message translates to:
  /// **'Guides you through adding a transaction step by step. First pick a title, then a category, then enter the amount. Best for beginners.'**
  String get entryModeAssistedDesc;

  /// Option title
  ///
  /// In en, this message translates to:
  /// **'Classic (Single form)'**
  String get entryModeClassic;

  /// Option description
  ///
  /// In en, this message translates to:
  /// **'All fields on one screen. Fill in what you need and save. Faster for experienced users.'**
  String get entryModeClassicDesc;

  /// Setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Assisted (step-by-step)'**
  String get entryModeAssistedShort;

  /// Setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Classic (single form)'**
  String get entryModeClassicShort;

  /// Theme subtitle
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get themeFollowDevice;

  /// Theme subtitle
  ///
  /// In en, this message translates to:
  /// **'AMOLED pure black'**
  String get themeAmoled;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColorTitle;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get accentColorSystem;

  /// Option subtitle
  ///
  /// In en, this message translates to:
  /// **'Material You (Android 12+)'**
  String get accentColorSystemSub;

  /// Color name
  ///
  /// In en, this message translates to:
  /// **'Royal Blue'**
  String get accentColorRoyalBlue;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get accentColorDefault;

  /// Setting value label
  ///
  /// In en, this message translates to:
  /// **'System (Material You)'**
  String get accentColorSystemLabel;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Start Screen'**
  String get startScreenTitle;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Opens when you launch the app.'**
  String get startScreenDesc;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Choose Font'**
  String get chooseFontTitle;

  /// Font preview text
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog'**
  String get fontPreview;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSizeTitle;

  /// Preview subtitle
  ///
  /// In en, this message translates to:
  /// **'Preview text at this size'**
  String get textSizePreview;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Currency Symbols'**
  String get currencySymbolsTitle;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Tap any currency to change how its symbol is displayed. For example, change ل.ل to LBP.'**
  String get currencySymbolsDesc;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'ALL CURRENCIES'**
  String get currencySymbolsAllSection;

  /// Subtitle for overridden currency
  ///
  /// In en, this message translates to:
  /// **'Default: {symbol}'**
  String currencySymbolDefault(String symbol);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Symbol for {code}'**
  String currencySymbolFor(String code);

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Number Format'**
  String get numberFormatTitle;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Choose how numbers are displayed throughout the app.'**
  String get numberFormatDesc;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get numberFormatPreview;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Thousands Separator'**
  String get numberFormatThousands;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Decimal Separator'**
  String get numberFormatDecimal;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Negative Numbers'**
  String get numberFormatNegative;

  /// Warning text
  ///
  /// In en, this message translates to:
  /// **'Some options are hidden because they conflict with the decimal separator.'**
  String get numberFormatConflict;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormatTitle;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get biometricNotAvailable;

  /// Auth reason
  ///
  /// In en, this message translates to:
  /// **'Verify to enable biometric lock'**
  String get biometricVerify;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Authentication failed — biometric lock not enabled'**
  String get biometricFailed;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Authentication error — biometric lock not enabled'**
  String get biometricError;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'No biometrics enrolled on this device. Please set up fingerprint or face unlock in your device settings, then try again.'**
  String get biometricNotEnrolled;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get biometricLockedOut;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'No screen lock is set up on this device. Please set up a PIN, pattern, or password first.'**
  String get biometricPasscodeNotSet;

  /// Banner message
  ///
  /// In en, this message translates to:
  /// **'You haven\'t backed up yet'**
  String get backupBannerNoBackup;

  /// Banner message
  ///
  /// In en, this message translates to:
  /// **'You haven\'t backed up in {days} days'**
  String backupBannerDaysAgo(int days);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Backup Now'**
  String get backupNowButton;

  /// Share invite text
  ///
  /// In en, this message translates to:
  /// **'Join my BudgetSeal household! Enter this code in the app:\n{code}'**
  String syncShareInviteText(String code);

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get privacyTermsTitle;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// Date
  ///
  /// In en, this message translates to:
  /// **'Last updated: May 2026'**
  String get privacyLastUpdated;

  /// Introduction
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal is designed with your privacy as a core principle. Your financial data belongs to you — we never collect, store, or transmit it to any server.'**
  String get privacyIntro;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'1. Data Storage'**
  String get privacyDataStorageTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'All your financial data (transactions, accounts, envelopes, categories, goals, and settings) is stored locally on your device in an SQLite database. No data leaves your device unless you explicitly enable Cloud Sync.'**
  String get privacyDataStorageBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'2. Cloud Sync (Optional)'**
  String get privacyCloudSyncTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'If you choose to enable Cloud Sync, your data is uploaded to your personal Google Drive account or a file storage provider you select. BudgetSeal does not have access to your Google account credentials — authentication is handled by Google\'s OAuth system.\n\nYou may optionally encrypt your sync file with AES-256 encryption using a password you set. The password is stored only on your device in secure storage (Android Keystore / iOS Keychain).'**
  String get privacyCloudSyncBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'3. Web Companion'**
  String get privacyWebCompanionTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'The Web Companion feature runs a local HTTP server on your phone. It is only accessible from devices on the same WiFi network (private IP addresses). No data is sent to the internet. The connection is protected by a PIN, session tokens, and rate limiting. The server stops automatically after 6 hours.'**
  String get privacyWebCompanionBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'4. Analytics & Tracking'**
  String get privacyAnalyticsTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal does not include any analytics SDKs, crash reporting tools, advertising libraries, or tracking pixels. No usage data, device identifiers, or behavioral metrics are collected.'**
  String get privacyAnalyticsBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'5. Permissions'**
  String get privacyPermissionsTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'• Camera — used only for receipt scanning (offline OCR)\n• Notifications — daily reminders and bill alerts\n• Biometrics — optional app lock\n• Network — only for Cloud Sync and exchange rate fetching\n• Local Network — Web Companion server\n\nAll permissions are optional and can be denied without affecting core functionality.'**
  String get privacyPermissionsBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'6. Receipt Images'**
  String get privacyReceiptsTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'Receipt photos are stored in the app\'s private directory on your device. They are not uploaded anywhere unless you enable receipt sync via Google Drive. OCR processing is performed entirely offline using on-device ML.'**
  String get privacyReceiptsBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'7. Backups'**
  String get privacyBackupsTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'Automatic backups are stored locally in the app\'s documents directory. You control backup frequency and retention. Exported backup files are shared via the system share sheet and deleted from temporary storage afterward.'**
  String get privacyBackupsBody;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUseTitle;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance'**
  String get termsAcceptanceTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'By using BudgetSeal, you agree to these terms. If you do not agree, please uninstall the app.'**
  String get termsAcceptanceBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'2. Intended Use'**
  String get termsIntendedUseTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal is a personal finance management tool for individual and household budgeting. It is not intended for commercial accounting, tax preparation, or financial advice. The app provides tools to organize your finances — it does not provide financial recommendations.'**
  String get termsIntendedUseBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'3. Data Accuracy'**
  String get termsDataAccuracyTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'You are responsible for the accuracy of the data you enter. BudgetSeal calculates balances, budgets, and reports based on your input. Exchange rates fetched from external sources are approximate and may not reflect real-time market rates.'**
  String get termsDataAccuracyBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'4. No Warranty'**
  String get termsNoWarrantyTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal is provided \"as is\" without warranty of any kind. While we strive for reliability, we cannot guarantee that the app will be error-free or uninterrupted. Regular backups are strongly recommended.'**
  String get termsNoWarrantyBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'5. Limitation of Liability'**
  String get termsLiabilityTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'The developer shall not be liable for any direct, indirect, incidental, or consequential damages arising from the use of BudgetSeal, including but not limited to data loss, financial miscalculations, or sync failures.'**
  String get termsLiabilityBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'6. Intellectual Property'**
  String get termsIPTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal and its original content are protected by copyright. The app uses open-source libraries listed in the Licenses section of the About screen.'**
  String get termsIPBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'7. Changes'**
  String get termsChangesTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'These terms may be updated with new app versions. Continued use after an update constitutes acceptance of the revised terms.'**
  String get termsChangesBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'8. Contact'**
  String get termsContactTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'For questions or concerns about this privacy policy or terms of use, contact: samer@budgetseal.app'**
  String get termsContactBody;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Health Check'**
  String get healthTitle;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get healthExportTooltip;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Re-run check'**
  String get healthRerunTooltip;

  /// Status title
  ///
  /// In en, this message translates to:
  /// **'All Clear'**
  String get healthAllClear;

  /// Status title
  ///
  /// In en, this message translates to:
  /// **'Issues Found'**
  String get healthIssuesFound;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Your data is consistent and healthy'**
  String get healthDataConsistent;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Some balance discrepancies detected'**
  String get healthDiscrepancies;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get healthTransactionsStat;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get healthLedgerStat;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get healthBackupStat;

  /// Badge value
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get healthNever;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Balance Invariant'**
  String get healthBalanceInvariant;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Account Balances'**
  String get healthAccountBalances;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Envelope Balances'**
  String get healthEnvelopeBalances;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Data Quality'**
  String get healthDataQuality;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Repair Balances'**
  String get healthRepairButton;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Ledger entries'**
  String get healthLedgerEntries;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Soft-deleted'**
  String get healthSoftDeleted;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Orphan ledger entries'**
  String get healthOrphanEntries;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get healthLastBackup;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get healthNoAccounts;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No envelopes'**
  String get healthNoEnvelopes;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Repair Balances'**
  String get healthRepairTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This will create adjustment ledger entries to bring allocation balances back in line with account balances. A backup is recommended before proceeding.\\n\\nContinue?'**
  String get healthRepairMsg;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get healthRepairDone;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'No adjustments needed'**
  String get healthNoAdjustments;

  /// Error snackbar
  ///
  /// In en, this message translates to:
  /// **'Repair failed. Please try again.'**
  String get healthRepairFailed;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Purge Deleted Transactions'**
  String get healthPurgeTitle;

  /// Dialog text
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get healthPurgeSuffix;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Purge'**
  String get healthPurgeButton;

  /// Onboarding welcome page title
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal'**
  String get onboardWelcomeTitle;

  /// Onboarding welcome tagline
  ///
  /// In en, this message translates to:
  /// **'Give every dollar a purpose.'**
  String get onboardTagline;

  /// Onboarding step 1
  ///
  /// In en, this message translates to:
  /// **'Add accounts — where your money lives'**
  String get onboardStep1;

  /// Onboarding step 2
  ///
  /// In en, this message translates to:
  /// **'Create envelopes — budget for each category'**
  String get onboardStep2;

  /// Onboarding step 3
  ///
  /// In en, this message translates to:
  /// **'Fund envelopes — distribute your income'**
  String get onboardStep3;

  /// Onboarding step 4
  ///
  /// In en, this message translates to:
  /// **'Spend — each expense draws from its envelope'**
  String get onboardStep4;

  /// Onboarding welcome button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardGetStarted;

  /// Onboarding restore button
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get onboardRestoreCloud;

  /// Onboarding join button
  ///
  /// In en, this message translates to:
  /// **'Join a Household'**
  String get onboardJoinHousehold;

  /// Onboarding setup page title
  ///
  /// In en, this message translates to:
  /// **'Set up your household'**
  String get onboardSetupTitle;

  /// Onboarding setup subtitle
  ///
  /// In en, this message translates to:
  /// **'You can change everything later in Settings.'**
  String get onboardChangeLater;

  /// Onboarding section label
  ///
  /// In en, this message translates to:
  /// **'HOUSEHOLD'**
  String get onboardHouseholdSection;

  /// Onboarding text field label
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get onboardHouseholdName;

  /// Onboarding currency picker label
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get onboardBaseCurrency;

  /// Onboarding dropdown label
  ///
  /// In en, this message translates to:
  /// **'Period start day'**
  String get onboardPeriodStart;

  /// Onboarding section label
  ///
  /// In en, this message translates to:
  /// **'FIRST ACCOUNT'**
  String get onboardFirstAccountSection;

  /// Onboarding text field label
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get onboardAccountName;

  /// Onboarding account type chip
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get onboardTypeCash;

  /// Onboarding account type chip
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get onboardTypeBank;

  /// Onboarding account type chip
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get onboardTypeCredit;

  /// Onboarding account type chip
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get onboardTypeDigital;

  /// Onboarding section label
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get onboardCategoriesSection;

  /// Onboarding category option title
  ///
  /// In en, this message translates to:
  /// **'Full set'**
  String get onboardFullSet;

  /// Onboarding category option subtitle
  ///
  /// In en, this message translates to:
  /// **'30 categories with subcategories'**
  String get onboardFullSetSub;

  /// Onboarding category option title
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get onboardEmpty;

  /// Onboarding category option subtitle
  ///
  /// In en, this message translates to:
  /// **'Create your own from scratch'**
  String get onboardEmptySub;

  /// Onboarding section label
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION ENTRY'**
  String get onboardEntrySection;

  /// Onboarding entry mode option title
  ///
  /// In en, this message translates to:
  /// **'Assisted'**
  String get onboardAssisted;

  /// Onboarding entry mode option subtitle
  ///
  /// In en, this message translates to:
  /// **'Step-by-step, fast for daily use'**
  String get onboardAssistedSub;

  /// Onboarding entry mode option title
  ///
  /// In en, this message translates to:
  /// **'Classic form'**
  String get onboardClassic;

  /// Onboarding entry mode option subtitle
  ///
  /// In en, this message translates to:
  /// **'All fields at once, for complex entries'**
  String get onboardClassicSub;

  /// Onboarding submit button
  ///
  /// In en, this message translates to:
  /// **'Create & Start'**
  String get onboardCreateStart;

  /// Onboarding done page title
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardAllSet;

  /// Onboarding done page subtitle
  ///
  /// In en, this message translates to:
  /// **'Start tracking your expenses.\nYour financial clarity begins now.'**
  String get onboardDoneSubtitle;

  /// Onboarding done page button
  ///
  /// In en, this message translates to:
  /// **'Start Using BudgetSeal'**
  String get onboardStartUsing;

  /// Onboarding restore sheet title
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get onboardRestoreTitle;

  /// Onboarding restore sheet description
  ///
  /// In en, this message translates to:
  /// **'Choose where your backup is stored. This will replace any local data.'**
  String get onboardRestoreDesc;

  /// Onboarding restore option
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get onboardGoogleDrive;

  /// Onboarding restore option
  ///
  /// In en, this message translates to:
  /// **'Pick a File'**
  String get onboardPickFile;

  /// Onboarding join sheet description
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code shared with you to join an existing BudgetSeal household.'**
  String get onboardJoinDesc;

  /// Onboarding join text field label
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get onboardInviteCode;

  /// Onboarding join text field hint
  ///
  /// In en, this message translates to:
  /// **'PP-...'**
  String get onboardInviteHint;

  /// Onboarding join button
  ///
  /// In en, this message translates to:
  /// **'Join Household'**
  String get onboardJoinButton;

  /// Onboarding join validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter an invite code'**
  String get onboardEnterCodeError;

  /// Onboarding join validation error
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code. It should start with PP-'**
  String get onboardInvalidCodeError;

  /// Biometric setup prompt
  ///
  /// In en, this message translates to:
  /// **'Set up a screen lock to protect BudgetSeal'**
  String get lockSetupReason;

  /// Biometric unlock prompt
  ///
  /// In en, this message translates to:
  /// **'Unlock BudgetSeal'**
  String get lockUnlockReason;

  /// Biometric error snackbar
  ///
  /// In en, this message translates to:
  /// **'Unlock failed: {error}'**
  String lockFailed(String error);

  /// Lock screen hint
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock'**
  String get lockTapToUnlock;

  /// Lock screen button
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlockButton;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reportsOverviewTab;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get reportsCategoriesTab;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get reportsInsightsTab;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get reportsBalanceTab;

  /// Hint title
  ///
  /// In en, this message translates to:
  /// **'Explore your spending patterns'**
  String get reportsHintTitle;

  /// Hint body
  ///
  /// In en, this message translates to:
  /// **'Switch between tabs to see different views. The Insights tab shows your financial health.'**
  String get reportsHintBody;

  /// Summary label
  ///
  /// In en, this message translates to:
  /// **'Daily pace'**
  String get reportsDailyPace;

  /// Summary label
  ///
  /// In en, this message translates to:
  /// **'Projected total'**
  String get reportsProjectedTotal;

  /// Comparison
  ///
  /// In en, this message translates to:
  /// **'{pct}% less than last month'**
  String reportsLessThanLast(double pct);

  /// Comparison
  ///
  /// In en, this message translates to:
  /// **'{pct}% more than last month'**
  String reportsMoreThanLast(double pct);

  /// Comparison
  ///
  /// In en, this message translates to:
  /// **'Same as last month'**
  String get reportsSameAsLast;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Spending Activity'**
  String get reportsSpendingActivity;

  /// Legend
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get reportsHeatmapNone;

  /// Help text
  ///
  /// In en, this message translates to:
  /// **'Each square is one day. Darker = higher amount. Scroll left to see past months.'**
  String get reportsHeatmapHelp;

  /// Toggle / title
  ///
  /// In en, this message translates to:
  /// **'6-Month Trend'**
  String get reports6MonthTrend;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Daily Pace'**
  String get reportsDailyPaceToggle;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No spending this month'**
  String get reportsNoSpending;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'TOP SPENDING'**
  String get reportsTopSpending;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'TOP TRANSACTIONS'**
  String get reportsTopTransactions;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No expenses this period'**
  String get reportsNoExpenses;

  /// Fallback
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get reportsNoNote;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get reportsNewBadge;

  /// Legend
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get reportsCurrentLegend;

  /// Legend
  ///
  /// In en, this message translates to:
  /// **'Typical'**
  String get reportsTypicalLegend;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Spending Velocity'**
  String get reportsVelocityTitle;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Projected'**
  String get reportsProjected;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get reportsBudget;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Daily rate'**
  String get reportsDailyRate;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get reportsDay;

  /// Card label
  ///
  /// In en, this message translates to:
  /// **'Biggest Expense'**
  String get reportsBiggestExpense;

  /// Card label
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get reportsSavingsRate;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Recurring Transactions'**
  String get reportsRecurringTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Age of Money'**
  String get reportsAgeTitle;

  /// Rating
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get reportsAgeExcellent;

  /// Rating
  ///
  /// In en, this message translates to:
  /// **'Getting there'**
  String get reportsAgeGettingThere;

  /// Rating
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get reportsAgeNeedsWork;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'You\'re spending last month\'s income -- a sign of financial stability.'**
  String get reportsAgeExcellentDesc;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'You\'re building a buffer but not quite there yet. Keep it up!'**
  String get reportsAgeGettingDesc;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'You\'re living paycheck to paycheck. Try to build up a buffer over time.'**
  String get reportsAgeNeedsDesc;

  /// Goal text
  ///
  /// In en, this message translates to:
  /// **'Goal: 30+ days'**
  String get reportsAgeGoal;

  /// Explanation
  ///
  /// In en, this message translates to:
  /// **'Age of Money measures how many days your money sits before you spend it. It traces each expense back to the income that funded it (oldest income first).'**
  String get reportsAgeExplanation;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'TIPS'**
  String get reportsTipsSection;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'NET WORTH'**
  String get reportsNetWorth;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'ASSETS'**
  String get reportsAssets;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'LIABILITIES'**
  String get reportsLiabilities;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Compare balances to:'**
  String get reportsCompareTo;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'End of Last Week'**
  String get reportsEndLastWeek;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'End of Last Month'**
  String get reportsEndLastMonth;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'Same Time Last Month'**
  String get reportsSameTimeLastMonth;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'End of Last Quarter'**
  String get reportsEndLastQuarter;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'End of Last Year'**
  String get reportsEndLastYear;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'Same Time Last Year'**
  String get reportsSameTimeLastYear;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get reportsCustom;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Web Companion'**
  String get wcTitle;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Server stopped'**
  String get wcStopped;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get wcStarting;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Server running'**
  String get wcRunning;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get wcError;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'No WiFi'**
  String get wcNoWifi;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Stops automatically after 6 hours'**
  String get wcAutoStop;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Stop Server'**
  String get wcStopButton;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Start Server'**
  String get wcStartButton;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Open on your laptop'**
  String get wcOpenOnLaptop;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'URL copied to clipboard'**
  String get wcUrlCopied;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get wcCopyUrl;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Hide QR code'**
  String get wcHideQr;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get wcShowQr;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get wcSecurityTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'A PIN is required to access the web interface.'**
  String get wcPinRequired;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'PIN is set'**
  String get wcPinIsSet;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'No PIN set'**
  String get wcNoPin;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get wcChangePin;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get wcSetPin;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Set Web PIN'**
  String get wcSetPinTitle;

  /// Sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'This PIN protects your budget data. Anyone on the same WiFi will need it to access the web interface.'**
  String get wcSetPinSubtitle;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get wcChangePinTitle;

  /// Sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter a new 4-digit PIN for your web interface.'**
  String get wcChangePinSubtitle;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN'**
  String get wc4DigitPin;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 4 digits'**
  String get wcEnter4DigitsError;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Update PIN'**
  String get wcUpdatePin;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'PIN updated. All active sessions signed out.'**
  String get wcPinUpdated;

  /// Warning banner
  ///
  /// In en, this message translates to:
  /// **'Keep BudgetSeal in the foreground while the server is running. iOS does not support background servers — locking your screen will stop it.'**
  String get wcIosWarning;

  /// Banner title
  ///
  /// In en, this message translates to:
  /// **'No WiFi Connection'**
  String get wcNoWifiTitle;

  /// Banner description
  ///
  /// In en, this message translates to:
  /// **'Connect your phone to a WiFi network to use Web Companion. The server needs WiFi to let your laptop access the budget.'**
  String get wcNoWifiDesc;

  /// Banner title
  ///
  /// In en, this message translates to:
  /// **'Public Network Detected'**
  String get wcPublicNetwork;

  /// Banner title
  ///
  /// In en, this message translates to:
  /// **'Network Security'**
  String get wcNetworkSecurity;

  /// Warning title
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get wcSecurityWarning;

  /// Info bullet
  ///
  /// In en, this message translates to:
  /// **'Only accessible on the same WiFi network'**
  String get wcInfo1;

  /// Info bullet
  ///
  /// In en, this message translates to:
  /// **'Server stops automatically after 6 hours'**
  String get wcInfo2;

  /// Info bullet
  ///
  /// In en, this message translates to:
  /// **'5 failed PIN attempts locks the interface for 30 minutes'**
  String get wcInfo3;

  /// Info bullet
  ///
  /// In en, this message translates to:
  /// **'Use only on trusted private networks — traffic is not encrypted'**
  String get wcInfo4;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Notification permission is needed to keep the server running in the background.'**
  String get wcNotifPermission;

  /// Notification channel name
  ///
  /// In en, this message translates to:
  /// **'Web Companion'**
  String get wcForegroundChannel;

  /// Notification channel description
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal Web Companion server is running'**
  String get wcForegroundChannelDesc;

  /// Browser tab title
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal Web'**
  String get webPageTitle;

  /// Auth screen
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue'**
  String get webAuthSubtitle;

  /// Auth error
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get webAuthLockout;

  /// Auth error
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get webAuthIncorrect;

  /// Toast error
  ///
  /// In en, this message translates to:
  /// **'Server unreachable'**
  String get webServerUnreachable;

  /// Toast error
  ///
  /// In en, this message translates to:
  /// **'Unexpected server response'**
  String get webUnexpectedResponse;

  /// Toast error
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get webUnexpectedError;

  /// Toast button
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get webUndo;

  /// Modal button
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get webSaving;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No accounts yet.'**
  String get webDashNoAccounts;

  /// Banner label
  ///
  /// In en, this message translates to:
  /// **'Unallocated'**
  String get webDashUnallocated;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No envelopes yet.'**
  String get webDashNoEnvelopes;

  /// Fallback title
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get webDashFallbackTx;

  /// Empty title
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get webDashNoTxTitle;

  /// Empty subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction to get started'**
  String get webDashNoTxSub;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get webDashSeeAll;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get webDashRecent;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get webDashViewAll;

  /// Warning
  ///
  /// In en, this message translates to:
  /// **'No rate'**
  String get webTxNoRate;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get webTxNoFound;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get webTxCsv;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get webTxCsvTooltip;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get webTxAdd;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Search by title…'**
  String get webTxSearch;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get webTxThDate;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get webTxThType;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get webTxThTitle;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get webTxThAccount;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get webTxThCategory;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get webTxThAmount;

  /// Pagination
  ///
  /// In en, this message translates to:
  /// **'← Prev'**
  String get webTxPrev;

  /// Pagination
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String webTxPageN(int page);

  /// Pagination
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get webTxNext;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'CSV exported'**
  String get webTxCsvExported;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get webTxEdit;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Del'**
  String get webTxDel;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get webFormType;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get webFormFromAccount;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get webFormAccount;

  /// Default option
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get webFormSelectAccount;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get webFormToAccount;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get webFormCategory;

  /// Default option
  ///
  /// In en, this message translates to:
  /// **'— None —'**
  String get webFormNone;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get webFormAmount;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get webFormAmountPlaceholder;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get webFormCurrency;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get webFormCurrencyPlaceholder;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get webFormExchangeRate;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Rate to base currency'**
  String get webFormRatePlaceholder;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get webFormDate;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Title / Note'**
  String get webFormTitleNote;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get webFormOptional;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'1 {txCur} = ? {baseCur}'**
  String webFormRateHint(String txCur, String baseCur);

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get webValSelectAccount;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get webValValidAmount;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Select destination account'**
  String get webValSelectDest;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'From and To accounts must differ'**
  String get webValAccountsDiffer;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get webModalAddTx;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Transaction added'**
  String get webToastTxAdded;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get webModalEditTx;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Transaction updated'**
  String get webToastTxUpdated;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get webToastTxDeleted;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'No line details available'**
  String get webToastNoLines;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Transaction Lines ({count})'**
  String webTxLinesHeader(int count);

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get webThLineAmount;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get webThLineCurrency;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get webThLineCategory;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get webThLineAccount;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get webThLineNote;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get webThLineRate;

  /// Count
  ///
  /// In en, this message translates to:
  /// **'1 sub-category'**
  String get webCatSubSingular;

  /// Count
  ///
  /// In en, this message translates to:
  /// **'{count} sub-categories'**
  String webCatSubPlural(int count);

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get webCatSectionExpense;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get webCatSectionIncome;

  /// Empty title
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get webCatEmptyTitle;

  /// Empty subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your first category to get started'**
  String get webCatEmptySub;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get webCatFormName;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. Groceries'**
  String get webCatFormNameHint;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Parent Category'**
  String get webCatFormParent;

  /// Default option
  ///
  /// In en, this message translates to:
  /// **'— None (top-level) —'**
  String get webCatFormNone;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Icon (emoji)'**
  String get webCatFormIcon;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get webCatFormColor;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get webCatFormType;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get webModalAddCat;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get webValNameRequired;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Category added'**
  String get webToastCatAdded;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Category not found'**
  String get webToastCatNotFound;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get webModalEditCat;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get webToastCatUpdated;

  /// Empty title
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get webAcctEmptyTitle;

  /// Empty subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your first account to get started'**
  String get webAcctEmptySub;

  /// Group label
  ///
  /// In en, this message translates to:
  /// **'Bank Accounts'**
  String get webAcctTypeBank;

  /// Group label
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get webAcctTypeCash;

  /// Group label
  ///
  /// In en, this message translates to:
  /// **'Credit Cards'**
  String get webAcctTypeCredit;

  /// Group label
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get webAcctTypeWallet;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Net Worth · {cur}'**
  String webAcctNetWorth(String cur);

  /// Count
  ///
  /// In en, this message translates to:
  /// **'1 account'**
  String get webAcctCountSingular;

  /// Count
  ///
  /// In en, this message translates to:
  /// **'{count} accounts'**
  String webAcctCountPlural(int count);

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No transactions for this account'**
  String get webAcctTxEmpty;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'← Back'**
  String get webAcctBack;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. Checking'**
  String get webAcctFormNameHint;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get webAcctFormType;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get webAcctFormTypeBank;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get webAcctFormTypeCash;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get webAcctFormTypeCredit;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get webAcctFormTypeWallet;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get webAcctFormOpening;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get webModalAddAcct;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Account added'**
  String get webToastAcctAdded;

  /// Empty title
  ///
  /// In en, this message translates to:
  /// **'No envelopes'**
  String get webEnvEmptyTitle;

  /// Empty subtitle
  ///
  /// In en, this message translates to:
  /// **'Envelopes are managed in the BudgetSeal app.'**
  String get webEnvEmptySub;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Unallocated:'**
  String get webEnvUnallocated;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'+ Fund'**
  String get webEnvFund;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Fund Envelope'**
  String get webModalFund;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Amount to Fund'**
  String get webFormAmountToFund;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get webFormNote;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Envelope funded'**
  String get webToastEnvFunded;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get webBtnFundConfirm;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions'**
  String get webRecurringEmpty;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get webThService;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get webThFrequency;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'Next Due'**
  String get webThNextDue;

  /// Table header
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get webThOn;

  /// Toggle title
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get webToggleEnabled;

  /// Toggle title
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get webToggleDisabled;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get webFormTitleLabel;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. Netflix'**
  String get webFormTitleHint;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get webFormFrequency;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get webFormEvery;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get webFormStartDate;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Add Recurring'**
  String get webModalAddRecurring;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Recurring added'**
  String get webToastRecurringAdded;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring'**
  String get webModalEditRecurring;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get webToastUpdated;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get webToastNotFound;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Select a start date'**
  String get webValSelectStartDate;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring'**
  String get webConfirmDeleteRecurring;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This recurring transaction will be permanently deleted.'**
  String get webConfirmDeleteRecurringMsg;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get webToastDeleted;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get webSubEmpty;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get webModalAddSub;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Subscription added'**
  String get webToastSubAdded;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Subscription'**
  String get webModalEditSub;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'New Amount'**
  String get webFormNewAmount;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Changing the amount will add a price history entry.'**
  String get webSubPriceHint;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Subscription'**
  String get webConfirmDeleteSub;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This subscription will be permanently deleted.'**
  String get webConfirmDeleteSubMsg;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get webReportsYear;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get webReportsMonth;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get webReportsLoad;

  /// Prompt
  ///
  /// In en, this message translates to:
  /// **'Select a period and click Load.'**
  String get webReportsSelectPrompt;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get webStatIncome;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get webStatExpenses;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get webStatNet;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get webStatSavingsRate;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Avg. Daily Spend'**
  String get webStatAvgDaily;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get webStatTransactions;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Daily Cashflow'**
  String get webReportDailyCashflow;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get webReportSpendingCat;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No expense data'**
  String get webReportNoExpense;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Income by Category'**
  String get webReportIncomeCat;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No income data'**
  String get webReportNoIncome;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Top Expenses'**
  String get webReportTopExpenses;

  /// Chart label
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get webChartIncome;

  /// Chart label
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get webChartExpense;

  /// Modal title
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get webShortcutsTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get webShortcutNewTx;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get webShortcutSearch;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Close modal / unfocus'**
  String get webShortcutClose;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Show this help'**
  String get webShortcutHelp;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// Month abbreviation
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// Notification title
  ///
  /// In en, this message translates to:
  /// **'Low Envelopes'**
  String get notifLowEnvelopesTitle;

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'{name} is overspent. Consider adding funds.'**
  String notifSingleOverspent(String name);

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'{count} envelopes are overspent: {names}{more}.'**
  String notifMultipleOverspent(int count, String names, String more);

  /// Notification suffix
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String notifAndMore(int count);

  /// Notification title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get notifUpcomingBillsTitle;

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'{title} is due soon.'**
  String notifSingleDue(String title);

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'{count} bills due: {names}{more}.'**
  String notifMultipleDue(int count, String names, String more);

  /// Notification suffix
  ///
  /// In en, this message translates to:
  /// **'and more'**
  String get notifBillsAndMore;

  /// Notification title for budget warning
  ///
  /// In en, this message translates to:
  /// **'Budget Alert'**
  String get notifBudgetWarningTitle;

  /// Notification body for envelope approaching budget limit
  ///
  /// In en, this message translates to:
  /// **'{name}: {percent}% used with {days} days left'**
  String notifBudgetWarning(String name, String percent, String days);

  /// Notification title
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal'**
  String get notifReminderTitle;

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'How did you spend today? Tap to record.'**
  String get notifReminder1;

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to log today\'s transactions!'**
  String get notifReminder2;

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'Stay on track — record today\'s spending.'**
  String get notifReminder3;

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'A minute now saves hours later. Log your day!'**
  String get notifReminder4;

  /// Notification body
  ///
  /// In en, this message translates to:
  /// **'Keep your budget honest — add today\'s transactions.'**
  String get notifReminder5;

  /// Channel name
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get notifReminderChannel;

  /// Channel description
  ///
  /// In en, this message translates to:
  /// **'Daily reminder to log transactions'**
  String get notifReminderChannelDesc;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Auto-covered from Unallocated'**
  String get engineAutoCovered;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Direct from income'**
  String get engineDirectIncome;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Withdrawn to Unallocated'**
  String get engineWithdrawn;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Period reset — returned to Unallocated'**
  String get enginePeriodReturned;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Period reset — transferred out'**
  String get enginePeriodOut;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Received from period reset'**
  String get enginePeriodReceived;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Period carry-forward'**
  String get engineCarryForward;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Period auto-reset'**
  String get engineAutoReset;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Comma (1,000)'**
  String get nfThousandsComma;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Period (1.000)'**
  String get nfThousandsPeriod;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Space (1 000)'**
  String get nfThousandsSpace;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'None (1000)'**
  String get nfThousandsNone;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Period (0.50)'**
  String get nfDecimalPeriod;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Comma (0,50)'**
  String get nfDecimalComma;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Minus (-\$100)'**
  String get nfNegativeMinus;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get textScaleSmall;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textScaleDefault;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textScaleLarge;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get textScaleExtraLarge;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get defcatFoodDining;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get defcatGroceries;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get defcatRestaurants;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Coffee & Snacks'**
  String get defcatCoffeeSnacks;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get defcatTransportation;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get defcatFuel;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Public Transit'**
  String get defcatPublicTransit;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Parking & Tolls'**
  String get defcatParkingTolls;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get defcatHousing;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Rent / Mortgage'**
  String get defcatRentMortgage;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get defcatUtilities;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get defcatMaintenance;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get defcatShopping;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get defcatClothing;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get defcatElectronics;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Household Items'**
  String get defcatHouseholdItems;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get defcatEntertainment;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get defcatSubscriptions;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Movies & Events'**
  String get defcatMoviesEvents;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get defcatHobbies;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get defcatHealth;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get defcatMedical;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get defcatPharmacy;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get defcatFitness;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get defcatPersonal;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get defcatEducation;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get defcatGifts;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Personal Care'**
  String get defcatPersonalCare;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get defcatSalary;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get defcatFreelance;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get defcatInvestments;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Other Income'**
  String get defcatOtherIncome;

  /// Default category preset group
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get defcatFoodDrink;

  /// Default category preset group
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get defcatTransport;

  /// Default category preset group
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get defcatBills;

  /// Default category preset group
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get defcatHome;

  /// Default category preset group
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get defcatTravel;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Dining Out'**
  String get defcatDiningOut;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get defcatCoffee;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get defcatRent;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get defcatFurniture;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get defcatElectricity;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get defcatInternet;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get defcatPhone;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Haircut'**
  String get defcatHaircut;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Skincare'**
  String get defcatSkincare;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get defcatGym;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get defcatMovies;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get defcatGames;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get defcatBooks;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get defcatHotels;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get defcatFlights;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Sync file is encrypted but no password is set. Enter your sync password to decrypt.'**
  String get syncErrEncryptedNoPw;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Wrong sync password. Could not decrypt the sync file.'**
  String get syncErrWrongPw;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Invalid encrypted sync file format'**
  String get syncErrInvalidFormat;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not configured for this app. A Google Cloud project with OAuth credentials is required.'**
  String get googleNotConfigured;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your internet connection.'**
  String get googleNetworkError;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String googleConnectionFailed(String error);

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Not connected to Google Drive'**
  String get googleNotConnected;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Select BudgetSeal Sync File'**
  String get filePickerTitle;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'No sync file path set'**
  String get filePickerNoPath;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get heatmapNoData;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get heatmapNoActivity;

  /// Size format
  ///
  /// In en, this message translates to:
  /// **'{size} B'**
  String backupSizeBytes(String size);

  /// Size format
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String backupSizeKb(String size);

  /// Size format
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String backupSizeMb(String size);

  /// Onboarding validation error
  ///
  /// In en, this message translates to:
  /// **'Enter a household name'**
  String get onboardHouseholdNameError;

  /// Onboarding validation error
  ///
  /// In en, this message translates to:
  /// **'Enter an account name'**
  String get onboardAccountNameError;

  /// Onboarding expandable section label
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get onboardMoreOptions;

  /// Onboarding period start day dropdown item
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String onboardDayN(int day);

  /// Brief explanation of envelope budgeting on the welcome page
  ///
  /// In en, this message translates to:
  /// **'Envelope budgeting is simple: divide your income into virtual envelopes for each spending category. When an envelope runs out, you stop spending in that category.'**
  String get onboardEnvelopeExplainer;

  /// Hint text for the household name field during onboarding
  ///
  /// In en, this message translates to:
  /// **'e.g. My Budget'**
  String get onboardHouseholdHint;

  /// Helper text below the period start day field during onboarding
  ///
  /// In en, this message translates to:
  /// **'The day your monthly budget resets (usually the 1st or your payday).'**
  String get onboardPeriodHelp;

  /// Help guide reference on the onboarding done page
  ///
  /// In en, this message translates to:
  /// **'Need help? Check our guide anytime from More > Help Guide.'**
  String get onboardHelpHint;

  /// Travel exchange reactivate dialog text
  ///
  /// In en, this message translates to:
  /// **'You have a previous {currency} travel wallet:'**
  String travelPreviousWallet(String currency);

  /// Travel exchange error snackbar
  ///
  /// In en, this message translates to:
  /// **'Exchange failed. Please try again.'**
  String get travelExchangeFailed;

  /// Travel exchange existing wallet balance
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String travelBalanceLabel(String amount);

  /// Period transition error snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to complete transition. Please try again.'**
  String get periodTransitionFailed;

  /// Leftover resolution error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get leftoverLoadError;

  /// Leftover resolution error snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve leftovers. Please try again.'**
  String get leftoverResolveFailed;

  /// Error boundary retry button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// Error boundary description
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Try going back or restarting the app.'**
  String get commonErrorDesc;

  /// Fallback category label
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get commonUncategorized;

  /// Public network warning with name
  ///
  /// In en, this message translates to:
  /// **'You appear to be on a public network (\"{wifiName}\"). Do not start the server — your data will be transmitted unencrypted and could be intercepted by others on the same network.'**
  String wcPublicNetworkDescNamed(String wifiName);

  /// Public network warning without name
  ///
  /// In en, this message translates to:
  /// **'You appear to be on a public network. Do not start the server — your data will be transmitted unencrypted and could be intercepted by others on the same network.'**
  String get wcPublicNetworkDescUnnamed;

  /// Network security notice body
  ///
  /// In en, this message translates to:
  /// **'Web Companion uses HTTP (unencrypted). Only use it on your private home or office WiFi. Never start the server on public networks (hotels, airports, cafes) — anyone on the same network could see your data.'**
  String get wcNetworkSecurityDesc;

  /// WiFi warning with named network
  ///
  /// In en, this message translates to:
  /// **'Network \"{wifiName}\" may be public. Traffic is unencrypted — avoid using Web Companion on public WiFi, as others on the same network could intercept your data.'**
  String wcSecurityWarningNamed(String wifiName);

  /// WiFi warning with unknown network
  ///
  /// In en, this message translates to:
  /// **'Could not detect your WiFi network name. If you\'re on a public network, avoid using Web Companion — traffic is unencrypted and could be intercepted.'**
  String get wcSecurityWarningUnnamed;

  /// Snackbar error
  ///
  /// In en, this message translates to:
  /// **'Could not apply template'**
  String get tmplApplyError;

  /// Snackbar error
  ///
  /// In en, this message translates to:
  /// **'Could not delete template'**
  String get tmplDeleteError;

  /// Validation snackbar
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get tmplEnterAmount;

  /// Template count singular
  ///
  /// In en, this message translates to:
  /// **'{count} template'**
  String tmplCountOne(int count);

  /// Template count plural
  ///
  /// In en, this message translates to:
  /// **'{count} templates'**
  String tmplCountOther(int count);

  /// Use count singular
  ///
  /// In en, this message translates to:
  /// **'{count} use'**
  String tmplUseCountOne(int count);

  /// Use count plural
  ///
  /// In en, this message translates to:
  /// **'{count} uses'**
  String tmplUseCountOther(int count);

  /// Settings tile title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get tileLanguage;

  /// Settings tile subtitle
  ///
  /// In en, this message translates to:
  /// **'App display language'**
  String get tileLanguageSub;

  /// Language option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language option
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Language option
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// Picker sheet title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePickerTitle;

  /// Recurring screen title
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTitle;

  /// Summary chip label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get recurringSummaryTotal;

  /// Summary chip label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringSummaryActive;

  /// Summary chip label
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringSummaryPaused;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions'**
  String get recurringEmptyTitle;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap + to create one'**
  String get recurringEmptySubtitle;

  /// Filtered empty state
  ///
  /// In en, this message translates to:
  /// **'No {type} recurring transactions'**
  String recurringFilteredEmpty(String type);

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete recurring transaction?'**
  String get recurringDeleteTitle;

  /// Delete confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'This will be permanently removed.'**
  String get recurringDeleteBody;

  /// Delete success snackbar
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction deleted'**
  String get recurringDeleted;

  /// Create success snackbar
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction created'**
  String get recurringCreated;

  /// Update success snackbar
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction updated'**
  String get recurringUpdated;

  /// Add sheet title
  ///
  /// In en, this message translates to:
  /// **'New Recurring Transaction'**
  String get recurringNewTitle;

  /// Add sheet title when subscription
  ///
  /// In en, this message translates to:
  /// **'New Subscription'**
  String get recurringNewSubTitle;

  /// Edit sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring Transaction'**
  String get recurringEditTitle;

  /// Title field label
  ///
  /// In en, this message translates to:
  /// **'Title (e.g. Rent, Salary)'**
  String get recurringFormTitleHint;

  /// Title validation error
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get recurringFormTitleRequired;

  /// End date button
  ///
  /// In en, this message translates to:
  /// **'Ends: {date}'**
  String recurringFormEnds(String date);

  /// End date button when no end date
  ///
  /// In en, this message translates to:
  /// **'Ends: Never (tap to set)'**
  String get recurringFormEndsNever;

  /// Next due date button
  ///
  /// In en, this message translates to:
  /// **'Next due: {date}'**
  String recurringFormNextDue(String date);

  /// Clear end date button
  ///
  /// In en, this message translates to:
  /// **'Clear end date'**
  String get recurringFormClearEndDate;

  /// Subscription toggle label
  ///
  /// In en, this message translates to:
  /// **'This is a subscription'**
  String get recurringFormIsSubscription;

  /// Subscription toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'e.g. Netflix, Spotify'**
  String get recurringFormSubscriptionHint;

  /// Create button label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get recurringFormCreate;

  /// Title required snackbar
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get recurringFormEnterTitle;

  /// Amount required snackbar
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get recurringFormEnterAmount;

  /// Account required snackbar
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get recurringFormSelectAccount;

  /// Tile status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringStatusActive;

  /// Tile status label
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringStatusPaused;

  /// Pause toggle tooltip
  ///
  /// In en, this message translates to:
  /// **'Pause recurring'**
  String get recurringPauseTooltip;

  /// Resume toggle tooltip
  ///
  /// In en, this message translates to:
  /// **'Resume recurring'**
  String get recurringResumeTooltip;

  /// Tile next due prefix
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String recurringTileNext(String date);

  /// Age of money display
  ///
  /// In en, this message translates to:
  /// **'{age} days'**
  String reportsAgeDays(int age);

  /// About tile subtitle with app version
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersionN(String version);

  /// Number format preview subtitle
  ///
  /// In en, this message translates to:
  /// **'Preview: {preview}'**
  String settingsPreview(String preview);

  /// Snackbar error
  ///
  /// In en, this message translates to:
  /// **'Could not update subscription'**
  String get subCouldNotUpdate;

  /// Help screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Help Guide'**
  String get helpGuideTitle;

  /// Receipt picker option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get receiptTakePhoto;

  /// Receipt picker option
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get receiptChooseGallery;

  /// Receipt picker subtitle
  ///
  /// In en, this message translates to:
  /// **'Select multiple photos'**
  String get receiptSelectMultiple;

  /// Import screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsvTitle;

  /// Import screen heading
  ///
  /// In en, this message translates to:
  /// **'Import from Bank CSV'**
  String get importFromBank;

  /// Import screen description
  ///
  /// In en, this message translates to:
  /// **'Select a CSV export from your bank. Column roles will be auto-detected.'**
  String get importCsvDesc;

  /// Button to pick CSV file
  ///
  /// In en, this message translates to:
  /// **'Load CSV'**
  String get importLoadCsv;

  /// Snackbar on CSV parse error
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please check the file format.'**
  String get importFailed;

  /// Row count after loading CSV
  ///
  /// In en, this message translates to:
  /// **'Found {count} rows in {fileName}'**
  String importFoundRows(int count, String fileName);

  /// Section title for column mapping
  ///
  /// In en, this message translates to:
  /// **'Column Mapping'**
  String get importColumnMapping;

  /// Column mapping description
  ///
  /// In en, this message translates to:
  /// **'Assign a role to each column. Roles were auto-detected -- adjust as needed.'**
  String get importColumnMapDesc;

  /// Section title for preview
  ///
  /// In en, this message translates to:
  /// **'Import Preview'**
  String get importPreview;

  /// Warning when no amount column mapped
  ///
  /// In en, this message translates to:
  /// **'No Amount column assigned. Please map at least one column to Amount.'**
  String get importNoAmount;

  /// Account selector label
  ///
  /// In en, this message translates to:
  /// **'Import into account'**
  String get importIntoAccount;

  /// Snackbar validation
  ///
  /// In en, this message translates to:
  /// **'Please assign an Amount column'**
  String get importAssignAmount;

  /// Snackbar on successful import
  ///
  /// In en, this message translates to:
  /// **'Imported {count} transactions'**
  String importSuccess(int count);

  /// Button label during import
  ///
  /// In en, this message translates to:
  /// **'Importing… ({count})'**
  String importImporting(int count);

  /// Button label to start import
  ///
  /// In en, this message translates to:
  /// **'Import {count} transactions'**
  String importButton(int count);

  /// Column role label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get importColSkip;

  /// Column role label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get importColDate;

  /// Column role label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get importColDescription;

  /// Snackbar on payment error
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get objPaymentFailed;

  /// Empty state for payment history
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get objNoPayments;

  /// Payment sheet subtitle showing current amount
  ///
  /// In en, this message translates to:
  /// **'Current: {amount}'**
  String objCurrent(String amount);

  /// Category picker placeholder in payment sheet
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get objCategoryOptional;

  /// Loan direction hint for lent
  ///
  /// In en, this message translates to:
  /// **'You gave money — payments are incoming'**
  String get objLoanDirLentHint;

  /// Loan direction hint for borrowed
  ///
  /// In en, this message translates to:
  /// **'You owe money — payments are outgoing'**
  String get objLoanDirBorrowedHint;

  /// Calculator field label
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get objTargetAmountLabel;

  /// Deadline display with date
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String objDeadlinePrefix(String date);

  /// Summary row label
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get objSummaryRemaining;

  /// Section header for payment history
  ///
  /// In en, this message translates to:
  /// **'PAYMENTS'**
  String get objPaymentsSection;

  /// Section header for settings form
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get objSettingsSection;

  /// Section header for type toggle
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get objTypeSection;

  /// Menu item to hide settings
  ///
  /// In en, this message translates to:
  /// **'Hide Settings'**
  String get objHideSettings;

  /// Menu item to show settings
  ///
  /// In en, this message translates to:
  /// **'Edit Settings'**
  String get objEditSettings;

  /// Progress text: of $X
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String objOfTarget(String amount);

  /// Snackbar after receiving payment
  ///
  /// In en, this message translates to:
  /// **'Received {amount} from {account}'**
  String objReceivedFrom(String amount, String account);

  /// Snackbar after making payment
  ///
  /// In en, this message translates to:
  /// **'Paid {amount} from {account}'**
  String objPaidFrom(String amount, String account);

  /// Purge confirmation dialog content
  ///
  /// In en, this message translates to:
  /// **'Permanently remove {count} soft-deleted transaction(s) and their lines from the database?\n\n{suffix}'**
  String healthPurgeContent(int count, String suffix);

  /// Purge button with count
  ///
  /// In en, this message translates to:
  /// **'Purge {count} deleted transaction(s)'**
  String healthPurgeButtonN(int count);

  /// Ledger note for repair entries
  ///
  /// In en, this message translates to:
  /// **'Health check auto-adjustment'**
  String get healthAutoAdjustment;

  /// Share sheet title for exported report
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal Health Check Report'**
  String get healthReportTitle;

  /// Snackbar after repair
  ///
  /// In en, this message translates to:
  /// **'{count} adjustment(s) created'**
  String healthAdjustmentsCreated(int count);

  /// Snackbar after purge
  ///
  /// In en, this message translates to:
  /// **'{count} transaction(s) purged'**
  String healthPurged(int count);

  /// Dashboard customize sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Toggle to show/hide sections.'**
  String get customizeDesc;

  /// New category input hint
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get catSheetCategoryName;

  /// Empty state when search has no results
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get catSheetNoMatch;

  /// Empty state when no categories exist
  ///
  /// In en, this message translates to:
  /// **'No categories yet.\nTap \"New\" above to create one.'**
  String get catSheetNoCategories;

  /// Snackbar after connecting sync provider
  ///
  /// In en, this message translates to:
  /// **'Connected to {provider}'**
  String syncConnectedTo(String provider);

  /// Status subtitle with last sync time
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}{suffix}'**
  String syncLastSynced(String time, String suffix);

  /// Suffix for changes merged
  ///
  /// In en, this message translates to:
  /// **' · {count} change(s) merged'**
  String syncChangesMerged(int count);

  /// Suffix when no changes
  ///
  /// In en, this message translates to:
  /// **' · up to date'**
  String get syncUpToDate;

  /// Language picker subtitle for system option
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get languageSystemDesc;

  /// Hint banner title for quick actions
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActionsHintTitle;

  /// Hint banner body explaining Fund and Split
  ///
  /// In en, this message translates to:
  /// **'Fund assigns money to your envelopes. Split lets you divide a bill with others.'**
  String get dashboardQuickActionsHintBody;

  /// Funding progress
  ///
  /// In en, this message translates to:
  /// **'Distributing {distributed} of {available}'**
  String fundDistributing(String distributed, String available);

  /// Delete dialog warning
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction uses this category} other{{count} transactions use this category}}'**
  String catDeleteTxCount(int count);

  /// Delete dialog warning
  ///
  /// In en, this message translates to:
  /// **'linked to envelope \"{name}\"'**
  String catDeleteLinkedEnvelope(String name);

  /// Delete dialog content
  ///
  /// In en, this message translates to:
  /// **'This category has {warnings}.\n\nDeleting will uncategorize those transactions and unlink it from the envelope.\n\nConsider archiving instead.'**
  String catDeleteWarning(String warnings);

  /// Subscription frequency suffix for daily
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get subFreqDay;

  /// Subscription frequency suffix for weekly
  ///
  /// In en, this message translates to:
  /// **'/week'**
  String get subFreqWeek;

  /// Subscription frequency suffix for monthly
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get subFreqMonth;

  /// Subscription frequency suffix for yearly
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get subFreqYear;

  /// Subscription frequency suffix for every N days
  ///
  /// In en, this message translates to:
  /// **'/{n} days'**
  String subFreqDays(int n);

  /// Subscription frequency suffix for every N weeks
  ///
  /// In en, this message translates to:
  /// **'/{n} weeks'**
  String subFreqWeeks(int n);

  /// Subscription frequency suffix for every N months
  ///
  /// In en, this message translates to:
  /// **'/{n} months'**
  String subFreqMonths(int n);

  /// Subscription frequency suffix for every N years
  ///
  /// In en, this message translates to:
  /// **'/{n} years'**
  String subFreqYears(int n);

  /// Cancel subscription dialog body when there are future transactions
  ///
  /// In en, this message translates to:
  /// **'This will cancel future billing and remove {count, plural, =1{1 transaction} other{{count} transactions}} after {date}.'**
  String subCancelBodyWithTx(int count, String date);

  /// Cancel subscription dialog body when there are no future transactions
  ///
  /// In en, this message translates to:
  /// **'This will set the cancellation date to {date}.'**
  String subCancelBodyNoTx(String date);

  /// Screen title for planned payments
  ///
  /// In en, this message translates to:
  /// **'Planned Payments'**
  String get plannedTitle;

  /// Settings tile subtitle for planned payments
  ///
  /// In en, this message translates to:
  /// **'Plan future one-time payments'**
  String get plannedSubtitle;

  /// FAB tooltip on planned payments screen
  ///
  /// In en, this message translates to:
  /// **'Add planned payment'**
  String get plannedAddTooltip;

  /// Empty state title on planned payments screen
  ///
  /// In en, this message translates to:
  /// **'No planned payments'**
  String get plannedEmptyTitle;

  /// Empty state subtitle on planned payments screen
  ///
  /// In en, this message translates to:
  /// **'Plan future payments to track what you expect to spend before committing.'**
  String get plannedEmptySubtitle;

  /// Snackbar after posting a planned payment
  ///
  /// In en, this message translates to:
  /// **'Payment posted successfully'**
  String get plannedPosted;

  /// Snackbar when posting a planned payment fails
  ///
  /// In en, this message translates to:
  /// **'Failed to post payment'**
  String get plannedPostFailed;

  /// Dialog title for posting all planned payments in a month
  ///
  /// In en, this message translates to:
  /// **'Post All Payments'**
  String get plannedPostAllTitle;

  /// Dialog body for posting all planned payments
  ///
  /// In en, this message translates to:
  /// **'Post all {count} planned payments for {month}?'**
  String plannedPostAllContent(int count, String month);

  /// Button label to post all planned payments
  ///
  /// In en, this message translates to:
  /// **'Post All'**
  String get plannedPostAll;

  /// Snackbar after posting all planned payments
  ///
  /// In en, this message translates to:
  /// **'{count} payments posted'**
  String plannedPostAllResult(int count);

  /// Snackbar after partial post-all
  ///
  /// In en, this message translates to:
  /// **'{posted} posted, {failed} failed'**
  String plannedPostAllResultPartial(int posted, int failed);

  /// Dialog title for deleting a planned payment
  ///
  /// In en, this message translates to:
  /// **'Delete Planned Payment'**
  String get plannedDeleteTitle;

  /// Dialog body for deleting a planned payment
  ///
  /// In en, this message translates to:
  /// **'This payment will be permanently removed. This cannot be undone.'**
  String get plannedDeleteContent;

  /// Snackbar after deleting a planned payment
  ///
  /// In en, this message translates to:
  /// **'Planned payment deleted'**
  String get plannedDeleted;

  /// Snackbar when deleting a planned payment fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete payment'**
  String get plannedDeleteFailed;

  /// Swipe-to-post label on planned payment card
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get plannedPost;

  /// Summary chip label (lowercase)
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get plannedChipLabel;

  /// Summary chip label for total amount
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get plannedTotalLabel;

  /// Save button label on plan payment form
  ///
  /// In en, this message translates to:
  /// **'Plan Payment'**
  String get plannedPlanButton;

  /// AppBar title when editing a planned payment
  ///
  /// In en, this message translates to:
  /// **'Edit Planned Payment'**
  String get plannedEditTitle;

  /// Label for month picker in plan payment form
  ///
  /// In en, this message translates to:
  /// **'Target Month'**
  String get plannedTargetMonth;

  /// Label for exact date picker when no date selected
  ///
  /// In en, this message translates to:
  /// **'Pick exact date (optional)'**
  String get plannedExactDate;

  /// Label for exact date picker when date is selected
  ///
  /// In en, this message translates to:
  /// **'Exact date: {date}'**
  String plannedExactDateValue(String date);

  /// Validation error when no account selected
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get plannedSelectAccount;

  /// Snackbar after updating a planned payment
  ///
  /// In en, this message translates to:
  /// **'Planned payment updated'**
  String get plannedUpdated;

  /// Snackbar after creating a planned payment
  ///
  /// In en, this message translates to:
  /// **'Payment planned'**
  String get plannedCreated;

  /// Snackbar when saving a planned payment fails
  ///
  /// In en, this message translates to:
  /// **'Could not save planned payment'**
  String get plannedSaveFailed;

  /// Badge label for planned transactions
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get plannedBadge;

  /// Envelope card planned amount label
  ///
  /// In en, this message translates to:
  /// **'{amount} planned'**
  String plannedNPlanned(String amount);

  /// SnackBar after successful travel exchange
  ///
  /// In en, this message translates to:
  /// **'Exchanged {fromAmount} → {toAmount}. Open the travel wallet and use \"Convert Back & Close\" to return leftover money.'**
  String travelExchangeSuccess(String fromAmount, String toAmount);

  /// Restore backup confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'From: {date}\nSize: {size}\n\nThis will replace your current data. The app will need to restart.'**
  String backupRestoreDialogBody(String date, String size);

  /// Subtitle when auto-backup is enabled
  ///
  /// In en, this message translates to:
  /// **'Backing up {frequency}'**
  String backupAutoEvery(String frequency);

  /// Label showing last auto-backup time
  ///
  /// In en, this message translates to:
  /// **'Last auto-backup: {date}'**
  String backupLastAutoBackup(String date);

  /// Category dropdown label in recurring form
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get recurringFormCategory;

  /// Menu item to save transaction as template
  ///
  /// In en, this message translates to:
  /// **'Save as Template'**
  String get txDetailSaveAsTemplate;

  /// Snackbar after saving as template
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get txDetailTemplateSaved;

  /// Snackbar when saving template fails
  ///
  /// In en, this message translates to:
  /// **'Could not save template'**
  String get txDetailTemplateError;

  /// Settings toggle for Arabic numeral style
  ///
  /// In en, this message translates to:
  /// **'Arabic-Indic Numerals'**
  String get tileArabicDigits;

  /// Upgrade screen title
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeTitle;

  /// Upgrade screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Unlock every feature with a single purchase. No subscriptions, no ads.'**
  String get upgradeSubtitle;

  /// Premium feature: cloud sync
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get upgradeFeatureSync;

  /// Premium feature: web companion
  ///
  /// In en, this message translates to:
  /// **'Web Companion'**
  String get upgradeFeatureWebCompanion;

  /// Premium feature: bill splitter
  ///
  /// In en, this message translates to:
  /// **'Bill Splitter'**
  String get upgradeFeatureBillSplitter;

  /// Premium feature: travel exchange
  ///
  /// In en, this message translates to:
  /// **'Travel Exchange'**
  String get upgradeFeatureTravelExchange;

  /// Premium feature: planned payments
  ///
  /// In en, this message translates to:
  /// **'Planned Payments'**
  String get upgradeFeaturePlannedPayments;

  /// Premium feature: no limits
  ///
  /// In en, this message translates to:
  /// **'Unlimited accounts & envelopes'**
  String get upgradeFeatureUnlimitedItems;

  /// Premium price display
  ///
  /// In en, this message translates to:
  /// **'\$4.99'**
  String get upgradePrice;

  /// Price clarification
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. Yours forever.'**
  String get upgradePriceSubtitle;

  /// Upgrade purchase button
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeButton;

  /// Toast when upgrade is tapped before IAP is ready
  ///
  /// In en, this message translates to:
  /// **'In-app purchases coming soon'**
  String get upgradeComingSoon;

  /// Redeem code link/dialog title
  ///
  /// In en, this message translates to:
  /// **'Redeem Code'**
  String get upgradeRedeemCode;

  /// Redeem code text field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get upgradeRedeemHint;

  /// Redeem code confirm button
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get upgradeRedeemButton;

  /// Error when redeem code is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get upgradeRedeemInvalid;

  /// Success message after redeeming code
  ///
  /// In en, this message translates to:
  /// **'Code redeemed! Premium unlocked.'**
  String get upgradeRedeemSuccess;

  /// Restore purchase link
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get upgradeRestorePurchase;

  /// Success message after restoring purchase
  ///
  /// In en, this message translates to:
  /// **'Purchase restored! Premium unlocked.'**
  String get upgradeRestoreSuccess;

  /// Message when no purchase to restore
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found.'**
  String get upgradeRestoreNone;

  /// Search field hint
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get catSheetSearchHint;

  /// Subtitle showing subcategory count
  ///
  /// In en, this message translates to:
  /// **'{count} subcategories'**
  String catSheetSubcategories(int count);

  /// Summary row label
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get objSummaryDeadline;

  /// Hint text for note field
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get plannedNoteHint;

  /// Account validation error
  ///
  /// In en, this message translates to:
  /// **'Account is required'**
  String get recurringFormAccountRequired;

  /// Start date button
  ///
  /// In en, this message translates to:
  /// **'Starts: {date}'**
  String recurringFormStarts(String date);
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return SAr();
    case 'en':
      return SEn();
    case 'fr':
      return SFr();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
