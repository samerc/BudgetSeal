// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String travelWalletName(String currency) {
    return 'Travel - $currency';
  }

  @override
  String travelAddsToWallet(String wallet) {
    return 'Adds to your $wallet wallet';
  }

  @override
  String get travelExchangeTopUp => 'Exchange & add to wallet';

  @override
  String get travelOverBalanceTitle => 'More than this account holds';

  @override
  String travelOverBalanceMsg(String account, String balance, String after) {
    return '$account holds $balance. After this exchange it will be $after.';
  }

  @override
  String get travelExchangeAnyway => 'Exchange anyway';

  @override
  String get acctBalanceChanged =>
      'This wallet\'s balance just changed. Check the new amount and try again.';

  @override
  String get plannedTotalOther => 'total + other currencies';

  @override
  String get syncOtherBudgetTitle => 'Another budget is already synced here';

  @override
  String get syncOtherBudgetBody =>
      'This account\'s sync file holds a budget made on another device. Use it on this device? It replaces the data on this device; a backup of it is saved first in Backup & Restore.';

  @override
  String get syncUseSyncedBudget => 'Use the synced budget';

  @override
  String get syncErrWrongPassword =>
      'Wrong sync password. Use the same password as on your other device.';

  @override
  String get syncErrCorrupt =>
      'The sync file couldn\'t be read. Sync again from your other device.';

  @override
  String get syncErrSignedOut =>
      'You were signed out of Google Drive. Connect again to keep syncing.';

  @override
  String get syncErrGeneric =>
      'Sync didn\'t finish. Please try again in a moment.';

  @override
  String get syncErrBackupFailed =>
      'Couldn\'t back up your current data, so nothing was replaced.';

  @override
  String wcBrowsersConnected(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n browsers connected',
      one: '1 browser connected',
      zero: 'No browser connected',
    );
    return '$_temp0';
  }

  @override
  String get wcBrowsersHint => 'A browser counts while its page is open.';

  @override
  String get wcSignOutAll => 'Sign out all';

  @override
  String get wcSignedOutAll =>
      'All browsers signed out — they need the PIN again';

  @override
  String get webImportBtn => 'Import CSV';

  @override
  String get webImportTitle => 'Import a CSV file';

  @override
  String get webImportSub =>
      'Bring in a bank statement or a spreadsheet. Rows already in BudgetSeal are skipped.';

  @override
  String get webImportChoose => 'Choose a CSV file, or drop it here';

  @override
  String get webImportChooseHint =>
      'It needs a date and an amount (or debit and credit) column. Commas, semicolons and tabs all work.';

  @override
  String webImportRowsFound(int n) {
    return 'Rows found: $n · choose another file';
  }

  @override
  String get webImportTooBig => 'That file is over 5 MB.';

  @override
  String get webImportUnreadableFile => 'Couldn\'t read that file as CSV.';

  @override
  String get webImportColumns => 'Columns';

  @override
  String webImportColumnN(int n) {
    return 'Column $n';
  }

  @override
  String get webImportHasHeader => 'First row is a header';

  @override
  String get webImportRoleSkip => 'Skip';

  @override
  String get webImportRoleDate => 'Date';

  @override
  String get webImportRoleDescription => 'Description';

  @override
  String get webImportRoleAmount => 'Amount (±)';

  @override
  String get webImportRoleDebit => 'Money out';

  @override
  String get webImportRoleCredit => 'Money in';

  @override
  String get webImportRoleCategory => 'Category';

  @override
  String get webImportPreview => 'How it will look';

  @override
  String get webImportNeedCols =>
      'Pick a Date column and an Amount column (or Money out / Money in).';

  @override
  String get webImportInto => 'Import into';

  @override
  String get webImportReadyRows => 'rows ready';

  @override
  String webImportUnreadable(int n) {
    return 'Rows without a readable date or amount: $n';
  }

  @override
  String get webImportCheck => 'Check & import';

  @override
  String get webImportConfirmTitle => 'Import these transactions?';

  @override
  String webImportWillAdd(String account, int n) {
    return 'New transactions for $account: $n';
  }

  @override
  String webImportCategorized(int n) {
    return 'With a category (matched or guessed from your past titles): $n';
  }

  @override
  String webImportDupes(int n) {
    return 'Already in BudgetSeal, skipped: $n';
  }

  @override
  String webImportGo(int n) {
    return 'Import $n';
  }

  @override
  String webImportNothingNew(int n) {
    return 'Nothing new — all $n rows are already in BudgetSeal.';
  }

  @override
  String webImportDone(int n) {
    return 'Imported: $n';
  }

  @override
  String get webAcctBalanceAfter => 'Balance after this transaction';

  @override
  String webAcctReconciledOn(String date) {
    return 'Reconciled $date';
  }

  @override
  String get webAcctNeverReconciled => 'Never reconciled';

  @override
  String get webAcctReconcile => 'Reconcile';

  @override
  String webAcctReconcileTitle(String name) {
    return 'Reconcile $name';
  }

  @override
  String get webAcctReconcileHelp =>
      'Enter the balance your bank or wallet shows right now. If it differs, a “Balance adjustment” is recorded so they match.';

  @override
  String get webAcctStatementBalance => 'Actual balance';

  @override
  String get webAcctReconcileMatches => 'Matches — nothing to adjust.';

  @override
  String webAcctReconcileDiff(String amount) {
    return 'An adjustment of $amount will be recorded.';
  }

  @override
  String get webAcctReconciled => 'Reconciled — it matches';

  @override
  String webAcctAdjusted(String amount) {
    return 'Reconciled — adjusted by $amount';
  }

  @override
  String get webAcctEdit => 'Edit account';

  @override
  String get webAcctDecimals => 'Decimal places';

  @override
  String webAcctDecimalsAuto(int n) {
    return 'Auto ($n)';
  }

  @override
  String get webAcctStartingBalance => 'Starting balance';

  @override
  String get webAcctStartingHelp =>
      'What the account held before your first transaction. Changing it moves every balance after it.';

  @override
  String get webAcctSaved => 'Account saved';

  @override
  String get webAcctArchive => 'Archive';

  @override
  String webAcctArchiveTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String get webAcctArchiveMsg =>
      'It’s hidden from lists and pickers. Its transactions stay, and you can unarchive it any time.';

  @override
  String webAcctArchiveNotZero(String amount) {
    return 'This account still holds $amount. Move it to another account or reconcile it to zero first — archived accounts no longer count toward your money.';
  }

  @override
  String get webAcctArchived => 'Archived';

  @override
  String get webAcctArchivedSection => 'Archived';

  @override
  String get webAcctArchivedToast => 'Account archived';

  @override
  String get webAcctUnarchive => 'Unarchive';

  @override
  String get webAcctUnarchived => 'Account restored';

  @override
  String get webNavUpcoming => 'Upcoming';

  @override
  String get webUpSub =>
      'Bills coming up and payments you’ve planned. Nothing here touches your balances until it’s posted.';

  @override
  String get webUpBills => 'Bills';

  @override
  String webUpDays(int n) {
    return '$n days';
  }

  @override
  String webUpTotalOut(int n) {
    return 'Bills, next $n days';
  }

  @override
  String webUpTotalIn(String amount) {
    return '+ $amount coming in';
  }

  @override
  String get webUpSubTag => 'Subscription';

  @override
  String webUpOverdue(int n) {
    return 'Overdue by $n days';
  }

  @override
  String get webUpToday => 'Due today';

  @override
  String get webUpTomorrow => 'Due tomorrow';

  @override
  String webUpInDays(int n) {
    return 'Due in $n days';
  }

  @override
  String webUpNone(int n) {
    return 'Nothing due in the next $n days';
  }

  @override
  String get webUpNoneSub =>
      'Recurring items and subscriptions show up here before they post.';

  @override
  String get webUpPostNow => 'Post now';

  @override
  String get webUpSkip => 'Skip this one';

  @override
  String get webUpPostHelp =>
      'Post now records it today. Skip records nothing. Either way the next date moves on.';

  @override
  String get webUpPosted => 'Posted';

  @override
  String get webUpSkipped => 'Skipped';

  @override
  String get webPlanSection => 'Planned payments';

  @override
  String get webPlanAdd => 'Plan a payment';

  @override
  String get webPlanEdit => 'Edit planned payment';

  @override
  String get webPlanSave => 'Plan it';

  @override
  String get webPlanDate => 'Planned for';

  @override
  String get webPlanNeedDate => 'Pick a date.';

  @override
  String get webPlanEmpty => 'No planned payments';

  @override
  String get webPlanEmptySub =>
      'Plan a one-time payment ahead — it won’t touch your balances until you post it.';

  @override
  String get webPlanPost => 'Post';

  @override
  String get webPlanPostHelp =>
      'Posting records it as a real transaction on its planned date.';

  @override
  String get webPlanPostAll => 'Post all';

  @override
  String get webPlanPostAllTitle => 'Post these payments?';

  @override
  String webPlanPostAllMsg(int n) {
    return 'Payments to post: $n. Each becomes a real transaction on its planned date.';
  }

  @override
  String webPlanPosted(int n) {
    return 'Posted: $n';
  }

  @override
  String webPlanPostPartial(int n, String failed) {
    return 'Posted: $n · not posted: $failed (no exchange rate)';
  }

  @override
  String get webPlanAdded => 'Payment planned';

  @override
  String get webPlanUpdated => 'Saved';

  @override
  String get webPlanDeleted => 'Planned payment deleted';

  @override
  String get webPlanDeleteTitle => 'Delete this planned payment?';

  @override
  String get webPlanDeleteMsg =>
      'It was never recorded, so no balance changes.';

  @override
  String get webNavGoals => 'Goals & loans';

  @override
  String get webGoalsSub =>
      'Save toward a target, or track money you lent or borrowed.';

  @override
  String get webGoalNew => 'New goal or loan';

  @override
  String get webGoalCreate => 'Create';

  @override
  String get webGoalEdit => 'Edit';

  @override
  String get webGoalsEmptyTitle => 'No goals or loans yet';

  @override
  String get webGoalsEmptySub =>
      'Goals track savings toward a target. Loans track money you lent or borrowed.';

  @override
  String get webGoalsSection => 'Goals';

  @override
  String get webLoansSection => 'Loans';

  @override
  String get webGoalKindGoal => 'Goal';

  @override
  String get webGoalKindLoan => 'Loan';

  @override
  String get webGoalSaved => 'Saved';

  @override
  String get webGoalYouOwe => 'You owe';

  @override
  String get webGoalOwedToYou => 'Owed to you';

  @override
  String webGoalLentTo(String name) {
    return 'Lent to $name';
  }

  @override
  String webGoalBorrowedFrom(String name) {
    return 'Borrowed from $name';
  }

  @override
  String webGoalDue(String date) {
    return 'Due $date';
  }

  @override
  String get webGoalPaidOff => 'Paid off';

  @override
  String webGoalPaidBack(String amount) {
    return '$amount paid back';
  }

  @override
  String get webGoalPaidBackLabel => 'Paid back';

  @override
  String get webGoalRemaining => 'Remaining';

  @override
  String webGoalPerMonth(String amount) {
    return '$amount a month to stay on track';
  }

  @override
  String get webGoalPerMonthLabel => 'Needed per month';

  @override
  String get webGoalDeadline => 'Deadline';

  @override
  String get webGoalPayments => 'Payments';

  @override
  String get webGoalNoPayments => 'No payments yet';

  @override
  String get webGoalAddFunds => 'Add funds';

  @override
  String get webGoalPayReceived => 'Payment received';

  @override
  String get webGoalPaySent => 'Record payment';

  @override
  String get webGoalFillRest => 'All that’s left';

  @override
  String get webGoalFromAccount => 'From account';

  @override
  String get webGoalIntoAccount => 'Into account';

  @override
  String webGoalConverted(String cur) {
    return 'Converted to $cur at the phone’s latest rate';
  }

  @override
  String get webGoalLentChoice => 'I lent';

  @override
  String get webGoalBorrowedChoice => 'I borrowed';

  @override
  String get webGoalLentHint => 'You gave money — payments come in';

  @override
  String get webGoalBorrowedHint => 'You owe money — payments go out';

  @override
  String get webGoalPerson => 'Person';

  @override
  String get webGoalTarget => 'Target amount';

  @override
  String get webGoalLoanAmount => 'Loan amount';

  @override
  String get webGoalDeadlineOpt => 'Deadline (optional)';

  @override
  String get webGoalDueBy => 'Due by (optional)';

  @override
  String get webGoalWhatGoal =>
      'Each deposit moves money out of the account you pick and is recorded as a transaction.';

  @override
  String get webGoalWhatLoan =>
      'Each payment moves money in or out of the account you pick.';

  @override
  String webGoalDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get webGoalDeleteMsg => 'This cannot be undone.';

  @override
  String webGoalDeletePayments(int n) {
    return 'Linked payments: $n. The money already moved between your accounts — keep them, or delete everything?';
  }

  @override
  String get webGoalDeleteKeep => 'Delete, keep payments';

  @override
  String get webGoalDeleteAll => 'Delete everything';

  @override
  String get webToastGoalAdded => 'Created';

  @override
  String get webToastGoalUpdated => 'Saved';

  @override
  String get webToastGoalDeleted => 'Deleted';

  @override
  String get webToastGoalPaid => 'Payment recorded';

  @override
  String get webBulkAdd => 'Add several';

  @override
  String get webBulkTitle => 'Add several transactions';

  @override
  String get webBulkHint =>
      'Tab moves across, Enter goes down a row, Ctrl+Enter saves. Paste rows from a spreadsheet to fill several at once.';

  @override
  String get webBulkAddRow => 'Add row';

  @override
  String get webBulkRemoveRow => 'Remove row';

  @override
  String get webBulkSave => 'Save all';

  @override
  String get webBulkClear => 'Clear all';

  @override
  String webBulkCount(int n) {
    return 'Rows: $n';
  }

  @override
  String get webBulkEmpty => 'Fill in at least one row.';

  @override
  String webBulkRowBad(int n) {
    return 'Check row $n';
  }

  @override
  String webBulkPasted(int n) {
    return 'Rows pasted: $n';
  }

  @override
  String webBulkSaved(int n) {
    return 'Transactions added: $n';
  }

  @override
  String get webMoveTitle => 'Move money';

  @override
  String get webMoveSubmit => 'Move';

  @override
  String get webMoveFrom => 'From';

  @override
  String get webMoveTo => 'To';

  @override
  String get webMoveAll => 'All of it';

  @override
  String get webMoveShortfall => 'Overspent amount';

  @override
  String webMoveHas(String name, String amount) {
    return '$name has $amount';
  }

  @override
  String get webMoveSame => 'Pick two different places.';

  @override
  String webMoveNotEnough(String name, String amount) {
    return '$name only has $amount.';
  }

  @override
  String get webEnvCover => 'Cover';

  @override
  String webCoverTitle(String name) {
    return 'Cover $name';
  }

  @override
  String get webToastMoved => 'Money moved';

  @override
  String get webToastCovered => 'Overspending covered';

  @override
  String get webNavHome => 'Home';

  @override
  String get webNavBudget => 'Budget';

  @override
  String get webMenu => 'Menu';

  @override
  String get webShortcuts => 'Shortcuts';

  @override
  String get webSignOut => 'Sign out';

  @override
  String get webConnChecking => 'Connecting…';

  @override
  String get webConnOk => 'Connected to phone';

  @override
  String get webConnLost => 'Phone not reachable';

  @override
  String get webOffline =>
      'Can\'t reach your phone. Keep BudgetSeal open with the Web Companion running, on the same Wi‑Fi.';

  @override
  String get webOfflineShort => 'Can\'t reach your phone';

  @override
  String get webAuthSubtitle => 'Enter the PIN you set on your phone';

  @override
  String get webAuthFoot =>
      'Your data stays on your phone. This page reads it over your Wi‑Fi.';

  @override
  String get webAuthDelete => 'Delete digit';

  @override
  String webAuthWrongLeft(int n) {
    return 'Wrong PIN · $n attempts left';
  }

  @override
  String webAuthLocked(int n) {
    return 'Too many attempts. Try again in $n min.';
  }

  @override
  String get webAuthExpired => 'Your session ended. Enter your PIN again.';

  @override
  String get webErrRequest => 'Couldn\'t save. Check the values and try again.';

  @override
  String get webErrTooMany => 'Too many changes at once. Wait a moment.';

  @override
  String get webErrNoRate =>
      'No exchange rate for this currency yet. Enter one.';

  @override
  String get webNeedAccount => 'Add an account first.';

  @override
  String get webSeeAll => 'See all';

  @override
  String get webRecent => 'Recent';

  @override
  String get webLoadMore => 'Load more';

  @override
  String get webDuplicate => 'Duplicate';

  @override
  String get webCsv => 'Export CSV';

  @override
  String get webCsvPreparing => 'Preparing the export…';

  @override
  String webCsvDone(int n) {
    return '$n rows exported';
  }

  @override
  String get webWholeYear => 'Whole year';

  @override
  String get webPrevYear => 'Previous year';

  @override
  String get webNextYear => 'Next year';

  @override
  String get webPrevMonth => 'Previous month';

  @override
  String get webNextMonth => 'Next month';

  @override
  String get webRta => 'Ready to assign';

  @override
  String get webRtaAssign => 'Assign';

  @override
  String get webNetWorth => 'Net worth';

  @override
  String webNetWorthCur(String cur) {
    return 'Net worth · $cur';
  }

  @override
  String get webEnvSpending => 'Spending';

  @override
  String get webEnvFlexible => 'Rollover';

  @override
  String get webEnvAvailable => 'Available';

  @override
  String get webEnvOverspent => 'Overspent';

  @override
  String webEnvSpent(String amount) {
    return '$amount spent';
  }

  @override
  String webEnvOf(String amount) {
    return 'of $amount';
  }

  @override
  String webEnvToGo(String amount) {
    return '$amount to go';
  }

  @override
  String get webEnvReached => 'Target reached';

  @override
  String webFundTitle(String name) {
    return 'Fund $name';
  }

  @override
  String get webFundToTarget => 'To target';

  @override
  String get webFundAll => 'All available';

  @override
  String webFundAvailable(String amount) {
    return 'Ready to assign: $amount';
  }

  @override
  String webFundOver(String amount) {
    return 'Ready to assign would go to $amount';
  }

  @override
  String get webFundOverMsg =>
      'This is more than you have ready to assign. Fund anyway?';

  @override
  String get webFundAnyway => 'Fund anyway';

  @override
  String get webTxAddShort => 'Add';

  @override
  String get webTxNewExpense => 'New expense';

  @override
  String get webTxNewIncome => 'New income';

  @override
  String get webTxNewTransfer => 'New transfer';

  @override
  String get webTxEditExpense => 'Edit expense';

  @override
  String get webTxEditIncome => 'Edit income';

  @override
  String get webTxEditTransfer => 'Edit transfer';

  @override
  String get webTxEmptyTitle => 'No transactions here';

  @override
  String get webTxEmptySub => 'Add one, or pick another month.';

  @override
  String get webTxNoMatch => 'Nothing matches your search';

  @override
  String webTxSplit(int n) {
    return 'Split · $n';
  }

  @override
  String get webTxSplitHint => 'Items of a split are edited on your phone.';

  @override
  String get webSaveAddAnother => 'Save & add another';

  @override
  String get webFormTitle => 'Title';

  @override
  String get webFormName => 'Name';

  @override
  String get webFormNoCategory => 'No category';

  @override
  String webFormInCurrency(String cur) {
    return 'In $cur, the source account’s currency';
  }

  @override
  String webFormRateLabel(String cur, String base) {
    return 'Rate: 1 $cur = ? $base';
  }

  @override
  String get webFormRateAuto => 'Leave empty to use the phone\'s latest rate';

  @override
  String webFormReceived(String cur) {
    return 'Amount received in $cur';
  }

  @override
  String get webFormRepeats => 'Repeats';

  @override
  String get webFormNextDue => 'Next date';

  @override
  String get webFormFirstDate => 'First date';

  @override
  String get webValReceived => 'Enter the amount received';

  @override
  String get webValRate => 'Enter a valid rate';

  @override
  String get webValCurrency => 'Use a 3-letter currency code, like USD';

  @override
  String get webAcctAdd => 'Add account';

  @override
  String get webAcctNew => 'New account';

  @override
  String get webAcctNameHint => 'e.g. Main bank';

  @override
  String get webAcctOpening => 'Current balance';

  @override
  String get webAcctOpeningHint => 'Negative for a card you owe on';

  @override
  String get webAcctTravel => 'Travel wallet';

  @override
  String get webAcctGroupBank => 'Bank accounts';

  @override
  String get webAcctGroupCash => 'Cash';

  @override
  String get webAcctGroupCredit => 'Credit cards';

  @override
  String get webAcctGroupWallet => 'Digital wallets';

  @override
  String get webCatAdd => 'Add category';

  @override
  String get webCatNew => 'New category';

  @override
  String get webCatEdit => 'Edit category';

  @override
  String get webCatNameHint => 'e.g. Groceries';

  @override
  String get webCatParent => 'Inside';

  @override
  String get webCatTopLevel => 'Main category';

  @override
  String get webCatParentLocked =>
      'It has subcategories, so it stays a main category.';

  @override
  String get webCatIcon => 'Emoji';

  @override
  String get webCatColor => 'Color';

  @override
  String get webCatCustomColor => 'Custom color';

  @override
  String webCatSubs(int n) {
    return '$n subcategories';
  }

  @override
  String get webCatNoSubs => 'No subcategories';

  @override
  String get webRecAdd => 'Add recurring';

  @override
  String get webRecNew => 'New recurring item';

  @override
  String get webRecEdit => 'Edit recurring item';

  @override
  String get webRecEmpty => 'No recurring items yet';

  @override
  String get webRecEmptySub =>
      'Rent, salary, savings transfers: they post on their own.';

  @override
  String get webRecTitleHint => 'e.g. Rent';

  @override
  String webRecNext(String date) {
    return 'next $date';
  }

  @override
  String get webRecOn => 'Active';

  @override
  String get webRecOff => 'Paused';

  @override
  String get webRecPaused => 'Paused';

  @override
  String get webRecPausedToast => 'Paused';

  @override
  String get webRecResumed => 'Active again';

  @override
  String get webRecPastHint =>
      'A past date posts the missed occurrences the next time the app opens.';

  @override
  String get webSubAdd => 'Add subscription';

  @override
  String get webSubNew => 'New subscription';

  @override
  String get webSubEdit => 'Edit subscription';

  @override
  String get webSubEmptySub =>
      'Track streaming, apps and memberships, with their price changes.';

  @override
  String get webSubTitleHint => 'e.g. Netflix';

  @override
  String get webSubMonthly => 'Per month';

  @override
  String webSubYearly(String amount) {
    return '$amount per year';
  }

  @override
  String get webRepEmpty => 'Nothing recorded this month';

  @override
  String get webRepEmptySub => 'Pick another month with the arrows.';

  @override
  String get webShortcutPages => 'Go to a page in the menu';

  @override
  String get wcStartFailed =>
      'Couldn\'t start. Turn Wi‑Fi off and on, then try again.';

  @override
  String billItemN(int n) {
    return 'Item $n';
  }

  @override
  String get billDiscardTitle => 'Discard this bill?';

  @override
  String get billDiscardBody =>
      'The items and splits you entered will be lost.';

  @override
  String get billWhoPaid => 'Who paid?';

  @override
  String get billPaidMe => 'I paid the whole bill';

  @override
  String get billPaidMeDesc =>
      'Records the full bill from your account and tracks what each person owes you in Goals & Loans.';

  @override
  String get billPaidOther => 'Someone else paid';

  @override
  String billPaidOtherDesc(String name) {
    return 'Tracks what you owe $name in Goals & Loans. Nothing leaves your account until you pay them back.';
  }

  @override
  String get billPaidEach => 'Everyone paid their own part';

  @override
  String get billPaidEachDesc => 'Records only your share.';

  @override
  String billLinePart(String name) {
    return '$name\'s part';
  }

  @override
  String billLoanName(String date) {
    return 'Bill split · $date';
  }

  @override
  String billLoansCreated(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n loans added to Goals & Loans',
      one: '1 loan added to Goals & Loans',
    );
    return '$_temp0';
  }

  @override
  String billOweCreated(String name, String amount) {
    return 'Added to Goals & Loans: you owe $name $amount';
  }

  @override
  String get billShare => 'Share split';

  @override
  String billShareHeader(String total) {
    return 'Bill split · total $total';
  }

  @override
  String billSharePaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String get billTax => 'Tax & service';

  @override
  String get billTaxAmount => 'Tax & service amount';

  @override
  String get billTaxHint => 'Split in proportion to what each person ordered.';

  @override
  String billReceiptMatch(String total) {
    return 'Matches the receipt total ($total)';
  }

  @override
  String billReceiptDiff(String items, String total) {
    return 'Items add up to $items · receipt total $total';
  }

  @override
  String get webShortcutRefresh => 'Reload from the phone';

  @override
  String get currencyNameUsd => 'US Dollar';

  @override
  String get currencyNameEur => 'Euro';

  @override
  String get currencyNameGbp => 'British Pound';

  @override
  String get currencyNameJpy => 'Japanese Yen';

  @override
  String get currencyNameChf => 'Swiss Franc';

  @override
  String get currencyNameCad => 'Canadian Dollar';

  @override
  String get currencyNameAud => 'Australian Dollar';

  @override
  String get currencyNameCny => 'Chinese Yuan';

  @override
  String get currencyNameInr => 'Indian Rupee';

  @override
  String get currencyNameBrl => 'Brazilian Real';

  @override
  String get currencyNameMxn => 'Mexican Peso';

  @override
  String get currencyNameSgd => 'Singapore Dollar';

  @override
  String get currencyNameHkd => 'Hong Kong Dollar';

  @override
  String get currencyNameNok => 'Norwegian Krone';

  @override
  String get currencyNameSek => 'Swedish Krona';

  @override
  String get currencyNameNzd => 'New Zealand Dollar';

  @override
  String get currencyNameZar => 'South African Rand';

  @override
  String get currencyNameAed => 'UAE Dirham';

  @override
  String get currencyNameLbp => 'Lebanese Pound';

  @override
  String get currencyNameSar => 'Saudi Riyal';

  @override
  String get currencyNameKwd => 'Kuwaiti Dinar';

  @override
  String get currencyNameTry => 'Turkish Lira';

  @override
  String get notifAlertsChannel => 'BudgetSeal alerts';

  @override
  String get notifAlertsChannelDesc => 'Low envelope and upcoming bill alerts';

  @override
  String widgetReadyToAssign(String amount) {
    return 'Ready to assign: $amount';
  }

  @override
  String widgetSpentToday(String amount) {
    return '$amount spent today';
  }

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusFailed => 'Last sync failed — tap to check';

  @override
  String syncStatusLast(String when) {
    return 'Synced $when';
  }

  @override
  String get importColDebit => 'Debit (money out)';

  @override
  String get importColCredit => 'Credit (money in)';

  @override
  String importDuplicatesSkipped(int n) {
    return '$n already in the app';
  }

  @override
  String get acctReconcileMatches => 'Matches — nothing to adjust';

  @override
  String acctReconcileDiff(String amount) {
    return 'Difference $amount — an adjustment will be recorded';
  }

  @override
  String get acctReconcileConfirm => 'Mark as reconciled';

  @override
  String get acctReconciledMatch => 'Balance matches — reconciled';

  @override
  String acctLastReconciled(String date) {
    return 'Reconciled $date';
  }

  @override
  String get reportsCalendarMonths => 'Calendar months';

  @override
  String get reportsBudgetPeriods => 'Budget periods';

  @override
  String get upcomingPostNow => 'Post now';

  @override
  String get upcomingPostNowDesc => 'Record it today and move to the next date';

  @override
  String get upcomingSkip => 'Skip this one';

  @override
  String get upcomingSkipDesc => 'Move to the next date without recording it';

  @override
  String get upcomingPosted => 'Bill posted';

  @override
  String get upcomingSkipped => 'Skipped — next date updated';

  @override
  String recurringPostedN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n recurring items posted',
      one: '1 recurring item posted',
    );
    return '$_temp0';
  }

  @override
  String get objSummaryPerMonth => 'Needed per month';

  @override
  String get catLinkEnvelope => 'Envelope';

  @override
  String catLinkEnvelopeTitle(String name) {
    return 'Where does $name spending go?';
  }

  @override
  String catCreateEnvelope(String name) {
    return 'Create a \"$name\" envelope';
  }

  @override
  String get catUnlinkEnvelope => 'No envelope (unbudgeted)';

  @override
  String get allocReorderTitle => 'Reorder envelopes';

  @override
  String get allocReorderHint =>
      'Drag the handles. The Budget tab and funding screen follow this order.';

  @override
  String get periodSummaryTitle => 'A new budget period started';

  @override
  String periodSummaryBody(String spent, String funded) {
    return 'Last period you spent $spent of $funded budgeted.';
  }

  @override
  String periodSummaryUnder(String amount) {
    return '$amount under budget';
  }

  @override
  String periodSummaryOver(String amount) {
    return '$amount over budget';
  }

  @override
  String get periodSummaryFund => 'Fund this period';

  @override
  String get enginePeriodCovered => 'Overspending covered at period end';

  @override
  String get periodCoverFromRta => 'Cover from Ready to assign';

  @override
  String get periodCoverFromRtaDesc => 'Start the new period at zero';

  @override
  String get periodCarryDebt => 'Carry the overspending';

  @override
  String get periodCarryDebtDesc => 'The new period starts below zero';

  @override
  String allocFundToTarget(String amount) {
    return 'To target · $amount';
  }

  @override
  String allocFundAllAvailable(String amount) {
    return 'All available · $amount';
  }

  @override
  String get fundPresetLastPeriod => 'Same as last period';

  @override
  String get fundPresetSpent => 'What I spent last period';

  @override
  String get fundPresetClear => 'Clear';

  @override
  String get txExportSelected => 'Export CSV';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get txAllMonths => 'All months';

  @override
  String get txSelectAll => 'Select all';

  @override
  String get txBulkCategory => 'Change category';

  @override
  String get txBulkAccount => 'Change account';

  @override
  String get txBulkDate => 'Change date';

  @override
  String txBulkUpdated(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n transactions updated',
      one: '1 transaction updated',
    );
    return '$_temp0';
  }

  @override
  String txBulkSkipped(int n) {
    return '$n skipped';
  }

  @override
  String get txAllAccounts => 'All accounts';

  @override
  String get txAllCategories => 'All categories';

  @override
  String get txClearAllFilters => 'Clear all filters';

  @override
  String get txClearAll => 'Clear all';

  @override
  String get txSearchingAllMonths => 'Showing all months';

  @override
  String txSavedEnvelopeLeft(String envelope, String amount) {
    return 'Saved · $envelope: $amount left';
  }

  @override
  String txSavedEnvelopeOver(String envelope, String amount) {
    return 'Saved · $envelope is over by $amount';
  }

  @override
  String get allocMoveTitle => 'Move money';

  @override
  String get allocMoveDesc =>
      'Move money between envelopes, or back to Ready to assign.';

  @override
  String get allocCoverTitle => 'Cover overspending';

  @override
  String get allocCoverDesc =>
      'Take money from another envelope (or Ready to assign) to bring this one back to zero.';

  @override
  String get allocMoveFrom => 'From';

  @override
  String get allocMoveTo => 'To';

  @override
  String get allocMoveButton => 'Move';

  @override
  String get allocCoverButton => 'Cover';

  @override
  String get allocMoveMenu => 'Move money';

  @override
  String allocMoveNotEnough(String name, String amount) {
    return '$name only has $amount.';
  }

  @override
  String allocMovedTo(String name) {
    return 'Moved to $name';
  }

  @override
  String allocMovedFrom(String name) {
    return 'Moved from $name';
  }

  @override
  String allocMoveDone(String amount, String from, String to) {
    return 'Moved $amount from $from to $to';
  }

  @override
  String get tmplEditTitle => 'Edit template';

  @override
  String get tmplSaved => 'Template saved';

  @override
  String get txAfAddTitle => 'Add a title';

  @override
  String txAfItemN(int n) {
    return 'Item $n';
  }

  @override
  String get txAfRemoveItem => 'Remove item';

  @override
  String get shortcutAddTransaction => 'Add transaction';

  @override
  String get shortcutFundEnvelopes => 'Fund envelopes';

  @override
  String get shortcutUpcomingBills => 'Upcoming bills';

  @override
  String get catSheetRecent => 'Recent';

  @override
  String get txFormSwapAccounts => 'Swap accounts';

  @override
  String get txFormSaveAndNew => 'Save & new';

  @override
  String get allocEntryWithdrawn => 'Withdrawn';

  @override
  String get allocEntryRevaluation => 'Revaluation';

  @override
  String get allocEntryMoved => 'Moved';

  @override
  String fxSetRateTitle(String currency) {
    return 'Rate for $currency';
  }

  @override
  String get fxSetRateHint =>
      'Your rate is used for new transactions and reports until you switch back to the live rate.';

  @override
  String get fxUseLiveRate => 'Use live rate';

  @override
  String fxBaseLabel(String currency) {
    return 'Base currency: $currency';
  }

  @override
  String get fxNoCurrencies =>
      'Your budget uses only one currency. Add an account in another currency to see its rate here.';

  @override
  String fxNoRateFor(String currency) {
    return 'No rate for $currency yet — tap to set one';
  }

  @override
  String get fxManualTag => 'Your rate';

  @override
  String get fxLiveTag => 'Live';

  @override
  String get tileExchangeRatesSub => 'Live rates, or set your own';

  @override
  String get allocArchivedTitle => 'Archived envelopes';

  @override
  String get allocNoArchived => 'No archived envelopes.';

  @override
  String allocUnarchived(String name) {
    return '$name unarchived';
  }

  @override
  String get txNoRate => 'No rate';

  @override
  String get allocReadyToAssign => 'Ready to assign';

  @override
  String get allocAssign => 'Assign';

  @override
  String get accentGold => 'Gold';

  @override
  String get accentWax => 'Wax red';

  @override
  String get accentCopper => 'Copper';

  @override
  String get accentSage => 'Sage';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentSapphire => 'Sapphire';

  @override
  String get accentPlum => 'Plum';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentColorPairHint =>
      'Each color has a bright tone for dark mode and a deeper one for light mode, so text stays readable in both.';

  @override
  String commonPerDay(String amount) {
    return '$amount/day';
  }

  @override
  String commonNOfM(int n, int m) {
    return '$n of $m';
  }

  @override
  String fundAmountOfAvailable(
      String currency, String amount, String available) {
    return '$currency: $amount of $available';
  }

  @override
  String get syncNoSyncFile => 'No sync file found';

  @override
  String get syncErrNeedsPassword =>
      'The sync file is encrypted. Enter your sync password in Cloud Sync to read it.';

  @override
  String travelExchangeNote(String currency) {
    return 'Travel exchange → $currency';
  }

  @override
  String travelConvertBackNote(String currency) {
    return 'Travel convert back → $currency';
  }

  @override
  String healthUnallocShort(String amount) {
    return 'Unallocated: $amount';
  }

  @override
  String reportsRecurringSummary(int count, String amount) {
    return '$count active · $amount/month';
  }

  @override
  String allocRevaluationNote(String amount, String rate, String oldRate) {
    return 'Revaluation: $amount at $rate (was $oldRate)';
  }

  @override
  String notifEveryDayAt(String time) {
    return 'Every day at $time';
  }

  @override
  String periodStartsEachMonth(String date, int day) {
    return '$date · starts on day $day each month';
  }

  @override
  String fundMoreThanAvailable(String amount, String currency) {
    return '$amount more than available in $currency';
  }

  @override
  String get shareHouseholdFailed =>
      'Couldn\'t create the invite. Check your connection and try again.';

  @override
  String a11yPctOfTarget(int pct, String amount) {
    return '$pct% of $amount';
  }

  @override
  String get a11yFlexibleEnvelope => 'flexible envelope';

  @override
  String get a11yNeedsReview => 'needs review';

  @override
  String get syncLocalFile => 'Local file';

  @override
  String get syncGoogleSub => 'Sign in with your Google account';

  @override
  String get syncOneDriveSub => 'Requires the OneDrive app installed';

  @override
  String get syncDropboxSub => 'Requires the Dropbox app installed';

  @override
  String get syncLocalFileSub => 'Pick any file on your device';

  @override
  String get syncErrGoogleNotConfigured =>
      'Google Sign-In is not set up for this build of the app. Use another sync option.';

  @override
  String get syncErrNetwork => 'Network error. Check your internet connection.';

  @override
  String get syncErrConnectFailed => 'Couldn\'t connect. Please try again.';

  @override
  String onboardConnectFailed(String provider) {
    return 'Couldn\'t connect to $provider';
  }

  @override
  String get onboardNoSyncFile => 'No sync file found';

  @override
  String get onboardDriveJoinFailed =>
      'Couldn\'t connect to Google Drive. Make sure you\'re signed in and have access to the shared folder.';

  @override
  String get onboardNoSyncFileShared =>
      'No sync file found in the shared folder';

  @override
  String get billNoteTitle => 'Bill split';

  @override
  String billNoteTotal(String total) {
    return 'Bill: $total';
  }

  @override
  String billNoteSplitWith(String people, String total) {
    return 'Split with $people · Total: $total';
  }

  @override
  String reportsDayN(int n) {
    return 'Day $n';
  }

  @override
  String reportsTipOverPace(String amount) {
    return 'At your current pace, you\'ll exceed your budget by $amount. Try to slow down.';
  }

  @override
  String reportsTipUnderPace(String amount) {
    return 'Great pace! You\'re on track to stay $amount under budget.';
  }

  @override
  String reportsTipSavingHigh(int percent) {
    return 'You\'re saving $percent% of your income this month. Keep it up!';
  }

  @override
  String reportsTipSavingLow(int percent) {
    return 'Your savings rate is low ($percent%). Try to set aside at least 10–20%.';
  }

  @override
  String reportsTipAgeLow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Your money sits only $days days before being spent. A buffer of 30+ days is healthier.',
      one:
          'Your money sits only 1 day before being spent. A buffer of 30+ days is healthier.',
    );
    return '$_temp0';
  }

  @override
  String txNoRateBetween(String from, String to) {
    return 'No exchange rate from $from to $to. Enter a rate for this amount, or refresh rates in Settings › Exchange rates.';
  }

  @override
  String acctArchiveNonZero(String amount) {
    return 'This account still holds $amount. Transfer it to another account or adjust the balance to zero, then archive it — archived accounts no longer count toward your money.';
  }

  @override
  String get receiptPickFailed =>
      'Couldn\'t add the photo. Check camera and photo permissions.';

  @override
  String get backupCloseApp => 'Close app';

  @override
  String importSkippedRows(int count) {
    return '$count rows skipped (unreadable date or amount)';
  }

  @override
  String get moreMoneySection => 'Money';

  @override
  String get moreAppSection => 'App';

  @override
  String get txFormNewExpense => 'New expense';

  @override
  String get txFormNewIncome => 'New income';

  @override
  String get txFormNewTransfer => 'New transfer';

  @override
  String get txFormEditExpense => 'Edit expense';

  @override
  String get txFormEditIncome => 'Edit income';

  @override
  String get txFormEditTransfer => 'Edit transfer';

  @override
  String reportsTxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get dashUpcoming => 'Upcoming';

  @override
  String get dashOverdue => 'Overdue';

  @override
  String dashBillsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills',
      one: '1 bill',
      zero: 'No bills',
    );
    return '$_temp0';
  }

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
  String get appTaglineAbout => 'Envelope budgeting, simplified.';

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
  String get dashboardQuickTemplates => 'Quick Templates';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardNoTransactionsYet => 'No transactions yet';

  @override
  String get dashboardNoTransactionsToday =>
      'No transactions today — tap + to add one';

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
  String get dashboardSectionMoneyDesc => 'Bills, net worth and unallocated';

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
  String get txFromDate => 'From date';

  @override
  String get txToDate => 'To date';

  @override
  String get txMinAmount => 'Min';

  @override
  String get txMaxAmount => 'Max';

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
  String get txLongPressHint => 'Long press to select';

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
  String txNAccounts(int count) {
    return '$count accounts';
  }

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
  String get txFormDuplicateTitle => 'Possible Duplicate';

  @override
  String get txFormDuplicateContent =>
      'A similar transaction with the same amount, category, and date already exists. Save anyway?';

  @override
  String get txFormSaved => 'Transaction saved';

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
    return 'Split items ($count)';
  }

  @override
  String get txDetailLineDetail => 'Line detail';

  @override
  String get txDetailUncategorized => 'Uncategorized';

  @override
  String get txDetailRelatedSingle => 'Related transaction';

  @override
  String get txDetailRelatedPlural => 'Related transactions';

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
  String get catSheetAdd => 'Add';

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
  String get billWhosSplitting => 'Who\'s splitting?';

  @override
  String get billAddPerson => 'Add person';

  @override
  String get billSplitEvenly => 'Split evenly';

  @override
  String get billAssignItems => 'Assign items';

  @override
  String get billItemName => 'Item name';

  @override
  String get billTip => 'Tip';

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
  String get billEveryone => 'Everyone';

  @override
  String billSharedEach(int count, String amount) {
    return 'Shared $count ways · $amount each';
  }

  @override
  String get billSplitIntoUnits => 'Split into units';

  @override
  String get billSplitUnitsPrompt => 'How many units?';

  @override
  String get billTipLabel => 'Tip';

  @override
  String get billItemRemoved => 'Item removed';

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
  String get allocReview => 'Review';

  @override
  String get allocBudgeted => 'Budgeted';

  @override
  String get allocSpent => 'Spent';

  @override
  String get allocRemaining => 'Remaining';

  @override
  String get allocSectionSpending => 'Spending';

  @override
  String get allocSectionFlexible => 'Rollover';

  @override
  String get allocCreateTooltip => 'Create envelope';

  @override
  String get allocNoYet => 'No envelopes yet';

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
  String get allocNameIconSection => 'Name & icon';

  @override
  String get allocNameHint => 'Envelope name (e.g. Groceries)';

  @override
  String get allocRemoveIcon => 'Remove icon';

  @override
  String get allocTypeSection => 'Envelope type';

  @override
  String get allocSpendingTitle => 'Spending';

  @override
  String get allocSpendingDesc =>
      'For recurring expenses like groceries or fuel. Set a monthly budget and spend from it.';

  @override
  String get allocInfoBanner =>
      'Envelopes don\'t move money between accounts. They help you plan how to use the money you already have.';

  @override
  String get allocPurposeSection => 'Purpose';

  @override
  String get allocCycleSection => 'Cycle';

  @override
  String get allocPeriodic => 'Periodic';

  @override
  String get allocPermanent => 'Permanent';

  @override
  String get allocTargetAmount => 'Target amount';

  @override
  String get allocBudgetAmount => 'Budget amount';

  @override
  String get allocLinkCategory => 'Link Category';

  @override
  String get allocFromUnallocated => 'From your unallocated balance';

  @override
  String get allocFundAnyway => 'Fund Anyway';

  @override
  String get allocRecentActivity => 'Recent activity';

  @override
  String get allocNoActivity => 'No activity yet';

  @override
  String get allocSpendingHistory => 'Spending history';

  @override
  String get allocWithdrawTitle => 'Withdraw from Savings';

  @override
  String get allocWithdrawButton => 'Withdraw';

  @override
  String get allocNoForeignBalances =>
      'No foreign-currency balances to revalue';

  @override
  String get allocBalanceInEnvelope => 'balance in this envelope';

  @override
  String get allocOriginalRate => 'Original rate';

  @override
  String get allocOriginalValue => 'Original value';

  @override
  String get allocNewRate => 'New rate';

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
  String get allocArchiveTitle => 'Archive Envelope';

  @override
  String get allocArchiveMsg =>
      'This envelope will be hidden from all lists and stop taking spending. Linked categories and transaction history will be preserved.\n\nYou can unarchive it later from the Budget tab menu (⋮ › Archived envelopes).';

  @override
  String get allocArchived => 'Envelope archived';

  @override
  String get allocDeleteTitle => 'Delete Envelope';

  @override
  String get allocArchiveInstead => 'Archive Instead';

  @override
  String get allocDeletePermanently => 'Delete Permanently';

  @override
  String allocPercentSaved(int pct) {
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
  String get allocMonthlyBudget => 'Monthly budget';

  @override
  String get allocTargetOptional => 'Target (optional)';

  @override
  String get allocMonthlyBudgetDesc =>
      'How much do you want to spend in this envelope each month?';

  @override
  String get allocTargetDesc =>
      'Set a target amount, or leave at zero for open-ended.';

  @override
  String get allocLinkedCategoriesSection => 'Linked categories';

  @override
  String get allocLinkedCategoriesDesc =>
      'Expenses with these categories will debit this envelope.';

  @override
  String get allocNoCategoriesLinked =>
      'No categories linked. Tap + to link categories so expenses debit this envelope.';

  @override
  String get allocAvailable => 'Available';

  @override
  String allocAmountSpent(String amount) {
    return '$amount spent';
  }

  @override
  String allocAmountToGo(String amount) {
    return '$amount to go';
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
    return 'and $count more';
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
  String allocNoMatch(String query) {
    return 'No envelopes match \"$query\"';
  }

  @override
  String get allocCreateHelp =>
      'Create an envelope to start budgeting.\nTap ? for help.';

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
    return 'You\'re assigning $details. Your unallocated balance will go negative.\n\nContinue anyway?';
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
  String get acctAdjustBalance => 'Reconcile balance';

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
  String get acctArchived => 'Archived';

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
  String get acctNameSection => 'Name';

  @override
  String get acctAccountName => 'Account name';

  @override
  String get acctTypeSection => 'Type';

  @override
  String get acctCurrencySection => 'Currency';

  @override
  String get acctSelectCurrency => 'Select currency';

  @override
  String get acctDecimalSection => 'Decimal places';

  @override
  String acctDecimalAuto(int count) {
    return 'Auto ($count)';
  }

  @override
  String get acctOpeningBalance => 'Opening balance';

  @override
  String get acctCreateAccount => 'Create account';

  @override
  String get acctCreated => 'Account created';

  @override
  String get acctUpdated => 'Account updated';

  @override
  String get tmplCreated => 'Template created';

  @override
  String get acctRecentTransactions => 'Recent transactions';

  @override
  String get acctNoTransactions => 'No transactions yet';

  @override
  String get acctAdjustDesc =>
      'Enter the balance your bank (or wallet) shows. If it differs, an adjustment transaction is recorded for the difference.';

  @override
  String acctCurrentBalanceLabel(String amount) {
    return 'Current balance: $amount';
  }

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
  String get catSectionExpense => 'Expense';

  @override
  String get catSectionIncome => 'Income';

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
  String get commonCancel => 'Cancel';

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
  String get billCalUpcoming => 'Upcoming';

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
  String get subDetailPriceHistory => 'Price history';

  @override
  String get subDetailPresent => 'present';

  @override
  String get subDetailChangeCancel => 'Change Cancel Date';

  @override
  String get subDetailSetCancel => 'Set Cancellation Date';

  @override
  String get subDetailPastTx => 'Past transactions';

  @override
  String get subDetailUpcoming => 'Upcoming';

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
  String get objGoalsSection => 'Goals';

  @override
  String get objLoansSection => 'Loans';

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
  String get objColorSection => 'Color';

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
  String get settingsMoreTitle => 'More';

  @override
  String get settingsToolsSection => 'Tools';

  @override
  String get settingsAccountsSub => 'Manage your accounts and balances';

  @override
  String get settingsCategoriesSub => 'Manage groups and categories';

  @override
  String get settingsBillSplitterSub => 'Split bills & scan receipts';

  @override
  String get settingsTravelSub => 'Exchange currency for a trip';

  @override
  String get settingsWebCompanionSub => 'Manage your budget from a browser';

  @override
  String get settingsRecurringSub => 'Manage recurring transactions';

  @override
  String get settingsSubscriptionsSub => 'Track recurring subscriptions';

  @override
  String get settingsGoalsSub => 'Savings goals and debt tracking';

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
      'This will permanently delete ALL your data:\n\n• All accounts and balances\n• All transactions\n• All envelopes and categories\n• All settings\n\nThis cannot be undone. Are you absolutely sure?';

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
  String get tileTravelExchange => 'Travel Exchange';

  @override
  String get tileExchangeRates => 'Exchange rates';

  @override
  String get tileWebCompanion => 'Web Companion';

  @override
  String get tileSubscriptions => 'Subscriptions';

  @override
  String get tileGoalsLoans => 'Goals & Loans';

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
  String get syncConnectSection => 'Connect a provider';

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
  String get backupLocalSection => 'Local backups';

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
      'You\'ll get a notification when envelopes are overspent or bills are coming up. The app checks when it opens or comes back to the foreground, at most once a day per alert.';

  @override
  String get notifBillsTitle => 'Upcoming Bills';

  @override
  String get notifBillsDesc =>
      'You\'ll receive a notification when recurring transactions are due within 2 days. Checked when the app opens or comes back, at most once a day.';

  @override
  String get fxTitle => 'Exchange Rates';

  @override
  String get fxRefreshTooltip => 'Refresh rates';

  @override
  String get fxCacheInfo =>
      'Live rates are cached for an hour and filled in when you add a transaction. Tap a currency to set your own rate — it is used instead of the live one until you switch back.';

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
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsDataSection => 'Data';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsSecuritySection => 'Security';

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
  String get currencySymbolsAllSection => 'All currencies';

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
      'This will create adjustment ledger entries to bring allocation balances back in line with account balances. A backup is recommended before proceeding.\n\nContinue?';

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
  String reportsLessThanLast(int pct) {
    return '$pct% less than last month';
  }

  @override
  String reportsMoreThanLast(int pct) {
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
  String get reportsTopSpending => 'Top spending';

  @override
  String get reportsTopTransactions => 'Top transactions';

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
  String get reportsTipsSection => 'Tips';

  @override
  String get reportsNetWorth => 'Net worth';

  @override
  String get reportsAssets => 'Assets';

  @override
  String get reportsLiabilities => 'Liabilities';

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
  String get webAuthIncorrect => 'Incorrect PIN';

  @override
  String get webUndo => 'Undo';

  @override
  String get webTxNoRate => 'No rate';

  @override
  String get webTxAdd => 'Add transaction';

  @override
  String get webTxSearch => 'Search titles and notes';

  @override
  String get webFormType => 'Type';

  @override
  String get webFormFromAccount => 'From account';

  @override
  String get webFormAccount => 'Account';

  @override
  String get webFormToAccount => 'To account';

  @override
  String get webFormCategory => 'Category';

  @override
  String get webFormAmount => 'Amount';

  @override
  String get webFormCurrency => 'Currency';

  @override
  String get webFormDate => 'Date';

  @override
  String get webFormOptional => 'Optional';

  @override
  String get webValSelectAccount => 'Select an account';

  @override
  String get webValValidAmount => 'Enter a valid amount';

  @override
  String get webValSelectDest => 'Select destination account';

  @override
  String get webValAccountsDiffer => 'Pick two different accounts';

  @override
  String get webToastTxAdded => 'Transaction added';

  @override
  String get webToastTxUpdated => 'Transaction updated';

  @override
  String get webToastTxDeleted => 'Transaction deleted';

  @override
  String get webCatEmptyTitle => 'No categories here';

  @override
  String get webCatEmptySub => 'Categories group your spending and income.';

  @override
  String get webValNameRequired => 'Name is required';

  @override
  String get webToastCatAdded => 'Category added';

  @override
  String get webToastCatUpdated => 'Category saved';

  @override
  String get webAcctEmptyTitle => 'No accounts yet';

  @override
  String get webAcctEmptySub =>
      'Add the accounts you pay from to start tracking.';

  @override
  String get webAcctTypeBank => 'Bank';

  @override
  String get webAcctTypeCash => 'Cash';

  @override
  String get webAcctTypeCredit => 'Credit';

  @override
  String get webAcctTypeWallet => 'Wallet';

  @override
  String get webToastAcctAdded => 'Account added';

  @override
  String get webEnvEmptyTitle => 'No envelopes yet';

  @override
  String get webEnvEmptySub =>
      'Create envelopes in the app\'s Budget tab, then fund them from here.';

  @override
  String get webEnvFund => 'Fund';

  @override
  String get webFormNote => 'Note';

  @override
  String get webToastEnvFunded => 'Envelope funded';

  @override
  String get webFormEvery => 'Every';

  @override
  String get webToastRecurringAdded => 'Recurring added';

  @override
  String get webToastUpdated => 'Updated';

  @override
  String get webValSelectStartDate => 'Pick a date';

  @override
  String get webConfirmDeleteRecurring => 'Delete this recurring item?';

  @override
  String get webConfirmDeleteRecurringMsg =>
      'It stops posting. Transactions it already posted stay.';

  @override
  String get webToastDeleted => 'Deleted';

  @override
  String get webSubEmpty => 'No subscriptions yet';

  @override
  String get webToastSubAdded => 'Subscription added';

  @override
  String get webSubPriceHint => 'A new amount is added to the price history.';

  @override
  String get webConfirmDeleteSub => 'Delete this subscription?';

  @override
  String get webConfirmDeleteSubMsg =>
      'It stops posting. Payments already recorded stay.';

  @override
  String get webStatIncome => 'Income';

  @override
  String get webStatExpenses => 'Expenses';

  @override
  String get webStatNet => 'Net';

  @override
  String get webStatSavingsRate => 'Savings rate';

  @override
  String get webStatAvgDaily => 'Average per day';

  @override
  String get webStatTransactions => 'Transactions';

  @override
  String get webReportDailyCashflow => 'Day by day';

  @override
  String get webReportSpendingCat => 'Spending by category';

  @override
  String get webReportNoExpense => 'No spending this month';

  @override
  String get webReportIncomeCat => 'Income by category';

  @override
  String get webReportNoIncome => 'No income this month';

  @override
  String get webReportTopExpenses => 'Biggest expenses';

  @override
  String get webChartIncome => 'Income';

  @override
  String get webChartExpense => 'Expense';

  @override
  String get webShortcutsTitle => 'Keyboard shortcuts';

  @override
  String get webShortcutNewTx => 'New transaction';

  @override
  String get webShortcutSearch => 'Search transactions';

  @override
  String get webShortcutClose => 'Close the dialog';

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
  String get textScaleSmall => 'Small';

  @override
  String get textScaleDefault => 'Default';

  @override
  String get textScaleLarge => 'Large';

  @override
  String get textScaleExtraLarge => 'Extra Large';

  @override
  String get defcatGroceries => 'Groceries';

  @override
  String get defcatFuel => 'Fuel';

  @override
  String get defcatPublicTransit => 'Public Transit';

  @override
  String get defcatParkingTolls => 'Parking & Tolls';

  @override
  String get defcatMaintenance => 'Maintenance';

  @override
  String get defcatShopping => 'Shopping';

  @override
  String get defcatClothing => 'Clothing';

  @override
  String get defcatElectronics => 'Electronics';

  @override
  String get defcatEntertainment => 'Entertainment';

  @override
  String get defcatSubscriptions => 'Subscriptions';

  @override
  String get defcatHealth => 'Health';

  @override
  String get defcatPharmacy => 'Pharmacy';

  @override
  String get defcatPersonal => 'Personal';

  @override
  String get defcatEducation => 'Education';

  @override
  String get defcatGifts => 'Gifts';

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
  String get filePickerTitle => 'Select BudgetSeal Sync File';

  @override
  String get heatmapNoData => 'No data yet';

  @override
  String get heatmapNoActivity => 'No activity';

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
  String get onboardHouseholdSection => 'Household';

  @override
  String get onboardHouseholdName => 'Household name';

  @override
  String get onboardBaseCurrency => 'Base currency';

  @override
  String get onboardPeriodStart => 'Period start day';

  @override
  String get onboardFirstAccountSection => 'First account';

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
  String get onboardCategoriesSection => 'Categories';

  @override
  String get onboardFullSet => 'Full set';

  @override
  String get onboardFullSetSub => '30 categories with subcategories';

  @override
  String get onboardEmpty => 'Empty';

  @override
  String get onboardEmptySub => 'Create your own from scratch';

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
  String get travelTitle => 'Travel Exchange';

  @override
  String get travelInfo =>
      'Exchange money for your trip. A temporary travel wallet will be created automatically.';

  @override
  String get travelFrom => 'From';

  @override
  String get travelSelectAccount => 'Select account';

  @override
  String get travelAmountToExchange => 'Amount to exchange';

  @override
  String get travelCurrencySection => 'Travel currency';

  @override
  String get travelCurrencyReceive => 'Currency you receive';

  @override
  String get travelAmountReceived => 'Amount received';

  @override
  String get travelExchangeButton => 'Exchange & Create Travel Wallet';

  @override
  String get travelExistingWallet => 'Existing Travel Wallet';

  @override
  String travelPreviousWallet(String currency) {
    return 'You have a previous $currency travel wallet:';
  }

  @override
  String get travelCreateNew => 'Create New';

  @override
  String get travelReactivate => 'Reactivate';

  @override
  String get travelExchangeFailed => 'Exchange failed. Please try again.';

  @override
  String travelBalanceLabel(String amount) {
    return 'Balance: $amount';
  }

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
  String get periodTransitionFailed =>
      'Failed to complete transition. Please try again.';

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
  String get leftoverLoadError => 'Couldn\'t load data';

  @override
  String get leftoverCurrentBalance => 'Current balance';

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
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age days',
      one: '1 day',
    );
    return '$_temp0';
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
  String get objPaymentsSection => 'Payments';

  @override
  String get objSettingsSection => 'Settings';

  @override
  String get objTypeSection => 'Type';

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
  String get currencyYourAccounts => 'Your accounts';

  @override
  String get currencyRecentlyUsed => 'Recently used';

  @override
  String get currencyAll => 'All currencies';

  @override
  String syncConnectedTo(String provider) {
    return 'Connected to $provider';
  }

  @override
  String syncLastSynced(String time, String suffix) {
    return 'Last synced $time · $suffix';
  }

  @override
  String syncChangesMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes merged',
      one: '1 change merged',
    );
    return '$_temp0';
  }

  @override
  String get syncUpToDate => 'up to date';

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
