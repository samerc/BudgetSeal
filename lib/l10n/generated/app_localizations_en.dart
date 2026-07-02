// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonOk => 'OK';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonDone => 'Done';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonSearchHint => 'Search…';

  @override
  String get commonNone => 'None';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonGoBack => 'Go Back';

  @override
  String get commonSaveAnyway => 'Save Anyway';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonShowDetails => 'Show details';

  @override
  String get commonHideDetails => 'Hide details';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonEnable => 'Enable';

  @override
  String get commonChange => 'Change';

  @override
  String get commonFund => 'Fund';

  @override
  String get commonNoData => 'No data';

  @override
  String get commonCouldntLoadData => 'Couldn\'t load your data';

  @override
  String get commonCouldntLoadAccounts => 'Couldn\'t load accounts';

  @override
  String get commonAccount => 'Account';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonCategory => 'Category';

  @override
  String get commonCurrency => 'Currency';

  @override
  String get commonTitle => 'Title';

  @override
  String get appName => 'BudgetSeal';

  @override
  String get appTagline => 'Budget with purpose';

  @override
  String get appTaglineAbout => 'Envelope budgeting, simplified.';

  @override
  String get appBrandAbbr => 'PP';

  @override
  String get tabHome => 'Home';

  @override
  String get tabActivity => 'Activity';

  @override
  String get tabBudget => 'Budget';

  @override
  String get tabReports => 'Reports';

  @override
  String get tabMore => 'More';

  @override
  String get navPressBackToExit => 'Press back again to exit';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navCategories => 'Categories';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navEnvelopes => 'Envelopes';

  @override
  String get navRecurring => 'Recurring';

  @override
  String get navSubscriptions => 'Subscriptions';

  @override
  String get navReports => 'Reports';

  @override
  String get navServerStatus => 'Server';

  @override
  String get navSignOut => 'Sign out';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String get typeAll => 'All';

  @override
  String get dashboardWelcomeTitle => 'Welcome to BudgetSeal!';

  @override
  String get dashboardWelcomeBody =>
      'This is your financial overview. Tap the quick actions below to start recording transactions.';

  @override
  String get dashboardHouseholdLabel => 'Household';

  @override
  String get dashboardDefaultName => 'BudgetSeal';

  @override
  String get dashboardCustomizeTooltip => 'Customize';

  @override
  String get dashboardSearchTooltip => 'Search';

  @override
  String get dashboardQuickTransfer => 'Transfer';

  @override
  String get dashboardQuickFund => 'Fund';

  @override
  String get dashboardQuickSplit => 'Split';

  @override
  String get dashboardSectionYourMoney => 'Your Money';

  @override
  String get dashboardReadyToAssign => 'Ready to assign';

  @override
  String get dashboardMoneyNotInEnvelope => 'Money not yet in an envelope';

  @override
  String get dashboardSectionActivity => 'Activity';

  @override
  String get dashboardQuickTemplates => 'Quick Templates';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardRecent => 'Recent';

  @override
  String get dashboardNoTransactionsYet => 'No transactions yet';

  @override
  String get dashboardNoTransactionsToday =>
      'No transactions today — tap + to add one';

  @override
  String get dashboardTotalAcrossAccounts => 'Total across all accounts';

  @override
  String get dashboardLabelExpenses => 'Expenses';

  @override
  String get dashboardLabelNet => 'Net';

  @override
  String get dashboardSpent => 'spent';

  @override
  String get dashboardNoSpending => 'No spending';

  @override
  String get dashboardLast7Days => 'Last 7 Days';

  @override
  String get dashboardThisMonth => 'This Month';

  @override
  String get dashboardEnvelopes => 'Envelopes';

  @override
  String get dashboardOnTrack => 'On track';

  @override
  String get dashboardRunningLow => 'Running low';

  @override
  String get dashboardOverspent => 'Overspent';

  @override
  String get dashboardHeadsUp => 'Heads up';

  @override
  String dashboardIsOverLimit(String amount) {
    return 'is $amount over its limit';
  }

  @override
  String dashboardHasPercentLeft(String percent) {
    return 'has only $percent% left';
  }

  @override
  String dashboardBudgetLeftOf(String amount, String total) {
    return '$amount left of $total budget';
  }

  @override
  String dashboardBudgetOver(String amount, String total) {
    return '$amount over $total budget';
  }

  @override
  String dashboardSpendingPerDay(String amount, String projected) {
    return 'Spending $amount/day · ~$projected by month end';
  }

  @override
  String get dashboardMoneySits1Day => 'Money sits 1 day before being spent';

  @override
  String dashboardMoneySitsNDays(int n) {
    return 'Money sits $n days before being spent';
  }

  @override
  String get dashboardAgeOfMoneyTitle => 'Age of Money';

  @override
  String get dashboardAgeOfMoneyExplanation =>
      'This shows how long money sits in your accounts before you spend it.\\n\\nThink of it as a buffer:\\n\\n• Under 14 days — you\'re spending money almost as fast as it comes in\\n• 14–30 days — you have a small cushion, getting ahead\\n• 30–60 days — you\'re spending last month\'s income. Great!\\n• 60+ days — strong financial health, big safety net\\n\\nThe goal is to increase this number over time. The higher it is, the more financially secure you are.';

  @override
  String get dashboardSearchPlaceholder => 'Search transactions, accounts...';

  @override
  String get dashboardTypeAtLeast2 => 'Type at least 2 characters';

  @override
  String dashboardNoResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get dashboardSearchAccounts => 'Accounts';

  @override
  String get dashboardSearchCategories => 'Categories';

  @override
  String get dashboardSearchTransactions => 'Transactions';

  @override
  String get dashboardOtherCategory => 'Other';

  @override
  String get customizeTitle => 'Customize Dashboard';

  @override
  String get customizeInstructions =>
      'Drag to reorder. Toggle to show/hide sections.';

  @override
  String get dashboardSectionStatusLabel => 'Status Card';

  @override
  String get dashboardSectionStatusDesc =>
      'Budget status, velocity, age of money';

  @override
  String get dashboardSectionSpendingLabel => 'Spending Overview';

  @override
  String get dashboardSectionSpendingDesc =>
      'Donut chart with category breakdown';

  @override
  String get dashboardSectionQuickLabel => 'Quick Actions';

  @override
  String get dashboardSectionQuickDesc => 'Expense, income, transfer, fund';

  @override
  String get dashboardSectionMoneyLabel => 'Your Money';

  @override
  String get dashboardSectionMoneyDesc => 'Net worth and envelope health';

  @override
  String get dashboardSectionUnallocatedLabel => 'Ready to Assign';

  @override
  String get dashboardSectionUnallocatedDesc => 'Unallocated funds';

  @override
  String get dashboardSectionActivityLabel => 'Recent Activity';

  @override
  String get dashboardSectionActivityDesc =>
      'Templates and recent transactions';

  @override
  String get dashboardNetWorth => 'Net Worth';

  @override
  String get dashboardUnallocated => 'Unallocated';

  @override
  String dashboardOtherCount(int count) {
    return '+ $count other';
  }

  @override
  String get dashboardAddFirstExpense => 'Add your first expense';

  @override
  String get dashboardFundEnvelopesTooltip => 'Fund envelopes';

  @override
  String get dashboardSplitBillTooltip => 'Split a bill';

  @override
  String dashboardCatSpendingHigher(String category, int percent) {
    return '$category spending is $percent% higher than last month';
  }

  @override
  String dashboardSpendingLowerNice(int percent) {
    return 'Spending is $percent% lower than last month — nice!';
  }

  @override
  String dashboardSpendingHigher(int percent) {
    return 'Spending is $percent% higher than last month';
  }

  @override
  String get dashboardSpendingOnTrack => 'Spending is on track this month';

  @override
  String dashboardAddLabel(String label) {
    return 'Add $label';
  }

  @override
  String dashboardChartSemantic(String amount, int count) {
    return 'Spending chart, total $amount, $count categories';
  }

  @override
  String get dashboardNoSpendingSemantic => 'No spending this period';

  @override
  String get txTitle => 'Transactions';

  @override
  String get txIntroTitle => 'Your transactions';

  @override
  String get txIntroBody =>
      'Your transactions appear here grouped by date. Swipe left to delete, right to edit. Long-press for more options.';

  @override
  String get txDeleteSelectedTitle => 'Delete selected?';

  @override
  String txDeleteSelectedContent(int count) {
    return 'Delete $count transaction(s)? This will reverse any envelope deductions.';
  }

  @override
  String txNDeleted(int count) {
    return '$count transaction(s) deleted';
  }

  @override
  String txNSelected(int count) {
    return '$count selected';
  }

  @override
  String get txDeleteSelectedTooltip => 'Delete selected';

  @override
  String get txSearchHint => 'Search transactions...';

  @override
  String get txCloseSearch => 'Close search';

  @override
  String get txFilterTooltip => 'Filter transactions';

  @override
  String get txSearchTooltip => 'Search transactions';

  @override
  String get txListSettingsTooltip => 'List settings';

  @override
  String get txQuickAddHint => 'Type name and amount, e.g. Coffee 4.50';

  @override
  String get txSendTooltip => 'Send';

  @override
  String get txScrollTopTooltip => 'Scroll to top';

  @override
  String get txSplitBillTooltip => 'Split Bill';

  @override
  String get txAddTooltip => 'Add transaction';

  @override
  String get txFromDate => 'From date';

  @override
  String get txToDate => 'To date';

  @override
  String get txMinAmount => 'Min';

  @override
  String get txMaxAmount => 'Max';

  @override
  String get txClearFilters => 'Clear advanced filters';

  @override
  String get txSelectYear => 'Select Year';

  @override
  String txFilteredCategory(String categoryName) {
    return 'Filtered: $categoryName';
  }

  @override
  String txNoCategoryInMonth(String categoryName, String monthLabel) {
    return 'No $categoryName transactions in $monthLabel';
  }

  @override
  String get txNoMatching => 'No matching transactions';

  @override
  String get txNoYet => 'No transactions yet';

  @override
  String get txTapPlus => 'Tap + to record one';

  @override
  String get txAddFirst => 'Add your first transaction';

  @override
  String txSpentOfBudget(String spent, String budget) {
    return 'Spent $spent of $budget budget';
  }

  @override
  String txTotalCashFlow(String amount, int count) {
    return 'Total cash flow: $amount · $count transaction(s)';
  }

  @override
  String get txLongPressHint => 'Long press for options';

  @override
  String txNItems(int count) {
    return '$count items';
  }

  @override
  String txNMore(int count) {
    return '+$count more';
  }

  @override
  String get txContextEdit => 'Edit';

  @override
  String get txContextDuplicate => 'Duplicate';

  @override
  String get txDeleteTitle => 'Delete transaction?';

  @override
  String get txDeleteCannotUndo => 'This action cannot be undone.';

  @override
  String get txDeleteShort => 'Delete?';

  @override
  String txDeleteWithReversal(String label) {
    return 'Delete $label? This will reverse any envelope deductions.';
  }

  @override
  String txNAccounts(int count) {
    return '$count accounts';
  }

  @override
  String get txFormEditTitle => 'Edit';

  @override
  String get txFormNewTitle => 'New Transaction';

  @override
  String get txFormNoteHint => 'Add a note…';

  @override
  String get txFormTitleHint => 'Title (e.g. Coffee, Groceries)';

  @override
  String get txFormUseTemplate => 'Use Template';

  @override
  String get txFormAutoDetected => 'Auto-detected';

  @override
  String get txFormNoCategory => 'No category';

  @override
  String get txFormFromAccount => 'From account';

  @override
  String get txFormToAccount => 'To account';

  @override
  String get txFormDestReceives => 'Destination receives:';

  @override
  String get txFormAddItem => 'Add item';

  @override
  String get txFormTotal => 'Total';

  @override
  String get txFormSelectSource => 'Select a source account';

  @override
  String get txFormSelectDest => 'Select a destination account';

  @override
  String get txFormSourceDestDiffer => 'Source and destination must differ';

  @override
  String get txFormEnterAmount => 'Enter an amount';

  @override
  String txFormSelectAccountItem(int n) {
    return 'Select an account for item $n';
  }

  @override
  String get txFormSelectAccount => 'Select an account for the transaction';

  @override
  String txFormEnterAmountItem(int n) {
    return 'Enter an amount for item $n';
  }

  @override
  String get txFormEnterAmountTx => 'Enter an amount for the transaction';

  @override
  String get txFormRateNotSetTitle => 'Exchange rate not set';

  @override
  String get txFormRateNotSetContent =>
      'Save anyway, or go back to set the rate?';

  @override
  String get txFormDuplicateTitle => 'Possible Duplicate';

  @override
  String get txFormDuplicateContent =>
      'A similar transaction with the same amount, category, and date already exists. Save anyway?';

  @override
  String get txFormSaved => 'Transaction saved';

  @override
  String txFormSavedEnvelope(String envelopeName) {
    return 'Transaction saved · $envelopeName envelope updated';
  }

  @override
  String txFormErrorSaving(String error) {
    return 'Error saving: $error';
  }

  @override
  String get txFormReceiptAttached => 'Receipt attached';

  @override
  String txFormNReceipts(int count) {
    return '$count receipts attached';
  }

  @override
  String get txFormAddMore => 'Add more';

  @override
  String get txFormScanReceipt => 'Scan Receipt';

  @override
  String get txFormGallery => 'Gallery';

  @override
  String get txDetailTitle => 'Transaction Details';

  @override
  String get txDetailNotFound => 'Transaction not found';

  @override
  String txDetailCopied(String amount) {
    return 'Copied $amount';
  }

  @override
  String get txDetailDate => 'Date';

  @override
  String get txDetailTime => 'Time';

  @override
  String get txDetailAccounts => 'Accounts';

  @override
  String get txDetailNote => 'Note';

  @override
  String get txDetailUnknownAccount => 'Unknown';

  @override
  String txDetailSplitItems(int count) {
    return 'SPLIT ITEMS ($count)';
  }

  @override
  String get txDetailLineDetail => 'LINE DETAIL';

  @override
  String get txDetailUncategorized => 'Uncategorized';

  @override
  String get txDetailRelatedSingle => 'RELATED TRANSACTION';

  @override
  String get txDetailRelatedPlural => 'RELATED TRANSACTIONS';

  @override
  String txDetailReceipts(int count) {
    return 'Receipts ($count)';
  }

  @override
  String get txDetailReceipt => 'Receipt';

  @override
  String get txDetailAttach => 'Attach';

  @override
  String get txDetailNoReceipt => 'No receipt attached';

  @override
  String get txDetailDeleteTitle => 'Delete Transaction';

  @override
  String get txDetailDeleteContent =>
      'Are you sure you want to delete this transaction?\\n\\nThis will reverse any envelope deductions and restore the balance. Ledger entries will be removed.\\n\\nThis cannot be undone.';

  @override
  String get txAfDiscardTitle => 'Discard transaction?';

  @override
  String get txAfDiscardContent =>
      'You have an unsaved transaction. Are you sure you want to go back?';

  @override
  String get txAfKeepEditing => 'Keep editing';

  @override
  String get txAfDiscard => 'Discard';

  @override
  String get txAfEnterTitle => 'Enter Title';

  @override
  String get txAfTransferNoteHint => 'Note (e.g. rent, savings)';

  @override
  String get txAfEnterAmountButton => 'Enter Amount';

  @override
  String get txAfSelectCategoryButton => 'Select Category';

  @override
  String get txAfSelectCategoryTitle => 'Select Category';

  @override
  String get txAfSearchCategories => 'Search categories...';

  @override
  String get txAfNewCategory => 'New Category';

  @override
  String get txAfEnterAmountTitle => 'Enter Amount';

  @override
  String get txAfFromAccount => 'From Account';

  @override
  String get txAfToAccount => 'To Account';

  @override
  String get txAfTapToSelect => 'Tap to select';

  @override
  String get txAfAddAccount => 'Add Account';

  @override
  String get txAfExchangeRateRequired => 'Exchange Rate Required';

  @override
  String txAfHowManyPer(String sourceCurrency, String destCurrency) {
    return 'How many $sourceCurrency per 1 $destCurrency?';
  }

  @override
  String get txAfTapToEnterRate => 'Tap to enter rate';

  @override
  String txAfRecipientGets(String amount) {
    return 'Recipient gets = $amount';
  }

  @override
  String txAfFetchingRate(String currency) {
    return 'Fetching rate for $currency...';
  }

  @override
  String get txAfEnterAmountFirst => 'Enter an amount for this item first';

  @override
  String get txAfPleaseSelectAccount => 'Please select an account';

  @override
  String get txAfPleaseSelectDest => 'Please select a destination account';

  @override
  String get txAfMixedTitle => 'Mixed transaction';

  @override
  String get txAfAddAnother => 'Add another item';

  @override
  String get txAfSaveTransfer => 'Save Transfer';

  @override
  String txAfSaveNItems(int count) {
    return 'Save $count Items';
  }

  @override
  String get txAfAddTransaction => 'Add Transaction';

  @override
  String get catSheetNew => 'New';

  @override
  String get catSheetNameHint => 'Category name';

  @override
  String get catSheetAdd => 'Add';

  @override
  String get catSheetNoMatching => 'No matching categories';

  @override
  String get catSheetNoYet =>
      'No categories yet.\\nTap \"New\" above to create one.';

  @override
  String catSheetNSubcategories(int count) {
    return '$count subcategories';
  }

  @override
  String get currencyYourAccounts => 'YOUR ACCOUNTS';

  @override
  String get currencyRecentlyUsed => 'RECENTLY USED';

  @override
  String get currencyAll => 'ALL CURRENCIES';

  @override
  String get txWidgetSelectAccount => 'Select account';

  @override
  String get txWidgetItemNote => 'Item note…';

  @override
  String get txListTitle => 'Transaction List';

  @override
  String get txListSelectLayout => 'Select Layout';

  @override
  String get txListDateBanner => 'Date Banner Total';

  @override
  String get txListDayTotal => 'Day Total';

  @override
  String get txListNone => 'None';

  @override
  String get txListAccountLabel => 'Account Label';

  @override
  String get txListAccountSubtitle => 'Show account name on each transaction';

  @override
  String get txListCategoryIcon => 'Category Icon';

  @override
  String get txListCategorySubtitle => 'Show category icon circle';

  @override
  String get txListTime => 'Time';

  @override
  String get txListTimeSubtitle => 'Show time of the transaction';

  @override
  String get txListPreviewName => 'Transaction Name';

  @override
  String get txListPreviewNote =>
      'This is a note that is part of the transaction.';

  @override
  String get billTitle => 'Bill Splitter';

  @override
  String get billScanning => 'Scanning receipt...';

  @override
  String get billScanTooltip => 'Scan receipt';

  @override
  String get billEmptyTitle => 'Add items to split';

  @override
  String get billEmptySubtitle => 'Scan a receipt or add items manually';

  @override
  String get billScanButton => 'Scan Receipt';

  @override
  String get billAddManually => 'Add Manually';

  @override
  String get billAddItem => 'Add item';

  @override
  String get billTakePhoto => 'Take Photo';

  @override
  String get billFromGallery => 'Choose from Gallery';

  @override
  String get billNoText => 'No text detected. Try a clearer photo.';

  @override
  String get billEnterAmount => 'Enter amount';

  @override
  String get billKeepAsOne => 'Keep as one';

  @override
  String get billSplit => 'Split';

  @override
  String get billWhosSplitting => 'WHO\'S SPLITTING?';

  @override
  String get billAddPerson => 'Add person';

  @override
  String get billSplitEvenly => 'Split evenly';

  @override
  String get billAssignItems => 'ASSIGN ITEMS';

  @override
  String get billItemName => 'Item name';

  @override
  String get billTip => 'Tip';

  @override
  String get billTipNone => '';

  @override
  String get billPercentage => 'Percentage';

  @override
  String get billTipAmount => 'Tip amount';

  @override
  String get billBillCurrency => 'Bill currency';

  @override
  String get billRateHint => 'Rate';

  @override
  String get billTotal => 'Total';

  @override
  String get billReScan => 'Re-scan';

  @override
  String billNLines(int detected, int withPrice) {
    return '$detected lines ($withPrice with prices)';
  }

  @override
  String get billMe => 'Me';

  @override
  String get billStep1Desc =>
      'Step 1: Add items from your receipt — scan or enter manually.';

  @override
  String get billStep2Desc =>
      'Step 2: Add people and assign items. Toggle \"Split evenly\" to divide the total equally.';

  @override
  String get billStep3Desc => 'Step 3: Review the split, add tip, and confirm.';

  @override
  String billBillIn(String currency) {
    return 'Bill in $currency';
  }

  @override
  String get billExchangeRateTitle => 'Exchange Rate';

  @override
  String get billRemovePersonTitle => 'Remove person';

  @override
  String billRemovePersonContent(String name, int count) {
    return '$name has $count item(s) assigned only to them. Reassign to someone else, or delete those items?';
  }

  @override
  String get billReassignTo => 'Reassign to:';

  @override
  String get billPersonRemoved => 'Person removed';

  @override
  String get billDeleteItems => 'Delete items';

  @override
  String billEachPays(String amount) {
    return 'Each person pays $amount';
  }

  @override
  String billSplitQtyTitle(int qty, String name) {
    return '$qty × $name';
  }

  @override
  String billSplitQtyContent(int qty, String amount) {
    return 'Split into $qty items ($amount each)?';
  }

  @override
  String get billRateNotSetTitle => 'Exchange rate not set';

  @override
  String billRateNotSetContent(String currency) {
    return 'Bill is in $currency but no rate was entered.\nThe transaction will be saved without conversion.';
  }

  @override
  String get billGoBackBtn => 'Go back';

  @override
  String get billContinueAnyway => 'Continue anyway';

  @override
  String get txFormCouldNotSave =>
      'Could not save transaction. Please try again.';

  @override
  String get txTransactionDeleted => 'Transaction deleted';

  @override
  String get txUndoAction => 'Undo';

  @override
  String get txNewTransactionSheet => 'New Transaction';

  @override
  String get txCouldNotLoad => 'Could not load transaction';

  @override
  String txAfMixedContent(int count, String summary) {
    return 'This will create $count linked transactions:\n\n$summary\n\nThey will appear as separate transactions but linked together.';
  }

  @override
  String txAfAnotherWithCount(int count, String total) {
    return 'Add another item ($count items · $total)';
  }

  @override
  String txFormRateNotSetBody(String items, String baseCurrency) {
    return '$items has no exchange rate to $baseCurrency. The amount won\'t be included in your base currency totals.\n\nSave anyway, or go back to set the rate?';
  }

  @override
  String get txFormDuplicateSimilarExists =>
      'A similar transaction already exists:';

  @override
  String get txFormDuplicateSaveAnyway => 'Save anyway?';

  @override
  String get txFormNoTitle => 'No title';

  @override
  String get allocTitle => 'Budget';

  @override
  String get allocSearchTooltip => 'Search envelopes';

  @override
  String get allocHelpTooltip => 'How envelopes work';

  @override
  String get allocHelpTitle => 'How Envelopes Work';

  @override
  String get allocHelpStep1 => 'Create envelopes for each spending category';

  @override
  String get allocHelpStep2 => 'Set a monthly budget target for each';

  @override
  String get allocHelpStep3 => 'Fund envelopes when you get paid';

  @override
  String get allocHelpStep4 => 'Spend from envelopes — track what\'s left';

  @override
  String get allocSearchHint => 'Search envelopes...';

  @override
  String get allocNewPeriodStarted => 'New period started';

  @override
  String allocNNeedReview(int count) {
    return '$count envelope(s) need review';
  }

  @override
  String get allocReview => 'Review';

  @override
  String get allocBudgeted => 'Budgeted';

  @override
  String get allocSpent => 'Spent';

  @override
  String get allocRemaining => 'Remaining';

  @override
  String get allocUnallocated => 'Unallocated';

  @override
  String get allocFundEnvelopes => 'Fund Envelopes';

  @override
  String get allocSectionSpending => 'Spending';

  @override
  String get allocSectionSavings => 'Savings';

  @override
  String get allocSectionFlexible => 'Rollover';

  @override
  String allocNoMatch(String query) {
    return 'No envelopes match \"$query\"';
  }

  @override
  String get allocCreateTooltip => 'Create envelope';

  @override
  String get allocNoYet => 'No envelopes yet';

  @override
  String get allocCreateHelp =>
      'Create an envelope to start budgeting.\nTap ? for help.';

  @override
  String get allocCreateButton => 'Create Envelope';

  @override
  String get allocNewEnvelope => 'New Envelope';

  @override
  String get allocFallbackName => 'Envelope';

  @override
  String get allocEditSettings => 'Edit Settings';

  @override
  String get allocWithdrawMenu => 'Withdraw';

  @override
  String get allocRevalueMenu => 'Revalue Balances';

  @override
  String get allocArchiveMenu => 'Archive';

  @override
  String get allocCreateButtonDetail => 'Create Envelope';

  @override
  String get allocSaveChanges => 'Save Changes';

  @override
  String get allocNameIconSection => 'NAME & ICON';

  @override
  String get allocNameHint => 'Envelope name (e.g. Groceries)';

  @override
  String get allocRemoveIcon => 'Remove icon';

  @override
  String get allocTypeSection => 'ENVELOPE TYPE';

  @override
  String get allocSpendingTitle => 'Spending';

  @override
  String get allocSpendingDesc =>
      'For recurring expenses like groceries or fuel. Set a monthly budget and spend from it.';

  @override
  String get allocSavingGoalTitle => 'Saving (with goal)';

  @override
  String get allocSavingGoalDesc =>
      'For a specific goal like taxes or vacation. Set a target and fund it over time.';

  @override
  String get allocSavingOpenTitle => 'Saving (open)';

  @override
  String get allocSavingOpenDesc =>
      'For general savings with no specific goal. Put money aside whenever you can.';

  @override
  String get allocInfoBanner =>
      'Envelopes don\'t move money between accounts. They help you plan how to use the money you already have.';

  @override
  String get allocPurposeSection => 'PURPOSE';

  @override
  String get allocSaving => 'Saving';

  @override
  String get allocFlexible => 'Rollover';

  @override
  String get allocCycleSection => 'CYCLE';

  @override
  String get allocPeriodicDesc =>
      '• Periodic: resets each month (e.g. groceries budget)\\n• Permanent: accumulates over time (e.g. emergency fund)';

  @override
  String get allocPeriodic => 'Periodic';

  @override
  String get allocPermanent => 'Permanent';

  @override
  String get allocRolloverTitle => 'Rollover balance';

  @override
  String get allocRolloverSubtitle =>
      'Carry remaining funds to the next period';

  @override
  String get allocAutoResetTitle => 'Auto-reset';

  @override
  String get allocAutoResetSubtitle => 'Reset automatically at period start';

  @override
  String get allocSavingsTargetSection => 'SAVINGS TARGET';

  @override
  String get allocMonthlyBudgetSection => 'MONTHLY BUDGET';

  @override
  String get allocSavingsTargetHelp =>
      'How much do you want to save in this envelope?';

  @override
  String get allocMonthlyBudgetHelp =>
      'How much do you want to spend in this envelope each month?';

  @override
  String get allocTargetAmount => 'Target amount';

  @override
  String get allocBudgetAmount => 'Budget amount';

  @override
  String get allocLinkedCategories => 'LINKED CATEGORIES';

  @override
  String get allocLinkedHelp =>
      'Expenses with these categories will debit this envelope.';

  @override
  String get allocNoCategoriesWarning =>
      'No categories linked. Tap + to link categories so expenses debit this envelope.';

  @override
  String get allocLinkCategory => 'Link Category';

  @override
  String get allocSavedLabel => 'Saved';

  @override
  String get allocAvailableLabel => 'Available';

  @override
  String get allocLeftSuffix => 'left';

  @override
  String get allocFromUnallocated => 'From your unallocated balance';

  @override
  String get allocOverfundingTitle => 'Over-funding';

  @override
  String get allocOverfundingMsg =>
      'Your unallocated balance will go negative. Continue anyway?';

  @override
  String get allocFundAnyway => 'Fund Anyway';

  @override
  String allocCouldNotFund(String error) {
    return 'Could not fund: $error';
  }

  @override
  String get allocRecentActivity => 'RECENT ACTIVITY';

  @override
  String get allocNoActivity => 'No activity yet';

  @override
  String get allocLedgerFunded => 'Funded';

  @override
  String get allocLedgerSpent => 'Spent';

  @override
  String get allocLedgerAdjustment => 'Adjustment';

  @override
  String get allocLedgerPeriodReset => 'Period Reset';

  @override
  String get allocLedgerCarried => 'Carried Forward';

  @override
  String get allocSpendingHistory => 'SPENDING HISTORY';

  @override
  String get allocWithdrawTitle => 'Withdraw from Savings';

  @override
  String get allocWithdrawHelp =>
      'Move money from this envelope back to Unallocated.';

  @override
  String get allocWithdrawAmount => 'Amount to withdraw';

  @override
  String get allocWithdrawButton => 'Withdraw';

  @override
  String get allocAllLinked => 'All categories are already linked to envelopes';

  @override
  String get allocLinkTitle => 'Link a Category';

  @override
  String get allocNoForeignBalances =>
      'No foreign-currency balances to revalue';

  @override
  String get allocRevalueTitle => 'Revalue Foreign Balances';

  @override
  String get allocBalanceInEnvelope => 'balance in this envelope';

  @override
  String get allocOriginalRate => 'Original rate';

  @override
  String get allocOriginalValue => 'Original value';

  @override
  String get allocNewRate => 'New rate';

  @override
  String get allocFetchButton => 'Fetch';

  @override
  String get allocNewValue => 'New value';

  @override
  String get allocGain => 'Gain';

  @override
  String get allocLoss => 'Loss';

  @override
  String get allocTotalAdjustment => 'Total adjustment';

  @override
  String get allocApplyRevaluation => 'Apply Revaluation';

  @override
  String get allocRevaluationApplied => 'Revaluation applied';

  @override
  String get allocArchiveTitle => 'Archive Envelope';

  @override
  String get allocArchiveMsg =>
      'This envelope will be hidden from all lists. Linked categories and transaction history will be preserved.\\n\\nYou can unarchive it later from Settings.';

  @override
  String get allocArchived => 'Envelope archived';

  @override
  String get allocDeleteTitle => 'Delete Envelope';

  @override
  String get allocArchiveInstead => 'Archive Instead';

  @override
  String get allocDeletePermanently => 'Delete Permanently';

  @override
  String get allocDeleteNoLinkedTitle => 'Delete Envelope Permanently';

  @override
  String get allocDeleteNoLinkedMsg =>
      'This envelope has no linked categories. All ledger history will be removed.\\n\\nAre you sure? This cannot be undone.';

  @override
  String get allocCreated => 'Envelope created';

  @override
  String get allocUpdated => 'Envelope updated';

  @override
  String get allocSavedPrefix => 'Saved:';

  @override
  String allocPercentSaved(double pct) {
    return '$pct% saved';
  }

  @override
  String get allocFlexibleTitle => 'Rollover';

  @override
  String get allocFlexibleDesc =>
      'Unspent money rolls over to the next period. Set an optional target, or leave it open.';

  @override
  String get allocCycleHelp =>
      '• Periodic: resets each month (e.g. groceries budget)\n• Permanent: accumulates over time (e.g. emergency fund)';

  @override
  String get allocRolloverBalance => 'Rollover balance';

  @override
  String get allocRolloverDesc => 'Carry remaining funds to the next period';

  @override
  String get allocAutoReset => 'Auto-reset';

  @override
  String get allocAutoResetDesc => 'Reset automatically at period start';

  @override
  String get allocMonthlyBudget => 'MONTHLY BUDGET';

  @override
  String get allocTargetOptional => 'TARGET (OPTIONAL)';

  @override
  String get allocMonthlyBudgetDesc =>
      'How much do you want to spend in this envelope each month?';

  @override
  String get allocTargetDesc =>
      'Set a target amount, or leave at zero for open-ended.';

  @override
  String get allocLinkedCategoriesSection => 'LINKED CATEGORIES';

  @override
  String get allocLinkedCategoriesDesc =>
      'Expenses with these categories will debit this envelope.';

  @override
  String get allocNoCategoriesLinked =>
      'No categories linked. Tap + to link categories so expenses debit this envelope.';

  @override
  String get allocAvailable => 'Available';

  @override
  String allocPercentOfTarget(int percent, String target) {
    return '$percent% of $target';
  }

  @override
  String allocAmountLeft(String amount) {
    return '$amount left';
  }

  @override
  String get allocFund => 'Fund';

  @override
  String allocFundEnvelope(String name) {
    return 'Fund $name';
  }

  @override
  String get allocOverFundingTitle => 'Over-funding';

  @override
  String allocOverFundingMsg(String deficit, String available) {
    return 'You\'re assigning $deficit more than your available $available unallocated balance.\n\nYour unallocated balance will go negative. Continue anyway?';
  }

  @override
  String get allocFundedNote => 'Funded from Unallocated';

  @override
  String allocFundedSuccess(String amount, String name) {
    return 'Funded $amount to $name';
  }

  @override
  String get allocFundError => 'Could not fund envelope. Please try again.';

  @override
  String get allocEntryFunded => 'Funded';

  @override
  String get allocEntrySpent => 'Spent';

  @override
  String get allocEntryAdjustment => 'Adjustment';

  @override
  String get allocEntryPeriodReset => 'Period Reset';

  @override
  String get allocEntryCarryForward => 'Carried Forward';

  @override
  String get allocWithdrawDesc =>
      'Move money from this envelope back to Unallocated.';

  @override
  String get allocWithdrawAmountLabel => 'Amount to withdraw';

  @override
  String allocWithdrawSuccess(String amount) {
    return 'Withdrew $amount to Unallocated';
  }

  @override
  String get allocLinkCategoryTitle => 'Link a Category';

  @override
  String get allocSearchCategories => 'Search categories...';

  @override
  String get allocNoMatchingCategories => 'No matching categories';

  @override
  String get allocAllCategoriesLinked =>
      'All categories are already linked to envelopes';

  @override
  String get allocRevalueForeignTitle => 'Revalue Foreign Balances';

  @override
  String get allocFetch => 'Fetch';

  @override
  String get allocRevalApplied => 'Revaluation applied';

  @override
  String get allocRevalError =>
      'Could not apply revaluation. Please try again.';

  @override
  String allocFetchRateError(String currency) {
    return 'Could not fetch rate for $currency';
  }

  @override
  String allocDeleteLinkedWarning(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories are',
      one: '1 category is',
    );
    return '$_temp0 linked to this envelope ($names)';
  }

  @override
  String allocDeleteAndMore(int count) {
    return ' and $count more';
  }

  @override
  String get allocDeleteConsequences =>
      'Deleting will:\n  • Unlink all categories from this envelope\n  • Remove all ledger history for this envelope\n\nConsider archiving instead to preserve history.';

  @override
  String get allocDeleteNoLinksTitle => 'Delete Envelope Permanently';

  @override
  String get allocDeleteNoLinksMsg =>
      'This envelope has no linked categories. All ledger history will be removed.\n\nAre you sure? This cannot be undone.';

  @override
  String get allocDeleteError => 'Could not delete. Please try again.';

  @override
  String get allocEnvelopeCreated => 'Envelope created';

  @override
  String get allocEnvelopeUpdated => 'Envelope updated';

  @override
  String get allocGotIt => 'Got it';

  @override
  String allocBaseCurrencyOnly(String currency, int count) {
    return '$currency envelopes only · $count in other currencies';
  }

  @override
  String get allocHideOtherCurrencies => 'Hide other currencies';

  @override
  String allocDailyBudget(String amount, int days) {
    return '$amount/day for $days days';
  }

  @override
  String allocOtherCurrencies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count other currencies',
      one: '+ 1 other currency',
    );
    return '$_temp0';
  }

  @override
  String get allocGoalsLoans => 'Goals & Loans';

  @override
  String allocGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals',
      one: '1 goal',
    );
    return '$_temp0';
  }

  @override
  String allocLoansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count loans',
      one: '1 loan',
    );
    return '$_temp0';
  }

  @override
  String allocNEnvelopesNeedReset(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count envelopes need reset',
      one: '1 envelope needs reset',
    );
    return '$_temp0';
  }

  @override
  String get fundTitle => 'Fund Envelopes';

  @override
  String get fundError => 'Couldn\'t load envelopes';

  @override
  String get fundCouldntLoad => 'Couldn\'t load envelopes';

  @override
  String get fundNoAllocations =>
      'No allocations to fund.\nCreate allocations first.';

  @override
  String get fundHowTitle => 'How does funding work?';

  @override
  String get fundStep1 =>
      'Check your unallocated balance — this is money you haven\'t assigned to any envelope yet.';

  @override
  String get fundStep2 =>
      'Enter how much to put in each envelope, or use \"Quick Fill\" to auto-fill periodic envelopes up to their target.';

  @override
  String get fundStep3 =>
      'Tap \"Fund All\" to move the money into your envelopes.';

  @override
  String get fundAvailableToDistribute => 'Available to distribute';

  @override
  String get fundExceedsWarning => 'Total exceeds available unallocated funds';

  @override
  String get fundQuickFill => 'Quick Fill';

  @override
  String fundQuickFillDesc(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Auto-fill $count periodic envelopes up to their target',
      one: 'Auto-fill 1 periodic envelope up to its target',
    );
    return '$_temp0';
  }

  @override
  String get fundAllAtTarget => 'All periodic envelopes are at their target';

  @override
  String get fundFunded => 'Funded';

  @override
  String fundBalance(String amount) {
    return 'Balance: $amount';
  }

  @override
  String fundFill(String amount) {
    return 'Fill $amount';
  }

  @override
  String get fundEnterAmounts => 'Enter amounts to fund';

  @override
  String fundAllWithTotal(String total) {
    return 'Fund All  ($total)';
  }

  @override
  String get fundOverfundingTitle => 'Over-funding';

  @override
  String fundOverfundingMsg(String details) {
    return 'You\'re assigning $details. Your unallocated balance will go negative.\\n\\nContinue anyway?';
  }

  @override
  String get fundAnyway => 'Fund Anyway';

  @override
  String get fundNote => 'Funded from Unallocated';

  @override
  String get fundSuccess => 'Allocations funded successfully';

  @override
  String fundErrorMsg(String error) {
    return 'Error funding allocations: $error';
  }

  @override
  String get acctTitle => 'Accounts';

  @override
  String get acctNoYet => 'No accounts yet';

  @override
  String get acctTapPlus => 'Tap + to add one';

  @override
  String get acctTotalBalance => 'Total Balance';

  @override
  String get acctAddTooltip => 'Add account';

  @override
  String get acctNewTitle => 'New Account';

  @override
  String get acctTypeCash => 'Cash';

  @override
  String get acctTypeBank => 'Bank';

  @override
  String get acctTypeCredit => 'Credit card';

  @override
  String get acctTypeDigital => 'Digital wallet';

  @override
  String get acctAdjustBalance => 'Adjust Balance';

  @override
  String get acctHideArchived => 'Hide Archived';

  @override
  String get acctShowArchived => 'Show Archived';

  @override
  String get acctSortByName => 'Sort by name';

  @override
  String get acctSortByBalance => 'Sort by balance';

  @override
  String get acctSortByType => 'Sort by type';

  @override
  String acctTravelWallet(String currency) {
    return 'Travel wallet · $currency';
  }

  @override
  String get acctArchived => 'ARCHIVED';

  @override
  String get acctNoArchived => 'No archived accounts';

  @override
  String get acctUnarchiveTitle => 'Unarchive Account';

  @override
  String acctUnarchiveMsg(String name) {
    return 'Restore \"$name\" to your active accounts?';
  }

  @override
  String get acctUnarchive => 'Unarchive';

  @override
  String acctUnarchived(String name) {
    return '$name unarchived';
  }

  @override
  String get acctCurrentBalance => 'Current Balance';

  @override
  String get acctBackFromTrip => 'Back from your trip?';

  @override
  String acctConvertBackDesc(String currency) {
    return 'Convert your remaining $currency balance back and close this travel wallet.';
  }

  @override
  String get acctConvertBackClose => 'Convert Back & Close';

  @override
  String get acctSettings => 'Account Settings';

  @override
  String get acctNameSection => 'NAME';

  @override
  String get acctAccountName => 'Account name';

  @override
  String get acctTypeSection => 'TYPE';

  @override
  String get acctCurrencySection => 'CURRENCY';

  @override
  String get acctSelectCurrency => 'Select currency';

  @override
  String get acctDecimalSection => 'DECIMAL PLACES';

  @override
  String acctDecimalAuto(int count) {
    return 'Auto ($count)';
  }

  @override
  String get acctOpeningBalance => 'OPENING BALANCE';

  @override
  String get acctCreateAccount => 'Create account';

  @override
  String get acctCreated => 'Account created';

  @override
  String get acctUpdated => 'Account updated';

  @override
  String get tmplCreated => 'Template created';

  @override
  String get acctRecentTransactions => 'RECENT TRANSACTIONS';

  @override
  String get acctNoTransactions => 'No transactions yet';

  @override
  String get acctAdjustDesc =>
      'Enter the actual balance of this account. An adjustment transaction will be created for the difference.';

  @override
  String acctCurrentBalanceLabel(String amount) {
    return 'Current balance: $amount';
  }

  @override
  String get acctActualBalance => 'Actual balance';

  @override
  String get acctEnterRealBalance => 'Enter the real balance';

  @override
  String get acctApplyAdjustment => 'Apply Adjustment';

  @override
  String get acctBalanceAdjustment => 'Balance adjustment';

  @override
  String acctBalanceAdjustedBy(String amount) {
    return 'Balance adjusted by $amount';
  }

  @override
  String get acctConvertBack => 'Convert Back';

  @override
  String acctConvertBackMsg(String amount) {
    return 'Convert $amount back to your account';
  }

  @override
  String get acctTransferTo => 'Transfer to';

  @override
  String get acctAmountReceived => 'Amount received';

  @override
  String get acctConvertArchive => 'Convert & Archive';

  @override
  String get acctNoTransferTarget => 'No account to transfer to';

  @override
  String acctConvertedBack(String amount) {
    return 'Converted back $amount and archived';
  }

  @override
  String get acctSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get acctArchiveTitle => 'Archive Account';

  @override
  String get acctArchiveMsg =>
      'This account will be hidden from all lists and dropdowns. Your transactions will be preserved.\n\nYou can unarchive it later from Settings.';

  @override
  String get acctCannotDeleteTitle => 'Cannot Delete Account';

  @override
  String acctCannotDeleteMsg(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'This account has $count transaction reference$_temp0. You can\'t delete it while it has transactions.\n\nWould you like to archive it instead? Archived accounts are hidden from lists but preserve all transaction history.';
  }

  @override
  String get acctDeleteTitle => 'Delete Account Permanently';

  @override
  String get acctDeleteMsg =>
      'This account has no transactions. Are you sure you want to permanently delete it? This cannot be undone.';

  @override
  String get acctArchiveInstead => 'Archive Instead';

  @override
  String acctHasTxnsMsg(int count) {
    return 'This account has $count transaction(s). Archive it to keep everything but hide it, or delete it along with those transactions.';
  }

  @override
  String get acctDeleteWithTxns => 'Delete with transactions';

  @override
  String acctDeleteSharedMsg(int count) {
    return '$count of these are shared with other accounts (transfers or splits). Deleting will also remove them and change those accounts\' balances. Continue?';
  }

  @override
  String acctDeleteCountConfirm(int count) {
    return 'Permanently delete this account and $count transaction(s)? This cannot be undone.';
  }

  @override
  String get catTitle => 'Categories';

  @override
  String get catAddTooltip => 'Add category';

  @override
  String catTotal(int count) {
    return '$count total';
  }

  @override
  String catExpenseCount(int count) {
    return '$count expense';
  }

  @override
  String catIncomeCount(int count) {
    return '$count income';
  }

  @override
  String get catSearchHint => 'Search categories...';

  @override
  String get catAll => 'All';

  @override
  String get catNoYet => 'No categories yet';

  @override
  String get catTapPlus => 'Tap + to create one';

  @override
  String get catNoMatch => 'No matching categories';

  @override
  String get catCouldntLoad => 'Couldn\'t load categories';

  @override
  String catSubcategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subcategories',
      one: '1 subcategory',
    );
    return '$_temp0';
  }

  @override
  String get catSectionExpense => 'EXPENSE';

  @override
  String get catSectionIncome => 'INCOME';

  @override
  String get catEdit => 'Edit';

  @override
  String get catArchive => 'Archive';

  @override
  String get catUnarchive => 'Unarchive';

  @override
  String get catRestored => 'Category restored';

  @override
  String get catArchived => 'Category archived';

  @override
  String get catDeleteTitle => 'Delete Category';

  @override
  String get catDeleteNoTx =>
      'This category has no transactions. Delete permanently?';

  @override
  String get catDeleted => 'Category deleted';

  @override
  String get catNewTitle => 'New Category';

  @override
  String get catEditTitle => 'Edit Category';

  @override
  String get catName => 'Name';

  @override
  String get catParent => 'Parent';

  @override
  String get catNone => 'None';

  @override
  String get catCreate => 'Create';

  @override
  String get catEnterName => 'Enter a category name';

  @override
  String get catCreated => 'Category created';

  @override
  String get catUpdated => 'Category updated';

  @override
  String get commonArchive => 'Archive';

  @override
  String get recurringAddTooltip => 'Add recurring transaction';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String freqEveryNDays(int n) {
    return 'Every $n days';
  }

  @override
  String freqEveryNWeeks(int n) {
    return 'Every $n weeks';
  }

  @override
  String freqEveryNMonths(int n) {
    return 'Every $n months';
  }

  @override
  String freqEveryNYears(int n) {
    return 'Every $n years';
  }

  @override
  String get billCalTitle => 'Bill Calendar';

  @override
  String billCalNDue(int count) {
    return '$count bill(s) due';
  }

  @override
  String get billCalUpcoming => 'UPCOMING';

  @override
  String get billCalNoUpcoming => 'No upcoming bills';

  @override
  String get upcomingTitle => 'Upcoming Bills';

  @override
  String get upcomingNoTitle => 'No upcoming bills';

  @override
  String get upcomingNoSubtitle =>
      'Create recurring transactions to see them here.';

  @override
  String upcomingOverdue(int days) {
    return 'Overdue by $days day(s)';
  }

  @override
  String get upcomingDueToday => 'Due today';

  @override
  String get upcomingDueTomorrow => 'Due tomorrow';

  @override
  String upcomingDueInDays(int days) {
    return 'Due in $days days';
  }

  @override
  String get subTitle => 'Subscriptions';

  @override
  String get subAddTooltip => 'Add subscription';

  @override
  String get subTotal => 'Total';

  @override
  String get subActive => 'Active';

  @override
  String get subCancelled => 'Cancelled';

  @override
  String get subNoTitle => 'No subscriptions';

  @override
  String get subNoSubtitle =>
      'Add a recurring transaction and mark it as a subscription';

  @override
  String get subEndingSoon => 'Ending soon';

  @override
  String get subPause => 'Pause';

  @override
  String get subResume => 'Resume';

  @override
  String get subUntitled => 'Untitled';

  @override
  String get subDetailError => 'Could not load subscription';

  @override
  String get subDetailNotFound => 'Subscription not found';

  @override
  String subDetailAnnualCost(String amount) {
    return 'Annual cost: $amount';
  }

  @override
  String get subDetailStatus => 'Status';

  @override
  String get subDetailActiveSince => 'Active since';

  @override
  String get subDetailNextBilling => 'Next billing';

  @override
  String get subDetailEndsOn => 'Ends on';

  @override
  String get subDetailTotalPaid => 'Total paid (est.)';

  @override
  String get subDetailPriceHistory => 'PRICE HISTORY';

  @override
  String get subDetailPresent => 'present';

  @override
  String get subDetailChangeCancel => 'Change Cancel Date';

  @override
  String get subDetailSetCancel => 'Set Cancellation Date';

  @override
  String get subDetailPastTx => 'PAST TRANSACTIONS';

  @override
  String get subDetailUpcoming => 'UPCOMING';

  @override
  String get subDetailScheduled => 'scheduled';

  @override
  String get subDetailCancelTitle => 'Cancel subscription';

  @override
  String get tmplTitle => 'Templates';

  @override
  String get tmplSortTooltip => 'Sort';

  @override
  String get tmplGroupTooltip => 'Group';

  @override
  String get tmplSortMostUsed => 'Most used';

  @override
  String get tmplSortAz => 'A–Z';

  @override
  String get tmplSortNewest => 'Newest first';

  @override
  String get tmplSortHighest => 'Highest amount';

  @override
  String get tmplGroupNone => 'No grouping';

  @override
  String get tmplGroupType => 'By type';

  @override
  String get tmplGroupCategory => 'By category';

  @override
  String get tmplSearchHint => 'Search templates...';

  @override
  String get tmplNoTitle => 'No templates found';

  @override
  String get tmplNoSubtitle => 'Save frequent transactions for quick re-use';

  @override
  String get tmplAddTooltip => 'Add template';

  @override
  String get tmplUse => 'Use template';

  @override
  String get tmplDeleteTitle => 'Delete template?';

  @override
  String get tmplDeleteMsg => 'This template will be permanently removed.';

  @override
  String get tmplNewTitle => 'New Template';

  @override
  String get tmplNewDesc => 'Save a transaction you do often for quick re-use.';

  @override
  String get tmplTitleRequired => 'Title is required';

  @override
  String get tmplCategoryOptional => 'Category (optional)';

  @override
  String get tmplSaveButton => 'Save Template';

  @override
  String get objTitle => 'Goals & Loans';

  @override
  String get objFailedToLoad => 'Failed to load objectives';

  @override
  String get objNoTitle => 'No goals or loans yet';

  @override
  String get objNoSubtitle =>
      'Create a savings goal or track money you lent or borrowed.';

  @override
  String get objGoalsSection => 'GOALS';

  @override
  String get objLoansSection => 'LOANS';

  @override
  String objLentTo(String contact) {
    return 'Lent to $contact';
  }

  @override
  String objBorrowedFrom(String contact) {
    return 'Borrowed from $contact';
  }

  @override
  String objDue(String date) {
    return 'Due $date';
  }

  @override
  String get objNewTitle => 'New Objective';

  @override
  String get objNameRequired => 'Name is required';

  @override
  String get objCreated => 'Objective created';

  @override
  String get objNotePaymentReceived => 'Payment received';

  @override
  String get objNotePayment => 'Payment';

  @override
  String get objNoteGoalSavings => 'Goal savings';

  @override
  String get objUpdated => 'Objective updated';

  @override
  String get objNoAccounts => 'No accounts available';

  @override
  String get objRecordPayment => 'Record Payment';

  @override
  String get objAddFunds => 'Add Funds';

  @override
  String get objRecordReceived => 'Record Payment Received';

  @override
  String get objRecordSent => 'Record Payment Sent';

  @override
  String get objSaveFromAccount => 'Save from Account';

  @override
  String get objGoalChip => 'Goal';

  @override
  String get objLoanChip => 'Loan';

  @override
  String get objGoalName => 'Goal name';

  @override
  String get objGoalNameHint => 'e.g. Emergency fund';

  @override
  String get objLoanName => 'Loan name';

  @override
  String get objLoanNameHint => 'e.g. Car loan';

  @override
  String get objPerson => 'Person';

  @override
  String get objPersonHint => 'e.g. Ali, Bank, etc.';

  @override
  String get objDirection => 'Direction';

  @override
  String get objILent => 'I lent';

  @override
  String get objIBorrowed => 'I borrowed';

  @override
  String get objSetDeadline => 'Set a deadline (optional)';

  @override
  String get objColorSection => 'COLOR';

  @override
  String get objDeleteTitle => 'Delete Objective';

  @override
  String get objCannotUndo => 'This cannot be undone.';

  @override
  String get objSavedSoFar => 'Saved so far';

  @override
  String get objRecordedSoFar => 'Recorded so far';

  @override
  String get objEmptyHintGoal =>
      'Add funds from one of your accounts to grow this goal.';

  @override
  String get objEmptyHintLoanLent =>
      'Record payments you receive to track repayment.';

  @override
  String get objEmptyHintLoanBorrowed =>
      'Record payments you make to track what you owe.';

  @override
  String get objWhatIsGoal =>
      'Save toward a target. Each deposit moves money out of the account you pick and is recorded as a transaction.';

  @override
  String get objWhatIsLoan =>
      'Track money you lent or borrowed. Each recorded payment moves money in or out of the account you pick.';

  @override
  String get objTargetOptional =>
      'Optional — leave blank for an open-ended goal';

  @override
  String get objIcon => 'Icon';

  @override
  String get objChooseIcon => 'Choose an icon (optional)';

  @override
  String get objRemoveIcon => 'Remove icon';

  @override
  String get objIntro =>
      'Goals track savings toward a target. Loans track money you lent or borrowed.';

  @override
  String get objCreateFirst => 'Create your first goal';

  @override
  String objDeleteLinkedPayments(int count) {
    return '$count linked payment(s). The money already moved between your accounts — keep them, or delete everything?';
  }

  @override
  String get objDeleteKeep => 'Delete, keep payments';

  @override
  String get objDeleteAll => 'Delete everything';

  @override
  String get travelTitle => 'Travel Exchange';

  @override
  String get travelInfo =>
      'Exchange money for your trip. A temporary travel wallet will be created automatically.';

  @override
  String get travelFrom => 'FROM';

  @override
  String get travelSelectAccount => 'Select account';

  @override
  String get travelAmountToExchange => 'AMOUNT TO EXCHANGE';

  @override
  String get travelCurrencySection => 'TRAVEL CURRENCY';

  @override
  String get travelCurrencyReceive => 'Currency you receive';

  @override
  String get travelAmountReceived => 'AMOUNT RECEIVED';

  @override
  String get travelExchangeButton => 'Exchange & Create Travel Wallet';

  @override
  String get travelExistingWallet => 'Existing Travel Wallet';

  @override
  String get travelCreateNew => 'Create New';

  @override
  String get travelReactivate => 'Reactivate';

  @override
  String get periodNewTitle => 'New Period';

  @override
  String get periodError => 'Couldn\'t load envelopes';

  @override
  String get periodResolveLeftovers => 'Resolve leftover balances';

  @override
  String periodNItems(int count) {
    return '$count items';
  }

  @override
  String get periodNoLeftovers => 'No leftover balances to resolve';

  @override
  String get periodAllZero =>
      'All periodic allocations have zero or negative balances.';

  @override
  String get periodCompleteButton => 'Complete Period Transition';

  @override
  String get periodRollover => 'Rollover allocation';

  @override
  String get periodPeriodic => 'Periodic allocation';

  @override
  String get periodReturnUnallocated => 'Return to Unallocated';

  @override
  String get periodReturnDesc => 'Balance returns to the pool';

  @override
  String get periodCarryForward => 'Carry Forward';

  @override
  String get periodCarryDesc => 'Keep balance for next period';

  @override
  String get periodMoveTo => 'Move to...';

  @override
  String get periodMoveDesc => 'Transfer to another allocation';

  @override
  String get periodSelectAllocation => 'Select allocation';

  @override
  String get leftoverTitle => 'Resolve Leftovers';

  @override
  String get leftoverNoAllocation => 'No allocation specified.';

  @override
  String get leftoverNotFound => 'Allocation not found.';

  @override
  String get leftoverCurrentBalance => 'Current Balance';

  @override
  String get leftoverNoBalance => 'No balance';

  @override
  String get leftoverNoPositive => 'No positive balance to resolve.';

  @override
  String get leftoverCurrencyToResolve => 'Currency to resolve';

  @override
  String get leftoverAllCurrencies => 'All currencies';

  @override
  String get leftoverWhatToDo => 'What to do with the leftover';

  @override
  String get leftoverReturnSubtitle => 'Leftover balance goes back to the pool';

  @override
  String get leftoverKeepSubtitle => 'Keep the balance for the next period';

  @override
  String get leftoverMoveTitle => 'Move to another allocation';

  @override
  String get leftoverMoveSubtitle =>
      'Transfer leftover to a different allocation';

  @override
  String get settingsMoreTitle => 'More';

  @override
  String get settingsToolsSection => 'TOOLS';

  @override
  String get settingsAutomationSection => 'AUTOMATION';

  @override
  String get settingsAccountsSub => 'Manage your accounts and balances';

  @override
  String get settingsCategoriesSub => 'Manage groups and categories';

  @override
  String get settingsBillSplitterSub => 'Split bills & scan receipts';

  @override
  String get settingsBillCalendarSub => 'View upcoming recurring bills';

  @override
  String get settingsUpcomingBillsSub => 'Bills due soon with urgency';

  @override
  String get settingsTravelSub => 'Exchange currency for a trip';

  @override
  String get settingsExchangeRatesSub => 'View and refresh currency rates';

  @override
  String get settingsWebCompanionSub => 'Manage your budget from a browser';

  @override
  String get settingsRecurringSub => 'Manage recurring transactions';

  @override
  String get settingsTemplatesSub => 'Save frequent transactions';

  @override
  String get settingsSubscriptionsSub => 'Track recurring subscriptions';

  @override
  String get settingsGoalsSub => 'Savings goals and debt tracking';

  @override
  String get settingsPeriodSub => 'End period and resolve leftovers';

  @override
  String get settingsCustomization => 'Settings & Customization';

  @override
  String get settingsCustomizationSub => 'Theme, font, data, preferences';

  @override
  String get settingsAbout => 'About BudgetSeal';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeBlack => 'Black';

  @override
  String get themeSystem => 'System';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeTitle => 'Theme';

  @override
  String get autofillTitle => 'Auto-fill Settings';

  @override
  String get autofillDesc =>
      'When you pick a category, these fields are pre-filled from your last transaction with that category.';

  @override
  String get autofillAccount => 'Account';

  @override
  String get autofillAccountSub => 'Use the same account as last time';

  @override
  String get autofillTitleToggle => 'Title';

  @override
  String get autofillTitleSub => 'Copy the title from last time';

  @override
  String get autofillAmountToggle => 'Amount';

  @override
  String get autofillAmountSub => 'Copy the amount from last time';

  @override
  String get autofillCategoryToggle => 'Category';

  @override
  String get autofillCategorySub => 'Remember last used category per account';

  @override
  String get autofillOverride => 'Override existing values';

  @override
  String get autofillOverrideSub =>
      'Replace fields even if you already filled them';

  @override
  String get resetTitle => 'Reset Everything';

  @override
  String get resetContent =>
      'This will permanently delete ALL your data:\\n\\n• All accounts and balances\\n• All transactions\\n• All envelopes and categories\\n• All settings\\n\\nThis cannot be undone. Are you absolutely sure?';

  @override
  String get resetButton => 'Delete Everything';

  @override
  String get txColorsTitle => 'Transaction Colors';

  @override
  String get txColorsDesc =>
      'Choose a color for each transaction type. These colors are used throughout the app to visually distinguish income, expenses, and transfers.';

  @override
  String get txColorsReset => 'Reset to Defaults';

  @override
  String get householdNameTitle => 'Household Name';

  @override
  String get tileBillCalendar => 'Bill Calendar';

  @override
  String get tileUpcomingBills => 'Upcoming Bills';

  @override
  String get tileTravelExchange => 'Travel Exchange';

  @override
  String get tileExchangeRates => 'Exchange Rates';

  @override
  String get tileWebCompanion => 'Web Companion';

  @override
  String get tileRecurring => 'Recurring';

  @override
  String get tileTemplates => 'Templates';

  @override
  String get tileSubscriptions => 'Subscriptions';

  @override
  String get tileGoalsLoans => 'Goals & Loans';

  @override
  String get tilePeriodTransition => 'Period Transition';

  @override
  String get syncTitle => 'Cloud Sync';

  @override
  String get syncNotConnected => 'Not connected';

  @override
  String get syncSyncing => 'Syncing...';

  @override
  String get syncLastFailed => 'Last sync failed';

  @override
  String get syncNotYet => 'Not yet synced';

  @override
  String get syncConnectPrompt => 'Connect a cloud provider to sync your data';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncShareHousehold => 'Share Household';

  @override
  String get syncDisconnect => 'Disconnect';

  @override
  String get syncConnectSection => 'CONNECT A PROVIDER';

  @override
  String get syncReceiptComingSoon =>
      'Receipt sync coming soon for this provider';

  @override
  String get syncProviderInfo =>
      'OneDrive and Dropbox open the system file picker, which can access those services when their apps are installed on your device. Google Drive requires a Google Cloud project with OAuth configured.';

  @override
  String get syncConnectionFailed => 'Connection Failed';

  @override
  String get syncFailedToConnect => 'Failed to connect';

  @override
  String get syncDisconnectMsg =>
      'Your data will remain on your device, but automatic sync will stop. You can reconnect at any time.';

  @override
  String get syncShareDesc =>
      'Share your BudgetSeal data with another person. They will be able to sync to the same file on Google Drive.';

  @override
  String get syncTheirEmail => 'Their email address';

  @override
  String get syncEmailHint => 'partner@gmail.com';

  @override
  String get syncSharing => 'Sharing...';

  @override
  String get syncGenerateInvite => 'Generate Invite Code';

  @override
  String get syncInviteCode => 'Invite Code';

  @override
  String get syncShareCode => 'Share Code';

  @override
  String get syncValidEmailError => 'Please enter a valid email address';

  @override
  String get syncEncryptionTitle => 'Sync Encryption';

  @override
  String get syncEncrypted => 'Your sync file is encrypted with AES-256';

  @override
  String get syncNotEncrypted => 'Sync file is not encrypted';

  @override
  String get syncGdriveWarning =>
      'Anyone with access to your Google Drive can read your financial data';

  @override
  String get syncSetPasswordTitle => 'Set Sync Password';

  @override
  String get syncPasswordDesc =>
      'This password encrypts your sync file on Google Drive. You\'ll need the same password on any other device that syncs with this household.';

  @override
  String get syncPasswordLabel => 'Password';

  @override
  String get syncPasswordHint => 'Enter a strong password';

  @override
  String get syncConfirmPassword => 'Confirm Password';

  @override
  String get syncSetPasswordButton => 'Set Password';

  @override
  String get syncPasswordsDontMatch => 'Passwords don\'t match';

  @override
  String get syncEncryptionEnabled =>
      'Sync encryption enabled. Next sync will be encrypted.';

  @override
  String get syncRemoveEncryptionTitle => 'Remove Encryption?';

  @override
  String get syncRemoveEncryptionMsg =>
      'Future sync files will be unencrypted. Other devices will need to remove their password too.';

  @override
  String get syncEncryptionRemoved => 'Sync encryption removed';

  @override
  String get providerGoogleDrive => 'Google Drive';

  @override
  String get providerGoogleDriveSub => 'Sign in with your Google account';

  @override
  String get providerOnedrive => 'OneDrive';

  @override
  String get providerOnedriveSub => 'Requires the OneDrive app installed';

  @override
  String get providerDropbox => 'Dropbox';

  @override
  String get providerDropboxSub => 'Requires the Dropbox app installed';

  @override
  String get providerLocalFile => 'Local File';

  @override
  String get providerLocalFileSub => 'Pick any file on your device';

  @override
  String get syncNoFileFound => 'No sync file found';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupAutoTitle => 'Automatic Backups';

  @override
  String get backupEnable => 'Enable automatic backups';

  @override
  String get backupDisabled => 'Disabled';

  @override
  String get backupFrequency => 'Frequency';

  @override
  String get backupEvery6h => 'Every 6 hours';

  @override
  String get backupEvery12h => 'Every 12 hours';

  @override
  String get backupDaily => 'Daily';

  @override
  String get backupEvery3d => 'Every 3 days';

  @override
  String get backupWeekly => 'Weekly';

  @override
  String get backupKeepLast => 'Keep last';

  @override
  String backupNBackups(int n) {
    return '$n backups';
  }

  @override
  String get backupManualTitle => 'Manual Backup';

  @override
  String get backupExportDesc =>
      'Export your database to share or store externally.';

  @override
  String get backupExporting => 'Exporting...';

  @override
  String get backupExportShare => 'Export & Share';

  @override
  String get backupRestoreTitle => 'Restore';

  @override
  String get backupRestoreDesc => 'Pick a .db file to restore from.';

  @override
  String get backupRestoreFromFile => 'Restore from File';

  @override
  String get backupLocalSection => 'LOCAL BACKUPS';

  @override
  String get backupRestoreDialogTitle => 'Restore Backup';

  @override
  String get backupRestoreWarning =>
      'This will replace ALL current data with the backup. This cannot be undone. Continue?';

  @override
  String get backupRestored => 'Backup restored. Please restart the app.';

  @override
  String get backupRestoreFailed =>
      'Restore failed. The backup may be corrupted.';

  @override
  String get backupDbNotFound => 'Database file not found';

  @override
  String get backupTooLarge => 'Backup file too large (max 100MB)';

  @override
  String get backupInvalid => 'Invalid backup file — not a valid database';

  @override
  String get ieTitle => 'Import & Export';

  @override
  String get ieImportCsv => 'Import CSV';

  @override
  String get ieImportCsvSub => 'Import transactions from a bank CSV file';

  @override
  String get ieExportCsv => 'Export CSV';

  @override
  String get ieExportCsvSub => 'Export transactions as a spreadsheet';

  @override
  String get ieExportReport => 'Export Report';

  @override
  String get ieExportReportSub => 'Generate a printable monthly report';

  @override
  String get exportDataTitle => 'Export Data';

  @override
  String get exportTransTitle => 'Export Transactions';

  @override
  String get exportTransDesc =>
      'Export all your transactions as a CSV file. You can open it in Excel, Google Sheets, or any spreadsheet app.';

  @override
  String get exportReportTitle => 'Export Report';

  @override
  String get exportMonthlyTitle => 'Monthly Report';

  @override
  String get exportMonthlyDesc =>
      'Generate a printable HTML report for a selected month. Open it in a browser and use Print > Save as PDF.';

  @override
  String get exportGenerating => 'Generating...';

  @override
  String get exportGenerateShare => 'Generate & Share';

  @override
  String get exportSpendingByCat => 'Spending by Category';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifDailyTitle => 'Daily Reminder';

  @override
  String get notifDailyEnable => 'Enable daily reminder';

  @override
  String get notifDailyDisabled => 'Remind me to log transactions';

  @override
  String get notifTime => 'Time';

  @override
  String get notifCustomMessage => 'Custom message (optional)';

  @override
  String get notifEnvelopeTitle => 'Envelope Alerts';

  @override
  String get notifEnvelopeDesc =>
      'You\'ll receive a notification when envelopes are overspent. These check on app startup, at most once every 6 hours.';

  @override
  String get notifBillsTitle => 'Upcoming Bills';

  @override
  String get notifBillsDesc =>
      'You\'ll receive a notification when recurring transactions are due within 2 days. Checks on app startup.';

  @override
  String get fxTitle => 'Exchange Rates';

  @override
  String get fxRefreshTooltip => 'Refresh rates';

  @override
  String get fxCouldNotFetch => 'Could not fetch rates';

  @override
  String get fxNoRates => 'No rates available';

  @override
  String get fxCheckInternet => 'Check your internet connection and try again.';

  @override
  String get fxCacheInfo =>
      'Rates are fetched from the internet and cached for 1 hour. They are auto-filled when creating transactions.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutShare => 'Share';

  @override
  String get aboutContact => 'Contact';

  @override
  String get aboutShareText =>
      'Check out BudgetSeal — envelope budgeting made simple!';

  @override
  String get aboutPrivacy => 'No tracking. Your data stays on your device.';

  @override
  String get aboutCredit => 'Made by Samer';

  @override
  String get aboutPrivacyTerms => 'Privacy & Terms';

  @override
  String get aboutLicenses => 'Licenses';

  @override
  String aboutLegalese(int year) {
    return '© $year Samer Cheaib. All rights reserved.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceSection => 'APPEARANCE';

  @override
  String get settingsDataSection => 'DATA';

  @override
  String get settingsPreferencesSection => 'PREFERENCES';

  @override
  String get settingsSecuritySection => 'SECURITY';

  @override
  String get tileRecurringBills => 'Recurring & Bills';

  @override
  String get tileBillSplitter => 'Bill Splitter';

  @override
  String get tileHelpGuide => 'Help Guide';

  @override
  String get settingsHelpSub => 'How to use BudgetSeal';

  @override
  String get tileTheme => 'Theme';

  @override
  String get tileAccentColor => 'Accent Color';

  @override
  String get tileColors => 'Colors';

  @override
  String get tileColorsSub => 'Income, expense & transfer';

  @override
  String get tileEntryMode => 'Entry Mode';

  @override
  String get tileAutofill => 'Auto-fill';

  @override
  String get tileAutofillSub => 'Pre-fill fields from last transaction';

  @override
  String get tileStartScreen => 'Start Screen';

  @override
  String get tileFont => 'Font';

  @override
  String get tileTextSize => 'Text Size';

  @override
  String get tileTxList => 'Transaction List';

  @override
  String get tileTxListSub => 'Layout, icons, date banner';

  @override
  String get tileCloudSync => 'Cloud Sync';

  @override
  String get tileCloudSyncSub => 'Sync across devices';

  @override
  String get tileShareHousehold => 'Share Household';

  @override
  String get tileShareHouseholdConnected => 'Invite someone to share your data';

  @override
  String get tileShareHouseholdDisconnected =>
      'Connect Cloud Sync first to share';

  @override
  String get tileShareHouseholdSnackbar =>
      'Set up Cloud Sync with Google Drive first to share your household.';

  @override
  String get tileBackupRestore => 'Backup & Restore';

  @override
  String get tileBackupRestoreSub => 'Export or restore database';

  @override
  String get tileImportExport => 'Import & Export';

  @override
  String get tileImportExportSub => 'CSV import, export, and reports';

  @override
  String get tileNotifications => 'Notifications';

  @override
  String get tileNotificationsSub => 'Daily reminder, envelope & bill alerts';

  @override
  String get tileHealthCheck => 'Health Check';

  @override
  String get tileHealthCheckSub => 'Verify data integrity & repair';

  @override
  String get tileSyncReceipts => 'Sync Receipts';

  @override
  String get tileSyncReceiptsOn => 'Upload receipt photos to cloud storage';

  @override
  String get tileSyncReceiptsOff => 'Receipts are stored on this device only';

  @override
  String get tileBaseCurrency => 'Base Currency';

  @override
  String get tilePeriodStartDay => 'Period Start Day';

  @override
  String get tilePeriodStartDayDesc =>
      'The day of the month when a new budget period starts.';

  @override
  String get tileCurrencySymbols => 'Currency Symbols';

  @override
  String get tileCurrencySymbolsSub => 'Override how currencies are displayed';

  @override
  String get tileNumberFormat => 'Number Format';

  @override
  String get tileDateFormat => 'Date Format';

  @override
  String get tileBiometricLock => 'Biometric Lock';

  @override
  String get tileBiometricSub => 'Require fingerprint or face to open';

  @override
  String get tileResetEverything => 'Reset Everything';

  @override
  String get tileResetSub => 'Erase all data and start fresh';

  @override
  String get entryModeTitle => 'Entry Mode';

  @override
  String get entryModeDesc => 'Choose how you add new transactions.';

  @override
  String get entryModeAssisted => 'Assisted (Step-by-step)';

  @override
  String get entryModeAssistedDesc =>
      'Guides you through adding a transaction step by step. First pick a title, then a category, then enter the amount. Best for beginners.';

  @override
  String get entryModeClassic => 'Classic (Single form)';

  @override
  String get entryModeClassicDesc =>
      'All fields on one screen. Fill in what you need and save. Faster for experienced users.';

  @override
  String get entryModeAssistedShort => 'Assisted (step-by-step)';

  @override
  String get entryModeClassicShort => 'Classic (single form)';

  @override
  String get themeFollowDevice => 'Follow device settings';

  @override
  String get themeAmoled => 'AMOLED pure black';

  @override
  String get accentColorTitle => 'Accent Color';

  @override
  String get accentColorSystem => 'System';

  @override
  String get accentColorSystemSub => 'Material You (Android 12+)';

  @override
  String get accentColorRoyalBlue => 'Royal Blue';

  @override
  String get accentColorDefault => 'Default';

  @override
  String get accentColorSystemLabel => 'System (Material You)';

  @override
  String get startScreenTitle => 'Start Screen';

  @override
  String get startScreenDesc => 'Opens when you launch the app.';

  @override
  String get chooseFontTitle => 'Choose Font';

  @override
  String get fontPreview => 'The quick brown fox jumps over the lazy dog';

  @override
  String get textSizeTitle => 'Text Size';

  @override
  String get textSizePreview => 'Preview text at this size';

  @override
  String get currencySymbolsTitle => 'Currency Symbols';

  @override
  String get currencySymbolsDesc =>
      'Tap any currency to change how its symbol is displayed. For example, change ل.ل to LBP.';

  @override
  String get currencySymbolsAllSection => 'ALL CURRENCIES';

  @override
  String currencySymbolDefault(String symbol) {
    return 'Default: $symbol';
  }

  @override
  String currencySymbolFor(String code) {
    return 'Symbol for $code';
  }

  @override
  String get numberFormatTitle => 'Number Format';

  @override
  String get numberFormatDesc =>
      'Choose how numbers are displayed throughout the app.';

  @override
  String get numberFormatPreview => 'Preview';

  @override
  String get numberFormatThousands => 'Thousands Separator';

  @override
  String get numberFormatDecimal => 'Decimal Separator';

  @override
  String get numberFormatNegative => 'Negative Numbers';

  @override
  String get numberFormatConflict =>
      'Some options are hidden because they conflict with the decimal separator.';

  @override
  String get dateFormatTitle => 'Date Format';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication is not available on this device';

  @override
  String get biometricVerify => 'Verify to enable biometric lock';

  @override
  String get biometricFailed =>
      'Authentication failed — biometric lock not enabled';

  @override
  String get biometricError =>
      'Authentication error — biometric lock not enabled';

  @override
  String get biometricNotEnrolled =>
      'No biometrics enrolled on this device. Please set up fingerprint or face unlock in your device settings, then try again.';

  @override
  String get biometricLockedOut =>
      'Too many attempts. Please wait and try again.';

  @override
  String get biometricPasscodeNotSet =>
      'No screen lock is set up on this device. Please set up a PIN, pattern, or password first.';

  @override
  String get backupBannerNoBackup => 'You haven\'t backed up yet';

  @override
  String backupBannerDaysAgo(int days) {
    return 'You haven\'t backed up in $days days';
  }

  @override
  String get backupNowButton => 'Backup Now';

  @override
  String syncShareInviteText(String code) {
    return 'Join my BudgetSeal household! Enter this code in the app:\n$code';
  }

  @override
  String get privacyTermsTitle => 'Privacy & Terms';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyLastUpdated => 'Last updated: May 2026';

  @override
  String get privacyIntro =>
      'BudgetSeal is designed with your privacy as a core principle. Your financial data belongs to you — we never collect, store, or transmit it to any server.';

  @override
  String get privacyDataStorageTitle => '1. Data Storage';

  @override
  String get privacyDataStorageBody =>
      'All your financial data (transactions, accounts, envelopes, categories, goals, and settings) is stored locally on your device in an SQLite database. No data leaves your device unless you explicitly enable Cloud Sync.';

  @override
  String get privacyCloudSyncTitle => '2. Cloud Sync (Optional)';

  @override
  String get privacyCloudSyncBody =>
      'If you choose to enable Cloud Sync, your data is uploaded to your personal Google Drive account or a file storage provider you select. BudgetSeal does not have access to your Google account credentials — authentication is handled by Google\'s OAuth system.\n\nYou may optionally encrypt your sync file with AES-256 encryption using a password you set. The password is stored only on your device in secure storage (Android Keystore / iOS Keychain).';

  @override
  String get privacyWebCompanionTitle => '3. Web Companion';

  @override
  String get privacyWebCompanionBody =>
      'The Web Companion feature runs a local HTTP server on your phone. It is only accessible from devices on the same WiFi network (private IP addresses). No data is sent to the internet. The connection is protected by a PIN, session tokens, and rate limiting. The server stops automatically after 6 hours.';

  @override
  String get privacyAnalyticsTitle => '4. Analytics & Tracking';

  @override
  String get privacyAnalyticsBody =>
      'BudgetSeal does not include any analytics SDKs, crash reporting tools, advertising libraries, or tracking pixels. No usage data, device identifiers, or behavioral metrics are collected.';

  @override
  String get privacyPermissionsTitle => '5. Permissions';

  @override
  String get privacyPermissionsBody =>
      '• Camera — used only for receipt scanning (offline OCR)\n• Notifications — daily reminders and bill alerts\n• Biometrics — optional app lock\n• Network — only for Cloud Sync and exchange rate fetching\n• Local Network — Web Companion server\n\nAll permissions are optional and can be denied without affecting core functionality.';

  @override
  String get privacyReceiptsTitle => '6. Receipt Images';

  @override
  String get privacyReceiptsBody =>
      'Receipt photos are stored in the app\'s private directory on your device. They are not uploaded anywhere unless you enable receipt sync via Google Drive. OCR processing is performed entirely offline using on-device ML.';

  @override
  String get privacyBackupsTitle => '7. Backups';

  @override
  String get privacyBackupsBody =>
      'Automatic backups are stored locally in the app\'s documents directory. You control backup frequency and retention. Exported backup files are shared via the system share sheet and deleted from temporary storage afterward.';

  @override
  String get termsOfUseTitle => 'Terms of Use';

  @override
  String get termsAcceptanceTitle => '1. Acceptance';

  @override
  String get termsAcceptanceBody =>
      'By using BudgetSeal, you agree to these terms. If you do not agree, please uninstall the app.';

  @override
  String get termsIntendedUseTitle => '2. Intended Use';

  @override
  String get termsIntendedUseBody =>
      'BudgetSeal is a personal finance management tool for individual and household budgeting. It is not intended for commercial accounting, tax preparation, or financial advice. The app provides tools to organize your finances — it does not provide financial recommendations.';

  @override
  String get termsDataAccuracyTitle => '3. Data Accuracy';

  @override
  String get termsDataAccuracyBody =>
      'You are responsible for the accuracy of the data you enter. BudgetSeal calculates balances, budgets, and reports based on your input. Exchange rates fetched from external sources are approximate and may not reflect real-time market rates.';

  @override
  String get termsNoWarrantyTitle => '4. No Warranty';

  @override
  String get termsNoWarrantyBody =>
      'BudgetSeal is provided \"as is\" without warranty of any kind. While we strive for reliability, we cannot guarantee that the app will be error-free or uninterrupted. Regular backups are strongly recommended.';

  @override
  String get termsLiabilityTitle => '5. Limitation of Liability';

  @override
  String get termsLiabilityBody =>
      'The developer shall not be liable for any direct, indirect, incidental, or consequential damages arising from the use of BudgetSeal, including but not limited to data loss, financial miscalculations, or sync failures.';

  @override
  String get termsIPTitle => '6. Intellectual Property';

  @override
  String get termsIPBody =>
      'BudgetSeal and its original content are protected by copyright. The app uses open-source libraries listed in the Licenses section of the About screen.';

  @override
  String get termsChangesTitle => '7. Changes';

  @override
  String get termsChangesBody =>
      'These terms may be updated with new app versions. Continued use after an update constitutes acceptance of the revised terms.';

  @override
  String get termsContactTitle => '8. Contact';

  @override
  String get termsContactBody =>
      'For questions or concerns about this privacy policy or terms of use, contact: fancyshark505@gmail.com';

  @override
  String get healthTitle => 'Health Check';

  @override
  String get healthExportTooltip => 'Export report';

  @override
  String get healthRerunTooltip => 'Re-run check';

  @override
  String get healthAllClear => 'All Clear';

  @override
  String get healthIssuesFound => 'Issues Found';

  @override
  String get healthDataConsistent => 'Your data is consistent and healthy';

  @override
  String get healthDiscrepancies => 'Some balance discrepancies detected';

  @override
  String get healthTransactionsStat => 'Transactions';

  @override
  String get healthLedgerStat => 'Ledger';

  @override
  String get healthBackupStat => 'Backup';

  @override
  String get healthNever => 'Never';

  @override
  String get healthBalanceInvariant => 'Balance Invariant';

  @override
  String get healthAccountBalances => 'Account Balances';

  @override
  String get healthEnvelopeBalances => 'Envelope Balances';

  @override
  String get healthDataQuality => 'Data Quality';

  @override
  String get healthRepairButton => 'Repair Balances';

  @override
  String get healthLedgerEntries => 'Ledger entries';

  @override
  String get healthSoftDeleted => 'Soft-deleted';

  @override
  String get healthOrphanEntries => 'Orphan ledger entries';

  @override
  String get healthLastBackup => 'Last backup';

  @override
  String get healthNoAccounts => 'No accounts';

  @override
  String get healthNoEnvelopes => 'No envelopes';

  @override
  String get healthRepairTitle => 'Repair Balances';

  @override
  String get healthRepairMsg =>
      'This will create adjustment ledger entries to bring allocation balances back in line with account balances. A backup is recommended before proceeding.\\n\\nContinue?';

  @override
  String get healthRepairDone => 'Repair';

  @override
  String get healthNoAdjustments => 'No adjustments needed';

  @override
  String get healthRepairFailed => 'Repair failed. Please try again.';

  @override
  String get healthPurgeTitle => 'Purge Deleted Transactions';

  @override
  String get healthPurgeSuffix => 'This cannot be undone.';

  @override
  String get healthPurgeButton => 'Purge';

  @override
  String get onboardWelcomeTitle => 'BudgetSeal';

  @override
  String get onboardTagline => 'Give every dollar a purpose.';

  @override
  String get onboardStep1 => 'Add accounts — where your money lives';

  @override
  String get onboardStep2 => 'Create envelopes — budget for each category';

  @override
  String get onboardStep3 => 'Fund envelopes — distribute your income';

  @override
  String get onboardStep4 => 'Spend — each expense draws from its envelope';

  @override
  String get onboardGetStarted => 'Get Started';

  @override
  String get onboardRestoreCloud => 'Restore from Cloud';

  @override
  String get onboardJoinHousehold => 'Join a Household';

  @override
  String get onboardSetupTitle => 'Set up your household';

  @override
  String get onboardChangeLater =>
      'You can change everything later in Settings.';

  @override
  String get onboardHouseholdSection => 'HOUSEHOLD';

  @override
  String get onboardHouseholdName => 'Household name';

  @override
  String get onboardBaseCurrency => 'Base currency';

  @override
  String get onboardPeriodStart => 'Period start day';

  @override
  String get onboardFirstAccountSection => 'FIRST ACCOUNT';

  @override
  String get onboardAccountName => 'Account name';

  @override
  String get onboardTypeCash => 'Cash';

  @override
  String get onboardTypeBank => 'Bank';

  @override
  String get onboardTypeCredit => 'Credit';

  @override
  String get onboardTypeDigital => 'Digital';

  @override
  String get onboardCategoriesSection => 'CATEGORIES';

  @override
  String get onboardFullSet => 'Full set';

  @override
  String get onboardFullSetSub => '30 categories with subcategories';

  @override
  String get onboardEmpty => 'Empty';

  @override
  String get onboardEmptySub => 'Create your own from scratch';

  @override
  String get onboardEntrySection => 'TRANSACTION ENTRY';

  @override
  String get onboardAssisted => 'Assisted';

  @override
  String get onboardAssistedSub => 'Step-by-step, fast for daily use';

  @override
  String get onboardClassic => 'Classic form';

  @override
  String get onboardClassicSub => 'All fields at once, for complex entries';

  @override
  String get onboardCreateStart => 'Create & Start';

  @override
  String get onboardAllSet => 'You\'re all set!';

  @override
  String get onboardDoneSubtitle =>
      'Start tracking your expenses.\nYour financial clarity begins now.';

  @override
  String get onboardStartUsing => 'Start Using BudgetSeal';

  @override
  String get onboardRestoreTitle => 'Restore from Cloud';

  @override
  String get onboardRestoreDesc =>
      'Choose where your backup is stored. This will replace any local data.';

  @override
  String get onboardGoogleDrive => 'Google Drive';

  @override
  String get onboardPickFile => 'Pick a File';

  @override
  String get onboardJoinDesc =>
      'Enter the invite code shared with you to join an existing BudgetSeal household.';

  @override
  String get onboardInviteCode => 'Invite code';

  @override
  String get onboardInviteHint => 'PP-...';

  @override
  String get onboardJoinButton => 'Join Household';

  @override
  String get onboardEnterCodeError => 'Please enter an invite code';

  @override
  String get onboardInvalidCodeError =>
      'Invalid invite code. It should start with PP-';

  @override
  String get lockSetupReason => 'Set up a screen lock to protect BudgetSeal';

  @override
  String get lockUnlockReason => 'Unlock BudgetSeal';

  @override
  String lockFailed(String error) {
    return 'Unlock failed: $error';
  }

  @override
  String get lockTapToUnlock => 'Tap to unlock';

  @override
  String get lockUnlockButton => 'Unlock';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsOverviewTab => 'Overview';

  @override
  String get reportsCategoriesTab => 'Categories';

  @override
  String get reportsInsightsTab => 'Insights';

  @override
  String get reportsBalanceTab => 'Balance Sheet';

  @override
  String get reportsHintTitle => 'Explore your spending patterns';

  @override
  String get reportsHintBody =>
      'Switch between tabs to see different views. The Insights tab shows your financial health.';

  @override
  String get reportsDailyPace => 'Daily pace';

  @override
  String get reportsProjectedTotal => 'Projected total';

  @override
  String reportsLessThanLast(double pct) {
    return '$pct% less than last month';
  }

  @override
  String reportsMoreThanLast(double pct) {
    return '$pct% more than last month';
  }

  @override
  String get reportsSameAsLast => 'Same as last month';

  @override
  String get reportsSpendingActivity => 'Spending Activity';

  @override
  String get reportsHeatmapNone => 'None';

  @override
  String get reportsHeatmapHelp =>
      'Each square is one day. Darker = higher amount. Scroll left to see past months.';

  @override
  String get reports6MonthTrend => '6-Month Trend';

  @override
  String get reportsDailyPaceToggle => 'Daily Pace';

  @override
  String get reportsNoSpending => 'No spending this month';

  @override
  String get reportsTopSpending => 'TOP SPENDING';

  @override
  String get reportsTopTransactions => 'TOP TRANSACTIONS';

  @override
  String get reportsNoExpenses => 'No expenses this period';

  @override
  String get reportsNoNote => 'No note';

  @override
  String get reportsNewBadge => 'NEW';

  @override
  String get reportsCurrentLegend => 'Current';

  @override
  String get reportsTypicalLegend => 'Typical';

  @override
  String get reportsVelocityTitle => 'Spending Velocity';

  @override
  String get reportsProjected => 'Projected';

  @override
  String get reportsBudget => 'Budget';

  @override
  String get reportsDailyRate => 'Daily rate';

  @override
  String get reportsDay => 'Day';

  @override
  String get reportsBiggestExpense => 'Biggest Expense';

  @override
  String get reportsSavingsRate => 'Savings Rate';

  @override
  String get reportsRecurringTitle => 'Recurring Transactions';

  @override
  String get reportsAgeTitle => 'Age of Money';

  @override
  String get reportsAgeExcellent => 'Excellent';

  @override
  String get reportsAgeGettingThere => 'Getting there';

  @override
  String get reportsAgeNeedsWork => 'Needs work';

  @override
  String get reportsAgeExcellentDesc =>
      'You\'re spending last month\'s income -- a sign of financial stability.';

  @override
  String get reportsAgeGettingDesc =>
      'You\'re building a buffer but not quite there yet. Keep it up!';

  @override
  String get reportsAgeNeedsDesc =>
      'You\'re living paycheck to paycheck. Try to build up a buffer over time.';

  @override
  String get reportsAgeGoal => 'Goal: 30+ days';

  @override
  String get reportsAgeExplanation =>
      'Age of Money measures how many days your money sits before you spend it. It traces each expense back to the income that funded it (oldest income first).';

  @override
  String get reportsTipsSection => 'TIPS';

  @override
  String get reportsNetWorth => 'NET WORTH';

  @override
  String get reportsAssets => 'ASSETS';

  @override
  String get reportsLiabilities => 'LIABILITIES';

  @override
  String get reportsCompareTo => 'Compare balances to:';

  @override
  String get reportsEndLastWeek => 'End of Last Week';

  @override
  String get reportsEndLastMonth => 'End of Last Month';

  @override
  String get reportsSameTimeLastMonth => 'Same Time Last Month';

  @override
  String get reportsEndLastQuarter => 'End of Last Quarter';

  @override
  String get reportsEndLastYear => 'End of Last Year';

  @override
  String get reportsSameTimeLastYear => 'Same Time Last Year';

  @override
  String get reportsCustom => 'Custom...';

  @override
  String get wcTitle => 'Web Companion';

  @override
  String get wcStopped => 'Server stopped';

  @override
  String get wcStarting => 'Starting...';

  @override
  String get wcRunning => 'Server running';

  @override
  String get wcError => 'Error';

  @override
  String get wcNoWifi => 'No WiFi';

  @override
  String get wcAutoStop => 'Stops automatically after 6 hours';

  @override
  String get wcStopButton => 'Stop Server';

  @override
  String get wcStartButton => 'Start Server';

  @override
  String get wcOpenOnLaptop => 'Open on your laptop';

  @override
  String get wcUrlCopied => 'URL copied to clipboard';

  @override
  String get wcCopyUrl => 'Copy URL';

  @override
  String get wcHideQr => 'Hide QR code';

  @override
  String get wcShowQr => 'Show QR code';

  @override
  String get wcSecurityTitle => 'Security';

  @override
  String get wcPinRequired => 'A PIN is required to access the web interface.';

  @override
  String get wcPinIsSet => 'PIN is set';

  @override
  String get wcNoPin => 'No PIN set';

  @override
  String get wcChangePin => 'Change PIN';

  @override
  String get wcSetPin => 'Set PIN';

  @override
  String get wcSetPinTitle => 'Set Web PIN';

  @override
  String get wcSetPinSubtitle =>
      'This PIN protects your budget data. Anyone on the same WiFi will need it to access the web interface.';

  @override
  String get wcChangePinTitle => 'Change PIN';

  @override
  String get wcChangePinSubtitle =>
      'Enter a new 4-digit PIN for your web interface.';

  @override
  String get wc4DigitPin => '4-digit PIN';

  @override
  String get wcEnter4DigitsError => 'Enter exactly 4 digits';

  @override
  String get wcUpdatePin => 'Update PIN';

  @override
  String get wcPinUpdated => 'PIN updated. All active sessions signed out.';

  @override
  String get wcIosWarning =>
      'Keep BudgetSeal in the foreground while the server is running. iOS does not support background servers — locking your screen will stop it.';

  @override
  String get wcNoWifiTitle => 'No WiFi Connection';

  @override
  String get wcNoWifiDesc =>
      'Connect your phone to a WiFi network to use Web Companion. The server needs WiFi to let your laptop access the budget.';

  @override
  String get wcPublicNetwork => 'Public Network Detected';

  @override
  String get wcNetworkSecurity => 'Network Security';

  @override
  String get wcSecurityWarning => 'Security Warning';

  @override
  String get wcInfo1 => 'Only accessible on the same WiFi network';

  @override
  String get wcInfo2 => 'Server stops automatically after 6 hours';

  @override
  String get wcInfo3 =>
      '5 failed PIN attempts locks the interface for 30 minutes';

  @override
  String get wcInfo4 =>
      'Use only on trusted private networks — traffic is not encrypted';

  @override
  String get wcNotifPermission =>
      'Notification permission is needed to keep the server running in the background.';

  @override
  String get wcForegroundChannel => 'Web Companion';

  @override
  String get wcForegroundChannelDesc =>
      'BudgetSeal Web Companion server is running';

  @override
  String get webPageTitle => 'BudgetSeal Web';

  @override
  String get webAuthSubtitle => 'Enter your PIN to continue';

  @override
  String get webAuthLockout => 'Too many attempts. Try again later.';

  @override
  String get webAuthIncorrect => 'Incorrect PIN';

  @override
  String get webServerUnreachable => 'Server unreachable';

  @override
  String get webUnexpectedResponse => 'Unexpected server response';

  @override
  String get webUnexpectedError => 'Unexpected error';

  @override
  String get webUndo => 'Undo';

  @override
  String get webSaving => 'Saving…';

  @override
  String get webDashNoAccounts => 'No accounts yet.';

  @override
  String get webDashUnallocated => 'Unallocated';

  @override
  String get webDashNoEnvelopes => 'No envelopes yet.';

  @override
  String get webDashFallbackTx => 'Transaction';

  @override
  String get webDashNoTxTitle => 'No transactions yet';

  @override
  String get webDashNoTxSub => 'Add your first transaction to get started';

  @override
  String get webDashSeeAll => 'See all';

  @override
  String get webDashRecent => 'Recent Transactions';

  @override
  String get webDashViewAll => 'View all';

  @override
  String get webTxNoRate => 'No rate';

  @override
  String get webTxNoFound => 'No transactions found';

  @override
  String get webTxCsv => 'CSV';

  @override
  String get webTxCsvTooltip => 'Export CSV';

  @override
  String get webTxAdd => '+ Add';

  @override
  String get webTxSearch => 'Search by title…';

  @override
  String get webTxThDate => 'Date';

  @override
  String get webTxThType => 'Type';

  @override
  String get webTxThTitle => 'Title';

  @override
  String get webTxThAccount => 'Account';

  @override
  String get webTxThCategory => 'Category';

  @override
  String get webTxThAmount => 'Amount';

  @override
  String get webTxPrev => '← Prev';

  @override
  String webTxPageN(int page) {
    return 'Page $page';
  }

  @override
  String get webTxNext => 'Next →';

  @override
  String get webTxCsvExported => 'CSV exported';

  @override
  String get webTxEdit => 'Edit';

  @override
  String get webTxDel => 'Del';

  @override
  String get webFormType => 'Type';

  @override
  String get webFormFromAccount => 'From Account';

  @override
  String get webFormAccount => 'Account';

  @override
  String get webFormSelectAccount => 'Select account';

  @override
  String get webFormToAccount => 'To Account';

  @override
  String get webFormCategory => 'Category';

  @override
  String get webFormNone => '— None —';

  @override
  String get webFormAmount => 'Amount';

  @override
  String get webFormAmountPlaceholder => '0.00';

  @override
  String get webFormCurrency => 'Currency';

  @override
  String get webFormCurrencyPlaceholder => 'USD';

  @override
  String get webFormExchangeRate => 'Exchange Rate';

  @override
  String get webFormRatePlaceholder => 'Rate to base currency';

  @override
  String get webFormDate => 'Date';

  @override
  String get webFormTitleNote => 'Title / Note';

  @override
  String get webFormOptional => 'Optional';

  @override
  String webFormRateHint(String txCur, String baseCur) {
    return '1 $txCur = ? $baseCur';
  }

  @override
  String get webValSelectAccount => 'Select an account';

  @override
  String get webValValidAmount => 'Enter a valid amount';

  @override
  String get webValSelectDest => 'Select destination account';

  @override
  String get webValAccountsDiffer => 'From and To accounts must differ';

  @override
  String get webModalAddTx => 'Add Transaction';

  @override
  String get webToastTxAdded => 'Transaction added';

  @override
  String get webModalEditTx => 'Edit Transaction';

  @override
  String get webToastTxUpdated => 'Transaction updated';

  @override
  String get webToastTxDeleted => 'Transaction deleted';

  @override
  String get webToastNoLines => 'No line details available';

  @override
  String webTxLinesHeader(int count) {
    return 'Transaction Lines ($count)';
  }

  @override
  String get webThLineAmount => 'Amount';

  @override
  String get webThLineCurrency => 'Currency';

  @override
  String get webThLineCategory => 'Category';

  @override
  String get webThLineAccount => 'Account';

  @override
  String get webThLineNote => 'Note';

  @override
  String get webThLineRate => 'Rate';

  @override
  String get webCatSubSingular => '1 sub-category';

  @override
  String webCatSubPlural(int count) {
    return '$count sub-categories';
  }

  @override
  String get webCatSectionExpense => 'Expense';

  @override
  String get webCatSectionIncome => 'Income';

  @override
  String get webCatEmptyTitle => 'No categories yet';

  @override
  String get webCatEmptySub => 'Add your first category to get started';

  @override
  String get webCatFormName => 'Name';

  @override
  String get webCatFormNameHint => 'e.g. Groceries';

  @override
  String get webCatFormParent => 'Parent Category';

  @override
  String get webCatFormNone => '— None (top-level) —';

  @override
  String get webCatFormIcon => 'Icon (emoji)';

  @override
  String get webCatFormColor => 'Color';

  @override
  String get webCatFormType => 'Transaction Type';

  @override
  String get webModalAddCat => 'Add Category';

  @override
  String get webValNameRequired => 'Name is required';

  @override
  String get webToastCatAdded => 'Category added';

  @override
  String get webToastCatNotFound => 'Category not found';

  @override
  String get webModalEditCat => 'Edit Category';

  @override
  String get webToastCatUpdated => 'Category updated';

  @override
  String get webAcctEmptyTitle => 'No accounts yet';

  @override
  String get webAcctEmptySub => 'Add your first account to get started';

  @override
  String get webAcctTypeBank => 'Bank Accounts';

  @override
  String get webAcctTypeCash => 'Cash';

  @override
  String get webAcctTypeCredit => 'Credit Cards';

  @override
  String get webAcctTypeWallet => 'Wallets';

  @override
  String webAcctNetWorth(String cur) {
    return 'Net Worth · $cur';
  }

  @override
  String get webAcctCountSingular => '1 account';

  @override
  String webAcctCountPlural(int count) {
    return '$count accounts';
  }

  @override
  String get webAcctTxEmpty => 'No transactions for this account';

  @override
  String get webAcctBack => '← Back';

  @override
  String get webAcctFormNameHint => 'e.g. Checking';

  @override
  String get webAcctFormType => 'Type';

  @override
  String get webAcctFormTypeBank => 'Bank';

  @override
  String get webAcctFormTypeCash => 'Cash';

  @override
  String get webAcctFormTypeCredit => 'Credit';

  @override
  String get webAcctFormTypeWallet => 'Wallet';

  @override
  String get webAcctFormOpening => 'Opening Balance';

  @override
  String get webModalAddAcct => 'Add Account';

  @override
  String get webToastAcctAdded => 'Account added';

  @override
  String get webEnvEmptyTitle => 'No envelopes';

  @override
  String get webEnvEmptySub => 'Envelopes are managed in the BudgetSeal app.';

  @override
  String get webEnvUnallocated => 'Unallocated:';

  @override
  String get webEnvFund => '+ Fund';

  @override
  String get webModalFund => 'Fund Envelope';

  @override
  String get webFormAmountToFund => 'Amount to Fund';

  @override
  String get webFormNote => 'Note';

  @override
  String get webToastEnvFunded => 'Envelope funded';

  @override
  String get webBtnFundConfirm => 'Fund';

  @override
  String get webRecurringEmpty => 'No recurring transactions';

  @override
  String get webThService => 'Service';

  @override
  String get webThFrequency => 'Frequency';

  @override
  String get webThNextDue => 'Next Due';

  @override
  String get webThOn => 'On';

  @override
  String get webToggleEnabled => 'Enabled';

  @override
  String get webToggleDisabled => 'Disabled';

  @override
  String get webFormTitleLabel => 'Title';

  @override
  String get webFormTitleHint => 'e.g. Netflix';

  @override
  String get webFormFrequency => 'Frequency';

  @override
  String get webFormEvery => 'Every';

  @override
  String get webFormStartDate => 'Start Date';

  @override
  String get webModalAddRecurring => 'Add Recurring';

  @override
  String get webToastRecurringAdded => 'Recurring added';

  @override
  String get webModalEditRecurring => 'Edit Recurring';

  @override
  String get webToastUpdated => 'Updated';

  @override
  String get webToastNotFound => 'Not found';

  @override
  String get webValSelectStartDate => 'Select a start date';

  @override
  String get webConfirmDeleteRecurring => 'Delete Recurring';

  @override
  String get webConfirmDeleteRecurringMsg =>
      'This recurring transaction will be permanently deleted.';

  @override
  String get webToastDeleted => 'Deleted';

  @override
  String get webSubEmpty => 'No subscriptions yet';

  @override
  String get webModalAddSub => 'Add Subscription';

  @override
  String get webToastSubAdded => 'Subscription added';

  @override
  String get webModalEditSub => 'Edit Subscription';

  @override
  String get webFormNewAmount => 'New Amount';

  @override
  String get webSubPriceHint =>
      'Changing the amount will add a price history entry.';

  @override
  String get webConfirmDeleteSub => 'Delete Subscription';

  @override
  String get webConfirmDeleteSubMsg =>
      'This subscription will be permanently deleted.';

  @override
  String get webReportsYear => 'Year';

  @override
  String get webReportsMonth => 'Month';

  @override
  String get webReportsLoad => 'Load';

  @override
  String get webReportsSelectPrompt => 'Select a period and click Load.';

  @override
  String get webStatIncome => 'Income';

  @override
  String get webStatExpenses => 'Expenses';

  @override
  String get webStatNet => 'Net';

  @override
  String get webStatSavingsRate => 'Savings Rate';

  @override
  String get webStatAvgDaily => 'Avg. Daily Spend';

  @override
  String get webStatTransactions => 'Transactions';

  @override
  String get webReportDailyCashflow => 'Daily Cashflow';

  @override
  String get webReportSpendingCat => 'Spending by Category';

  @override
  String get webReportNoExpense => 'No expense data';

  @override
  String get webReportIncomeCat => 'Income by Category';

  @override
  String get webReportNoIncome => 'No income data';

  @override
  String get webReportTopExpenses => 'Top Expenses';

  @override
  String get webChartIncome => 'Income';

  @override
  String get webChartExpense => 'Expense';

  @override
  String get webShortcutsTitle => 'Keyboard Shortcuts';

  @override
  String get webShortcutNewTx => 'New transaction';

  @override
  String get webShortcutSearch => 'Search transactions';

  @override
  String get webShortcutClose => 'Close modal / unfocus';

  @override
  String get webShortcutHelp => 'Show this help';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get notifLowEnvelopesTitle => 'Low Envelopes';

  @override
  String notifSingleOverspent(String name) {
    return '$name is overspent. Consider adding funds.';
  }

  @override
  String notifMultipleOverspent(int count, String names, String more) {
    return '$count envelopes are overspent: $names$more.';
  }

  @override
  String notifAndMore(int count) {
    return 'and $count more';
  }

  @override
  String get notifUpcomingBillsTitle => 'Upcoming Bills';

  @override
  String notifSingleDue(String title) {
    return '$title is due soon.';
  }

  @override
  String notifMultipleDue(int count, String names, String more) {
    return '$count bills due: $names$more.';
  }

  @override
  String get notifBillsAndMore => 'and more';

  @override
  String get notifBudgetWarningTitle => 'Budget Alert';

  @override
  String notifBudgetWarning(String name, String percent, String days) {
    return '$name: $percent% used with $days days left';
  }

  @override
  String get notifReminderTitle => 'BudgetSeal';

  @override
  String get notifReminder1 => 'How did you spend today? Tap to record.';

  @override
  String get notifReminder2 => 'Don\'t forget to log today\'s transactions!';

  @override
  String get notifReminder3 => 'Stay on track — record today\'s spending.';

  @override
  String get notifReminder4 => 'A minute now saves hours later. Log your day!';

  @override
  String get notifReminder5 =>
      'Keep your budget honest — add today\'s transactions.';

  @override
  String get notifReminderChannel => 'Daily Reminder';

  @override
  String get notifReminderChannelDesc => 'Daily reminder to log transactions';

  @override
  String get engineAutoCovered => 'Auto-covered from Unallocated';

  @override
  String get engineDirectIncome => 'Direct from income';

  @override
  String get engineWithdrawn => 'Withdrawn to Unallocated';

  @override
  String get enginePeriodReturned => 'Period reset — returned to Unallocated';

  @override
  String get enginePeriodOut => 'Period reset — transferred out';

  @override
  String get enginePeriodReceived => 'Received from period reset';

  @override
  String get engineCarryForward => 'Period carry-forward';

  @override
  String get engineAutoReset => 'Period auto-reset';

  @override
  String get nfThousandsComma => 'Comma (1,000)';

  @override
  String get nfThousandsPeriod => 'Period (1.000)';

  @override
  String get nfThousandsSpace => 'Space (1 000)';

  @override
  String get nfThousandsNone => 'None (1000)';

  @override
  String get nfDecimalPeriod => 'Period (0.50)';

  @override
  String get nfDecimalComma => 'Comma (0,50)';

  @override
  String get nfNegativeMinus => 'Minus (-\$100)';

  @override
  String get textScaleSmall => 'Small';

  @override
  String get textScaleDefault => 'Default';

  @override
  String get textScaleLarge => 'Large';

  @override
  String get textScaleExtraLarge => 'Extra Large';

  @override
  String get defcatFoodDining => 'Food & Dining';

  @override
  String get defcatGroceries => 'Groceries';

  @override
  String get defcatRestaurants => 'Restaurants';

  @override
  String get defcatCoffeeSnacks => 'Coffee & Snacks';

  @override
  String get defcatTransportation => 'Transportation';

  @override
  String get defcatFuel => 'Fuel';

  @override
  String get defcatPublicTransit => 'Public Transit';

  @override
  String get defcatParkingTolls => 'Parking & Tolls';

  @override
  String get defcatHousing => 'Housing';

  @override
  String get defcatRentMortgage => 'Rent / Mortgage';

  @override
  String get defcatUtilities => 'Utilities';

  @override
  String get defcatMaintenance => 'Maintenance';

  @override
  String get defcatShopping => 'Shopping';

  @override
  String get defcatClothing => 'Clothing';

  @override
  String get defcatElectronics => 'Electronics';

  @override
  String get defcatHouseholdItems => 'Household Items';

  @override
  String get defcatEntertainment => 'Entertainment';

  @override
  String get defcatSubscriptions => 'Subscriptions';

  @override
  String get defcatMoviesEvents => 'Movies & Events';

  @override
  String get defcatHobbies => 'Hobbies';

  @override
  String get defcatHealth => 'Health';

  @override
  String get defcatMedical => 'Medical';

  @override
  String get defcatPharmacy => 'Pharmacy';

  @override
  String get defcatFitness => 'Fitness';

  @override
  String get defcatPersonal => 'Personal';

  @override
  String get defcatEducation => 'Education';

  @override
  String get defcatGifts => 'Gifts';

  @override
  String get defcatPersonalCare => 'Personal Care';

  @override
  String get defcatSalary => 'Salary';

  @override
  String get defcatFreelance => 'Freelance';

  @override
  String get defcatInvestments => 'Investments';

  @override
  String get defcatOtherIncome => 'Other Income';

  @override
  String get defcatFoodDrink => 'Food & Drink';

  @override
  String get defcatTransport => 'Transport';

  @override
  String get defcatBills => 'Bills';

  @override
  String get defcatHome => 'Home';

  @override
  String get defcatTravel => 'Travel';

  @override
  String get defcatDiningOut => 'Dining Out';

  @override
  String get defcatCoffee => 'Coffee';

  @override
  String get defcatRent => 'Rent';

  @override
  String get defcatFurniture => 'Furniture';

  @override
  String get defcatElectricity => 'Electricity';

  @override
  String get defcatInternet => 'Internet';

  @override
  String get defcatPhone => 'Phone';

  @override
  String get defcatHaircut => 'Haircut';

  @override
  String get defcatSkincare => 'Skincare';

  @override
  String get defcatGym => 'Gym';

  @override
  String get defcatMovies => 'Movies';

  @override
  String get defcatGames => 'Games';

  @override
  String get defcatBooks => 'Books';

  @override
  String get defcatHotels => 'Hotels';

  @override
  String get defcatFlights => 'Flights';

  @override
  String get defcatWater => 'Water';

  @override
  String get defcatInsurance => 'Insurance';

  @override
  String get defcatPets => 'Pets';

  @override
  String get defcatOther => 'Other';

  @override
  String get syncErrEncryptedNoPw =>
      'Sync file is encrypted but no password is set. Enter your sync password to decrypt.';

  @override
  String get syncErrWrongPw =>
      'Wrong sync password. Could not decrypt the sync file.';

  @override
  String get syncErrInvalidFormat => 'Invalid encrypted sync file format';

  @override
  String get googleNotConfigured =>
      'Google Sign-In is not configured for this app. A Google Cloud project with OAuth credentials is required.';

  @override
  String get googleNetworkError =>
      'Network error. Check your internet connection.';

  @override
  String googleConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get googleNotConnected => 'Not connected to Google Drive';

  @override
  String get filePickerTitle => 'Select BudgetSeal Sync File';

  @override
  String get filePickerNoPath => 'No sync file path set';

  @override
  String get heatmapNoData => 'No data yet';

  @override
  String get heatmapNoActivity => 'No activity';

  @override
  String backupSizeBytes(String size) {
    return '$size B';
  }

  @override
  String backupSizeKb(String size) {
    return '$size KB';
  }

  @override
  String backupSizeMb(String size) {
    return '$size MB';
  }

  @override
  String get onboardHouseholdNameError => 'Enter a household name';

  @override
  String get onboardAccountNameError => 'Enter an account name';

  @override
  String get onboardMoreOptions => 'More options';

  @override
  String onboardDayN(int day) {
    return 'Day $day';
  }

  @override
  String get onboardEnvelopeExplainer =>
      'Envelope budgeting is simple: divide your income into virtual envelopes for each spending category. When an envelope runs out, you stop spending in that category.';

  @override
  String get onboardHouseholdHint => 'e.g. My Budget';

  @override
  String get onboardPeriodHelp =>
      'The day your monthly budget resets (usually the 1st or your payday).';

  @override
  String get onboardHelpHint =>
      'Need help? Check our guide anytime from More > Help Guide.';

  @override
  String travelPreviousWallet(String currency) {
    return 'You have a previous $currency travel wallet:';
  }

  @override
  String get travelExchangeFailed => 'Exchange failed. Please try again.';

  @override
  String travelBalanceLabel(String amount) {
    return 'Balance: $amount';
  }

  @override
  String get periodTransitionFailed =>
      'Failed to complete transition. Please try again.';

  @override
  String get leftoverLoadError => 'Couldn\'t load data';

  @override
  String get leftoverResolveFailed =>
      'Failed to resolve leftovers. Please try again.';

  @override
  String get commonTryAgain => 'Try Again';

  @override
  String get commonErrorDesc =>
      'An unexpected error occurred. Try going back or restarting the app.';

  @override
  String get commonUncategorized => 'Uncategorized';

  @override
  String wcPublicNetworkDescNamed(String wifiName) {
    return 'You appear to be on a public network (\"$wifiName\"). Do not start the server — your data will be transmitted unencrypted and could be intercepted by others on the same network.';
  }

  @override
  String get wcPublicNetworkDescUnnamed =>
      'You appear to be on a public network. Do not start the server — your data will be transmitted unencrypted and could be intercepted by others on the same network.';

  @override
  String get wcNetworkSecurityDesc =>
      'Web Companion uses HTTP (unencrypted). Only use it on your private home or office WiFi. Never start the server on public networks (hotels, airports, cafes) — anyone on the same network could see your data.';

  @override
  String wcSecurityWarningNamed(String wifiName) {
    return 'Network \"$wifiName\" may be public. Traffic is unencrypted — avoid using Web Companion on public WiFi, as others on the same network could intercept your data.';
  }

  @override
  String get wcSecurityWarningUnnamed =>
      'Could not detect your WiFi network name. If you\'re on a public network, avoid using Web Companion — traffic is unencrypted and could be intercepted.';

  @override
  String get tmplApplyError => 'Could not apply template';

  @override
  String get tmplDeleteError => 'Could not delete template';

  @override
  String get tmplEnterAmount => 'Enter an amount';

  @override
  String tmplCountOne(int count) {
    return '$count template';
  }

  @override
  String tmplCountOther(int count) {
    return '$count templates';
  }

  @override
  String tmplUseCountOne(int count) {
    return '$count use';
  }

  @override
  String tmplUseCountOther(int count) {
    return '$count uses';
  }

  @override
  String get tileLanguage => 'Language';

  @override
  String get tileLanguageSub => 'App display language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get languagePickerTitle => 'Language';

  @override
  String get recurringTitle => 'Recurring';

  @override
  String get recurringSummaryTotal => 'Total';

  @override
  String get recurringSummaryActive => 'Active';

  @override
  String get recurringSummaryPaused => 'Paused';

  @override
  String get recurringEmptyTitle => 'No recurring transactions';

  @override
  String get recurringEmptySubtitle => 'Tap + to create one';

  @override
  String recurringFilteredEmpty(String type) {
    return 'No $type recurring transactions';
  }

  @override
  String get recurringDeleteTitle => 'Delete recurring transaction?';

  @override
  String get recurringDeleteBody => 'This will be permanently removed.';

  @override
  String get recurringDeleted => 'Recurring transaction deleted';

  @override
  String get recurringCreated => 'Recurring transaction created';

  @override
  String get recurringUpdated => 'Recurring transaction updated';

  @override
  String get recurringNewTitle => 'New Recurring Transaction';

  @override
  String get recurringNewSubTitle => 'New Subscription';

  @override
  String get recurringEditTitle => 'Edit Recurring Transaction';

  @override
  String get recurringFormTitleHint => 'Title (e.g. Rent, Salary)';

  @override
  String get recurringFormTitleRequired => 'Title is required';

  @override
  String recurringFormEnds(String date) {
    return 'Ends: $date';
  }

  @override
  String get recurringFormEndsNever => 'Ends: Never (tap to set)';

  @override
  String recurringFormNextDue(String date) {
    return 'Next due: $date';
  }

  @override
  String get recurringFormClearEndDate => 'Clear end date';

  @override
  String get recurringFormIsSubscription => 'This is a subscription';

  @override
  String get recurringFormSubscriptionHint => 'e.g. Netflix, Spotify';

  @override
  String get recurringFormCreate => 'Create';

  @override
  String get recurringFormEnterTitle => 'Enter a title';

  @override
  String get recurringFormEnterAmount => 'Enter a valid amount';

  @override
  String get recurringFormSelectAccount => 'Select an account';

  @override
  String get recurringStatusActive => 'Active';

  @override
  String get recurringStatusPaused => 'Paused';

  @override
  String get recurringPauseTooltip => 'Pause recurring';

  @override
  String get recurringResumeTooltip => 'Resume recurring';

  @override
  String recurringTileNext(String date) {
    return 'Next: $date';
  }

  @override
  String reportsAgeDays(int age) {
    return '$age days';
  }

  @override
  String settingsVersionN(String version) {
    return 'Version $version';
  }

  @override
  String settingsPreview(String preview) {
    return 'Preview: $preview';
  }

  @override
  String get subCouldNotUpdate => 'Could not update subscription';

  @override
  String get helpGuideTitle => 'Help Guide';

  @override
  String get receiptTakePhoto => 'Take Photo';

  @override
  String get receiptChooseGallery => 'Choose from Gallery';

  @override
  String get receiptSelectMultiple => 'Select multiple photos';

  @override
  String get importCsvTitle => 'Import CSV';

  @override
  String get importFromBank => 'Import from Bank CSV';

  @override
  String get importCsvDesc =>
      'Select a CSV export from your bank. Column roles will be auto-detected.';

  @override
  String get importLoadCsv => 'Load CSV';

  @override
  String get importFailed => 'Import failed. Please check the file format.';

  @override
  String importFoundRows(int count, String fileName) {
    return 'Found $count rows in $fileName';
  }

  @override
  String get importColumnMapping => 'Column Mapping';

  @override
  String get importColumnMapDesc =>
      'Assign a role to each column. Roles were auto-detected -- adjust as needed.';

  @override
  String get importPreview => 'Import Preview';

  @override
  String get importNoAmount =>
      'No Amount column assigned. Please map at least one column to Amount.';

  @override
  String get importIntoAccount => 'Import into account';

  @override
  String get importAssignAmount => 'Please assign an Amount column';

  @override
  String importSuccess(int count) {
    return 'Imported $count transactions';
  }

  @override
  String importImporting(int count) {
    return 'Importing… ($count)';
  }

  @override
  String importButton(int count) {
    return 'Import $count transactions';
  }

  @override
  String get importColSkip => 'Skip';

  @override
  String get importColDate => 'Date';

  @override
  String get importColDescription => 'Description';

  @override
  String get objPaymentFailed => 'Payment failed. Please try again.';

  @override
  String get objNoPayments => 'No payments yet';

  @override
  String objCurrent(String amount) {
    return 'Current: $amount';
  }

  @override
  String get objCategoryOptional => 'Category (optional)';

  @override
  String get objLoanDirLentHint => 'You gave money — payments are incoming';

  @override
  String get objLoanDirBorrowedHint => 'You owe money — payments are outgoing';

  @override
  String get objTargetAmountLabel => 'Target amount';

  @override
  String objDeadlinePrefix(String date) {
    return 'Deadline: $date';
  }

  @override
  String get objSummaryRemaining => 'Remaining';

  @override
  String get objPaymentsSection => 'PAYMENTS';

  @override
  String get objSettingsSection => 'SETTINGS';

  @override
  String get objTypeSection => 'TYPE';

  @override
  String get objHideSettings => 'Hide Settings';

  @override
  String get objEditSettings => 'Edit Settings';

  @override
  String objOfTarget(String amount) {
    return 'of $amount';
  }

  @override
  String objReceivedFrom(String amount, String account) {
    return 'Received $amount from $account';
  }

  @override
  String objPaidFrom(String amount, String account) {
    return 'Paid $amount from $account';
  }

  @override
  String healthPurgeContent(int count, String suffix) {
    return 'Permanently remove $count soft-deleted transaction(s) and their lines from the database?\n\n$suffix';
  }

  @override
  String healthPurgeButtonN(int count) {
    return 'Purge $count deleted transaction(s)';
  }

  @override
  String get healthAutoAdjustment => 'Health check auto-adjustment';

  @override
  String get healthReportTitle => 'BudgetSeal Health Check Report';

  @override
  String healthAdjustmentsCreated(int count) {
    return '$count adjustment(s) created';
  }

  @override
  String healthPurged(int count) {
    return '$count transaction(s) purged';
  }

  @override
  String get customizeDesc => 'Drag to reorder. Toggle to show/hide sections.';

  @override
  String get catSheetCategoryName => 'Category name';

  @override
  String get catSheetNoMatch => 'No matching categories';

  @override
  String get catSheetNoCategories =>
      'No categories yet.\nTap \"New\" above to create one.';

  @override
  String syncConnectedTo(String provider) {
    return 'Connected to $provider';
  }

  @override
  String syncLastSynced(String time, String suffix) {
    return 'Last synced $time$suffix';
  }

  @override
  String syncChangesMerged(int count) {
    return ' · $count change(s) merged';
  }

  @override
  String get syncUpToDate => ' · up to date';

  @override
  String get languageSystemDesc => 'Follow device settings';

  @override
  String get dashboardQuickActionsHintTitle => 'Quick Actions';

  @override
  String get dashboardQuickActionsHintBody =>
      'Fund assigns money to your envelopes. Split lets you divide a bill with others.';

  @override
  String fundDistributing(String distributed, String available) {
    return 'Distributing $distributed of $available';
  }

  @override
  String catDeleteTxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions use this category',
      one: '1 transaction uses this category',
    );
    return '$_temp0';
  }

  @override
  String catDeleteLinkedEnvelope(String name) {
    return 'linked to envelope \"$name\"';
  }

  @override
  String catDeleteWarning(String warnings) {
    return 'This category has $warnings.\n\nDeleting will uncategorize those transactions and unlink it from the envelope.\n\nConsider archiving instead.';
  }

  @override
  String get subFreqDay => '/day';

  @override
  String get subFreqWeek => '/week';

  @override
  String get subFreqMonth => '/month';

  @override
  String get subFreqYear => '/year';

  @override
  String subFreqDays(int n) {
    return '/$n days';
  }

  @override
  String subFreqWeeks(int n) {
    return '/$n weeks';
  }

  @override
  String subFreqMonths(int n) {
    return '/$n months';
  }

  @override
  String subFreqYears(int n) {
    return '/$n years';
  }

  @override
  String subCancelBodyWithTx(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return 'This will cancel future billing and remove $_temp0 after $date.';
  }

  @override
  String subCancelBodyNoTx(String date) {
    return 'This will set the cancellation date to $date.';
  }

  @override
  String get plannedTitle => 'Planned Payments';

  @override
  String get plannedSubtitle => 'Plan future one-time payments';

  @override
  String get plannedAddTooltip => 'Add planned payment';

  @override
  String get plannedEmptyTitle => 'No planned payments';

  @override
  String get plannedEmptySubtitle =>
      'Plan future payments to track what you expect to spend before committing.';

  @override
  String get plannedPosted => 'Payment posted successfully';

  @override
  String get plannedPostFailed => 'Failed to post payment';

  @override
  String get plannedPostAllTitle => 'Post All Payments';

  @override
  String plannedPostAllContent(int count, String month) {
    return 'Post all $count planned payments for $month?';
  }

  @override
  String get plannedPostAll => 'Post All';

  @override
  String plannedPostAllResult(int count) {
    return '$count payments posted';
  }

  @override
  String plannedPostAllResultPartial(int posted, int failed) {
    return '$posted posted, $failed failed';
  }

  @override
  String get plannedDeleteTitle => 'Delete Planned Payment';

  @override
  String get plannedDeleteContent =>
      'This payment will be permanently removed. This cannot be undone.';

  @override
  String get plannedDeleted => 'Planned payment deleted';

  @override
  String get plannedDeleteFailed => 'Failed to delete payment';

  @override
  String get plannedPost => 'Post';

  @override
  String get plannedChipLabel => 'planned';

  @override
  String get plannedTotalLabel => 'total';

  @override
  String get plannedPlanButton => 'Plan Payment';

  @override
  String get plannedEditTitle => 'Edit Planned Payment';

  @override
  String get plannedTargetMonth => 'Target Month';

  @override
  String get plannedExactDate => 'Pick exact date (optional)';

  @override
  String plannedExactDateValue(String date) {
    return 'Exact date: $date';
  }

  @override
  String get plannedSelectAccount => 'Select an account';

  @override
  String get plannedUpdated => 'Planned payment updated';

  @override
  String get plannedCreated => 'Payment planned';

  @override
  String get plannedSaveFailed => 'Could not save planned payment';

  @override
  String get plannedBadge => 'Planned';

  @override
  String plannedNPlanned(String amount) {
    return '$amount planned';
  }

  @override
  String travelExchangeSuccess(String fromAmount, String toAmount) {
    return 'Exchanged $fromAmount → $toAmount. Open the travel wallet and use \"Convert Back & Close\" to return leftover money.';
  }

  @override
  String backupRestoreDialogBody(String date, String size) {
    return 'From: $date\nSize: $size\n\nThis will replace your current data. The app will need to restart.';
  }

  @override
  String backupAutoEvery(String frequency) {
    return 'Backing up $frequency';
  }

  @override
  String backupLastAutoBackup(String date) {
    return 'Last auto-backup: $date';
  }

  @override
  String get recurringFormCategory => 'Category (optional)';

  @override
  String get txDetailSaveAsTemplate => 'Save as Template';

  @override
  String get txDetailTemplateSaved => 'Template saved';

  @override
  String get txDetailTemplateError => 'Could not save template';

  @override
  String get tileArabicDigits => 'Arabic-Indic Numerals';

  @override
  String get upgradeTitle => 'Upgrade to Premium';

  @override
  String get upgradeSubtitle =>
      'Unlock every feature with a single purchase. No subscriptions, no ads.';

  @override
  String get upgradeFeatureSync => 'Cloud Sync';

  @override
  String get upgradeFeatureWebCompanion => 'Web Companion';

  @override
  String get upgradeFeatureBillSplitter => 'Bill Splitter';

  @override
  String get upgradeFeatureTravelExchange => 'Travel Exchange';

  @override
  String get upgradeFeaturePlannedPayments => 'Planned Payments';

  @override
  String get upgradeFeatureUnlimitedItems => 'Unlimited accounts & envelopes';

  @override
  String get upgradePrice => '\$4.99';

  @override
  String get upgradePriceSubtitle => 'One-time purchase. Yours forever.';

  @override
  String get upgradeButton => 'Upgrade';

  @override
  String get upgradeComingSoon => 'In-app purchases coming soon';

  @override
  String get upgradeRedeemCode => 'Redeem Code';

  @override
  String get upgradeRedeemHint => 'Enter your code';

  @override
  String get upgradeRedeemButton => 'Redeem';

  @override
  String get upgradeRedeemInvalid => 'Invalid code. Please try again.';

  @override
  String get upgradeRedeemSuccess => 'Code redeemed! Premium unlocked.';

  @override
  String get upgradeRestorePurchase => 'Restore Purchase';

  @override
  String get upgradeRestoreSuccess => 'Purchase restored! Premium unlocked.';

  @override
  String get upgradeRestoreNone => 'No previous purchase found.';

  @override
  String get catSheetSearchHint => 'Search categories...';

  @override
  String catSheetSubcategories(int count) {
    return '$count subcategories';
  }

  @override
  String get objSummaryDeadline => 'Deadline';

  @override
  String get plannedNoteHint => 'Note (optional)';

  @override
  String get recurringFormAccountRequired => 'Account is required';

  @override
  String recurringFormStarts(String date) {
    return 'Starts: $date';
  }
}
