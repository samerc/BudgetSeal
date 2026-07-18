// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonOk => 'OK';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonReset => 'Réinitialiser';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonSearchHint => 'Rechercher…';

  @override
  String get commonNone => 'Aucun';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonYesterday => 'Hier';

  @override
  String get commonGotIt => 'Compris';

  @override
  String get commonGoBack => 'Retour';

  @override
  String get commonSaveAnyway => 'Enregistrer quand même';

  @override
  String get commonSomethingWentWrong => 'Une erreur est survenue';

  @override
  String get commonShowDetails => 'Afficher les détails';

  @override
  String get commonHideDetails => 'Masquer les détails';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get commonEnable => 'Activer';

  @override
  String get commonChange => 'Modifier';

  @override
  String get commonFund => 'Financer';

  @override
  String get commonNoData => 'Aucune donnée';

  @override
  String get commonCouldntLoadData => 'Impossible de charger vos données';

  @override
  String get commonCouldntLoadAccounts => 'Impossible de charger les comptes';

  @override
  String get commonAccount => 'Compte';

  @override
  String get commonAmount => 'Montant';

  @override
  String get commonCategory => 'Catégorie';

  @override
  String get commonCurrency => 'Devise';

  @override
  String get commonTitle => 'Titre';

  @override
  String get appName => 'BudgetSeal';

  @override
  String get appTagline => 'Budgétiser avec intention';

  @override
  String get appTaglineAbout => 'Budget par enveloppes, simplifié.';

  @override
  String get appBrandAbbr => 'PP';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabActivity => 'Activité';

  @override
  String get tabBudget => 'Budget';

  @override
  String get tabReports => 'Rapports';

  @override
  String get tabMore => 'Plus';

  @override
  String get navPressBackToExit => 'Appuyez à nouveau pour quitter';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navCategories => 'Catégories';

  @override
  String get navAccounts => 'Comptes';

  @override
  String get navEnvelopes => 'Enveloppes';

  @override
  String get navRecurring => 'Récurrents';

  @override
  String get navSubscriptions => 'Abonnements';

  @override
  String get navReports => 'Rapports';

  @override
  String get navServerStatus => 'Serveur';

  @override
  String get navSignOut => 'Déconnexion';

  @override
  String get typeIncome => 'Revenu';

  @override
  String get typeExpense => 'Dépense';

  @override
  String get typeTransfer => 'Virement';

  @override
  String get typeAll => 'Tout';

  @override
  String get dashboardWelcomeTitle => 'Bienvenue sur BudgetSeal !';

  @override
  String get dashboardWelcomeBody =>
      'Voici votre aperçu financier. Appuyez sur les actions rapides ci-dessous pour commencer à enregistrer des transactions.';

  @override
  String get dashboardHouseholdLabel => 'Foyer';

  @override
  String get dashboardDefaultName => 'BudgetSeal';

  @override
  String get dashboardCustomizeTooltip => 'Personnaliser';

  @override
  String get dashboardSearchTooltip => 'Rechercher';

  @override
  String get dashboardQuickTransfer => 'Virement';

  @override
  String get dashboardQuickFund => 'Financer';

  @override
  String get dashboardQuickSplit => 'Diviser';

  @override
  String get dashboardSectionYourMoney => 'Votre argent';

  @override
  String get dashboardReadyToAssign => 'Prêt à affecter';

  @override
  String get dashboardMoneyNotInEnvelope =>
      'Argent pas encore dans une enveloppe';

  @override
  String get dashboardSectionActivity => 'Activité';

  @override
  String get dashboardQuickTemplates => 'Modèles rapides';

  @override
  String get dashboardViewAll => 'Voir tout';

  @override
  String get dashboardRecent => 'Récent';

  @override
  String get dashboardNoTransactionsYet => 'Aucune transaction pour le moment';

  @override
  String get dashboardNoTransactionsToday =>
      'Aucune transaction aujourd\'hui — appuyez sur + pour en ajouter';

  @override
  String get dashboardTotalAcrossAccounts => 'Total de tous les comptes';

  @override
  String get dashboardLabelExpenses => 'Dépenses';

  @override
  String get dashboardLabelNet => 'Net';

  @override
  String get dashboardSpent => 'dépensé';

  @override
  String get dashboardNoSpending => 'Aucune dépense';

  @override
  String get dashboardLast7Days => '7 derniers jours';

  @override
  String get dashboardThisMonth => 'Ce mois-ci';

  @override
  String get dashboardEnvelopes => 'Enveloppes';

  @override
  String get dashboardOnTrack => 'En bonne voie';

  @override
  String get dashboardRunningLow => 'Presque épuisé';

  @override
  String get dashboardOverspent => 'Dépassé';

  @override
  String get dashboardHeadsUp => 'Attention';

  @override
  String dashboardIsOverLimit(String amount) {
    return 'dépasse sa limite de $amount';
  }

  @override
  String dashboardHasPercentLeft(String percent) {
    return 'n\'a plus que $percent% restant';
  }

  @override
  String dashboardBudgetLeftOf(String amount, String total) {
    return '$amount restant sur un budget de $total';
  }

  @override
  String dashboardBudgetOver(String amount, String total) {
    return '$amount au-dessus du budget de $total';
  }

  @override
  String dashboardSpendingPerDay(String amount, String projected) {
    return 'Dépenses $amount/jour · ~$projected en fin de mois';
  }

  @override
  String get dashboardMoneySits1Day =>
      'L\'argent reste 1 jour avant d\'être dépensé';

  @override
  String dashboardMoneySitsNDays(int n) {
    return 'L\'argent reste $n jours avant d\'être dépensé';
  }

  @override
  String get dashboardAgeOfMoneyTitle => 'Âge de l\'argent';

  @override
  String get dashboardAgeOfMoneyExplanation =>
      'Cela montre combien de temps l\'argent reste dans vos comptes avant d\'être dépensé.\\n\\nConsidérez-le comme un tampon :\\n\\n• Moins de 14 jours — vous dépensez aussi vite que l\'argent arrive\\n• 14–30 jours — vous avez un petit coussin\\n• 30–60 jours — vous dépensez le revenu du mois dernier. Excellent !\\n• 60+ jours — excellente santé financière\\n\\nL\'objectif est d\'augmenter ce nombre avec le temps.';

  @override
  String get dashboardSearchPlaceholder =>
      'Rechercher transactions, comptes...';

  @override
  String get dashboardTypeAtLeast2 => 'Tapez au moins 2 caractères';

  @override
  String dashboardNoResultsFor(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get dashboardSearchAccounts => 'Comptes';

  @override
  String get dashboardSearchCategories => 'Catégories';

  @override
  String get dashboardSearchTransactions => 'Transactions';

  @override
  String get dashboardOtherCategory => 'Autre';

  @override
  String get customizeTitle => 'Personnaliser le tableau de bord';

  @override
  String get customizeInstructions =>
      'Glissez pour réorganiser. Basculez pour afficher/masquer.';

  @override
  String get dashboardSectionStatusLabel => 'Carte de statut';

  @override
  String get dashboardSectionStatusDesc =>
      'Statut du budget, vélocité, âge de l\'argent';

  @override
  String get dashboardSectionSpendingLabel => 'Aperçu des dépenses';

  @override
  String get dashboardSectionSpendingDesc =>
      'Graphique en anneau avec répartition par catégorie';

  @override
  String get dashboardSectionQuickLabel => 'Actions rapides';

  @override
  String get dashboardSectionQuickDesc =>
      'Dépense, revenu, virement, financement';

  @override
  String get dashboardSectionMoneyLabel => 'Votre argent';

  @override
  String get dashboardSectionMoneyDesc =>
      'Patrimoine net et santé des enveloppes';

  @override
  String get dashboardSectionUnallocatedLabel => 'Prêt à affecter';

  @override
  String get dashboardSectionUnallocatedDesc => 'Fonds non affectés';

  @override
  String get dashboardSectionActivityLabel => 'Activité récente';

  @override
  String get dashboardSectionActivityDesc => 'Modèles et transactions récentes';

  @override
  String get dashboardNetWorth => 'Patrimoine net';

  @override
  String get dashboardUnallocated => 'Non alloué';

  @override
  String dashboardOtherCount(int count) {
    return '+ $count autre(s)';
  }

  @override
  String get dashboardAddFirstExpense => 'Ajoutez votre première dépense';

  @override
  String get dashboardFundEnvelopesTooltip => 'Alimenter les enveloppes';

  @override
  String get dashboardSplitBillTooltip => 'Partager une note';

  @override
  String dashboardCatSpendingHigher(String category, int percent) {
    return 'Les dépenses en $category sont $percent% plus élevées que le mois dernier';
  }

  @override
  String dashboardSpendingLowerNice(int percent) {
    return 'Les dépenses sont $percent% inférieures au mois dernier — bravo !';
  }

  @override
  String dashboardSpendingHigher(int percent) {
    return 'Les dépenses sont $percent% supérieures au mois dernier';
  }

  @override
  String get dashboardSpendingOnTrack =>
      'Les dépenses sont en bonne voie ce mois-ci';

  @override
  String dashboardAddLabel(String label) {
    return 'Ajouter $label';
  }

  @override
  String dashboardChartSemantic(String amount, int count) {
    return 'Graphique des dépenses, total $amount, $count catégories';
  }

  @override
  String get dashboardNoSpendingSemantic => 'Aucune dépense cette période';

  @override
  String get txTitle => 'Transactions';

  @override
  String get txIntroTitle => 'Vos transactions';

  @override
  String get txIntroBody =>
      'Vos transactions apparaissent ici groupées par date. Glissez à gauche pour supprimer, à droite pour modifier. Appui long pour plus d\'options.';

  @override
  String get txDeleteSelectedTitle => 'Supprimer la sélection ?';

  @override
  String txDeleteSelectedContent(int count) {
    return 'Supprimer $count transaction(s) ? Cela annulera les déductions des enveloppes.';
  }

  @override
  String txNDeleted(int count) {
    return '$count transaction(s) supprimée(s)';
  }

  @override
  String txNSelected(int count) {
    return '$count sélectionnée(s)';
  }

  @override
  String get txDeleteSelectedTooltip => 'Supprimer la sélection';

  @override
  String get txSearchHint => 'Rechercher des transactions...';

  @override
  String get txCloseSearch => 'Fermer la recherche';

  @override
  String get txFilterTooltip => 'Filtrer les transactions';

  @override
  String get txSearchTooltip => 'Rechercher les transactions';

  @override
  String get txListSettingsTooltip => 'Paramètres de la liste';

  @override
  String get txQuickAddHint => 'Tapez le nom et le montant, ex. Café 4.50';

  @override
  String get txSendTooltip => 'Envoyer';

  @override
  String get txScrollTopTooltip => 'Retour en haut';

  @override
  String get txSplitBillTooltip => 'Partager l\'addition';

  @override
  String get txAddTooltip => 'Ajouter une transaction';

  @override
  String get txFromDate => 'Du';

  @override
  String get txToDate => 'Au';

  @override
  String get txMinAmount => 'Min';

  @override
  String get txMaxAmount => 'Max';

  @override
  String get txClearFilters => 'Effacer les filtres avancés';

  @override
  String get txSelectYear => 'Choisir l\'année';

  @override
  String txFilteredCategory(String categoryName) {
    return 'Filtré : $categoryName';
  }

  @override
  String txNoCategoryInMonth(String categoryName, String monthLabel) {
    return 'Aucune transaction $categoryName en $monthLabel';
  }

  @override
  String get txNoMatching => 'Aucune transaction correspondante';

  @override
  String get txNoYet => 'Aucune transaction pour le moment';

  @override
  String get txTapPlus => 'Appuyez sur + pour en ajouter';

  @override
  String get txAddFirst => 'Ajoutez votre première transaction';

  @override
  String txSpentOfBudget(String spent, String budget) {
    return '$spent dépensé sur un budget de $budget';
  }

  @override
  String txTotalCashFlow(String amount, int count) {
    return 'Flux total : $amount · $count transaction(s)';
  }

  @override
  String get txLongPressHint => 'Appui long pour les options';

  @override
  String txNItems(int count) {
    return '$count éléments';
  }

  @override
  String txNMore(int count) {
    return '+$count de plus';
  }

  @override
  String get txContextEdit => 'Modifier';

  @override
  String get txContextDuplicate => 'Dupliquer';

  @override
  String get txDeleteTitle => 'Supprimer la transaction ?';

  @override
  String get txDeleteCannotUndo => 'Cette action est irréversible.';

  @override
  String get txDeleteShort => 'Supprimer ?';

  @override
  String txDeleteWithReversal(String label) {
    return 'Supprimer $label ? Cela annulera les déductions des enveloppes.';
  }

  @override
  String txNAccounts(int count) {
    return '$count comptes';
  }

  @override
  String get txFormEditTitle => 'Modifier';

  @override
  String get txFormNewTitle => 'Nouvelle transaction';

  @override
  String get txFormNoteHint => 'Ajouter une note…';

  @override
  String get txFormTitleHint => 'Titre (ex. Café, Courses)';

  @override
  String get txFormUseTemplate => 'Utiliser un modèle';

  @override
  String get txFormAutoDetected => 'Détecté automatiquement';

  @override
  String get txFormNoCategory => 'Aucune catégorie';

  @override
  String get txFormFromAccount => 'Depuis le compte';

  @override
  String get txFormToAccount => 'Vers le compte';

  @override
  String get txFormDestReceives => 'Le destinataire reçoit :';

  @override
  String get txFormAddItem => 'Ajouter un élément';

  @override
  String get txFormTotal => 'Total';

  @override
  String get txFormSelectSource => 'Sélectionnez un compte source';

  @override
  String get txFormSelectDest => 'Sélectionnez un compte de destination';

  @override
  String get txFormSourceDestDiffer =>
      'La source et la destination doivent être différents';

  @override
  String get txFormEnterAmount => 'Saisissez un montant';

  @override
  String txFormSelectAccountItem(int n) {
    return 'Sélectionnez un compte pour l\'élément $n';
  }

  @override
  String get txFormSelectAccount =>
      'Sélectionnez un compte pour la transaction';

  @override
  String txFormEnterAmountItem(int n) {
    return 'Saisissez un montant pour l\'élément $n';
  }

  @override
  String get txFormEnterAmountTx => 'Saisissez un montant pour la transaction';

  @override
  String get txFormRateNotSetTitle => 'Taux de change non défini';

  @override
  String get txFormRateNotSetContent =>
      'Enregistrer quand même, ou revenir définir le taux ?';

  @override
  String get txFormDuplicateTitle => 'Doublon possible';

  @override
  String get txFormDuplicateContent =>
      'Une transaction similaire avec le même montant, catégorie et date existe déjà. Enregistrer quand même ?';

  @override
  String get txFormSaved => 'Transaction enregistrée';

  @override
  String txFormSavedEnvelope(String envelopeName) {
    return 'Transaction enregistrée · Enveloppe $envelopeName mise à jour';
  }

  @override
  String txFormErrorSaving(String error) {
    return 'Erreur lors de l\'enregistrement : $error';
  }

  @override
  String get txFormReceiptAttached => 'Reçu joint';

  @override
  String txFormNReceipts(int count) {
    return '$count reçus joints';
  }

  @override
  String get txFormAddMore => 'Ajouter plus';

  @override
  String get txFormScanReceipt => 'Scanner le reçu';

  @override
  String get txFormGallery => 'Galerie';

  @override
  String get txDetailTitle => 'Détails de la transaction';

  @override
  String get txDetailNotFound => 'Transaction introuvable';

  @override
  String txDetailCopied(String amount) {
    return '$amount copié';
  }

  @override
  String get txDetailDate => 'Date';

  @override
  String get txDetailTime => 'Heure';

  @override
  String get txDetailAccounts => 'Comptes';

  @override
  String get txDetailNote => 'Note';

  @override
  String get txDetailUnknownAccount => 'Inconnu';

  @override
  String txDetailSplitItems(int count) {
    return 'ÉLÉMENTS RÉPARTIS ($count)';
  }

  @override
  String get txDetailLineDetail => 'DÉTAIL DE LA LIGNE';

  @override
  String get txDetailUncategorized => 'Non catégorisé';

  @override
  String get txDetailRelatedSingle => 'TRANSACTION LIÉE';

  @override
  String get txDetailRelatedPlural => 'TRANSACTIONS LIÉES';

  @override
  String txDetailReceipts(int count) {
    return 'Reçus ($count)';
  }

  @override
  String get txDetailReceipt => 'Reçu';

  @override
  String get txDetailAttach => 'Joindre';

  @override
  String get txDetailNoReceipt => 'Aucun reçu joint';

  @override
  String get txDetailDeleteTitle => 'Supprimer la transaction';

  @override
  String get txDetailDeleteContent =>
      'Voulez-vous vraiment supprimer cette transaction ?\\n\\nCela annulera les déductions des enveloppes et restaurera le solde. Les écritures seront supprimées.\\n\\nCette action est irréversible.';

  @override
  String get txAfDiscardTitle => 'Abandonner la transaction ?';

  @override
  String get txAfDiscardContent =>
      'Vous avez une transaction non enregistrée. Voulez-vous revenir en arrière ?';

  @override
  String get txAfKeepEditing => 'Continuer l\'édition';

  @override
  String get txAfDiscard => 'Abandonner';

  @override
  String get txAfEnterTitle => 'Saisir le titre';

  @override
  String get txAfTransferNoteHint => 'Note (ex. loyer, épargne)';

  @override
  String get txAfEnterAmountButton => 'Saisir le montant';

  @override
  String get txAfSelectCategoryButton => 'Choisir la catégorie';

  @override
  String get txAfSelectCategoryTitle => 'Choisir la catégorie';

  @override
  String get txAfSearchCategories => 'Rechercher des catégories...';

  @override
  String get txAfNewCategory => 'Nouvelle catégorie';

  @override
  String get txAfEnterAmountTitle => 'Saisir le montant';

  @override
  String get txAfFromAccount => 'Compte source';

  @override
  String get txAfToAccount => 'Compte destination';

  @override
  String get txAfTapToSelect => 'Appuyez pour sélectionner';

  @override
  String get txAfAddAccount => 'Ajouter un compte';

  @override
  String get txAfExchangeRateRequired => 'Taux de change requis';

  @override
  String txAfHowManyPer(String sourceCurrency, String destCurrency) {
    return 'Combien de $sourceCurrency pour 1 $destCurrency ?';
  }

  @override
  String get txAfTapToEnterRate => 'Appuyez pour saisir le taux';

  @override
  String txAfRecipientGets(String amount) {
    return 'Le destinataire reçoit = $amount';
  }

  @override
  String txAfFetchingRate(String currency) {
    return 'Récupération du taux pour $currency...';
  }

  @override
  String get txAfEnterAmountFirst =>
      'Saisissez d\'abord un montant pour cet élément';

  @override
  String get txAfPleaseSelectAccount => 'Veuillez sélectionner un compte';

  @override
  String get txAfPleaseSelectDest =>
      'Veuillez sélectionner un compte de destination';

  @override
  String get txAfMixedTitle => 'Transaction mixte';

  @override
  String get txAfAddAnother => 'Ajouter un autre élément';

  @override
  String get txAfSaveTransfer => 'Enregistrer le virement';

  @override
  String txAfSaveNItems(int count) {
    return 'Enregistrer $count éléments';
  }

  @override
  String get txAfAddTransaction => 'Ajouter une transaction';

  @override
  String get catSheetNew => 'Nouveau';

  @override
  String get catSheetNameHint => 'Nom de la catégorie';

  @override
  String get catSheetAdd => 'Ajouter';

  @override
  String get catSheetNoMatching => 'Aucune catégorie correspondante';

  @override
  String get catSheetNoYet =>
      'Aucune catégorie.\\nAppuyez sur « Nouveau » ci-dessus pour en créer une.';

  @override
  String catSheetNSubcategories(int count) {
    return '$count sous-catégories';
  }

  @override
  String get currencyYourAccounts => 'VOS COMPTES';

  @override
  String get currencyRecentlyUsed => 'RÉCEMMENT UTILISÉES';

  @override
  String get currencyAll => 'TOUTES LES DEVISES';

  @override
  String get txWidgetSelectAccount => 'Sélectionner un compte';

  @override
  String get txWidgetItemNote => 'Note de l\'élément…';

  @override
  String get txListTitle => 'Liste des transactions';

  @override
  String get txListSelectLayout => 'Choisir la disposition';

  @override
  String get txListDateBanner => 'Total de la bannière de date';

  @override
  String get txListDayTotal => 'Total du jour';

  @override
  String get txListNone => 'Aucun';

  @override
  String get txListAccountLabel => 'Libellé du compte';

  @override
  String get txListAccountSubtitle =>
      'Afficher le nom du compte sur chaque transaction';

  @override
  String get txListCategoryIcon => 'Icône de catégorie';

  @override
  String get txListCategorySubtitle =>
      'Afficher le cercle d\'icône de catégorie';

  @override
  String get txListTime => 'Heure';

  @override
  String get txListTimeSubtitle => 'Afficher l\'heure de la transaction';

  @override
  String get txListPreviewName => 'Nom de la transaction';

  @override
  String get txListPreviewNote =>
      'Ceci est une note associée à la transaction.';

  @override
  String get billTitle => 'Partage d\'addition';

  @override
  String get billScanning => 'Numérisation du reçu...';

  @override
  String get billScanTooltip => 'Scanner le reçu';

  @override
  String get billEmptyTitle => 'Ajouter des éléments à partager';

  @override
  String get billEmptySubtitle => 'Scannez un reçu ou ajoutez manuellement';

  @override
  String get billScanButton => 'Scanner le reçu';

  @override
  String get billAddManually => 'Ajouter manuellement';

  @override
  String get billAddItem => 'Ajouter un élément';

  @override
  String get billTakePhoto => 'Prendre une photo';

  @override
  String get billFromGallery => 'Choisir depuis la galerie';

  @override
  String get billNoText => 'Aucun texte détecté. Essayez une photo plus nette.';

  @override
  String get billEnterAmount => 'Saisir le montant';

  @override
  String get billKeepAsOne => 'Garder en un seul';

  @override
  String get billSplit => 'Diviser';

  @override
  String get billWhosSplitting => 'QUI PARTAGE ?';

  @override
  String get billAddPerson => 'Ajouter une personne';

  @override
  String get billSplitEvenly => 'Partager équitablement';

  @override
  String get billAssignItems => 'ATTRIBUER LES ÉLÉMENTS';

  @override
  String get billItemName => 'Nom de l\'élément';

  @override
  String get billTip => 'Pourboire';

  @override
  String get billTipNone => 'Aucun';

  @override
  String get billPercentage => 'Pourcentage';

  @override
  String get billTipAmount => 'Montant du pourboire';

  @override
  String get billBillCurrency => 'Devise de l\'addition';

  @override
  String get billRateHint => 'Taux';

  @override
  String get billTotal => 'Total';

  @override
  String get billReScan => 'Re-scanner';

  @override
  String billNLines(int detected, int withPrice) {
    return '$detected lignes ($withPrice avec prix)';
  }

  @override
  String get billMe => 'Moi';

  @override
  String get billStep1Desc =>
      'Étape 1 : Ajoutez les articles de votre reçu — scannez ou entrez manuellement.';

  @override
  String get billStep2Desc =>
      'Étape 2 : Ajoutez des personnes et assignez les articles. Activez « Diviser également » pour répartir le total équitablement.';

  @override
  String get billStep3Desc =>
      'Étape 3 : Vérifiez la répartition, ajoutez le pourboire et confirmez.';

  @override
  String billBillIn(String currency) {
    return 'Addition en $currency';
  }

  @override
  String get billExchangeRateTitle => 'Taux de change';

  @override
  String get billRemovePersonTitle => 'Supprimer la personne';

  @override
  String billRemovePersonContent(String name, int count) {
    return '$name a $count article(s) assigné(s) uniquement à lui/elle. Réassigner à quelqu\'un d\'autre ou supprimer ces articles ?';
  }

  @override
  String get billReassignTo => 'Réassigner à :';

  @override
  String get billPersonRemoved => 'Personne supprimée';

  @override
  String get billEveryone => 'Tout le monde';

  @override
  String billSharedEach(int count, String amount) {
    return 'Partagé en $count · $amount chacun';
  }

  @override
  String get billSplitIntoUnits => 'Diviser en unités';

  @override
  String get billSplitUnitsPrompt => 'Combien d\'unités ?';

  @override
  String get billTipLabel => 'Pourboire';

  @override
  String get billItemRemoved => 'Article supprimé';

  @override
  String get billDeleteItems => 'Supprimer les articles';

  @override
  String billEachPays(String amount) {
    return 'Chaque personne paie $amount';
  }

  @override
  String billSplitQtyTitle(int qty, String name) {
    return '$qty × $name';
  }

  @override
  String billSplitQtyContent(int qty, String amount) {
    return 'Diviser en $qty articles ($amount chacun) ?';
  }

  @override
  String get billRateNotSetTitle => 'Taux de change non défini';

  @override
  String billRateNotSetContent(String currency) {
    return 'L\'addition est en $currency mais aucun taux n\'a été saisi.\nLa transaction sera enregistrée sans conversion.';
  }

  @override
  String get billGoBackBtn => 'Retour';

  @override
  String get billContinueAnyway => 'Continuer quand même';

  @override
  String get txFormCouldNotSave =>
      'Impossible d\'enregistrer la transaction. Veuillez réessayer.';

  @override
  String get txTransactionDeleted => 'Transaction supprimée';

  @override
  String get txUndoAction => 'Annuler';

  @override
  String get txNewTransactionSheet => 'Nouvelle transaction';

  @override
  String get txCouldNotLoad => 'Impossible de charger la transaction';

  @override
  String txAfMixedContent(int count, String summary) {
    return 'Cela créera $count transactions liées :\n\n$summary\n\nElles apparaîtront comme des transactions séparées mais liées entre elles.';
  }

  @override
  String txAfAnotherWithCount(int count, String total) {
    return 'Ajouter un autre article ($count articles · $total)';
  }

  @override
  String txFormRateNotSetBody(String items, String baseCurrency) {
    return '$items n\'a pas de taux de change vers $baseCurrency. Le montant ne sera pas inclus dans vos totaux en devise de base.\n\nEnregistrer quand même ou revenir pour définir le taux ?';
  }

  @override
  String get txFormDuplicateSimilarExists =>
      'Une transaction similaire existe déjà :';

  @override
  String get txFormDuplicateSaveAnyway => 'Enregistrer quand même ?';

  @override
  String get txFormNoTitle => 'Sans titre';

  @override
  String get allocTitle => 'Budget';

  @override
  String get allocSearchTooltip => 'Rechercher des enveloppes';

  @override
  String get allocHelpTooltip => 'Comment fonctionnent les enveloppes';

  @override
  String get allocHelpTitle => 'Comment fonctionnent les enveloppes';

  @override
  String get allocHelpStep1 =>
      'Créez des enveloppes pour chaque catégorie de dépense';

  @override
  String get allocHelpStep2 => 'Définissez un objectif mensuel pour chacune';

  @override
  String get allocHelpStep3 => 'Financez les enveloppes quand vous êtes payé';

  @override
  String get allocHelpStep4 =>
      'Dépensez depuis les enveloppes — suivez ce qu\'il reste';

  @override
  String get allocSearchHint => 'Rechercher des enveloppes...';

  @override
  String get allocNewPeriodStarted => 'Nouvelle période commencée';

  @override
  String allocNNeedReview(int count) {
    return '$count enveloppe(s) à examiner';
  }

  @override
  String get allocReview => 'Examiner';

  @override
  String get allocBudgeted => 'Budgétisé';

  @override
  String get allocSpent => 'Dépensé';

  @override
  String get allocRemaining => 'Restant';

  @override
  String get allocUnallocated => 'Non affecté';

  @override
  String get allocFundEnvelopes => 'Financer les enveloppes';

  @override
  String get allocSectionSpending => 'Dépenses';

  @override
  String get allocSectionSavings => 'Épargne';

  @override
  String get allocSectionFlexible => 'Cumulatif';

  @override
  String allocNoMatch(String query) {
    return 'Aucune enveloppe ne correspond à « $query »';
  }

  @override
  String get allocCreateTooltip => 'Créer une enveloppe';

  @override
  String get allocNoYet => 'Aucune enveloppe pour le moment';

  @override
  String get allocCreateHelp =>
      'Créez une enveloppe pour commencer.\\nAppuyez sur ? pour l\'aide.';

  @override
  String get allocCreateButton => 'Créer une enveloppe';

  @override
  String get allocNewEnvelope => 'Nouvelle enveloppe';

  @override
  String get allocFallbackName => 'Enveloppe';

  @override
  String get allocEditSettings => 'Modifier les paramètres';

  @override
  String get allocWithdrawMenu => 'Retirer';

  @override
  String get allocRevalueMenu => 'Réévaluer les soldes';

  @override
  String get allocArchiveMenu => 'Archiver';

  @override
  String get allocCreateButtonDetail => 'Créer une enveloppe';

  @override
  String get allocSaveChanges => 'Enregistrer les modifications';

  @override
  String get allocNameIconSection => 'NOM ET ICÔNE';

  @override
  String get allocNameHint => 'Nom de l\'enveloppe (ex. Courses)';

  @override
  String get allocRemoveIcon => 'Supprimer l\'icône';

  @override
  String get allocTypeSection => 'TYPE D\'ENVELOPPE';

  @override
  String get allocSpendingTitle => 'Dépenses';

  @override
  String get allocSpendingDesc =>
      'Pour les dépenses récurrentes comme les courses ou le carburant. Définissez un budget mensuel.';

  @override
  String get allocSavingGoalTitle => 'Épargne (avec objectif)';

  @override
  String get allocSavingGoalDesc =>
      'Pour un objectif précis comme les impôts ou les vacances. Définissez un objectif et financez-le.';

  @override
  String get allocSavingOpenTitle => 'Épargne (libre)';

  @override
  String get allocSavingOpenDesc =>
      'Pour l\'épargne générale sans objectif précis. Mettez de l\'argent de côté quand vous pouvez.';

  @override
  String get allocInfoBanner =>
      'Les enveloppes ne déplacent pas l\'argent entre les comptes. Elles vous aident à planifier l\'utilisation de votre argent.';

  @override
  String get allocPurposeSection => 'OBJECTIF';

  @override
  String get allocSaving => 'Épargne';

  @override
  String get allocFlexible => 'Cumulatif';

  @override
  String get allocCycleSection => 'CYCLE';

  @override
  String get allocPeriodicDesc =>
      '• Périodique : se réinitialise chaque mois (ex. budget courses)\\n• Permanent : s\'accumule dans le temps (ex. fonds d\'urgence)';

  @override
  String get allocPeriodic => 'Périodique';

  @override
  String get allocPermanent => 'Permanent';

  @override
  String get allocRolloverTitle => 'Reporter le solde';

  @override
  String get allocRolloverSubtitle =>
      'Reporter les fonds restants à la prochaine période';

  @override
  String get allocAutoResetTitle => 'Réinitialisation auto';

  @override
  String get allocAutoResetSubtitle =>
      'Réinitialiser automatiquement au début de la période';

  @override
  String get allocSavingsTargetSection => 'OBJECTIF D\'ÉPARGNE';

  @override
  String get allocMonthlyBudgetSection => 'BUDGET MENSUEL';

  @override
  String get allocSavingsTargetHelp =>
      'Combien souhaitez-vous épargner dans cette enveloppe ?';

  @override
  String get allocMonthlyBudgetHelp =>
      'Combien souhaitez-vous dépenser dans cette enveloppe chaque mois ?';

  @override
  String get allocTargetAmount => 'Montant cible';

  @override
  String get allocBudgetAmount => 'Montant du budget';

  @override
  String get allocLinkedCategories => 'CATÉGORIES LIÉES';

  @override
  String get allocLinkedHelp =>
      'Les dépenses avec ces catégories seront débitées de cette enveloppe.';

  @override
  String get allocNoCategoriesWarning =>
      'Aucune catégorie liée. Appuyez sur + pour lier des catégories.';

  @override
  String get allocLinkCategory => 'Lier une catégorie';

  @override
  String get allocSavedLabel => 'Épargné';

  @override
  String get allocAvailableLabel => 'Disponible';

  @override
  String get allocLeftSuffix => 'restant';

  @override
  String get allocFromUnallocated => 'Depuis votre solde non affecté';

  @override
  String get allocOverfundingTitle => 'Surfinancement';

  @override
  String get allocOverfundingMsg =>
      'Votre solde non affecté deviendra négatif. Continuer ?';

  @override
  String get allocFundAnyway => 'Financer quand même';

  @override
  String allocCouldNotFund(String error) {
    return 'Impossible de financer : $error';
  }

  @override
  String get allocRecentActivity => 'ACTIVITÉ RÉCENTE';

  @override
  String get allocNoActivity => 'Aucune activité';

  @override
  String get allocLedgerFunded => 'Financé';

  @override
  String get allocLedgerSpent => 'Dépensé';

  @override
  String get allocLedgerAdjustment => 'Ajustement';

  @override
  String get allocLedgerPeriodReset => 'Réinitialisation de période';

  @override
  String get allocLedgerCarried => 'Reporté';

  @override
  String get allocSpendingHistory => 'HISTORIQUE DES DÉPENSES';

  @override
  String get allocWithdrawTitle => 'Retrait de l\'épargne';

  @override
  String get allocWithdrawHelp =>
      'Transférer l\'argent de cette enveloppe vers Non affecté.';

  @override
  String get allocWithdrawAmount => 'Montant à retirer';

  @override
  String get allocWithdrawButton => 'Retirer';

  @override
  String get allocAllLinked =>
      'Toutes les catégories sont déjà liées à des enveloppes';

  @override
  String get allocLinkTitle => 'Lier une catégorie';

  @override
  String get allocNoForeignBalances =>
      'Aucun solde en devise étrangère à réévaluer';

  @override
  String get allocRevalueTitle => 'Réévaluer les soldes étrangers';

  @override
  String get allocBalanceInEnvelope => 'solde dans cette enveloppe';

  @override
  String get allocOriginalRate => 'Taux original';

  @override
  String get allocOriginalValue => 'Valeur originale';

  @override
  String get allocNewRate => 'Nouveau taux';

  @override
  String get allocFetchButton => 'Récupérer';

  @override
  String get allocNewValue => 'Nouvelle valeur';

  @override
  String get allocGain => 'Gain';

  @override
  String get allocLoss => 'Perte';

  @override
  String get allocTotalAdjustment => 'Ajustement total';

  @override
  String get allocApplyRevaluation => 'Appliquer la réévaluation';

  @override
  String get allocRevaluationApplied => 'Réévaluation appliquée';

  @override
  String get allocArchiveTitle => 'Archiver l\'enveloppe';

  @override
  String get allocArchiveMsg =>
      'Cette enveloppe sera masquée de toutes les listes. Les catégories liées et l\'historique seront préservés.\\n\\nVous pourrez la désarchiver dans les Paramètres.';

  @override
  String get allocArchived => 'Enveloppe archivée';

  @override
  String get allocDeleteTitle => 'Supprimer l\'enveloppe';

  @override
  String get allocArchiveInstead => 'Archiver à la place';

  @override
  String get allocDeletePermanently => 'Supprimer définitivement';

  @override
  String get allocDeleteNoLinkedTitle =>
      'Supprimer l\'enveloppe définitivement';

  @override
  String get allocDeleteNoLinkedMsg =>
      'Cette enveloppe n\'a pas de catégories liées. Tout l\'historique sera supprimé.\\n\\nÊtes-vous sûr ? Cette action est irréversible.';

  @override
  String get allocCreated => 'Enveloppe créée';

  @override
  String get allocUpdated => 'Enveloppe mise à jour';

  @override
  String get allocSavedPrefix => 'Épargné :';

  @override
  String allocPercentSaved(double pct) {
    return '$pct% épargné';
  }

  @override
  String get allocFlexibleTitle => 'Cumulatif';

  @override
  String get allocFlexibleDesc =>
      'Le montant non dépensé est reporté à la période suivante. Définissez une cible facultative ou laissez-le ouvert.';

  @override
  String get allocCycleHelp =>
      '• Périodique : se réinitialise chaque mois (ex. budget courses)\n• Permanent : s\'accumule au fil du temps (ex. fonds d\'urgence)';

  @override
  String get allocRolloverBalance => 'Report du solde';

  @override
  String get allocRolloverDesc =>
      'Reporter les fonds restants à la prochaine période';

  @override
  String get allocAutoReset => 'Réinitialisation automatique';

  @override
  String get allocAutoResetDesc =>
      'Réinitialiser automatiquement en début de période';

  @override
  String get allocMonthlyBudget => 'BUDGET MENSUEL';

  @override
  String get allocTargetOptional => 'OBJECTIF (OPTIONNEL)';

  @override
  String get allocMonthlyBudgetDesc =>
      'Combien voulez-vous dépenser dans cette enveloppe chaque mois ?';

  @override
  String get allocTargetDesc =>
      'Définissez un montant cible, ou laissez à zéro pour un objectif ouvert.';

  @override
  String get allocLinkedCategoriesSection => 'CATÉGORIES LIÉES';

  @override
  String get allocLinkedCategoriesDesc =>
      'Les dépenses de ces catégories seront débitées de cette enveloppe.';

  @override
  String get allocNoCategoriesLinked =>
      'Aucune catégorie liée. Appuyez sur + pour lier des catégories afin que les dépenses soient débitées de cette enveloppe.';

  @override
  String get allocAvailable => 'Disponible';

  @override
  String allocPercentOfTarget(int percent, String target) {
    return '$percent% de $target';
  }

  @override
  String allocAmountLeft(String amount) {
    return '$amount restant';
  }

  @override
  String get allocFund => 'Financer';

  @override
  String allocFundEnvelope(String name) {
    return 'Financer $name';
  }

  @override
  String get allocOverFundingTitle => 'Sur-financement';

  @override
  String allocOverFundingMsg(String deficit, String available) {
    return 'Vous affectez $deficit de plus que votre solde non alloué disponible ($available).\n\nVotre solde non alloué deviendra négatif. Continuer ?';
  }

  @override
  String get allocFundedNote => 'Financé depuis le non alloué';

  @override
  String allocFundedSuccess(String amount, String name) {
    return 'Financé $amount vers $name';
  }

  @override
  String get allocFundError =>
      'Impossible de financer l\'enveloppe. Veuillez réessayer.';

  @override
  String get allocEntryFunded => 'Financé';

  @override
  String get allocEntrySpent => 'Dépensé';

  @override
  String get allocEntryAdjustment => 'Ajustement';

  @override
  String get allocEntryPeriodReset => 'Réinitialisation de période';

  @override
  String get allocEntryCarryForward => 'Reporté';

  @override
  String get allocWithdrawDesc =>
      'Transférer l\'argent de cette enveloppe vers le non alloué.';

  @override
  String get allocWithdrawAmountLabel => 'Montant à retirer';

  @override
  String allocWithdrawSuccess(String amount) {
    return 'Retiré $amount vers le non alloué';
  }

  @override
  String get allocLinkCategoryTitle => 'Lier une catégorie';

  @override
  String get allocSearchCategories => 'Rechercher des catégories...';

  @override
  String get allocNoMatchingCategories => 'Aucune catégorie correspondante';

  @override
  String get allocAllCategoriesLinked =>
      'Toutes les catégories sont déjà liées à des enveloppes';

  @override
  String get allocRevalueForeignTitle => 'Réévaluer les soldes en devises';

  @override
  String get allocFetch => 'Récupérer';

  @override
  String get allocRevalApplied => 'Réévaluation appliquée';

  @override
  String get allocRevalError =>
      'Impossible d\'appliquer la réévaluation. Veuillez réessayer.';

  @override
  String allocFetchRateError(String currency) {
    return 'Impossible de récupérer le taux pour $currency';
  }

  @override
  String allocDeleteLinkedWarning(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catégories sont liées',
      one: '1 catégorie est liée',
    );
    return '$_temp0 à cette enveloppe ($names)';
  }

  @override
  String allocDeleteAndMore(int count) {
    return ' et $count autre(s)';
  }

  @override
  String get allocDeleteConsequences =>
      'La suppression va :\n  • Délier toutes les catégories de cette enveloppe\n  • Supprimer tout l\'historique du grand livre\n\nEnvisagez l\'archivage pour préserver l\'historique.';

  @override
  String get allocDeleteNoLinksTitle => 'Supprimer l\'enveloppe définitivement';

  @override
  String get allocDeleteNoLinksMsg =>
      'Cette enveloppe n\'a pas de catégories liées. Tout l\'historique du grand livre sera supprimé.\n\nÊtes-vous sûr ? Cette action est irréversible.';

  @override
  String get allocDeleteError => 'Impossible de supprimer. Veuillez réessayer.';

  @override
  String get allocEnvelopeCreated => 'Enveloppe créée';

  @override
  String get allocEnvelopeUpdated => 'Enveloppe mise à jour';

  @override
  String get allocGotIt => 'Compris';

  @override
  String allocBaseCurrencyOnly(String currency, int count) {
    return 'Enveloppes en $currency uniquement · $count dans d\'autres devises';
  }

  @override
  String get allocHideOtherCurrencies => 'Masquer les autres devises';

  @override
  String allocDailyBudget(String amount, int days) {
    return '$amount/jour pendant $days jours';
  }

  @override
  String allocOtherCurrencies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count autres devises',
      one: '+ 1 autre devise',
    );
    return '$_temp0';
  }

  @override
  String get allocGoalsLoans => 'Objectifs et prêts';

  @override
  String allocGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectifs',
      one: '1 objectif',
    );
    return '$_temp0';
  }

  @override
  String allocLoansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prêts',
      one: '1 prêt',
    );
    return '$_temp0';
  }

  @override
  String allocNEnvelopesNeedReset(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enveloppes nécessitent une réinitialisation',
      one: '1 enveloppe nécessite une réinitialisation',
    );
    return '$_temp0';
  }

  @override
  String get fundTitle => 'Financer les enveloppes';

  @override
  String get fundError => 'Impossible de charger les enveloppes';

  @override
  String get fundCouldntLoad => 'Impossible de charger les enveloppes';

  @override
  String get fundNoAllocations =>
      'Aucune enveloppe à financer.\nCréez d\'abord des enveloppes.';

  @override
  String get fundHowTitle => 'Comment fonctionne le financement ?';

  @override
  String get fundStep1 =>
      'Vérifiez votre solde non alloué — c\'est l\'argent que vous n\'avez pas encore affecté à une enveloppe.';

  @override
  String get fundStep2 =>
      'Entrez le montant pour chaque enveloppe, ou utilisez « Remplissage rapide » pour remplir automatiquement les enveloppes périodiques jusqu\'à leur objectif.';

  @override
  String get fundStep3 =>
      'Appuyez sur « Financer tout » pour distribuer l\'argent dans vos enveloppes.';

  @override
  String get fundAvailableToDistribute => 'Disponible à distribuer';

  @override
  String get fundExceedsWarning =>
      'Le total dépasse les fonds non alloués disponibles';

  @override
  String get fundQuickFill => 'Remplissage rapide';

  @override
  String fundQuickFillDesc(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Remplir automatiquement $count enveloppes périodiques jusqu\'à leur objectif',
      one:
          'Remplir automatiquement 1 enveloppe périodique jusqu\'à son objectif',
    );
    return '$_temp0';
  }

  @override
  String get fundAllAtTarget =>
      'Toutes les enveloppes périodiques sont à leur objectif';

  @override
  String get fundFunded => 'Financé';

  @override
  String fundBalance(String amount) {
    return 'Solde : $amount';
  }

  @override
  String fundFill(String amount) {
    return 'Remplir $amount';
  }

  @override
  String get fundEnterAmounts => 'Entrez des montants à financer';

  @override
  String fundAllWithTotal(String total) {
    return 'Financer tout  ($total)';
  }

  @override
  String get fundOverfundingTitle => 'Surfinancement';

  @override
  String fundOverfundingMsg(String details) {
    return 'Vous affectez $details. Votre solde non affecté deviendra négatif.\\n\\nContinuer ?';
  }

  @override
  String get fundAnyway => 'Financer quand même';

  @override
  String get fundNote => 'Financé depuis Non affecté';

  @override
  String get fundSuccess => 'Enveloppes financées avec succès';

  @override
  String fundErrorMsg(String error) {
    return 'Erreur lors du financement : $error';
  }

  @override
  String get acctTitle => 'Comptes';

  @override
  String get acctNoYet => 'Aucun compte pour le moment';

  @override
  String get acctTapPlus => 'Appuyez sur + pour en ajouter';

  @override
  String get acctTotalBalance => 'Solde total';

  @override
  String get acctAddTooltip => 'Ajouter un compte';

  @override
  String get acctNewTitle => 'Nouveau compte';

  @override
  String get acctTypeCash => 'Espèces';

  @override
  String get acctTypeBank => 'Banque';

  @override
  String get acctTypeCredit => 'Carte de crédit';

  @override
  String get acctTypeDigital => 'Portefeuille numérique';

  @override
  String get acctAdjustBalance => 'Ajuster le solde';

  @override
  String get acctHideArchived => 'Masquer les archivés';

  @override
  String get acctShowArchived => 'Afficher les archivés';

  @override
  String get acctSortByName => 'Trier par nom';

  @override
  String get acctSortByBalance => 'Trier par solde';

  @override
  String get acctSortByType => 'Trier par type';

  @override
  String acctTravelWallet(String currency) {
    return 'Portefeuille de voyage · $currency';
  }

  @override
  String get acctArchived => 'ARCHIVÉS';

  @override
  String get acctNoArchived => 'Aucun compte archivé';

  @override
  String get acctUnarchiveTitle => 'Désarchiver le compte';

  @override
  String acctUnarchiveMsg(String name) {
    return 'Restaurer « $name » dans vos comptes actifs ?';
  }

  @override
  String get acctUnarchive => 'Désarchiver';

  @override
  String acctUnarchived(String name) {
    return '$name désarchivé';
  }

  @override
  String get acctCurrentBalance => 'Solde actuel';

  @override
  String get acctBackFromTrip => 'De retour de voyage ?';

  @override
  String acctConvertBackDesc(String currency) {
    return 'Convertir votre solde restant en $currency et fermer ce portefeuille de voyage.';
  }

  @override
  String get acctConvertBackClose => 'Convertir et fermer';

  @override
  String get acctSettings => 'Paramètres du compte';

  @override
  String get acctNameSection => 'NOM';

  @override
  String get acctAccountName => 'Nom du compte';

  @override
  String get acctTypeSection => 'TYPE';

  @override
  String get acctCurrencySection => 'DEVISE';

  @override
  String get acctSelectCurrency => 'Sélectionner la devise';

  @override
  String get acctDecimalSection => 'DÉCIMALES';

  @override
  String acctDecimalAuto(int count) {
    return 'Auto ($count)';
  }

  @override
  String get acctOpeningBalance => 'SOLDE D\'OUVERTURE';

  @override
  String get acctCreateAccount => 'Créer un compte';

  @override
  String get acctCreated => 'Compte créé';

  @override
  String get acctUpdated => 'Compte mis à jour';

  @override
  String get tmplCreated => 'Modèle créé';

  @override
  String get acctRecentTransactions => 'TRANSACTIONS RÉCENTES';

  @override
  String get acctNoTransactions => 'Aucune transaction pour le moment';

  @override
  String get acctAdjustDesc =>
      'Entrez le solde réel de ce compte. Une transaction d\'ajustement sera créée pour la différence.';

  @override
  String acctCurrentBalanceLabel(String amount) {
    return 'Solde actuel : $amount';
  }

  @override
  String get acctActualBalance => 'Solde réel';

  @override
  String get acctEnterRealBalance => 'Entrez le solde réel';

  @override
  String get acctApplyAdjustment => 'Appliquer l\'ajustement';

  @override
  String get acctBalanceAdjustment => 'Ajustement du solde';

  @override
  String acctBalanceAdjustedBy(String amount) {
    return 'Solde ajusté de $amount';
  }

  @override
  String get acctConvertBack => 'Reconvertir';

  @override
  String acctConvertBackMsg(String amount) {
    return 'Reconvertir $amount vers votre compte';
  }

  @override
  String get acctTransferTo => 'Transférer vers';

  @override
  String get acctAmountReceived => 'Montant reçu';

  @override
  String get acctConvertArchive => 'Convertir et archiver';

  @override
  String get acctNoTransferTarget => 'Aucun compte cible pour le transfert';

  @override
  String acctConvertedBack(String amount) {
    return 'Reconverti $amount et archivé';
  }

  @override
  String get acctSomethingWrong =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get acctArchiveTitle => 'Archiver le compte';

  @override
  String get acctArchiveMsg =>
      'Ce compte sera masqué de toutes les listes et menus déroulants. Vos transactions seront préservées.\n\nVous pouvez le désarchiver plus tard depuis les Paramètres.';

  @override
  String get acctCannotDeleteTitle => 'Impossible de supprimer le compte';

  @override
  String acctCannotDeleteMsg(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count références de transactions',
      one: '1 référence de transaction',
    );
    return 'Ce compte a $_temp0. Vous ne pouvez pas le supprimer tant qu\'il a des transactions.\n\nVoulez-vous l\'archiver à la place ? Les comptes archivés sont masqués des listes mais préservent tout l\'historique.';
  }

  @override
  String get acctDeleteTitle => 'Supprimer le compte définitivement';

  @override
  String get acctDeleteMsg =>
      'Ce compte n\'a aucune transaction. Êtes-vous sûr de vouloir le supprimer définitivement ? Cette action est irréversible.';

  @override
  String get acctArchiveInstead => 'Archiver à la place';

  @override
  String acctHasTxnsMsg(int count) {
    return 'Ce compte comporte $count transaction(s). Archivez-le pour tout conserver mais le masquer, ou supprimez-le avec ces transactions.';
  }

  @override
  String get acctDeleteWithTxns => 'Supprimer avec les transactions';

  @override
  String acctDeleteSharedMsg(int count) {
    return '$count d\'entre elles sont partagées avec d\'autres comptes (virements ou ventilations). La suppression les retirera aussi et modifiera le solde de ces comptes. Continuer ?';
  }

  @override
  String acctDeleteCountConfirm(int count) {
    return 'Supprimer définitivement ce compte et $count transaction(s) ? Cette action est irréversible.';
  }

  @override
  String get catTitle => 'Catégories';

  @override
  String get catAddTooltip => 'Ajouter une catégorie';

  @override
  String catTotal(int count) {
    return '$count au total';
  }

  @override
  String catExpenseCount(int count) {
    return '$count dépense(s)';
  }

  @override
  String catIncomeCount(int count) {
    return '$count revenu(s)';
  }

  @override
  String get catSearchHint => 'Rechercher des catégories...';

  @override
  String get catAll => 'Tout';

  @override
  String get catNoYet => 'Aucune catégorie pour le moment';

  @override
  String get catTapPlus => 'Appuyez sur + pour en créer une';

  @override
  String get catNoMatch => 'Aucune catégorie correspondante';

  @override
  String get catCouldntLoad => 'Impossible de charger les catégories';

  @override
  String catSubcategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sous-catégories',
      one: '1 sous-catégorie',
    );
    return '$_temp0';
  }

  @override
  String get catSectionExpense => 'DÉPENSE';

  @override
  String get catSectionIncome => 'REVENU';

  @override
  String get catEdit => 'Modifier';

  @override
  String get catArchive => 'Archiver';

  @override
  String get catUnarchive => 'Désarchiver';

  @override
  String get catRestored => 'Catégorie restaurée';

  @override
  String get catArchived => 'Catégorie archivée';

  @override
  String get catDeleteTitle => 'Supprimer la catégorie';

  @override
  String get catDeleteNoTx =>
      'Cette catégorie n\'a aucune transaction. Supprimer définitivement ?';

  @override
  String get catDeleted => 'Catégorie supprimée';

  @override
  String get catNewTitle => 'Nouvelle catégorie';

  @override
  String get catEditTitle => 'Modifier la catégorie';

  @override
  String get catName => 'Nom';

  @override
  String get catParent => 'Catégorie parente';

  @override
  String get catNone => 'Aucun';

  @override
  String get catCreate => 'Créer';

  @override
  String get catEnterName => 'Entrez un nom de catégorie';

  @override
  String get catCreated => 'Catégorie créée';

  @override
  String get catUpdated => 'Catégorie mise à jour';

  @override
  String get commonArchive => 'Archiver';

  @override
  String get recurringAddTooltip => 'Ajouter une transaction récurrente';

  @override
  String get freqDaily => 'Quotidien';

  @override
  String get freqWeekly => 'Hebdomadaire';

  @override
  String get freqMonthly => 'Mensuel';

  @override
  String get freqYearly => 'Annuel';

  @override
  String freqEveryNDays(int n) {
    return 'Tous les $n jours';
  }

  @override
  String freqEveryNWeeks(int n) {
    return 'Toutes les $n semaines';
  }

  @override
  String freqEveryNMonths(int n) {
    return 'Tous les $n mois';
  }

  @override
  String freqEveryNYears(int n) {
    return 'Tous les $n ans';
  }

  @override
  String get billCalTitle => 'Calendrier des factures';

  @override
  String billCalNDue(int count) {
    return '$count facture(s) due(s)';
  }

  @override
  String get billCalUpcoming => 'À VENIR';

  @override
  String get billCalNoUpcoming => 'Aucune facture à venir';

  @override
  String get upcomingTitle => 'Factures à venir';

  @override
  String get upcomingNoTitle => 'Aucune facture à venir';

  @override
  String get upcomingNoSubtitle =>
      'Créez des transactions récurrentes pour les voir ici.';

  @override
  String upcomingOverdue(int days) {
    return 'En retard de $days jour(s)';
  }

  @override
  String get upcomingDueToday => 'Due aujourd\'hui';

  @override
  String get upcomingDueTomorrow => 'Due demain';

  @override
  String upcomingDueInDays(int days) {
    return 'Due dans $days jours';
  }

  @override
  String get subTitle => 'Abonnements';

  @override
  String get subAddTooltip => 'Ajouter un abonnement';

  @override
  String get subTotal => 'Total';

  @override
  String get subActive => 'Actif';

  @override
  String get subCancelled => 'Annulé';

  @override
  String get subNoTitle => 'Aucun abonnement';

  @override
  String get subNoSubtitle =>
      'Ajoutez une transaction récurrente et marquez-la comme abonnement';

  @override
  String get subEndingSoon => 'Se termine bientôt';

  @override
  String get subPause => 'Mettre en pause';

  @override
  String get subResume => 'Reprendre';

  @override
  String get subUntitled => 'Sans titre';

  @override
  String get subDetailError => 'Impossible de charger l\'abonnement';

  @override
  String get subDetailNotFound => 'Abonnement introuvable';

  @override
  String subDetailAnnualCost(String amount) {
    return 'Coût annuel : $amount';
  }

  @override
  String get subDetailStatus => 'Statut';

  @override
  String get subDetailActiveSince => 'Actif depuis';

  @override
  String get subDetailNextBilling => 'Prochaine facturation';

  @override
  String get subDetailEndsOn => 'Se termine le';

  @override
  String get subDetailTotalPaid => 'Total payé (est.)';

  @override
  String get subDetailPriceHistory => 'HISTORIQUE DES PRIX';

  @override
  String get subDetailPresent => 'présent';

  @override
  String get subDetailChangeCancel => 'Modifier la date d\'annulation';

  @override
  String get subDetailSetCancel => 'Définir la date d\'annulation';

  @override
  String get subDetailPastTx => 'TRANSACTIONS PASSÉES';

  @override
  String get subDetailUpcoming => 'À VENIR';

  @override
  String get subDetailScheduled => 'prévu';

  @override
  String get subDetailCancelTitle => 'Annuler l\'abonnement';

  @override
  String get tmplTitle => 'Modèles';

  @override
  String get tmplSortTooltip => 'Trier';

  @override
  String get tmplGroupTooltip => 'Grouper';

  @override
  String get tmplSortMostUsed => 'Les plus utilisés';

  @override
  String get tmplSortAz => 'A–Z';

  @override
  String get tmplSortNewest => 'Plus récent d\'abord';

  @override
  String get tmplSortHighest => 'Montant le plus élevé';

  @override
  String get tmplGroupNone => 'Pas de groupement';

  @override
  String get tmplGroupType => 'Par type';

  @override
  String get tmplGroupCategory => 'Par catégorie';

  @override
  String get tmplSearchHint => 'Rechercher des modèles...';

  @override
  String get tmplNoTitle => 'Aucun modèle trouvé';

  @override
  String get tmplNoSubtitle =>
      'Enregistrez les transactions fréquentes pour les réutiliser rapidement';

  @override
  String get tmplAddTooltip => 'Ajouter un modèle';

  @override
  String get tmplUse => 'Utiliser le modèle';

  @override
  String get tmplDeleteTitle => 'Supprimer le modèle ?';

  @override
  String get tmplDeleteMsg => 'Ce modèle sera supprimé définitivement.';

  @override
  String get tmplNewTitle => 'Nouveau modèle';

  @override
  String get tmplNewDesc =>
      'Enregistrez une transaction fréquente pour la réutiliser rapidement.';

  @override
  String get tmplTitleRequired => 'Le titre est requis';

  @override
  String get tmplCategoryOptional => 'Catégorie (optionnel)';

  @override
  String get tmplSaveButton => 'Enregistrer le modèle';

  @override
  String get objTitle => 'Objectifs et prêts';

  @override
  String get objFailedToLoad => 'Échec du chargement des objectifs';

  @override
  String get objNoTitle => 'Aucun objectif ou prêt';

  @override
  String get objNoSubtitle =>
      'Créez un objectif d\'épargne ou suivez l\'argent prêté ou emprunté.';

  @override
  String get objGoalsSection => 'OBJECTIFS';

  @override
  String get objLoansSection => 'PRÊTS';

  @override
  String objLentTo(String contact) {
    return 'Prêté à $contact';
  }

  @override
  String objBorrowedFrom(String contact) {
    return 'Emprunté à $contact';
  }

  @override
  String objDue(String date) {
    return 'Dû le $date';
  }

  @override
  String get objNewTitle => 'Nouvel objectif';

  @override
  String get objNameRequired => 'Le nom est requis';

  @override
  String get objCreated => 'Objectif créé';

  @override
  String get objNotePaymentReceived => 'Paiement reçu';

  @override
  String get objNotePayment => 'Paiement';

  @override
  String get objNoteGoalSavings => 'Épargne objectif';

  @override
  String get objUpdated => 'Objectif mis à jour';

  @override
  String get objNoAccounts => 'Aucun compte disponible';

  @override
  String get objRecordPayment => 'Enregistrer un paiement';

  @override
  String get objAddFunds => 'Ajouter des fonds';

  @override
  String get objRecordReceived => 'Enregistrer un paiement reçu';

  @override
  String get objRecordSent => 'Enregistrer un paiement envoyé';

  @override
  String get objSaveFromAccount => 'Épargner depuis un compte';

  @override
  String get objGoalChip => 'Objectif';

  @override
  String get objLoanChip => 'Prêt';

  @override
  String get objGoalName => 'Nom de l\'objectif';

  @override
  String get objGoalNameHint => 'ex. Fonds d\'urgence';

  @override
  String get objLoanName => 'Nom du prêt';

  @override
  String get objLoanNameHint => 'ex. Prêt auto';

  @override
  String get objPerson => 'Personne';

  @override
  String get objPersonHint => 'ex. Ali, Banque, etc.';

  @override
  String get objDirection => 'Direction';

  @override
  String get objILent => 'J\'ai prêté';

  @override
  String get objIBorrowed => 'J\'ai emprunté';

  @override
  String get objSetDeadline => 'Définir une échéance (optionnel)';

  @override
  String get objColorSection => 'COULEUR';

  @override
  String get objDeleteTitle => 'Supprimer l\'objectif';

  @override
  String get objCannotUndo => 'Cette action est irréversible.';

  @override
  String get objSavedSoFar => 'Épargné à ce jour';

  @override
  String get objRecordedSoFar => 'Enregistré à ce jour';

  @override
  String get objEmptyHintGoal =>
      'Ajoutez des fonds depuis l\'un de vos comptes pour faire progresser cet objectif.';

  @override
  String get objEmptyHintLoanLent =>
      'Enregistrez les paiements reçus pour suivre le remboursement.';

  @override
  String get objEmptyHintLoanBorrowed =>
      'Enregistrez les paiements effectués pour suivre ce que vous devez.';

  @override
  String get objWhatIsGoal =>
      'Épargnez vers un objectif. Chaque dépôt retire de l\'argent du compte choisi et est enregistré comme transaction.';

  @override
  String get objWhatIsLoan =>
      'Suivez l\'argent prêté ou emprunté. Chaque paiement enregistré ajoute ou retire de l\'argent du compte choisi.';

  @override
  String get objTargetOptional =>
      'Facultatif — laissez vide pour un objectif ouvert';

  @override
  String get objIcon => 'Icône';

  @override
  String get objChooseIcon => 'Choisir une icône (facultatif)';

  @override
  String get objRemoveIcon => 'Supprimer l\'icône';

  @override
  String get objIntro =>
      'Les objectifs suivent l\'épargne vers une cible. Les prêts suivent l\'argent prêté ou emprunté.';

  @override
  String get objCreateFirst => 'Créez votre premier objectif';

  @override
  String objDeleteLinkedPayments(int count) {
    return '$count paiement(s) lié(s). L\'argent a déjà été déplacé entre vos comptes — les garder ou tout supprimer ?';
  }

  @override
  String get objDeleteKeep => 'Supprimer, garder les paiements';

  @override
  String get objDeleteAll => 'Tout supprimer';

  @override
  String get travelTitle => 'Change de voyage';

  @override
  String get travelInfo =>
      'Échangez de l\'argent pour votre voyage. Un portefeuille temporaire sera créé automatiquement.';

  @override
  String get travelFrom => 'DE';

  @override
  String get travelSelectAccount => 'Sélectionner un compte';

  @override
  String get travelAmountToExchange => 'MONTANT À ÉCHANGER';

  @override
  String get travelCurrencySection => 'DEVISE DE VOYAGE';

  @override
  String get travelCurrencyReceive => 'Devise que vous recevez';

  @override
  String get travelAmountReceived => 'MONTANT REÇU';

  @override
  String get travelExchangeButton =>
      'Changer et créer un portefeuille de voyage';

  @override
  String get travelExistingWallet => 'Portefeuille de voyage existant';

  @override
  String get travelCreateNew => 'Créer nouveau';

  @override
  String get travelReactivate => 'Réactiver';

  @override
  String get periodNewTitle => 'Nouvelle période';

  @override
  String get periodError => 'Impossible de charger les enveloppes';

  @override
  String get periodResolveLeftovers => 'Résoudre les soldes restants';

  @override
  String periodNItems(int count) {
    return '$count éléments';
  }

  @override
  String get periodNoLeftovers => 'Aucun solde restant à résoudre';

  @override
  String get periodAllZero =>
      'Toutes les enveloppes périodiques ont des soldes nuls ou négatifs.';

  @override
  String get periodCompleteButton => 'Terminer la transition de période';

  @override
  String get periodRollover => 'Enveloppe avec report';

  @override
  String get periodPeriodic => 'Enveloppe périodique';

  @override
  String get periodReturnUnallocated => 'Retourner au Non affecté';

  @override
  String get periodReturnDesc => 'Le solde retourne au pool';

  @override
  String get periodCarryForward => 'Reporter';

  @override
  String get periodCarryDesc => 'Garder le solde pour la prochaine période';

  @override
  String get periodMoveTo => 'Transférer à...';

  @override
  String get periodMoveDesc => 'Transférer à une autre enveloppe';

  @override
  String get periodSelectAllocation => 'Sélectionner une enveloppe';

  @override
  String get leftoverTitle => 'Résoudre les restes';

  @override
  String get leftoverNoAllocation => 'Aucune enveloppe spécifiée.';

  @override
  String get leftoverNotFound => 'Enveloppe introuvable.';

  @override
  String get leftoverCurrentBalance => 'Solde actuel';

  @override
  String get leftoverNoBalance => 'Aucun solde';

  @override
  String get leftoverNoPositive => 'Aucun solde positif à résoudre.';

  @override
  String get leftoverCurrencyToResolve => 'Devise à résoudre';

  @override
  String get leftoverAllCurrencies => 'Toutes les devises';

  @override
  String get leftoverWhatToDo => 'Que faire avec le reste';

  @override
  String get leftoverReturnSubtitle => 'Le solde restant retourne au pool';

  @override
  String get leftoverKeepSubtitle =>
      'Garder le solde pour la prochaine période';

  @override
  String get leftoverMoveTitle => 'Transférer à une autre enveloppe';

  @override
  String get leftoverMoveSubtitle =>
      'Transférer le reste à une enveloppe différente';

  @override
  String get settingsMoreTitle => 'Plus';

  @override
  String get settingsToolsSection => 'OUTILS';

  @override
  String get settingsAutomationSection => 'AUTOMATISATION';

  @override
  String get settingsAccountsSub => 'Gérez vos comptes et soldes';

  @override
  String get settingsCategoriesSub => 'Gérez les groupes et catégories';

  @override
  String get settingsBillSplitterSub =>
      'Partager les additions et scanner les reçus';

  @override
  String get settingsBillCalendarSub => 'Voir les factures récurrentes à venir';

  @override
  String get settingsUpcomingBillsSub => 'Factures bientôt dues avec urgence';

  @override
  String get settingsTravelSub => 'Échanger des devises pour un voyage';

  @override
  String get settingsExchangeRatesSub =>
      'Voir et actualiser les taux de change';

  @override
  String get settingsWebCompanionSub =>
      'Gérez votre budget depuis un navigateur';

  @override
  String get settingsRecurringSub => 'Gérer les transactions récurrentes';

  @override
  String get settingsTemplatesSub => 'Enregistrer les transactions fréquentes';

  @override
  String get settingsSubscriptionsSub => 'Suivre les abonnements récurrents';

  @override
  String get settingsGoalsSub => 'Objectifs d\'épargne et suivi des dettes';

  @override
  String get settingsPeriodSub => 'Terminer la période et résoudre les restes';

  @override
  String get settingsCustomization => 'Paramètres et personnalisation';

  @override
  String get settingsCustomizationSub => 'Thème, police, données, préférences';

  @override
  String get settingsAbout => 'À propos de BudgetSeal';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeBlack => 'Noir';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeTitle => 'Thème';

  @override
  String get autofillTitle => 'Paramètres de remplissage auto';

  @override
  String get autofillDesc =>
      'Lorsque vous choisissez une catégorie ces champs sont pré-remplis depuis votre dernière transaction.';

  @override
  String get autofillAccount => 'Compte';

  @override
  String get autofillAccountSub =>
      'Utiliser le même compte que la dernière fois';

  @override
  String get autofillTitleToggle => 'Titre';

  @override
  String get autofillTitleSub => 'Copier le titre de la dernière fois';

  @override
  String get autofillAmountToggle => 'Montant';

  @override
  String get autofillAmountSub => 'Copier le montant de la dernière fois';

  @override
  String get autofillCategoryToggle => 'Catégorie';

  @override
  String get autofillCategorySub =>
      'Se souvenir de la dernière catégorie par compte';

  @override
  String get autofillOverride => 'Remplacer les valeurs existantes';

  @override
  String get autofillOverrideSub =>
      'Remplacer les champs même s\'ils sont déjà remplis';

  @override
  String get resetTitle => 'Tout réinitialiser';

  @override
  String get resetContent =>
      'Cela supprimera définitivement TOUTES vos données :\\n\\n• Tous les comptes et soldes\\n• Toutes les transactions\\n• Toutes les enveloppes et catégories\\n• Tous les paramètres\\n\\nCette action est irréversible. Êtes-vous absolument sûr ?';

  @override
  String get resetButton => 'Tout supprimer';

  @override
  String get txColorsTitle => 'Couleurs des transactions';

  @override
  String get txColorsDesc =>
      'Choisissez une couleur pour chaque type de transaction. Ces couleurs sont utilisées dans l\'application pour distinguer visuellement les revenus, dépenses et virements.';

  @override
  String get txColorsReset => 'Réinitialiser les valeurs par défaut';

  @override
  String get householdNameTitle => 'Nom du foyer';

  @override
  String get tileBillCalendar => 'Calendrier des factures';

  @override
  String get tileUpcomingBills => 'Factures à venir';

  @override
  String get tileTravelExchange => 'Change de voyage';

  @override
  String get tileExchangeRates => 'Taux de change';

  @override
  String get tileWebCompanion => 'Compagnon Web';

  @override
  String get tileRecurring => 'Récurrents';

  @override
  String get tileTemplates => 'Modèles';

  @override
  String get tileSubscriptions => 'Abonnements';

  @override
  String get tileGoalsLoans => 'Objectifs et prêts';

  @override
  String get tilePeriodTransition => 'Transition de période';

  @override
  String get syncTitle => 'Synchronisation cloud';

  @override
  String get syncNotConnected => 'Non connecté';

  @override
  String get syncSyncing => 'Synchronisation...';

  @override
  String get syncLastFailed => 'Dernière sync échouée';

  @override
  String get syncNotYet => 'Pas encore synchronisé';

  @override
  String get syncConnectPrompt =>
      'Connectez un fournisseur cloud pour synchroniser';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncShareHousehold => 'Partager le foyer';

  @override
  String get syncDisconnect => 'Déconnecter';

  @override
  String get syncConnectSection => 'CONNECTER UN FOURNISSEUR';

  @override
  String get syncReceiptComingSoon =>
      'Synchronisation des reçus bientôt disponible';

  @override
  String get syncProviderInfo =>
      'OneDrive et Dropbox ouvrent le sélecteur de fichiers système qui accède à ces services quand leurs apps sont installées. Google Drive nécessite un projet Google Cloud avec OAuth.';

  @override
  String get syncConnectionFailed => 'Échec de la connexion';

  @override
  String get syncFailedToConnect => 'Échec de la connexion';

  @override
  String get syncDisconnectMsg =>
      'Vos données resteront sur votre appareil, mais la synchronisation automatique s\'arrêtera. Vous pourrez vous reconnecter à tout moment.';

  @override
  String get syncShareDesc =>
      'Partagez vos données BudgetSeal avec une autre personne. Elle pourra synchroniser avec le même fichier Google Drive.';

  @override
  String get syncTheirEmail => 'Leur adresse e-mail';

  @override
  String get syncEmailHint => 'partenaire@gmail.com';

  @override
  String get syncSharing => 'Partage...';

  @override
  String get syncGenerateInvite => 'Générer un code d\'invitation';

  @override
  String get syncInviteCode => 'Code d\'invitation';

  @override
  String get syncShareCode => 'Partager le code';

  @override
  String get syncValidEmailError => 'Veuillez saisir une adresse e-mail valide';

  @override
  String get syncEncryptionTitle => 'Chiffrement de la synchronisation';

  @override
  String get syncEncrypted =>
      'Votre fichier de synchronisation est chiffré en AES-256';

  @override
  String get syncNotEncrypted =>
      'Le fichier de synchronisation n\'est pas chiffré';

  @override
  String get syncGdriveWarning =>
      'Toute personne ayant accès à votre Google Drive peut lire vos données financières';

  @override
  String get syncSetPasswordTitle =>
      'Définir le mot de passe de synchronisation';

  @override
  String get syncPasswordDesc =>
      'Ce mot de passe chiffre votre fichier de synchronisation sur Google Drive. Vous aurez besoin du même mot de passe sur tout autre appareil.';

  @override
  String get syncPasswordLabel => 'Mot de passe';

  @override
  String get syncPasswordHint => 'Saisissez un mot de passe fort';

  @override
  String get syncConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get syncSetPasswordButton => 'Définir le mot de passe';

  @override
  String get syncPasswordsDontMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get syncEncryptionEnabled =>
      'Chiffrement activé. La prochaine synchronisation sera chiffrée.';

  @override
  String get syncRemoveEncryptionTitle => 'Supprimer le chiffrement ?';

  @override
  String get syncRemoveEncryptionMsg =>
      'Les futurs fichiers de synchronisation ne seront pas chiffrés. Les autres appareils devront aussi supprimer leur mot de passe.';

  @override
  String get syncEncryptionRemoved => 'Chiffrement supprimé';

  @override
  String get providerGoogleDrive => 'Google Drive';

  @override
  String get providerGoogleDriveSub =>
      'Connectez-vous avec votre compte Google';

  @override
  String get providerOnedrive => 'OneDrive';

  @override
  String get providerOnedriveSub =>
      'Nécessite l\'application OneDrive installée';

  @override
  String get providerDropbox => 'Dropbox';

  @override
  String get providerDropboxSub => 'Nécessite l\'application Dropbox installée';

  @override
  String get providerLocalFile => 'Fichier local';

  @override
  String get providerLocalFileSub => 'Choisissez un fichier sur votre appareil';

  @override
  String get syncNoFileFound => 'Aucun fichier de synchronisation trouvé';

  @override
  String get backupTitle => 'Sauvegarde et restauration';

  @override
  String get backupAutoTitle => 'Sauvegardes automatiques';

  @override
  String get backupEnable => 'Activer les sauvegardes automatiques';

  @override
  String get backupDisabled => 'Désactivé';

  @override
  String get backupFrequency => 'Fréquence';

  @override
  String get backupEvery6h => 'Toutes les 6 heures';

  @override
  String get backupEvery12h => 'Toutes les 12 heures';

  @override
  String get backupDaily => 'Quotidien';

  @override
  String get backupEvery3d => 'Tous les 3 jours';

  @override
  String get backupWeekly => 'Hebdomadaire';

  @override
  String get backupKeepLast => 'Garder les dernières';

  @override
  String backupNBackups(int n) {
    return '$n sauvegardes';
  }

  @override
  String get backupManualTitle => 'Sauvegarde manuelle';

  @override
  String get backupExportDesc =>
      'Exportez votre base de données pour la partager ou la stocker.';

  @override
  String get backupExporting => 'Exportation...';

  @override
  String get backupExportShare => 'Exporter et partager';

  @override
  String get backupRestoreTitle => 'Restauration';

  @override
  String get backupRestoreDesc => 'Choisissez un fichier .db pour restaurer.';

  @override
  String get backupRestoreFromFile => 'Restaurer depuis un fichier';

  @override
  String get backupLocalSection => 'SAUVEGARDES LOCALES';

  @override
  String get backupRestoreDialogTitle => 'Restaurer la sauvegarde';

  @override
  String get backupRestoreWarning =>
      'Cela remplacera TOUTES les données actuelles par la sauvegarde. Irréversible. Continuer ?';

  @override
  String get backupRestored =>
      'Sauvegarde restaurée. Veuillez redémarrer l\'application.';

  @override
  String get backupRestoreFailed =>
      'La restauration a échoué. Le fichier de sauvegarde est peut-être corrompu.';

  @override
  String get backupDbNotFound => 'Fichier de base de données introuvable';

  @override
  String get backupTooLarge => 'Fichier trop volumineux (max 100 Mo)';

  @override
  String get backupInvalid =>
      'Fichier de sauvegarde invalide — base de données non valide';

  @override
  String get ieTitle => 'Importation et exportation';

  @override
  String get ieImportCsv => 'Importer CSV';

  @override
  String get ieImportCsvSub =>
      'Importer des transactions depuis un fichier CSV bancaire';

  @override
  String get ieExportCsv => 'Exporter CSV';

  @override
  String get ieExportCsvSub => 'Exporter les transactions en tableur';

  @override
  String get ieExportReport => 'Exporter le rapport';

  @override
  String get ieExportReportSub => 'Générer un rapport mensuel imprimable';

  @override
  String get exportDataTitle => 'Exporter les données';

  @override
  String get exportTransTitle => 'Exporter les transactions';

  @override
  String get exportTransDesc =>
      'Exportez toutes vos transactions en fichier CSV. Vous pouvez l\'ouvrir dans Excel, Google Sheets ou toute application de tableur.';

  @override
  String get exportReportTitle => 'Exporter le rapport';

  @override
  String get exportMonthlyTitle => 'Rapport mensuel';

  @override
  String get exportMonthlyDesc =>
      'Générez un rapport HTML imprimable. Ouvrez-le dans un navigateur et utilisez Imprimer > Enregistrer en PDF.';

  @override
  String get exportGenerating => 'Génération...';

  @override
  String get exportGenerateShare => 'Générer et partager';

  @override
  String get exportSpendingByCat => 'Dépenses par catégorie';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifDailyTitle => 'Rappel quotidien';

  @override
  String get notifDailyEnable => 'Activer le rappel quotidien';

  @override
  String get notifDailyDisabled =>
      'Me rappeler d\'enregistrer les transactions';

  @override
  String get notifTime => 'Heure';

  @override
  String get notifCustomMessage => 'Message personnalisé (optionnel)';

  @override
  String get notifEnvelopeTitle => 'Alertes d\'enveloppes';

  @override
  String get notifEnvelopeDesc =>
      'Vous recevrez une notification quand les enveloppes sont dépassées. Vérification au démarrage toutes les 6 heures max.';

  @override
  String get notifBillsTitle => 'Factures à venir';

  @override
  String get notifBillsDesc =>
      'Vous recevrez une notification quand des transactions récurrentes sont dues sous 2 jours. Vérification au démarrage.';

  @override
  String get fxTitle => 'Taux de change';

  @override
  String get fxRefreshTooltip => 'Actualiser les taux';

  @override
  String get fxCouldNotFetch => 'Impossible de récupérer les taux';

  @override
  String get fxNoRates => 'Aucun taux disponible';

  @override
  String get fxCheckInternet =>
      'Vérifiez votre connexion internet et réessayez.';

  @override
  String get fxCacheInfo =>
      'Les taux sont récupérés en ligne et mis en cache 1 heure. Ils sont remplis automatiquement lors de la création de transactions.';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutShare => 'Partager';

  @override
  String get aboutContact => 'Contact';

  @override
  String get aboutShareText =>
      'Découvrez BudgetSeal — la budgétisation par enveloppes simplifiée !';

  @override
  String get aboutPrivacy =>
      'Aucun suivi. Vos données restent sur votre appareil.';

  @override
  String get aboutCredit => 'Créé par Samer';

  @override
  String get aboutPrivacyTerms => 'Confidentialité et conditions';

  @override
  String get aboutLicenses => 'Licences';

  @override
  String aboutLegalese(int year) {
    return '© $year Samer Cheaib. Tous droits réservés.';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAppearanceSection => 'APPARENCE';

  @override
  String get settingsDataSection => 'DONNÉES';

  @override
  String get settingsPreferencesSection => 'PRÉFÉRENCES';

  @override
  String get settingsSecuritySection => 'SÉCURITÉ';

  @override
  String get tileRecurringBills => 'Récurrences et factures';

  @override
  String get tileBillSplitter => 'Partage de facture';

  @override
  String get tileHelpGuide => 'Guide d\'aide';

  @override
  String get settingsHelpSub => 'Comment utiliser BudgetSeal';

  @override
  String get tileTheme => 'Thème';

  @override
  String get tileAccentColor => 'Couleur d\'accentuation';

  @override
  String get tileColors => 'Couleurs';

  @override
  String get tileColorsSub => 'Revenus, dépenses et transferts';

  @override
  String get tileEntryMode => 'Mode de saisie';

  @override
  String get tileAutofill => 'Remplissage auto';

  @override
  String get tileAutofillSub =>
      'Pré-remplir les champs de la dernière transaction';

  @override
  String get tileStartScreen => 'Écran de démarrage';

  @override
  String get tileFont => 'Police';

  @override
  String get tileTextSize => 'Taille du texte';

  @override
  String get tileTxList => 'Liste des transactions';

  @override
  String get tileTxListSub => 'Disposition, icônes, bannière de date';

  @override
  String get tileCloudSync => 'Synchronisation cloud';

  @override
  String get tileCloudSyncSub => 'Synchroniser entre les appareils';

  @override
  String get tileShareHousehold => 'Partager le foyer';

  @override
  String get tileShareHouseholdConnected =>
      'Inviter quelqu\'un à partager vos données';

  @override
  String get tileShareHouseholdDisconnected =>
      'Connectez d\'abord la synchronisation cloud';

  @override
  String get tileShareHouseholdSnackbar =>
      'Configurez d\'abord la synchronisation cloud avec Google Drive pour partager votre foyer.';

  @override
  String get tileBackupRestore => 'Sauvegarde et restauration';

  @override
  String get tileBackupRestoreSub => 'Exporter ou restaurer la base de données';

  @override
  String get tileImportExport => 'Importer et exporter';

  @override
  String get tileImportExportSub => 'Import CSV, export et rapports';

  @override
  String get tileNotifications => 'Notifications';

  @override
  String get tileNotificationsSub =>
      'Rappel quotidien, alertes enveloppes et factures';

  @override
  String get tileHealthCheck => 'Bilan de santé';

  @override
  String get tileHealthCheckSub =>
      'Vérifier l\'intégrité des données et réparer';

  @override
  String get tileSyncReceipts => 'Synchroniser les reçus';

  @override
  String get tileSyncReceiptsOn =>
      'Télécharger les photos de reçus vers le cloud';

  @override
  String get tileSyncReceiptsOff =>
      'Les reçus sont stockés uniquement sur cet appareil';

  @override
  String get tileBaseCurrency => 'Devise de base';

  @override
  String get tilePeriodStartDay => 'Jour de début de période';

  @override
  String get tilePeriodStartDayDesc =>
      'Le jour du mois où une nouvelle période budgétaire commence.';

  @override
  String get tileCurrencySymbols => 'Symboles de devises';

  @override
  String get tileCurrencySymbolsSub => 'Modifier l\'affichage des devises';

  @override
  String get tileNumberFormat => 'Format des nombres';

  @override
  String get tileDateFormat => 'Format de date';

  @override
  String get tileBiometricLock => 'Verrouillage biométrique';

  @override
  String get tileBiometricSub => 'Exiger empreinte ou visage pour ouvrir';

  @override
  String get tileResetEverything => 'Tout réinitialiser';

  @override
  String get tileResetSub => 'Effacer toutes les données et recommencer';

  @override
  String get entryModeTitle => 'Mode de saisie';

  @override
  String get entryModeDesc =>
      'Choisissez comment ajouter de nouvelles transactions.';

  @override
  String get entryModeAssisted => 'Assisté (étape par étape)';

  @override
  String get entryModeAssistedDesc =>
      'Vous guide étape par étape pour ajouter une transaction. Choisissez d\'abord un titre, puis une catégorie, puis entrez le montant. Idéal pour les débutants.';

  @override
  String get entryModeClassic => 'Classique (formulaire unique)';

  @override
  String get entryModeClassicDesc =>
      'Tous les champs sur un seul écran. Remplissez ce dont vous avez besoin et enregistrez. Plus rapide pour les utilisateurs expérimentés.';

  @override
  String get entryModeAssistedShort => 'Assisté (étape par étape)';

  @override
  String get entryModeClassicShort => 'Classique (formulaire unique)';

  @override
  String get themeFollowDevice => 'Suivre les paramètres de l\'appareil';

  @override
  String get themeAmoled => 'Noir AMOLED pur';

  @override
  String get accentColorTitle => 'Couleur d\'accentuation';

  @override
  String get accentColorSystem => 'Système';

  @override
  String get accentColorSystemSub => 'Material You (Android 12+)';

  @override
  String get accentColorRoyalBlue => 'Bleu royal';

  @override
  String get accentColorDefault => 'Par défaut';

  @override
  String get accentColorSystemLabel => 'Système (Material You)';

  @override
  String get startScreenTitle => 'Écran de démarrage';

  @override
  String get startScreenDesc => 'S\'ouvre au lancement de l\'application.';

  @override
  String get chooseFontTitle => 'Choisir la police';

  @override
  String get fontPreview =>
      'Le vif renard brun saute par-dessus le chien paresseux';

  @override
  String get textSizeTitle => 'Taille du texte';

  @override
  String get textSizePreview => 'Aperçu du texte à cette taille';

  @override
  String get currencySymbolsTitle => 'Symboles de devises';

  @override
  String get currencySymbolsDesc =>
      'Appuyez sur une devise pour changer l\'affichage de son symbole. Par exemple, changez ل.ل en LBP.';

  @override
  String get currencySymbolsAllSection => 'TOUTES LES DEVISES';

  @override
  String currencySymbolDefault(String symbol) {
    return 'Par défaut : $symbol';
  }

  @override
  String currencySymbolFor(String code) {
    return 'Symbole pour $code';
  }

  @override
  String get numberFormatTitle => 'Format des nombres';

  @override
  String get numberFormatDesc =>
      'Choisissez comment les nombres sont affichés dans l\'application.';

  @override
  String get numberFormatPreview => 'Aperçu';

  @override
  String get numberFormatThousands => 'Séparateur de milliers';

  @override
  String get numberFormatDecimal => 'Séparateur décimal';

  @override
  String get numberFormatNegative => 'Nombres négatifs';

  @override
  String get numberFormatConflict =>
      'Certaines options sont masquées car elles entrent en conflit avec le séparateur décimal.';

  @override
  String get dateFormatTitle => 'Format de date';

  @override
  String get biometricNotAvailable =>
      'L\'authentification biométrique n\'est pas disponible sur cet appareil';

  @override
  String get biometricVerify =>
      'Vérifiez pour activer le verrouillage biométrique';

  @override
  String get biometricFailed =>
      'Authentification échouée — verrouillage biométrique non activé';

  @override
  String get biometricError =>
      'Erreur d\'authentification — verrouillage biométrique non activé';

  @override
  String get biometricNotEnrolled =>
      'Aucune donnée biométrique enregistrée sur cet appareil. Veuillez configurer l\'empreinte digitale ou la reconnaissance faciale dans les paramètres de l\'appareil, puis réessayez.';

  @override
  String get biometricLockedOut =>
      'Trop de tentatives. Veuillez patienter et réessayer.';

  @override
  String get biometricPasscodeNotSet =>
      'Aucun verrouillage d\'écran n\'est configuré sur cet appareil. Veuillez d\'abord configurer un code PIN, un schéma ou un mot de passe.';

  @override
  String get backupBannerNoBackup => 'Vous n\'avez pas encore sauvegardé';

  @override
  String backupBannerDaysAgo(int days) {
    return 'Vous n\'avez pas sauvegardé depuis $days jours';
  }

  @override
  String get backupNowButton => 'Sauvegarder maintenant';

  @override
  String syncShareInviteText(String code) {
    return 'Rejoignez mon foyer BudgetSeal ! Entrez ce code dans l\'application :\n$code';
  }

  @override
  String get privacyTermsTitle => 'Confidentialité et conditions';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get privacyLastUpdated => 'Dernière mise à jour : mai 2026';

  @override
  String get privacyIntro =>
      'BudgetSeal est conçu avec votre vie privée comme principe fondamental. Vos données financières vous appartiennent — nous ne les collectons, stockons ou transmettons jamais à aucun serveur.';

  @override
  String get privacyDataStorageTitle => '1. Stockage des données';

  @override
  String get privacyDataStorageBody =>
      'Toutes vos données financières sont stockées localement sur votre appareil dans une base de données SQLite. Aucune donnée ne quitte votre appareil sauf si vous activez explicitement la synchronisation cloud.';

  @override
  String get privacyCloudSyncTitle => '2. Synchronisation cloud (optionnelle)';

  @override
  String get privacyCloudSyncBody =>
      'Si vous choisissez d\'activer la synchronisation cloud, vos données sont téléchargées sur votre compte Google Drive personnel ou un fournisseur de stockage de votre choix. BudgetSeal n\'a pas accès à vos identifiants Google — l\'authentification est gérée par le système OAuth de Google.\n\nVous pouvez optionnellement chiffrer votre fichier de synchronisation avec le chiffrement AES-256 en utilisant un mot de passe que vous définissez.';

  @override
  String get privacyWebCompanionTitle => '3. Compagnon Web';

  @override
  String get privacyWebCompanionBody =>
      'La fonctionnalité Compagnon Web exécute un serveur HTTP local sur votre téléphone. Il n\'est accessible que depuis les appareils sur le même réseau WiFi. Aucune donnée n\'est envoyée sur Internet. La connexion est protégée par un code PIN, des jetons de session et une limitation de débit. Le serveur s\'arrête automatiquement après 6 heures.';

  @override
  String get privacyAnalyticsTitle => '4. Analyses et suivi';

  @override
  String get privacyAnalyticsBody =>
      'BudgetSeal n\'inclut aucun SDK d\'analyse, outil de rapport de plantage, bibliothèque publicitaire ou pixel de suivi. Aucune donnée d\'utilisation, identifiant d\'appareil ou métrique comportementale n\'est collectée.';

  @override
  String get privacyPermissionsTitle => '5. Autorisations';

  @override
  String get privacyPermissionsBody =>
      '• Caméra — utilisée uniquement pour le scan de reçus\n• Notifications — rappels quotidiens et alertes de factures\n• Biométrie — verrouillage optionnel de l\'application\n• Réseau — uniquement pour la synchronisation cloud et les taux de change\n• Réseau local — serveur Compagnon Web\n\nToutes les autorisations sont optionnelles et peuvent être refusées sans affecter les fonctionnalités principales.';

  @override
  String get privacyReceiptsTitle => '6. Images de reçus';

  @override
  String get privacyReceiptsBody =>
      'Les photos de reçus sont stockées dans le répertoire privé de l\'application sur votre appareil. Elles ne sont téléchargées nulle part sauf si vous activez la synchronisation des reçus via Google Drive. Le traitement OCR est effectué entièrement hors ligne.';

  @override
  String get privacyBackupsTitle => '7. Sauvegardes';

  @override
  String get privacyBackupsBody =>
      'Les sauvegardes automatiques sont stockées localement dans le répertoire documents de l\'application. Vous contrôlez la fréquence et la rétention des sauvegardes.';

  @override
  String get termsOfUseTitle => 'Conditions d\'utilisation';

  @override
  String get termsAcceptanceTitle => '1. Acceptation';

  @override
  String get termsAcceptanceBody =>
      'En utilisant BudgetSeal, vous acceptez ces conditions. Si vous n\'êtes pas d\'accord, veuillez désinstaller l\'application.';

  @override
  String get termsIntendedUseTitle => '2. Utilisation prévue';

  @override
  String get termsIntendedUseBody =>
      'BudgetSeal est un outil de gestion financière personnelle pour la budgétisation individuelle et familiale. Il n\'est pas destiné à la comptabilité commerciale, la préparation fiscale ou les conseils financiers.';

  @override
  String get termsDataAccuracyTitle => '3. Exactitude des données';

  @override
  String get termsDataAccuracyBody =>
      'Vous êtes responsable de l\'exactitude des données que vous saisissez. BudgetSeal calcule les soldes, budgets et rapports en fonction de vos saisies. Les taux de change provenant de sources externes sont approximatifs.';

  @override
  String get termsNoWarrantyTitle => '4. Sans garantie';

  @override
  String get termsNoWarrantyBody =>
      'BudgetSeal est fourni \"tel quel\" sans garantie d\'aucune sorte. Bien que nous nous efforcions d\'assurer la fiabilité, nous ne pouvons pas garantir que l\'application sera exempte d\'erreurs. Des sauvegardes régulières sont fortement recommandées.';

  @override
  String get termsLiabilityTitle => '5. Limitation de responsabilité';

  @override
  String get termsLiabilityBody =>
      'Le développeur ne sera pas responsable des dommages directs, indirects, accessoires ou consécutifs résultant de l\'utilisation de BudgetSeal.';

  @override
  String get termsIPTitle => '6. Propriété intellectuelle';

  @override
  String get termsIPBody =>
      'BudgetSeal et son contenu original sont protégés par le droit d\'auteur. L\'application utilise des bibliothèques open source listées dans la section Licences.';

  @override
  String get termsChangesTitle => '7. Modifications';

  @override
  String get termsChangesBody =>
      'Ces conditions peuvent être mises à jour avec les nouvelles versions de l\'application. L\'utilisation continue après une mise à jour constitue l\'acceptation des conditions révisées.';

  @override
  String get termsContactTitle => '8. Contact';

  @override
  String get termsContactBody =>
      'Pour toute question ou préoccupation concernant cette politique de confidentialité ou ces conditions d\'utilisation, contactez : fancyshark505@gmail.com';

  @override
  String get healthTitle => 'Bilan de santé';

  @override
  String get healthExportTooltip => 'Exporter le rapport';

  @override
  String get healthRerunTooltip => 'Relancer le bilan';

  @override
  String get healthAllClear => 'Tout est en ordre';

  @override
  String get healthIssuesFound => 'Problèmes détectés';

  @override
  String get healthDataConsistent => 'Vos données sont cohérentes et saines';

  @override
  String get healthDiscrepancies => 'Des écarts de solde détectés';

  @override
  String get healthTransactionsStat => 'Transactions';

  @override
  String get healthLedgerStat => 'Grand livre';

  @override
  String get healthBackupStat => 'Sauvegarde';

  @override
  String get healthNever => 'Jamais';

  @override
  String get healthBalanceInvariant => 'Invariant de solde';

  @override
  String get healthAccountBalances => 'Soldes des comptes';

  @override
  String get healthEnvelopeBalances => 'Soldes des enveloppes';

  @override
  String get healthDataQuality => 'Qualité des données';

  @override
  String get healthRepairButton => 'Réparer les soldes';

  @override
  String get healthLedgerEntries => 'Écritures du grand livre';

  @override
  String get healthSoftDeleted => 'Supprimées temporairement';

  @override
  String get healthOrphanEntries => 'Écritures orphelines';

  @override
  String get healthLastBackup => 'Dernière sauvegarde';

  @override
  String get healthNoAccounts => 'Aucun compte';

  @override
  String get healthNoEnvelopes => 'Aucune enveloppe';

  @override
  String get healthRepairTitle => 'Réparer les soldes';

  @override
  String get healthRepairMsg =>
      'Cela créera des écritures d\'ajustement pour réaligner les soldes des enveloppes avec les comptes. Une sauvegarde est recommandée.\\n\\nContinuer ?';

  @override
  String get healthRepairDone => 'Réparer';

  @override
  String get healthNoAdjustments => 'Aucun ajustement nécessaire';

  @override
  String get healthRepairFailed =>
      'La réparation a échoué. Veuillez réessayer.';

  @override
  String get healthPurgeTitle => 'Purger les transactions supprimées';

  @override
  String get healthPurgeSuffix => 'Cette action est irréversible.';

  @override
  String get healthPurgeButton => 'Purger';

  @override
  String get onboardWelcomeTitle => 'BudgetSeal';

  @override
  String get onboardTagline => 'Donnez un but à chaque dollar.';

  @override
  String get onboardStep1 => 'Ajoutez des comptes — où vit votre argent';

  @override
  String get onboardStep2 => 'Créez des enveloppes — un budget par catégorie';

  @override
  String get onboardStep3 => 'Financez les enveloppes — distribuez vos revenus';

  @override
  String get onboardStep4 =>
      'Dépensez — chaque dépense puise dans son enveloppe';

  @override
  String get onboardGetStarted => 'Commencer';

  @override
  String get onboardRestoreCloud => 'Restaurer depuis le cloud';

  @override
  String get onboardJoinHousehold => 'Rejoindre un foyer';

  @override
  String get onboardSetupTitle => 'Configurer votre foyer';

  @override
  String get onboardChangeLater =>
      'Vous pourrez tout modifier plus tard dans les Paramètres.';

  @override
  String get onboardHouseholdSection => 'FOYER';

  @override
  String get onboardHouseholdName => 'Nom du foyer';

  @override
  String get onboardBaseCurrency => 'Devise de base';

  @override
  String get onboardPeriodStart => 'Jour de début de période';

  @override
  String get onboardFirstAccountSection => 'PREMIER COMPTE';

  @override
  String get onboardAccountName => 'Nom du compte';

  @override
  String get onboardTypeCash => 'Espèces';

  @override
  String get onboardTypeBank => 'Banque';

  @override
  String get onboardTypeCredit => 'Crédit';

  @override
  String get onboardTypeDigital => 'Numérique';

  @override
  String get onboardCategoriesSection => 'CATÉGORIES';

  @override
  String get onboardFullSet => 'Jeu complet';

  @override
  String get onboardFullSetSub => '30 catégories avec sous-catégories';

  @override
  String get onboardEmpty => 'Vide';

  @override
  String get onboardEmptySub => 'Créez les vôtres à partir de zéro';

  @override
  String get onboardEntrySection => 'SAISIE DES TRANSACTIONS';

  @override
  String get onboardAssisted => 'Assisté';

  @override
  String get onboardAssistedSub =>
      'Étape par étape, rapide pour l\'utilisation quotidienne';

  @override
  String get onboardClassic => 'Formulaire classique';

  @override
  String get onboardClassicSub =>
      'Tous les champs à la fois, pour les saisies complexes';

  @override
  String get onboardCreateStart => 'Créer et commencer';

  @override
  String get onboardAllSet => 'Vous êtes prêt !';

  @override
  String get onboardDoneSubtitle =>
      'Commencez à suivre vos dépenses.\\nVotre clarté financière commence maintenant.';

  @override
  String get onboardStartUsing => 'Commencer à utiliser BudgetSeal';

  @override
  String get onboardRestoreTitle => 'Restaurer depuis le cloud';

  @override
  String get onboardRestoreDesc =>
      'Choisissez où votre sauvegarde est stockée. Cela remplacera les données locales.';

  @override
  String get onboardGoogleDrive => 'Google Drive';

  @override
  String get onboardPickFile => 'Choisir un fichier';

  @override
  String get onboardJoinDesc =>
      'Entrez le code d\'invitation partagé avec vous pour rejoindre un foyer BudgetSeal existant.';

  @override
  String get onboardInviteCode => 'Code d\'invitation';

  @override
  String get onboardInviteHint => 'PP-...';

  @override
  String get onboardJoinButton => 'Rejoindre le foyer';

  @override
  String get onboardEnterCodeError => 'Veuillez saisir un code d\'invitation';

  @override
  String get onboardInvalidCodeError =>
      'Code d\'invitation invalide. Il doit commencer par PP-';

  @override
  String get lockSetupReason =>
      'Configurez un verrouillage d\'écran pour protéger BudgetSeal';

  @override
  String get lockUnlockReason => 'Déverrouiller BudgetSeal';

  @override
  String lockFailed(String error) {
    return 'Échec du déverrouillage : $error';
  }

  @override
  String get lockTapToUnlock => 'Appuyez pour déverrouiller';

  @override
  String get lockUnlockButton => 'Déverrouiller';

  @override
  String get reportsTitle => 'Rapports';

  @override
  String get reportsOverviewTab => 'Aperçu';

  @override
  String get reportsCategoriesTab => 'Catégories';

  @override
  String get reportsInsightsTab => 'Analyses';

  @override
  String get reportsBalanceTab => 'Bilan';

  @override
  String get reportsHintTitle => 'Explorez vos habitudes de dépenses';

  @override
  String get reportsHintBody =>
      'Basculez entre les onglets pour différentes vues. L\'onglet Analyses montre votre santé financière.';

  @override
  String get reportsDailyPace => 'Rythme quotidien';

  @override
  String get reportsProjectedTotal => 'Total projeté';

  @override
  String reportsLessThanLast(double pct) {
    return '$pct% de moins que le mois dernier';
  }

  @override
  String reportsMoreThanLast(double pct) {
    return '$pct% de plus que le mois dernier';
  }

  @override
  String get reportsSameAsLast => 'Identique au mois dernier';

  @override
  String get reportsSpendingActivity => 'Activité de dépenses';

  @override
  String get reportsHeatmapNone => 'Aucun';

  @override
  String get reportsHeatmapHelp =>
      'Chaque carré est un jour. Plus sombre = montant plus élevé. Faites défiler à gauche pour les mois précédents.';

  @override
  String get reports6MonthTrend => 'Tendance sur 6 mois';

  @override
  String get reportsDailyPaceToggle => 'Rythme quotidien';

  @override
  String get reportsNoSpending => 'Aucune dépense ce mois-ci';

  @override
  String get reportsTopSpending => 'TOP DÉPENSES';

  @override
  String get reportsTopTransactions => 'TOP TRANSACTIONS';

  @override
  String get reportsNoExpenses => 'Aucune dépense pour cette période';

  @override
  String get reportsNoNote => 'Aucune note';

  @override
  String get reportsNewBadge => 'NOUVEAU';

  @override
  String get reportsCurrentLegend => 'Actuel';

  @override
  String get reportsTypicalLegend => 'Typique';

  @override
  String get reportsVelocityTitle => 'Vélocité des dépenses';

  @override
  String get reportsProjected => 'Projeté';

  @override
  String get reportsBudget => 'Budget';

  @override
  String get reportsDailyRate => 'Taux quotidien';

  @override
  String get reportsDay => 'Jour';

  @override
  String get reportsBiggestExpense => 'Plus grosse dépense';

  @override
  String get reportsSavingsRate => 'Taux d\'épargne';

  @override
  String get reportsRecurringTitle => 'Transactions récurrentes';

  @override
  String get reportsAgeTitle => 'Âge de l\'argent';

  @override
  String get reportsAgeExcellent => 'Excellent';

  @override
  String get reportsAgeGettingThere => 'En bonne voie';

  @override
  String get reportsAgeNeedsWork => 'À améliorer';

  @override
  String get reportsAgeExcellentDesc =>
      'Vous dépensez les revenus du mois dernier — signe de stabilité financière.';

  @override
  String get reportsAgeGettingDesc =>
      'Vous construisez un tampon mais n\'y êtes pas encore. Continuez !';

  @override
  String get reportsAgeNeedsDesc =>
      'Vous vivez au jour le jour. Essayez de constituer un tampon avec le temps.';

  @override
  String get reportsAgeGoal => 'Objectif : 30+ jours';

  @override
  String get reportsAgeExplanation =>
      'L\'Âge de l\'argent mesure combien de jours votre argent reste avant d\'être dépensé. Il retrace chaque dépense jusqu\'au revenu qui l\'a financée (le plus ancien d\'abord).';

  @override
  String get reportsTipsSection => 'CONSEILS';

  @override
  String get reportsNetWorth => 'PATRIMOINE NET';

  @override
  String get reportsAssets => 'ACTIFS';

  @override
  String get reportsLiabilities => 'PASSIFS';

  @override
  String get reportsCompareTo => 'Comparer les soldes à :';

  @override
  String get reportsEndLastWeek => 'Fin de la semaine dernière';

  @override
  String get reportsEndLastMonth => 'Fin du mois dernier';

  @override
  String get reportsSameTimeLastMonth => 'Même période le mois dernier';

  @override
  String get reportsEndLastQuarter => 'Fin du dernier trimestre';

  @override
  String get reportsEndLastYear => 'Fin de l\'année dernière';

  @override
  String get reportsSameTimeLastYear => 'Même période l\'année dernière';

  @override
  String get reportsCustom => 'Personnalisé...';

  @override
  String get wcTitle => 'Compagnon Web';

  @override
  String get wcStopped => 'Serveur arrêté';

  @override
  String get wcStarting => 'Démarrage...';

  @override
  String get wcRunning => 'Serveur en marche';

  @override
  String get wcError => 'Erreur';

  @override
  String get wcNoWifi => 'Pas de WiFi';

  @override
  String get wcAutoStop => 'S\'arrête automatiquement après 6 heures';

  @override
  String get wcStopButton => 'Arrêter le serveur';

  @override
  String get wcStartButton => 'Démarrer le serveur';

  @override
  String get wcOpenOnLaptop => 'Ouvrez sur votre ordinateur';

  @override
  String get wcUrlCopied => 'URL copiée dans le presse-papiers';

  @override
  String get wcCopyUrl => 'Copier l\'URL';

  @override
  String get wcHideQr => 'Masquer le code QR';

  @override
  String get wcShowQr => 'Afficher le code QR';

  @override
  String get wcSecurityTitle => 'Sécurité';

  @override
  String get wcPinRequired =>
      'Un code PIN est requis pour accéder à l\'interface web.';

  @override
  String get wcPinIsSet => 'PIN défini';

  @override
  String get wcNoPin => 'Pas de PIN défini';

  @override
  String get wcChangePin => 'Changer le PIN';

  @override
  String get wcSetPin => 'Définir le PIN';

  @override
  String get wcSetPinTitle => 'Définir le PIN Web';

  @override
  String get wcSetPinSubtitle =>
      'Ce PIN protège vos données budgétaires. Toute personne sur le même WiFi en aura besoin.';

  @override
  String get wcChangePinTitle => 'Changer le PIN';

  @override
  String get wcChangePinSubtitle =>
      'Entrez un nouveau code PIN à 4 chiffres pour votre interface web.';

  @override
  String get wc4DigitPin => 'PIN à 4 chiffres';

  @override
  String get wcEnter4DigitsError => 'Entrez exactement 4 chiffres';

  @override
  String get wcUpdatePin => 'Mettre à jour le PIN';

  @override
  String get wcPinUpdated =>
      'PIN mis à jour. Toutes les sessions actives déconnectées.';

  @override
  String get wcIosWarning =>
      'Gardez BudgetSeal au premier plan pendant le fonctionnement du serveur. iOS ne supporte pas les serveurs en arrière-plan — verrouiller l\'écran l\'arrêtera.';

  @override
  String get wcNoWifiTitle => 'Pas de connexion WiFi';

  @override
  String get wcNoWifiDesc =>
      'Connectez votre téléphone au WiFi pour utiliser le Compagnon Web. Le serveur a besoin du WiFi pour que votre ordinateur accède au budget.';

  @override
  String get wcPublicNetwork => 'Réseau public détecté';

  @override
  String get wcNetworkSecurity => 'Sécurité du réseau';

  @override
  String get wcSecurityWarning => 'Avertissement de sécurité';

  @override
  String get wcInfo1 => 'Accessible uniquement sur le même réseau WiFi';

  @override
  String get wcInfo2 => 'Le serveur s\'arrête automatiquement après 6 heures';

  @override
  String get wcInfo3 =>
      '5 tentatives de PIN échouées verrouillent l\'interface pendant 30 minutes';

  @override
  String get wcInfo4 =>
      'Utilisez uniquement sur des réseaux privés de confiance — le trafic n\'est pas chiffré';

  @override
  String get wcNotifPermission =>
      'L\'autorisation de notification est nécessaire pour maintenir le serveur en arrière-plan.';

  @override
  String get wcForegroundChannel => 'Compagnon Web';

  @override
  String get wcForegroundChannelDesc =>
      'Le serveur Compagnon Web BudgetSeal est en marche';

  @override
  String get webPageTitle => 'BudgetSeal Web';

  @override
  String get webAuthSubtitle => 'Entrez votre PIN pour continuer';

  @override
  String get webAuthLockout => 'Trop de tentatives. Réessayez plus tard.';

  @override
  String get webAuthIncorrect => 'PIN incorrect';

  @override
  String get webServerUnreachable => 'Serveur injoignable';

  @override
  String get webUnexpectedResponse => 'Réponse inattendue du serveur';

  @override
  String get webUnexpectedError => 'Erreur inattendue';

  @override
  String get webUndo => 'Annuler';

  @override
  String get webSaving => 'Enregistrement…';

  @override
  String get webDashNoAccounts => 'Aucun compte pour le moment.';

  @override
  String get webDashUnallocated => 'Non affecté';

  @override
  String get webDashNoEnvelopes => 'Aucune enveloppe pour le moment.';

  @override
  String get webDashFallbackTx => 'Transaction';

  @override
  String get webDashNoTxTitle => 'Aucune transaction pour le moment';

  @override
  String get webDashNoTxSub =>
      'Ajoutez votre première transaction pour commencer';

  @override
  String get webDashSeeAll => 'Voir tout';

  @override
  String get webDashRecent => 'Transactions récentes';

  @override
  String get webDashViewAll => 'Voir tout';

  @override
  String get webTxNoRate => 'Pas de taux';

  @override
  String get webTxNoFound => 'Aucune transaction trouvée';

  @override
  String get webTxCsv => 'CSV';

  @override
  String get webTxCsvTooltip => 'Exporter CSV';

  @override
  String get webTxAdd => '+ Ajouter';

  @override
  String get webTxSearch => 'Rechercher par titre…';

  @override
  String get webTxThDate => 'Date';

  @override
  String get webTxThType => 'Type';

  @override
  String get webTxThTitle => 'Titre';

  @override
  String get webTxThAccount => 'Compte';

  @override
  String get webTxThCategory => 'Catégorie';

  @override
  String get webTxThAmount => 'Montant';

  @override
  String get webTxPrev => '← Préc.';

  @override
  String webTxPageN(int page) {
    return 'Page $page';
  }

  @override
  String get webTxNext => 'Suiv. →';

  @override
  String get webTxCsvExported => 'CSV exporté';

  @override
  String get webTxEdit => 'Modifier';

  @override
  String get webTxDel => 'Suppr.';

  @override
  String get webFormType => 'Type';

  @override
  String get webFormFromAccount => 'Compte source';

  @override
  String get webFormAccount => 'Compte';

  @override
  String get webFormSelectAccount => 'Sélectionner un compte';

  @override
  String get webFormToAccount => 'Compte destination';

  @override
  String get webFormCategory => 'Catégorie';

  @override
  String get webFormNone => '— Aucun —';

  @override
  String get webFormAmount => 'Montant';

  @override
  String get webFormAmountPlaceholder => '0.00';

  @override
  String get webFormCurrency => 'Devise';

  @override
  String get webFormCurrencyPlaceholder => 'USD';

  @override
  String get webFormExchangeRate => 'Taux de change';

  @override
  String get webFormRatePlaceholder => 'Taux vers la devise de base';

  @override
  String get webFormDate => 'Date';

  @override
  String get webFormTitleNote => 'Titre / Note';

  @override
  String get webFormOptional => 'Optionnel';

  @override
  String webFormRateHint(String txCur, String baseCur) {
    return '1 $txCur = ? $baseCur';
  }

  @override
  String get webValSelectAccount => 'Sélectionnez un compte';

  @override
  String get webValValidAmount => 'Saisissez un montant valide';

  @override
  String get webValSelectDest => 'Sélectionnez le compte de destination';

  @override
  String get webValAccountsDiffer =>
      'Les comptes source et destination doivent différer';

  @override
  String get webModalAddTx => 'Ajouter une transaction';

  @override
  String get webToastTxAdded => 'Transaction ajoutée';

  @override
  String get webModalEditTx => 'Modifier la transaction';

  @override
  String get webToastTxUpdated => 'Transaction mise à jour';

  @override
  String get webToastTxDeleted => 'Transaction supprimée';

  @override
  String get webToastNoLines => 'Aucun détail de ligne disponible';

  @override
  String webTxLinesHeader(int count) {
    return 'Lignes de transaction ($count)';
  }

  @override
  String get webThLineAmount => 'Montant';

  @override
  String get webThLineCurrency => 'Devise';

  @override
  String get webThLineCategory => 'Catégorie';

  @override
  String get webThLineAccount => 'Compte';

  @override
  String get webThLineNote => 'Note';

  @override
  String get webThLineRate => 'Taux';

  @override
  String get webCatSubSingular => '1 sous-catégorie';

  @override
  String webCatSubPlural(int count) {
    return '$count sous-catégories';
  }

  @override
  String get webCatSectionExpense => 'Dépense';

  @override
  String get webCatSectionIncome => 'Revenu';

  @override
  String get webCatEmptyTitle => 'Aucune catégorie';

  @override
  String get webCatEmptySub =>
      'Ajoutez votre première catégorie pour commencer';

  @override
  String get webCatFormName => 'Nom';

  @override
  String get webCatFormNameHint => 'ex. Courses';

  @override
  String get webCatFormParent => 'Catégorie parente';

  @override
  String get webCatFormNone => '— Aucune (niveau supérieur) —';

  @override
  String get webCatFormIcon => 'Icône (émoji)';

  @override
  String get webCatFormColor => 'Couleur';

  @override
  String get webCatFormType => 'Type de transaction';

  @override
  String get webModalAddCat => 'Ajouter une catégorie';

  @override
  String get webValNameRequired => 'Le nom est requis';

  @override
  String get webToastCatAdded => 'Catégorie ajoutée';

  @override
  String get webToastCatNotFound => 'Catégorie introuvable';

  @override
  String get webModalEditCat => 'Modifier la catégorie';

  @override
  String get webToastCatUpdated => 'Catégorie mise à jour';

  @override
  String get webAcctEmptyTitle => 'Aucun compte pour le moment';

  @override
  String get webAcctEmptySub => 'Ajoutez votre premier compte pour commencer';

  @override
  String get webAcctTypeBank => 'Comptes bancaires';

  @override
  String get webAcctTypeCash => 'Espèces';

  @override
  String get webAcctTypeCredit => 'Cartes de crédit';

  @override
  String get webAcctTypeWallet => 'Portefeuilles';

  @override
  String webAcctNetWorth(String cur) {
    return 'Patrimoine net · $cur';
  }

  @override
  String get webAcctCountSingular => '1 compte';

  @override
  String webAcctCountPlural(int count) {
    return '$count comptes';
  }

  @override
  String get webAcctTxEmpty => 'Aucune transaction pour ce compte';

  @override
  String get webAcctBack => '← Retour';

  @override
  String get webAcctFormNameHint => 'ex. Compte courant';

  @override
  String get webAcctFormType => 'Type';

  @override
  String get webAcctFormTypeBank => 'Banque';

  @override
  String get webAcctFormTypeCash => 'Espèces';

  @override
  String get webAcctFormTypeCredit => 'Crédit';

  @override
  String get webAcctFormTypeWallet => 'Portefeuille';

  @override
  String get webAcctFormOpening => 'Solde d\'ouverture';

  @override
  String get webModalAddAcct => 'Ajouter un compte';

  @override
  String get webToastAcctAdded => 'Compte ajouté';

  @override
  String get webEnvEmptyTitle => 'Aucune enveloppe';

  @override
  String get webEnvEmptySub =>
      'Les enveloppes sont gérées dans l\'application BudgetSeal.';

  @override
  String get webEnvUnallocated => 'Non affecté :';

  @override
  String get webEnvFund => '+ Financer';

  @override
  String get webModalFund => 'Financer l\'enveloppe';

  @override
  String get webFormAmountToFund => 'Montant à financer';

  @override
  String get webFormNote => 'Note';

  @override
  String get webToastEnvFunded => 'Enveloppe financée';

  @override
  String get webBtnFundConfirm => 'Financer';

  @override
  String get webRecurringEmpty => 'Aucune transaction récurrente';

  @override
  String get webThService => 'Service';

  @override
  String get webThFrequency => 'Fréquence';

  @override
  String get webThNextDue => 'Prochaine échéance';

  @override
  String get webThOn => 'Actif';

  @override
  String get webToggleEnabled => 'Activé';

  @override
  String get webToggleDisabled => 'Désactivé';

  @override
  String get webFormTitleLabel => 'Titre';

  @override
  String get webFormTitleHint => 'ex. Netflix';

  @override
  String get webFormFrequency => 'Fréquence';

  @override
  String get webFormEvery => 'Chaque';

  @override
  String get webFormStartDate => 'Date de début';

  @override
  String get webModalAddRecurring => 'Ajouter un récurrent';

  @override
  String get webToastRecurringAdded => 'Récurrent ajouté';

  @override
  String get webModalEditRecurring => 'Modifier le récurrent';

  @override
  String get webToastUpdated => 'Mis à jour';

  @override
  String get webToastNotFound => 'Introuvable';

  @override
  String get webValSelectStartDate => 'Sélectionnez une date de début';

  @override
  String get webConfirmDeleteRecurring => 'Supprimer le récurrent';

  @override
  String get webConfirmDeleteRecurringMsg =>
      'Cette transaction récurrente sera supprimée définitivement.';

  @override
  String get webToastDeleted => 'Supprimé';

  @override
  String get webSubEmpty => 'Aucun abonnement';

  @override
  String get webModalAddSub => 'Ajouter un abonnement';

  @override
  String get webToastSubAdded => 'Abonnement ajouté';

  @override
  String get webModalEditSub => 'Modifier l\'abonnement';

  @override
  String get webFormNewAmount => 'Nouveau montant';

  @override
  String get webSubPriceHint =>
      'Modifier le montant ajoutera une entrée dans l\'historique des prix.';

  @override
  String get webConfirmDeleteSub => 'Supprimer l\'abonnement';

  @override
  String get webConfirmDeleteSubMsg =>
      'Cet abonnement sera supprimé définitivement.';

  @override
  String get webReportsYear => 'Année';

  @override
  String get webReportsMonth => 'Mois';

  @override
  String get webReportsLoad => 'Charger';

  @override
  String get webReportsSelectPrompt =>
      'Sélectionnez une période et cliquez sur Charger.';

  @override
  String get webStatIncome => 'Revenu';

  @override
  String get webStatExpenses => 'Dépenses';

  @override
  String get webStatNet => 'Net';

  @override
  String get webStatSavingsRate => 'Taux d\'épargne';

  @override
  String get webStatAvgDaily => 'Dépense quotidienne moy.';

  @override
  String get webStatTransactions => 'Transactions';

  @override
  String get webReportDailyCashflow => 'Flux de trésorerie quotidien';

  @override
  String get webReportSpendingCat => 'Dépenses par catégorie';

  @override
  String get webReportNoExpense => 'Aucune donnée de dépense';

  @override
  String get webReportIncomeCat => 'Revenus par catégorie';

  @override
  String get webReportNoIncome => 'Aucune donnée de revenu';

  @override
  String get webReportTopExpenses => 'Principales dépenses';

  @override
  String get webChartIncome => 'Revenu';

  @override
  String get webChartExpense => 'Dépense';

  @override
  String get webShortcutsTitle => 'Raccourcis clavier';

  @override
  String get webShortcutNewTx => 'Nouvelle transaction';

  @override
  String get webShortcutSearch => 'Rechercher les transactions';

  @override
  String get webShortcutClose => 'Fermer la modale / défocaliser';

  @override
  String get webShortcutHelp => 'Afficher cette aide';

  @override
  String get monthJan => 'Janv';

  @override
  String get monthFeb => 'Fév';

  @override
  String get monthMar => 'Mars';

  @override
  String get monthApr => 'Avr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Juin';

  @override
  String get monthJul => 'Juil';

  @override
  String get monthAug => 'Août';

  @override
  String get monthSep => 'Sept';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Déc';

  @override
  String get notifLowEnvelopesTitle => 'Enveloppes faibles';

  @override
  String notifSingleOverspent(String name) {
    return '$name est dépassé(e). Pensez à ajouter des fonds.';
  }

  @override
  String notifMultipleOverspent(int count, String names, String more) {
    return '$count enveloppes sont dépassées : $names$more.';
  }

  @override
  String notifAndMore(int count) {
    return 'et $count de plus';
  }

  @override
  String get notifUpcomingBillsTitle => 'Factures à venir';

  @override
  String notifSingleDue(String title) {
    return '$title est bientôt due.';
  }

  @override
  String notifMultipleDue(int count, String names, String more) {
    return '$count factures dues : $names$more.';
  }

  @override
  String get notifBillsAndMore => 'et plus';

  @override
  String get notifBudgetWarningTitle => 'Alerte budget';

  @override
  String notifBudgetWarning(String name, String percent, String days) {
    return '$name : $percent% utilisé avec $days jours restants';
  }

  @override
  String get notifReminderTitle => 'BudgetSeal';

  @override
  String get notifReminder1 =>
      'Comment avez-vous dépensé aujourd\'hui ? Appuyez pour enregistrer.';

  @override
  String get notifReminder2 =>
      'N\'oubliez pas d\'enregistrer les transactions du jour !';

  @override
  String get notifReminder3 =>
      'Restez sur la bonne voie — enregistrez vos dépenses du jour.';

  @override
  String get notifReminder4 =>
      'Une minute maintenant économise des heures plus tard. Enregistrez votre journée !';

  @override
  String get notifReminder5 =>
      'Gardez votre budget honnête — ajoutez les transactions du jour.';

  @override
  String get notifReminderChannel => 'Rappel quotidien';

  @override
  String get notifReminderChannelDesc =>
      'Rappel quotidien pour enregistrer les transactions';

  @override
  String get engineAutoCovered => 'Couvert automatiquement depuis Non affecté';

  @override
  String get engineDirectIncome => 'Directement du revenu';

  @override
  String get engineWithdrawn => 'Retiré vers Non affecté';

  @override
  String get enginePeriodReturned =>
      'Réinitialisation de période — retourné au Non affecté';

  @override
  String get enginePeriodOut => 'Réinitialisation de période — transféré';

  @override
  String get enginePeriodReceived => 'Reçu de la réinitialisation de période';

  @override
  String get engineCarryForward => 'Report de période';

  @override
  String get engineAutoReset => 'Réinitialisation automatique de période';

  @override
  String get nfThousandsComma => 'Virgule (1,000)';

  @override
  String get nfThousandsPeriod => 'Point (1.000)';

  @override
  String get nfThousandsSpace => 'Espace (1 000)';

  @override
  String get nfThousandsNone => 'Aucun (1000)';

  @override
  String get nfDecimalPeriod => 'Point (0.50)';

  @override
  String get nfDecimalComma => 'Virgule (0,50)';

  @override
  String get nfNegativeMinus => 'Moins (-100 \$)';

  @override
  String get textScaleSmall => 'Petit';

  @override
  String get textScaleDefault => 'Par défaut';

  @override
  String get textScaleLarge => 'Grand';

  @override
  String get textScaleExtraLarge => 'Très grand';

  @override
  String get defcatFoodDining => 'Alimentation et restaurants';

  @override
  String get defcatGroceries => 'Courses';

  @override
  String get defcatRestaurants => 'Restaurants';

  @override
  String get defcatCoffeeSnacks => 'Café et snacks';

  @override
  String get defcatTransportation => 'Transport';

  @override
  String get defcatFuel => 'Carburant';

  @override
  String get defcatPublicTransit => 'Transports en commun';

  @override
  String get defcatParkingTolls => 'Parking et péages';

  @override
  String get defcatHousing => 'Logement';

  @override
  String get defcatRentMortgage => 'Loyer / Hypothèque';

  @override
  String get defcatUtilities => 'Services publics';

  @override
  String get defcatMaintenance => 'Entretien';

  @override
  String get defcatShopping => 'Shopping';

  @override
  String get defcatClothing => 'Vêtements';

  @override
  String get defcatElectronics => 'Électronique';

  @override
  String get defcatHouseholdItems => 'Articles ménagers';

  @override
  String get defcatEntertainment => 'Divertissement';

  @override
  String get defcatSubscriptions => 'Abonnements';

  @override
  String get defcatMoviesEvents => 'Cinéma et événements';

  @override
  String get defcatHobbies => 'Loisirs';

  @override
  String get defcatHealth => 'Santé';

  @override
  String get defcatMedical => 'Médical';

  @override
  String get defcatPharmacy => 'Pharmacie';

  @override
  String get defcatFitness => 'Fitness';

  @override
  String get defcatPersonal => 'Personnel';

  @override
  String get defcatEducation => 'Éducation';

  @override
  String get defcatGifts => 'Cadeaux';

  @override
  String get defcatPersonalCare => 'Soins personnels';

  @override
  String get defcatSalary => 'Salaire';

  @override
  String get defcatFreelance => 'Freelance';

  @override
  String get defcatInvestments => 'Investissements';

  @override
  String get defcatOtherIncome => 'Autres revenus';

  @override
  String get defcatFoodDrink => 'Alimentation';

  @override
  String get defcatTransport => 'Transport';

  @override
  String get defcatBills => 'Factures';

  @override
  String get defcatHome => 'Maison';

  @override
  String get defcatTravel => 'Voyage';

  @override
  String get defcatDiningOut => 'Restaurant';

  @override
  String get defcatCoffee => 'Cafe';

  @override
  String get defcatRent => 'Loyer';

  @override
  String get defcatFurniture => 'Meubles';

  @override
  String get defcatElectricity => 'Electricite';

  @override
  String get defcatInternet => 'Internet';

  @override
  String get defcatPhone => 'Telephone';

  @override
  String get defcatHaircut => 'Coiffure';

  @override
  String get defcatSkincare => 'Soins de peau';

  @override
  String get defcatGym => 'Sport';

  @override
  String get defcatMovies => 'Cinema';

  @override
  String get defcatGames => 'Jeux';

  @override
  String get defcatBooks => 'Livres';

  @override
  String get defcatHotels => 'Hôtels';

  @override
  String get defcatFlights => 'Vols';

  @override
  String get defcatWater => 'Eau';

  @override
  String get defcatInsurance => 'Assurance';

  @override
  String get defcatPets => 'Animaux';

  @override
  String get defcatOther => 'Autre';

  @override
  String get syncErrEncryptedNoPw =>
      'Le fichier de synchronisation est chiffré mais aucun mot de passe n\'est défini. Entrez votre mot de passe pour déchiffrer.';

  @override
  String get syncErrWrongPw =>
      'Mot de passe de synchronisation incorrect. Impossible de déchiffrer le fichier.';

  @override
  String get syncErrInvalidFormat =>
      'Format de fichier de synchronisation chiffré invalide';

  @override
  String get googleNotConfigured =>
      'La connexion Google n\'est pas configurée pour cette application. Un projet Google Cloud avec des identifiants OAuth est requis.';

  @override
  String get googleNetworkError =>
      'Erreur réseau. Vérifiez votre connexion internet.';

  @override
  String googleConnectionFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get googleNotConnected => 'Non connecté à Google Drive';

  @override
  String get filePickerTitle =>
      'Sélectionnez le fichier de synchronisation BudgetSeal';

  @override
  String get filePickerNoPath =>
      'Aucun chemin de fichier de synchronisation défini';

  @override
  String get heatmapNoData => 'Pas encore de données';

  @override
  String get heatmapNoActivity => 'Aucune activité';

  @override
  String backupSizeBytes(String size) {
    return '$size o';
  }

  @override
  String backupSizeKb(String size) {
    return '$size Ko';
  }

  @override
  String backupSizeMb(String size) {
    return '$size Mo';
  }

  @override
  String get onboardHouseholdNameError => 'Entrez un nom de foyer';

  @override
  String get onboardAccountNameError => 'Entrez un nom de compte';

  @override
  String get onboardMoreOptions => 'Plus d\'options';

  @override
  String onboardDayN(int day) {
    return 'Jour $day';
  }

  @override
  String get onboardEnvelopeExplainer =>
      'La budgétisation par enveloppes est simple : répartissez vos revenus dans des enveloppes virtuelles pour chaque catégorie de dépenses. Quand une enveloppe est vide, vous arrêtez de dépenser dans cette catégorie.';

  @override
  String get onboardHouseholdHint => 'ex. Mon Budget';

  @override
  String get onboardPeriodHelp =>
      'Le jour où votre budget mensuel se réinitialise (généralement le 1er ou votre jour de paie).';

  @override
  String get onboardHelpHint =>
      'Besoin d\'aide ? Consultez notre guide à tout moment depuis Plus > Guide d\'aide.';

  @override
  String travelPreviousWallet(String currency) {
    return 'Vous avez un précédent portefeuille de voyage en $currency :';
  }

  @override
  String get travelExchangeFailed => 'Échec du change. Veuillez réessayer.';

  @override
  String travelBalanceLabel(String amount) {
    return 'Solde : $amount';
  }

  @override
  String get periodTransitionFailed =>
      'Échec de la transition. Veuillez réessayer.';

  @override
  String get leftoverLoadError => 'Impossible de charger les données';

  @override
  String get leftoverResolveFailed =>
      'Échec de la résolution des restes. Veuillez réessayer.';

  @override
  String get commonTryAgain => 'Réessayer';

  @override
  String get commonErrorDesc =>
      'Une erreur inattendue s\'est produite. Essayez de revenir en arrière ou de redémarrer l\'application.';

  @override
  String get commonUncategorized => 'Non classé';

  @override
  String wcPublicNetworkDescNamed(String wifiName) {
    return 'Vous semblez être sur un réseau public (\"$wifiName\"). Ne démarrez pas le serveur — vos données seront transmises sans chiffrement et pourraient être interceptées par d\'autres sur le même réseau.';
  }

  @override
  String get wcPublicNetworkDescUnnamed =>
      'Vous semblez être sur un réseau public. Ne démarrez pas le serveur — vos données seront transmises sans chiffrement et pourraient être interceptées par d\'autres sur le même réseau.';

  @override
  String get wcNetworkSecurityDesc =>
      'Web Companion utilise HTTP (non chiffré). Utilisez-le uniquement sur votre WiFi privé domestique ou de bureau. Ne démarrez jamais le serveur sur des réseaux publics (hôtels, aéroports, cafés) — n\'importe qui sur le même réseau pourrait voir vos données.';

  @override
  String wcSecurityWarningNamed(String wifiName) {
    return 'Le réseau \"$wifiName\" peut être public. Le trafic n\'est pas chiffré — évitez d\'utiliser Web Companion sur les réseaux WiFi publics.';
  }

  @override
  String get wcSecurityWarningUnnamed =>
      'Impossible de détecter le nom de votre réseau WiFi. Si vous êtes sur un réseau public, évitez d\'utiliser Web Companion — le trafic n\'est pas chiffré et pourrait être intercepté.';

  @override
  String get tmplApplyError => 'Impossible d\'appliquer le modèle';

  @override
  String get tmplDeleteError => 'Impossible de supprimer le modèle';

  @override
  String get tmplEnterAmount => 'Entrez un montant';

  @override
  String tmplCountOne(int count) {
    return '$count modèle';
  }

  @override
  String tmplCountOther(int count) {
    return '$count modèles';
  }

  @override
  String tmplUseCountOne(int count) {
    return '$count utilisation';
  }

  @override
  String tmplUseCountOther(int count) {
    return '$count utilisations';
  }

  @override
  String get tileLanguage => 'Langue';

  @override
  String get tileLanguageSub => 'Langue d\'affichage de l\'application';

  @override
  String get languageSystem => 'Système';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get languagePickerTitle => 'Langue';

  @override
  String get recurringTitle => 'Récurrentes';

  @override
  String get recurringSummaryTotal => 'Total';

  @override
  String get recurringSummaryActive => 'Actives';

  @override
  String get recurringSummaryPaused => 'En pause';

  @override
  String get recurringEmptyTitle => 'Aucune transaction récurrente';

  @override
  String get recurringEmptySubtitle => 'Appuyez sur + pour en créer une';

  @override
  String recurringFilteredEmpty(String type) {
    return 'Aucune transaction récurrente de type $type';
  }

  @override
  String get recurringDeleteTitle => 'Supprimer la transaction récurrente ?';

  @override
  String get recurringDeleteBody => 'Elle sera définitivement supprimée.';

  @override
  String get recurringDeleted => 'Transaction récurrente supprimée';

  @override
  String get recurringCreated => 'Transaction récurrente créée';

  @override
  String get recurringUpdated => 'Transaction récurrente mise à jour';

  @override
  String get recurringNewTitle => 'Nouvelle transaction récurrente';

  @override
  String get recurringNewSubTitle => 'Nouvel abonnement';

  @override
  String get recurringEditTitle => 'Modifier la transaction récurrente';

  @override
  String get recurringFormTitleHint => 'Titre (ex. Loyer, Salaire)';

  @override
  String get recurringFormTitleRequired => 'Le titre est requis';

  @override
  String recurringFormEnds(String date) {
    return 'Fin : $date';
  }

  @override
  String get recurringFormEndsNever => 'Fin : Jamais (appuyez pour définir)';

  @override
  String recurringFormNextDue(String date) {
    return 'Prochaine échéance : $date';
  }

  @override
  String get recurringFormClearEndDate => 'Effacer la date de fin';

  @override
  String get recurringFormIsSubscription => 'Ceci est un abonnement';

  @override
  String get recurringFormSubscriptionHint => 'ex. Netflix, Spotify';

  @override
  String get recurringFormCreate => 'Créer';

  @override
  String get recurringFormEnterTitle => 'Entrez un titre';

  @override
  String get recurringFormEnterAmount => 'Entrez un montant valide';

  @override
  String get recurringFormSelectAccount => 'Sélectionnez un compte';

  @override
  String get recurringStatusActive => 'Active';

  @override
  String get recurringStatusPaused => 'En pause';

  @override
  String get recurringPauseTooltip => 'Mettre en pause';

  @override
  String get recurringResumeTooltip => 'Reprendre';

  @override
  String recurringTileNext(String date) {
    return 'Prochain : $date';
  }

  @override
  String reportsAgeDays(int age) {
    return '$age jours';
  }

  @override
  String settingsVersionN(String version) {
    return 'Version $version';
  }

  @override
  String settingsPreview(String preview) {
    return 'Aperçu : $preview';
  }

  @override
  String get subCouldNotUpdate => 'Impossible de mettre à jour l\'abonnement';

  @override
  String get helpGuideTitle => 'Guide d\'aide';

  @override
  String get receiptTakePhoto => 'Prendre une photo';

  @override
  String get receiptChooseGallery => 'Choisir dans la galerie';

  @override
  String get receiptSelectMultiple => 'Sélectionner plusieurs photos';

  @override
  String get importCsvTitle => 'Importer CSV';

  @override
  String get importFromBank => 'Importer depuis un CSV bancaire';

  @override
  String get importCsvDesc =>
      'Sélectionnez un export CSV de votre banque. Les rôles des colonnes seront détectés automatiquement.';

  @override
  String get importLoadCsv => 'Charger CSV';

  @override
  String get importFailed =>
      'Échec de l\'importation. Vérifiez le format du fichier.';

  @override
  String importFoundRows(int count, String fileName) {
    return '$count lignes trouvées dans $fileName';
  }

  @override
  String get importColumnMapping => 'Mappage des colonnes';

  @override
  String get importColumnMapDesc =>
      'Attribuez un rôle à chaque colonne. Les rôles ont été détectés automatiquement — ajustez si nécessaire.';

  @override
  String get importPreview => 'Aperçu de l\'importation';

  @override
  String get importNoAmount =>
      'Aucune colonne Montant attribuée. Veuillez mapper au moins une colonne au Montant.';

  @override
  String get importIntoAccount => 'Importer dans le compte';

  @override
  String get importAssignAmount => 'Veuillez attribuer une colonne Montant';

  @override
  String importSuccess(int count) {
    return '$count transactions importées';
  }

  @override
  String importImporting(int count) {
    return 'Importation… ($count)';
  }

  @override
  String importButton(int count) {
    return 'Importer $count transactions';
  }

  @override
  String get importColSkip => 'Ignorer';

  @override
  String get importColDate => 'Date';

  @override
  String get importColDescription => 'Description';

  @override
  String get objPaymentFailed => 'Échec du paiement. Veuillez réessayer.';

  @override
  String get objNoPayments => 'Aucun paiement pour le moment';

  @override
  String objCurrent(String amount) {
    return 'Actuel : $amount';
  }

  @override
  String get objCategoryOptional => 'Catégorie (optionnel)';

  @override
  String get objLoanDirLentHint =>
      'Vous avez prêté — les paiements sont entrants';

  @override
  String get objLoanDirBorrowedHint =>
      'Vous devez — les paiements sont sortants';

  @override
  String get objTargetAmountLabel => 'Montant cible';

  @override
  String objDeadlinePrefix(String date) {
    return 'Échéance : $date';
  }

  @override
  String get objSummaryRemaining => 'Restant';

  @override
  String get objPaymentsSection => 'PAIEMENTS';

  @override
  String get objSettingsSection => 'PARAMÈTRES';

  @override
  String get objTypeSection => 'TYPE';

  @override
  String get objHideSettings => 'Masquer les paramètres';

  @override
  String get objEditSettings => 'Modifier les paramètres';

  @override
  String objOfTarget(String amount) {
    return 'sur $amount';
  }

  @override
  String objReceivedFrom(String amount, String account) {
    return 'Reçu $amount de $account';
  }

  @override
  String objPaidFrom(String amount, String account) {
    return 'Payé $amount depuis $account';
  }

  @override
  String healthPurgeContent(int count, String suffix) {
    return 'Supprimer définitivement $count transaction(s) supprimée(s) et leurs lignes de la base de données ?\n\n$suffix';
  }

  @override
  String healthPurgeButtonN(int count) {
    return 'Purger $count transaction(s) supprimée(s)';
  }

  @override
  String get healthAutoAdjustment => 'Ajustement automatique du bilan de santé';

  @override
  String get healthReportTitle => 'Rapport de santé BudgetSeal';

  @override
  String healthAdjustmentsCreated(int count) {
    return '$count ajustement(s) créé(s)';
  }

  @override
  String healthPurged(int count) {
    return '$count transaction(s) purgée(s)';
  }

  @override
  String get customizeDesc =>
      'Faites glisser pour réorganiser. Basculez pour afficher/masquer les sections.';

  @override
  String get catSheetCategoryName => 'Nom de la catégorie';

  @override
  String get catSheetNoMatch => 'Aucune catégorie correspondante';

  @override
  String get catSheetNoCategories =>
      'Aucune catégorie pour le moment.\nAppuyez sur « Nouveau » ci-dessus pour en créer une.';

  @override
  String syncConnectedTo(String provider) {
    return 'Connecté à $provider';
  }

  @override
  String syncLastSynced(String time, String suffix) {
    return 'Dernière synchro $time$suffix';
  }

  @override
  String syncChangesMerged(int count) {
    return ' · $count modification(s) fusionnée(s)';
  }

  @override
  String get syncUpToDate => ' · à jour';

  @override
  String get languageSystemDesc => 'Suivre les paramètres de l\'appareil';

  @override
  String get dashboardQuickActionsHintTitle => 'Actions rapides';

  @override
  String get dashboardQuickActionsHintBody =>
      'Financer affecte de l\'argent à vos enveloppes. Diviser vous permet de partager une addition.';

  @override
  String fundDistributing(String distributed, String available) {
    return 'Distribution de $distributed sur $available';
  }

  @override
  String catDeleteTxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions utilisent cette catégorie',
      one: '1 transaction utilise cette catégorie',
    );
    return '$_temp0';
  }

  @override
  String catDeleteLinkedEnvelope(String name) {
    return 'liée à l\'enveloppe « $name »';
  }

  @override
  String catDeleteWarning(String warnings) {
    return 'Cette catégorie $warnings.\n\nLa suppression décatégorisera ces transactions et la déliera de l\'enveloppe.\n\nEnvisagez plutôt l\'archivage.';
  }

  @override
  String get subFreqDay => '/jour';

  @override
  String get subFreqWeek => '/semaine';

  @override
  String get subFreqMonth => '/mois';

  @override
  String get subFreqYear => '/an';

  @override
  String subFreqDays(int n) {
    return '/tous les $n jours';
  }

  @override
  String subFreqWeeks(int n) {
    return '/toutes les $n semaines';
  }

  @override
  String subFreqMonths(int n) {
    return '/tous les $n mois';
  }

  @override
  String subFreqYears(int n) {
    return '/tous les $n ans';
  }

  @override
  String subCancelBodyWithTx(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return 'Cela annulera la facturation future et supprimera $_temp0 après le $date.';
  }

  @override
  String subCancelBodyNoTx(String date) {
    return 'Cela définira la date d\'annulation au $date.';
  }

  @override
  String get plannedTitle => 'Paiements planifiés';

  @override
  String get plannedSubtitle => 'Planifiez des paiements ponctuels futurs';

  @override
  String get plannedAddTooltip => 'Ajouter un paiement planifié';

  @override
  String get plannedEmptyTitle => 'Aucun paiement planifié';

  @override
  String get plannedEmptySubtitle =>
      'Planifiez des paiements futurs pour suivre ce que vous prévoyez de dépenser avant de vous engager.';

  @override
  String get plannedPosted => 'Paiement enregistré avec succès';

  @override
  String get plannedPostFailed => 'Échec de l\'enregistrement du paiement';

  @override
  String get plannedPostAllTitle => 'Enregistrer tous les paiements';

  @override
  String plannedPostAllContent(int count, String month) {
    return 'Enregistrer les $count paiements planifiés pour $month ?';
  }

  @override
  String get plannedPostAll => 'Tout enregistrer';

  @override
  String plannedPostAllResult(int count) {
    return '$count paiements enregistrés';
  }

  @override
  String plannedPostAllResultPartial(int posted, int failed) {
    return '$posted enregistrés, $failed échoués';
  }

  @override
  String get plannedDeleteTitle => 'Supprimer le paiement planifié';

  @override
  String get plannedDeleteContent =>
      'Ce paiement sera définitivement supprimé. Cette action est irréversible.';

  @override
  String get plannedDeleted => 'Paiement planifié supprimé';

  @override
  String get plannedDeleteFailed => 'Échec de la suppression du paiement';

  @override
  String get plannedPost => 'Enregistrer';

  @override
  String get plannedChipLabel => 'planifiés';

  @override
  String get plannedTotalLabel => 'total';

  @override
  String get plannedPlanButton => 'Planifier le paiement';

  @override
  String get plannedEditTitle => 'Modifier le paiement planifié';

  @override
  String get plannedTargetMonth => 'Mois cible';

  @override
  String get plannedExactDate => 'Choisir une date précise (optionnel)';

  @override
  String plannedExactDateValue(String date) {
    return 'Date précise : $date';
  }

  @override
  String get plannedSelectAccount => 'Sélectionnez un compte';

  @override
  String get plannedUpdated => 'Paiement planifié mis à jour';

  @override
  String get plannedCreated => 'Paiement planifié';

  @override
  String get plannedSaveFailed =>
      'Impossible d\'enregistrer le paiement planifié';

  @override
  String get plannedBadge => 'Planifié';

  @override
  String plannedNPlanned(String amount) {
    return '$amount planifiés';
  }

  @override
  String travelExchangeSuccess(String fromAmount, String toAmount) {
    return 'Échangé $fromAmount → $toAmount. Ouvrez le portefeuille de voyage et utilisez « Reconvertir et fermer » pour récupérer le solde restant.';
  }

  @override
  String backupRestoreDialogBody(String date, String size) {
    return 'Du : $date\nTaille : $size\n\nCela remplacera vos données actuelles. L\'application devra redémarrer.';
  }

  @override
  String backupAutoEvery(String frequency) {
    return 'Sauvegarde $frequency';
  }

  @override
  String backupLastAutoBackup(String date) {
    return 'Dernière sauvegarde auto : $date';
  }

  @override
  String get recurringFormCategory => 'Catégorie (optionnel)';

  @override
  String get txDetailSaveAsTemplate => 'Enregistrer comme modèle';

  @override
  String get txDetailTemplateSaved => 'Modèle enregistré';

  @override
  String get txDetailTemplateError => 'Impossible d\'enregistrer le modèle';

  @override
  String get tileArabicDigits => 'Chiffres arabo-indiens';

  @override
  String get upgradeTitle => 'Passer au Premium';

  @override
  String get upgradeSubtitle =>
      'Débloquez toutes les fonctionnalités avec un seul achat. Sans abonnement, sans publicité.';

  @override
  String get upgradeFeatureSync => 'Synchronisation cloud';

  @override
  String get upgradeFeatureWebCompanion => 'Compagnon Web';

  @override
  String get upgradeFeatureBillSplitter => 'Partage de facture';

  @override
  String get upgradeFeatureTravelExchange => 'Change de voyage';

  @override
  String get upgradeFeaturePlannedPayments => 'Paiements planifiés';

  @override
  String get upgradeFeatureUnlimitedItems => 'Comptes et enveloppes illimités';

  @override
  String get upgradePrice => '4,99 \$';

  @override
  String get upgradePriceSubtitle => 'Achat unique. À vous pour toujours.';

  @override
  String get upgradeButton => 'Mettre à niveau';

  @override
  String get upgradeComingSoon => 'Achats intégrés bientôt disponibles';

  @override
  String get upgradeRedeemCode => 'Utiliser un code';

  @override
  String get upgradeRedeemHint => 'Entrez votre code';

  @override
  String get upgradeRedeemButton => 'Utiliser';

  @override
  String get upgradeRedeemInvalid => 'Code invalide. Veuillez réessayer.';

  @override
  String get upgradeRedeemSuccess => 'Code utilisé ! Premium débloqué.';

  @override
  String get upgradeRestorePurchase => 'Restaurer l\'achat';

  @override
  String get upgradeRestoreSuccess => 'Achat restauré ! Premium débloqué.';

  @override
  String get upgradeRestoreNone => 'Aucun achat précédent trouvé.';

  @override
  String get catSheetSearchHint => 'Rechercher des catégories...';

  @override
  String catSheetSubcategories(int count) {
    return '$count sous-catégories';
  }

  @override
  String get objSummaryDeadline => 'Échéance';

  @override
  String get plannedNoteHint => 'Note (optionnel)';

  @override
  String get recurringFormAccountRequired => 'Le compte est requis';

  @override
  String recurringFormStarts(String date) {
    return 'Début : $date';
  }
}
