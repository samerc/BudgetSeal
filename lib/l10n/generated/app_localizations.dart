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

  /// No description provided for @currencyNameAfn.
  ///
  /// In en, this message translates to:
  /// **'Afghan Afghani'**
  String get currencyNameAfn;

  /// No description provided for @currencyNameAll.
  ///
  /// In en, this message translates to:
  /// **'Albanian Lek'**
  String get currencyNameAll;

  /// No description provided for @currencyNameAmd.
  ///
  /// In en, this message translates to:
  /// **'Armenian Dram'**
  String get currencyNameAmd;

  /// No description provided for @currencyNameAng.
  ///
  /// In en, this message translates to:
  /// **'Netherlands Antillean Guilder'**
  String get currencyNameAng;

  /// No description provided for @currencyNameAoa.
  ///
  /// In en, this message translates to:
  /// **'Angolan Kwanza'**
  String get currencyNameAoa;

  /// No description provided for @currencyNameArs.
  ///
  /// In en, this message translates to:
  /// **'Argentine Peso'**
  String get currencyNameArs;

  /// No description provided for @currencyNameAwg.
  ///
  /// In en, this message translates to:
  /// **'Aruban Florin'**
  String get currencyNameAwg;

  /// No description provided for @currencyNameAzn.
  ///
  /// In en, this message translates to:
  /// **'Azerbaijani Manat'**
  String get currencyNameAzn;

  /// No description provided for @currencyNameBam.
  ///
  /// In en, this message translates to:
  /// **'Bosnia-Herzegovina Convertible Mark'**
  String get currencyNameBam;

  /// No description provided for @currencyNameBbd.
  ///
  /// In en, this message translates to:
  /// **'Barbadian Dollar'**
  String get currencyNameBbd;

  /// No description provided for @currencyNameBdt.
  ///
  /// In en, this message translates to:
  /// **'Bangladeshi Taka'**
  String get currencyNameBdt;

  /// No description provided for @currencyNameBgn.
  ///
  /// In en, this message translates to:
  /// **'Bulgarian Lev'**
  String get currencyNameBgn;

  /// No description provided for @currencyNameBhd.
  ///
  /// In en, this message translates to:
  /// **'Bahraini Dinar'**
  String get currencyNameBhd;

  /// No description provided for @currencyNameBif.
  ///
  /// In en, this message translates to:
  /// **'Burundian Franc'**
  String get currencyNameBif;

  /// No description provided for @currencyNameBmd.
  ///
  /// In en, this message translates to:
  /// **'Bermudian Dollar'**
  String get currencyNameBmd;

  /// No description provided for @currencyNameBnd.
  ///
  /// In en, this message translates to:
  /// **'Brunei Dollar'**
  String get currencyNameBnd;

  /// No description provided for @currencyNameBob.
  ///
  /// In en, this message translates to:
  /// **'Bolivian Boliviano'**
  String get currencyNameBob;

  /// No description provided for @currencyNameBsd.
  ///
  /// In en, this message translates to:
  /// **'Bahamian Dollar'**
  String get currencyNameBsd;

  /// No description provided for @currencyNameBtn.
  ///
  /// In en, this message translates to:
  /// **'Bhutanese Ngultrum'**
  String get currencyNameBtn;

  /// No description provided for @currencyNameBwp.
  ///
  /// In en, this message translates to:
  /// **'Botswana Pula'**
  String get currencyNameBwp;

  /// No description provided for @currencyNameByn.
  ///
  /// In en, this message translates to:
  /// **'Belarusian Ruble'**
  String get currencyNameByn;

  /// No description provided for @currencyNameBzd.
  ///
  /// In en, this message translates to:
  /// **'Belize Dollar'**
  String get currencyNameBzd;

  /// No description provided for @currencyNameCdf.
  ///
  /// In en, this message translates to:
  /// **'Congolese Franc'**
  String get currencyNameCdf;

  /// No description provided for @currencyNameClp.
  ///
  /// In en, this message translates to:
  /// **'Chilean Peso'**
  String get currencyNameClp;

  /// No description provided for @currencyNameCop.
  ///
  /// In en, this message translates to:
  /// **'Colombian Peso'**
  String get currencyNameCop;

  /// No description provided for @currencyNameCrc.
  ///
  /// In en, this message translates to:
  /// **'Costa Rican Colón'**
  String get currencyNameCrc;

  /// No description provided for @currencyNameCup.
  ///
  /// In en, this message translates to:
  /// **'Cuban Peso'**
  String get currencyNameCup;

  /// No description provided for @currencyNameCve.
  ///
  /// In en, this message translates to:
  /// **'Cape Verdean Escudo'**
  String get currencyNameCve;

  /// No description provided for @currencyNameCzk.
  ///
  /// In en, this message translates to:
  /// **'Czech Koruna'**
  String get currencyNameCzk;

  /// No description provided for @currencyNameDjf.
  ///
  /// In en, this message translates to:
  /// **'Djiboutian Franc'**
  String get currencyNameDjf;

  /// No description provided for @currencyNameDkk.
  ///
  /// In en, this message translates to:
  /// **'Danish Krone'**
  String get currencyNameDkk;

  /// No description provided for @currencyNameDop.
  ///
  /// In en, this message translates to:
  /// **'Dominican Peso'**
  String get currencyNameDop;

  /// No description provided for @currencyNameDzd.
  ///
  /// In en, this message translates to:
  /// **'Algerian Dinar'**
  String get currencyNameDzd;

  /// No description provided for @currencyNameEgp.
  ///
  /// In en, this message translates to:
  /// **'Egyptian Pound'**
  String get currencyNameEgp;

  /// No description provided for @currencyNameErn.
  ///
  /// In en, this message translates to:
  /// **'Eritrean Nakfa'**
  String get currencyNameErn;

  /// No description provided for @currencyNameEtb.
  ///
  /// In en, this message translates to:
  /// **'Ethiopian Birr'**
  String get currencyNameEtb;

  /// No description provided for @currencyNameFjd.
  ///
  /// In en, this message translates to:
  /// **'Fijian Dollar'**
  String get currencyNameFjd;

  /// No description provided for @currencyNameFkp.
  ///
  /// In en, this message translates to:
  /// **'Falkland Islands Pound'**
  String get currencyNameFkp;

  /// No description provided for @currencyNameGel.
  ///
  /// In en, this message translates to:
  /// **'Georgian Lari'**
  String get currencyNameGel;

  /// No description provided for @currencyNameGhs.
  ///
  /// In en, this message translates to:
  /// **'Ghanaian Cedi'**
  String get currencyNameGhs;

  /// No description provided for @currencyNameGip.
  ///
  /// In en, this message translates to:
  /// **'Gibraltar Pound'**
  String get currencyNameGip;

  /// No description provided for @currencyNameGmd.
  ///
  /// In en, this message translates to:
  /// **'Gambian Dalasi'**
  String get currencyNameGmd;

  /// No description provided for @currencyNameGnf.
  ///
  /// In en, this message translates to:
  /// **'Guinean Franc'**
  String get currencyNameGnf;

  /// No description provided for @currencyNameGtq.
  ///
  /// In en, this message translates to:
  /// **'Guatemalan Quetzal'**
  String get currencyNameGtq;

  /// No description provided for @currencyNameGyd.
  ///
  /// In en, this message translates to:
  /// **'Guyanese Dollar'**
  String get currencyNameGyd;

  /// No description provided for @currencyNameHnl.
  ///
  /// In en, this message translates to:
  /// **'Honduran Lempira'**
  String get currencyNameHnl;

  /// No description provided for @currencyNameHtg.
  ///
  /// In en, this message translates to:
  /// **'Haitian Gourde'**
  String get currencyNameHtg;

  /// No description provided for @currencyNameHuf.
  ///
  /// In en, this message translates to:
  /// **'Hungarian Forint'**
  String get currencyNameHuf;

  /// No description provided for @currencyNameIdr.
  ///
  /// In en, this message translates to:
  /// **'Indonesian Rupiah'**
  String get currencyNameIdr;

  /// No description provided for @currencyNameIls.
  ///
  /// In en, this message translates to:
  /// **'Israeli New Shekel'**
  String get currencyNameIls;

  /// No description provided for @currencyNameIqd.
  ///
  /// In en, this message translates to:
  /// **'Iraqi Dinar'**
  String get currencyNameIqd;

  /// No description provided for @currencyNameIrr.
  ///
  /// In en, this message translates to:
  /// **'Iranian Rial'**
  String get currencyNameIrr;

  /// No description provided for @currencyNameIsk.
  ///
  /// In en, this message translates to:
  /// **'Icelandic Króna'**
  String get currencyNameIsk;

  /// No description provided for @currencyNameJmd.
  ///
  /// In en, this message translates to:
  /// **'Jamaican Dollar'**
  String get currencyNameJmd;

  /// No description provided for @currencyNameJod.
  ///
  /// In en, this message translates to:
  /// **'Jordanian Dinar'**
  String get currencyNameJod;

  /// No description provided for @currencyNameKes.
  ///
  /// In en, this message translates to:
  /// **'Kenyan Shilling'**
  String get currencyNameKes;

  /// No description provided for @currencyNameKgs.
  ///
  /// In en, this message translates to:
  /// **'Kyrgyzstani Som'**
  String get currencyNameKgs;

  /// No description provided for @currencyNameKhr.
  ///
  /// In en, this message translates to:
  /// **'Cambodian Riel'**
  String get currencyNameKhr;

  /// No description provided for @currencyNameKmf.
  ///
  /// In en, this message translates to:
  /// **'Comorian Franc'**
  String get currencyNameKmf;

  /// No description provided for @currencyNameKpw.
  ///
  /// In en, this message translates to:
  /// **'North Korean Won'**
  String get currencyNameKpw;

  /// No description provided for @currencyNameKrw.
  ///
  /// In en, this message translates to:
  /// **'South Korean Won'**
  String get currencyNameKrw;

  /// No description provided for @currencyNameKyd.
  ///
  /// In en, this message translates to:
  /// **'Cayman Islands Dollar'**
  String get currencyNameKyd;

  /// No description provided for @currencyNameKzt.
  ///
  /// In en, this message translates to:
  /// **'Kazakhstani Tenge'**
  String get currencyNameKzt;

  /// No description provided for @currencyNameLak.
  ///
  /// In en, this message translates to:
  /// **'Lao Kip'**
  String get currencyNameLak;

  /// No description provided for @currencyNameLkr.
  ///
  /// In en, this message translates to:
  /// **'Sri Lankan Rupee'**
  String get currencyNameLkr;

  /// No description provided for @currencyNameLrd.
  ///
  /// In en, this message translates to:
  /// **'Liberian Dollar'**
  String get currencyNameLrd;

  /// No description provided for @currencyNameLsl.
  ///
  /// In en, this message translates to:
  /// **'Lesotho Loti'**
  String get currencyNameLsl;

  /// No description provided for @currencyNameLyd.
  ///
  /// In en, this message translates to:
  /// **'Libyan Dinar'**
  String get currencyNameLyd;

  /// No description provided for @currencyNameMad.
  ///
  /// In en, this message translates to:
  /// **'Moroccan Dirham'**
  String get currencyNameMad;

  /// No description provided for @currencyNameMdl.
  ///
  /// In en, this message translates to:
  /// **'Moldovan Leu'**
  String get currencyNameMdl;

  /// No description provided for @currencyNameMga.
  ///
  /// In en, this message translates to:
  /// **'Malagasy Ariary'**
  String get currencyNameMga;

  /// No description provided for @currencyNameMkd.
  ///
  /// In en, this message translates to:
  /// **'Macedonian Denar'**
  String get currencyNameMkd;

  /// No description provided for @currencyNameMmk.
  ///
  /// In en, this message translates to:
  /// **'Myanmar Kyat'**
  String get currencyNameMmk;

  /// No description provided for @currencyNameMnt.
  ///
  /// In en, this message translates to:
  /// **'Mongolian Tögrög'**
  String get currencyNameMnt;

  /// No description provided for @currencyNameMop.
  ///
  /// In en, this message translates to:
  /// **'Macanese Pataca'**
  String get currencyNameMop;

  /// No description provided for @currencyNameMru.
  ///
  /// In en, this message translates to:
  /// **'Mauritanian Ouguiya'**
  String get currencyNameMru;

  /// No description provided for @currencyNameMur.
  ///
  /// In en, this message translates to:
  /// **'Mauritian Rupee'**
  String get currencyNameMur;

  /// No description provided for @currencyNameMvr.
  ///
  /// In en, this message translates to:
  /// **'Maldivian Rufiyaa'**
  String get currencyNameMvr;

  /// No description provided for @currencyNameMwk.
  ///
  /// In en, this message translates to:
  /// **'Malawian Kwacha'**
  String get currencyNameMwk;

  /// No description provided for @currencyNameMyr.
  ///
  /// In en, this message translates to:
  /// **'Malaysian Ringgit'**
  String get currencyNameMyr;

  /// No description provided for @currencyNameMzn.
  ///
  /// In en, this message translates to:
  /// **'Mozambican Metical'**
  String get currencyNameMzn;

  /// No description provided for @currencyNameNad.
  ///
  /// In en, this message translates to:
  /// **'Namibian Dollar'**
  String get currencyNameNad;

  /// No description provided for @currencyNameNgn.
  ///
  /// In en, this message translates to:
  /// **'Nigerian Naira'**
  String get currencyNameNgn;

  /// No description provided for @currencyNameNio.
  ///
  /// In en, this message translates to:
  /// **'Nicaraguan Córdoba'**
  String get currencyNameNio;

  /// No description provided for @currencyNameNpr.
  ///
  /// In en, this message translates to:
  /// **'Nepalese Rupee'**
  String get currencyNameNpr;

  /// No description provided for @currencyNameOmr.
  ///
  /// In en, this message translates to:
  /// **'Omani Rial'**
  String get currencyNameOmr;

  /// No description provided for @currencyNamePab.
  ///
  /// In en, this message translates to:
  /// **'Panamanian Balboa'**
  String get currencyNamePab;

  /// No description provided for @currencyNamePen.
  ///
  /// In en, this message translates to:
  /// **'Peruvian Sol'**
  String get currencyNamePen;

  /// No description provided for @currencyNamePgk.
  ///
  /// In en, this message translates to:
  /// **'Papua New Guinean Kina'**
  String get currencyNamePgk;

  /// No description provided for @currencyNamePhp.
  ///
  /// In en, this message translates to:
  /// **'Philippine Peso'**
  String get currencyNamePhp;

  /// No description provided for @currencyNamePkr.
  ///
  /// In en, this message translates to:
  /// **'Pakistani Rupee'**
  String get currencyNamePkr;

  /// No description provided for @currencyNamePln.
  ///
  /// In en, this message translates to:
  /// **'Polish Złoty'**
  String get currencyNamePln;

  /// No description provided for @currencyNamePyg.
  ///
  /// In en, this message translates to:
  /// **'Paraguayan Guaraní'**
  String get currencyNamePyg;

  /// No description provided for @currencyNameQar.
  ///
  /// In en, this message translates to:
  /// **'Qatari Riyal'**
  String get currencyNameQar;

  /// No description provided for @currencyNameRon.
  ///
  /// In en, this message translates to:
  /// **'Romanian Leu'**
  String get currencyNameRon;

  /// No description provided for @currencyNameRsd.
  ///
  /// In en, this message translates to:
  /// **'Serbian Dinar'**
  String get currencyNameRsd;

  /// No description provided for @currencyNameRub.
  ///
  /// In en, this message translates to:
  /// **'Russian Ruble'**
  String get currencyNameRub;

  /// No description provided for @currencyNameRwf.
  ///
  /// In en, this message translates to:
  /// **'Rwandan Franc'**
  String get currencyNameRwf;

  /// No description provided for @currencyNameSbd.
  ///
  /// In en, this message translates to:
  /// **'Solomon Islands Dollar'**
  String get currencyNameSbd;

  /// No description provided for @currencyNameScr.
  ///
  /// In en, this message translates to:
  /// **'Seychellois Rupee'**
  String get currencyNameScr;

  /// No description provided for @currencyNameSdg.
  ///
  /// In en, this message translates to:
  /// **'Sudanese Pound'**
  String get currencyNameSdg;

  /// No description provided for @currencyNameShp.
  ///
  /// In en, this message translates to:
  /// **'Saint Helena Pound'**
  String get currencyNameShp;

  /// No description provided for @currencyNameSle.
  ///
  /// In en, this message translates to:
  /// **'Sierra Leonean Leone'**
  String get currencyNameSle;

  /// No description provided for @currencyNameSos.
  ///
  /// In en, this message translates to:
  /// **'Somali Shilling'**
  String get currencyNameSos;

  /// No description provided for @currencyNameSrd.
  ///
  /// In en, this message translates to:
  /// **'Surinamese Dollar'**
  String get currencyNameSrd;

  /// No description provided for @currencyNameSsp.
  ///
  /// In en, this message translates to:
  /// **'South Sudanese Pound'**
  String get currencyNameSsp;

  /// No description provided for @currencyNameStn.
  ///
  /// In en, this message translates to:
  /// **'São Tomé and Príncipe Dobra'**
  String get currencyNameStn;

  /// No description provided for @currencyNameSyp.
  ///
  /// In en, this message translates to:
  /// **'Syrian Pound'**
  String get currencyNameSyp;

  /// No description provided for @currencyNameSzl.
  ///
  /// In en, this message translates to:
  /// **'Swazi Lilangeni'**
  String get currencyNameSzl;

  /// No description provided for @currencyNameThb.
  ///
  /// In en, this message translates to:
  /// **'Thai Baht'**
  String get currencyNameThb;

  /// No description provided for @currencyNameTjs.
  ///
  /// In en, this message translates to:
  /// **'Tajikistani Somoni'**
  String get currencyNameTjs;

  /// No description provided for @currencyNameTmt.
  ///
  /// In en, this message translates to:
  /// **'Turkmenistan Manat'**
  String get currencyNameTmt;

  /// No description provided for @currencyNameTnd.
  ///
  /// In en, this message translates to:
  /// **'Tunisian Dinar'**
  String get currencyNameTnd;

  /// No description provided for @currencyNameTop.
  ///
  /// In en, this message translates to:
  /// **'Tongan Paʻanga'**
  String get currencyNameTop;

  /// No description provided for @currencyNameTtd.
  ///
  /// In en, this message translates to:
  /// **'Trinidad and Tobago Dollar'**
  String get currencyNameTtd;

  /// No description provided for @currencyNameTwd.
  ///
  /// In en, this message translates to:
  /// **'New Taiwan Dollar'**
  String get currencyNameTwd;

  /// No description provided for @currencyNameTzs.
  ///
  /// In en, this message translates to:
  /// **'Tanzanian Shilling'**
  String get currencyNameTzs;

  /// No description provided for @currencyNameUah.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian Hryvnia'**
  String get currencyNameUah;

  /// No description provided for @currencyNameUgx.
  ///
  /// In en, this message translates to:
  /// **'Ugandan Shilling'**
  String get currencyNameUgx;

  /// No description provided for @currencyNameUyu.
  ///
  /// In en, this message translates to:
  /// **'Uruguayan Peso'**
  String get currencyNameUyu;

  /// No description provided for @currencyNameUzs.
  ///
  /// In en, this message translates to:
  /// **'Uzbekistani Som'**
  String get currencyNameUzs;

  /// No description provided for @currencyNameVes.
  ///
  /// In en, this message translates to:
  /// **'Venezuelan Bolívar'**
  String get currencyNameVes;

  /// No description provided for @currencyNameVnd.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese Đồng'**
  String get currencyNameVnd;

  /// No description provided for @currencyNameVuv.
  ///
  /// In en, this message translates to:
  /// **'Vanuatu Vatu'**
  String get currencyNameVuv;

  /// No description provided for @currencyNameWst.
  ///
  /// In en, this message translates to:
  /// **'Samoan Tālā'**
  String get currencyNameWst;

  /// No description provided for @currencyNameXaf.
  ///
  /// In en, this message translates to:
  /// **'Central African CFA Franc'**
  String get currencyNameXaf;

  /// No description provided for @currencyNameXcd.
  ///
  /// In en, this message translates to:
  /// **'East Caribbean Dollar'**
  String get currencyNameXcd;

  /// No description provided for @currencyNameXof.
  ///
  /// In en, this message translates to:
  /// **'West African CFA Franc'**
  String get currencyNameXof;

  /// No description provided for @currencyNameXpf.
  ///
  /// In en, this message translates to:
  /// **'CFP Franc'**
  String get currencyNameXpf;

  /// No description provided for @currencyNameYer.
  ///
  /// In en, this message translates to:
  /// **'Yemeni Rial'**
  String get currencyNameYer;

  /// No description provided for @currencyNameZmw.
  ///
  /// In en, this message translates to:
  /// **'Zambian Kwacha'**
  String get currencyNameZmw;

  /// No description provided for @currencyNameZwg.
  ///
  /// In en, this message translates to:
  /// **'Zimbabwe Gold'**
  String get currencyNameZwg;

  /// No description provided for @travelWalletName.
  ///
  /// In en, this message translates to:
  /// **'Travel - {currency}'**
  String travelWalletName(String currency);

  /// No description provided for @travelAddsToWallet.
  ///
  /// In en, this message translates to:
  /// **'Adds to your {wallet} wallet'**
  String travelAddsToWallet(String wallet);

  /// No description provided for @travelExchangeTopUp.
  ///
  /// In en, this message translates to:
  /// **'Exchange & add to wallet'**
  String get travelExchangeTopUp;

  /// No description provided for @travelOverBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'More than this account holds'**
  String get travelOverBalanceTitle;

  /// No description provided for @travelOverBalanceMsg.
  ///
  /// In en, this message translates to:
  /// **'{account} holds {balance}. After this exchange it will be {after}.'**
  String travelOverBalanceMsg(String account, String balance, String after);

  /// No description provided for @travelExchangeAnyway.
  ///
  /// In en, this message translates to:
  /// **'Exchange anyway'**
  String get travelExchangeAnyway;

  /// No description provided for @acctBalanceChanged.
  ///
  /// In en, this message translates to:
  /// **'This wallet\'s balance just changed. Check the new amount and try again.'**
  String get acctBalanceChanged;

  /// No description provided for @plannedTotalOther.
  ///
  /// In en, this message translates to:
  /// **'total + other currencies'**
  String get plannedTotalOther;

  /// No description provided for @syncOtherBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Another budget is already synced here'**
  String get syncOtherBudgetTitle;

  /// No description provided for @syncOtherBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'This account\'s sync file holds a budget made on another device. Use it on this device? It replaces the data on this device; a backup of it is saved first in Backup & Restore.'**
  String get syncOtherBudgetBody;

  /// No description provided for @syncUseSyncedBudget.
  ///
  /// In en, this message translates to:
  /// **'Use the synced budget'**
  String get syncUseSyncedBudget;

  /// No description provided for @syncErrWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong sync password. Use the same password as on your other device.'**
  String get syncErrWrongPassword;

  /// No description provided for @syncErrCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The sync file couldn\'t be read. Sync again from your other device.'**
  String get syncErrCorrupt;

  /// No description provided for @syncErrTooNew.
  ///
  /// In en, this message translates to:
  /// **'This file was made by a newer version of BudgetSeal. Update the app, then try again.'**
  String get syncErrTooNew;

  /// No description provided for @syncErrSignedOut.
  ///
  /// In en, this message translates to:
  /// **'You were signed out of Google Drive. Connect again to keep syncing.'**
  String get syncErrSignedOut;

  /// No description provided for @syncErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sync didn\'t finish. Please try again in a moment.'**
  String get syncErrGeneric;

  /// No description provided for @syncErrBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t back up your current data, so nothing was replaced.'**
  String get syncErrBackupFailed;

  /// No description provided for @wcBrowsersConnected.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No browser connected} =1{1 browser connected} other{{n} browsers connected}}'**
  String wcBrowsersConnected(int n);

  /// No description provided for @wcBrowsersHint.
  ///
  /// In en, this message translates to:
  /// **'A browser counts while its page is open.'**
  String get wcBrowsersHint;

  /// No description provided for @wcSignOutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out all'**
  String get wcSignOutAll;

  /// No description provided for @wcSignedOutAll.
  ///
  /// In en, this message translates to:
  /// **'All browsers signed out — they need the PIN again'**
  String get wcSignedOutAll;

  /// No description provided for @webImportBtn.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get webImportBtn;

  /// No description provided for @webImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import a CSV file'**
  String get webImportTitle;

  /// No description provided for @webImportSub.
  ///
  /// In en, this message translates to:
  /// **'Bring in a bank statement or a spreadsheet. Rows already in BudgetSeal are skipped.'**
  String get webImportSub;

  /// No description provided for @webImportChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a CSV file, or drop it here'**
  String get webImportChoose;

  /// No description provided for @webImportChooseHint.
  ///
  /// In en, this message translates to:
  /// **'It needs a date and an amount (or debit and credit) column. Commas, semicolons and tabs all work.'**
  String get webImportChooseHint;

  /// No description provided for @webImportRowsFound.
  ///
  /// In en, this message translates to:
  /// **'Rows found: {n} · choose another file'**
  String webImportRowsFound(int n);

  /// No description provided for @webImportTooBig.
  ///
  /// In en, this message translates to:
  /// **'That file is over 5 MB.'**
  String get webImportTooBig;

  /// No description provided for @webImportUnreadableFile.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that file as CSV.'**
  String get webImportUnreadableFile;

  /// No description provided for @webImportColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get webImportColumns;

  /// No description provided for @webImportColumnN.
  ///
  /// In en, this message translates to:
  /// **'Column {n}'**
  String webImportColumnN(int n);

  /// No description provided for @webImportHasHeader.
  ///
  /// In en, this message translates to:
  /// **'First row is a header'**
  String get webImportHasHeader;

  /// No description provided for @webImportRoleSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get webImportRoleSkip;

  /// No description provided for @webImportRoleDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get webImportRoleDate;

  /// No description provided for @webImportRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get webImportRoleDescription;

  /// No description provided for @webImportRoleAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (±)'**
  String get webImportRoleAmount;

  /// No description provided for @webImportRoleDebit.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get webImportRoleDebit;

  /// No description provided for @webImportRoleCredit.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get webImportRoleCredit;

  /// No description provided for @webImportRoleCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get webImportRoleCategory;

  /// No description provided for @webImportPreview.
  ///
  /// In en, this message translates to:
  /// **'How it will look'**
  String get webImportPreview;

  /// No description provided for @webImportNeedCols.
  ///
  /// In en, this message translates to:
  /// **'Pick a Date column and an Amount column (or Money out / Money in).'**
  String get webImportNeedCols;

  /// No description provided for @webImportInto.
  ///
  /// In en, this message translates to:
  /// **'Import into'**
  String get webImportInto;

  /// No description provided for @webImportReadyRows.
  ///
  /// In en, this message translates to:
  /// **'rows ready'**
  String get webImportReadyRows;

  /// No description provided for @webImportUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Rows without a readable date or amount: {n}'**
  String webImportUnreadable(int n);

  /// No description provided for @webImportCheck.
  ///
  /// In en, this message translates to:
  /// **'Check & import'**
  String get webImportCheck;

  /// No description provided for @webImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import these transactions?'**
  String get webImportConfirmTitle;

  /// No description provided for @webImportWillAdd.
  ///
  /// In en, this message translates to:
  /// **'New transactions for {account}: {n}'**
  String webImportWillAdd(String account, int n);

  /// No description provided for @webImportCategorized.
  ///
  /// In en, this message translates to:
  /// **'With a category (matched or guessed from your past titles): {n}'**
  String webImportCategorized(int n);

  /// No description provided for @webImportDupes.
  ///
  /// In en, this message translates to:
  /// **'Already in BudgetSeal, skipped: {n}'**
  String webImportDupes(int n);

  /// No description provided for @webImportGo.
  ///
  /// In en, this message translates to:
  /// **'Import {n}'**
  String webImportGo(int n);

  /// No description provided for @webImportNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new — all {n} rows are already in BudgetSeal.'**
  String webImportNothingNew(int n);

  /// No description provided for @webImportDone.
  ///
  /// In en, this message translates to:
  /// **'Imported: {n}'**
  String webImportDone(int n);

  /// No description provided for @webAcctReconciledOn.
  ///
  /// In en, this message translates to:
  /// **'Reconciled {date}'**
  String webAcctReconciledOn(String date);

  /// No description provided for @webAcctNeverReconciled.
  ///
  /// In en, this message translates to:
  /// **'Never reconciled'**
  String get webAcctNeverReconciled;

  /// No description provided for @webAcctReconcile.
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get webAcctReconcile;

  /// No description provided for @webAcctReconcileTitle.
  ///
  /// In en, this message translates to:
  /// **'Reconcile {name}'**
  String webAcctReconcileTitle(String name);

  /// No description provided for @webAcctReconcileHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the balance your bank or wallet shows right now. If it differs, a “Balance adjustment” is recorded so they match.'**
  String get webAcctReconcileHelp;

  /// No description provided for @webAcctStatementBalance.
  ///
  /// In en, this message translates to:
  /// **'Actual balance'**
  String get webAcctStatementBalance;

  /// No description provided for @webAcctReconcileMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches — nothing to adjust.'**
  String get webAcctReconcileMatches;

  /// No description provided for @webAcctReconcileDiff.
  ///
  /// In en, this message translates to:
  /// **'An adjustment of {amount} will be recorded.'**
  String webAcctReconcileDiff(String amount);

  /// No description provided for @webAcctReconciled.
  ///
  /// In en, this message translates to:
  /// **'Reconciled — it matches'**
  String get webAcctReconciled;

  /// No description provided for @webAcctAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Reconciled — adjusted by {amount}'**
  String webAcctAdjusted(String amount);

  /// No description provided for @webAcctEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get webAcctEdit;

  /// No description provided for @webAcctDecimals.
  ///
  /// In en, this message translates to:
  /// **'Decimal places'**
  String get webAcctDecimals;

  /// No description provided for @webAcctDecimalsAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto ({n})'**
  String webAcctDecimalsAuto(int n);

  /// No description provided for @webAcctStartingBalance.
  ///
  /// In en, this message translates to:
  /// **'Starting balance'**
  String get webAcctStartingBalance;

  /// No description provided for @webAcctStartingHelp.
  ///
  /// In en, this message translates to:
  /// **'What the account held before your first transaction. Changing it moves every balance after it.'**
  String get webAcctStartingHelp;

  /// No description provided for @webAcctSaved.
  ///
  /// In en, this message translates to:
  /// **'Account saved'**
  String get webAcctSaved;

  /// No description provided for @webAcctArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get webAcctArchive;

  /// No description provided for @webAcctArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String webAcctArchiveTitle(String name);

  /// No description provided for @webAcctArchiveMsg.
  ///
  /// In en, this message translates to:
  /// **'It’s hidden from lists and pickers. Its transactions stay, and you can unarchive it any time.'**
  String get webAcctArchiveMsg;

  /// No description provided for @webAcctArchiveNotZero.
  ///
  /// In en, this message translates to:
  /// **'This account still holds {amount}. Move it to another account or reconcile it to zero first — archived accounts no longer count toward your money.'**
  String webAcctArchiveNotZero(String amount);

  /// No description provided for @webAcctArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get webAcctArchived;

  /// No description provided for @webAcctArchivedSection.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get webAcctArchivedSection;

  /// No description provided for @webAcctArchivedToast.
  ///
  /// In en, this message translates to:
  /// **'Account archived'**
  String get webAcctArchivedToast;

  /// No description provided for @webAcctUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get webAcctUnarchive;

  /// No description provided for @webAcctUnarchived.
  ///
  /// In en, this message translates to:
  /// **'Account restored'**
  String get webAcctUnarchived;

  /// No description provided for @webNavUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get webNavUpcoming;

  /// No description provided for @webUpSub.
  ///
  /// In en, this message translates to:
  /// **'Bills coming up and payments you’ve planned. Nothing here touches your balances until it’s posted.'**
  String get webUpSub;

  /// No description provided for @webUpBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get webUpBills;

  /// No description provided for @webUpDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String webUpDays(int n);

  /// No description provided for @webUpTotalOut.
  ///
  /// In en, this message translates to:
  /// **'Bills, next {n} days'**
  String webUpTotalOut(int n);

  /// No description provided for @webUpTotalIn.
  ///
  /// In en, this message translates to:
  /// **'+ {amount} coming in'**
  String webUpTotalIn(String amount);

  /// No description provided for @webUpSubTag.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get webUpSubTag;

  /// No description provided for @webUpOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {n} days'**
  String webUpOverdue(int n);

  /// No description provided for @webUpToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get webUpToday;

  /// No description provided for @webUpTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get webUpTomorrow;

  /// No description provided for @webUpInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {n} days'**
  String webUpInDays(int n);

  /// No description provided for @webUpNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in the next {n} days'**
  String webUpNone(int n);

  /// No description provided for @webUpNoneSub.
  ///
  /// In en, this message translates to:
  /// **'Recurring items and subscriptions show up here before they post.'**
  String get webUpNoneSub;

  /// No description provided for @webUpPostNow.
  ///
  /// In en, this message translates to:
  /// **'Post now'**
  String get webUpPostNow;

  /// No description provided for @webUpSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this one'**
  String get webUpSkip;

  /// No description provided for @webUpPostHelp.
  ///
  /// In en, this message translates to:
  /// **'Post now records it today. Skip records nothing. Either way the next date moves on.'**
  String get webUpPostHelp;

  /// No description provided for @webUpPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get webUpPosted;

  /// No description provided for @webUpSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get webUpSkipped;

  /// No description provided for @webPlanSection.
  ///
  /// In en, this message translates to:
  /// **'Planned payments'**
  String get webPlanSection;

  /// No description provided for @webPlanAdd.
  ///
  /// In en, this message translates to:
  /// **'Plan a payment'**
  String get webPlanAdd;

  /// No description provided for @webPlanEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit planned payment'**
  String get webPlanEdit;

  /// No description provided for @webPlanSave.
  ///
  /// In en, this message translates to:
  /// **'Plan it'**
  String get webPlanSave;

  /// No description provided for @webPlanDate.
  ///
  /// In en, this message translates to:
  /// **'Planned for'**
  String get webPlanDate;

  /// No description provided for @webPlanNeedDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date.'**
  String get webPlanNeedDate;

  /// No description provided for @webPlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'No planned payments'**
  String get webPlanEmpty;

  /// No description provided for @webPlanEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Plan a one-time payment ahead — it won’t touch your balances until you post it.'**
  String get webPlanEmptySub;

  /// No description provided for @webPlanPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get webPlanPost;

  /// No description provided for @webPlanPostHelp.
  ///
  /// In en, this message translates to:
  /// **'Posting records it as a real transaction on its planned date.'**
  String get webPlanPostHelp;

  /// No description provided for @webPlanPostAll.
  ///
  /// In en, this message translates to:
  /// **'Post all'**
  String get webPlanPostAll;

  /// No description provided for @webPlanPostAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Post these payments?'**
  String get webPlanPostAllTitle;

  /// No description provided for @webPlanPostAllMsg.
  ///
  /// In en, this message translates to:
  /// **'Payments to post: {n}. Each becomes a real transaction on its planned date.'**
  String webPlanPostAllMsg(int n);

  /// No description provided for @webPlanPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted: {n}'**
  String webPlanPosted(int n);

  /// No description provided for @webPlanPostPartial.
  ///
  /// In en, this message translates to:
  /// **'Posted: {n} · not posted: {failed} (no exchange rate)'**
  String webPlanPostPartial(int n, String failed);

  /// No description provided for @webPlanAdded.
  ///
  /// In en, this message translates to:
  /// **'Payment planned'**
  String get webPlanAdded;

  /// No description provided for @webPlanUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get webPlanUpdated;

  /// No description provided for @webPlanDeleted.
  ///
  /// In en, this message translates to:
  /// **'Planned payment deleted'**
  String get webPlanDeleted;

  /// No description provided for @webPlanDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this planned payment?'**
  String get webPlanDeleteTitle;

  /// No description provided for @webPlanDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'It was never recorded, so no balance changes.'**
  String get webPlanDeleteMsg;

  /// No description provided for @webNavGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals & loans'**
  String get webNavGoals;

  /// No description provided for @webGoalsSub.
  ///
  /// In en, this message translates to:
  /// **'Save toward a target, or track money you lent or borrowed.'**
  String get webGoalsSub;

  /// No description provided for @webGoalNew.
  ///
  /// In en, this message translates to:
  /// **'New goal or loan'**
  String get webGoalNew;

  /// No description provided for @webGoalCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get webGoalCreate;

  /// No description provided for @webGoalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get webGoalEdit;

  /// No description provided for @webGoalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals or loans yet'**
  String get webGoalsEmptyTitle;

  /// No description provided for @webGoalsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Goals track savings toward a target. Loans track money you lent or borrowed.'**
  String get webGoalsEmptySub;

  /// No description provided for @webGoalsSection.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get webGoalsSection;

  /// No description provided for @webLoansSection.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get webLoansSection;

  /// No description provided for @webGoalKindGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get webGoalKindGoal;

  /// No description provided for @webGoalKindLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get webGoalKindLoan;

  /// No description provided for @webGoalSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get webGoalSaved;

  /// No description provided for @webGoalYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get webGoalYouOwe;

  /// No description provided for @webGoalOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'Owed to you'**
  String get webGoalOwedToYou;

  /// No description provided for @webGoalLentTo.
  ///
  /// In en, this message translates to:
  /// **'Lent to {name}'**
  String webGoalLentTo(String name);

  /// No description provided for @webGoalBorrowedFrom.
  ///
  /// In en, this message translates to:
  /// **'Borrowed from {name}'**
  String webGoalBorrowedFrom(String name);

  /// No description provided for @webGoalDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String webGoalDue(String date);

  /// No description provided for @webGoalPaidOff.
  ///
  /// In en, this message translates to:
  /// **'Paid off'**
  String get webGoalPaidOff;

  /// No description provided for @webGoalPaidBack.
  ///
  /// In en, this message translates to:
  /// **'{amount} paid back'**
  String webGoalPaidBack(String amount);

  /// No description provided for @webGoalPaidBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get webGoalPaidBackLabel;

  /// No description provided for @webGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get webGoalRemaining;

  /// No description provided for @webGoalPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month to stay on track'**
  String webGoalPerMonth(String amount);

  /// No description provided for @webGoalPerMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Needed per month'**
  String get webGoalPerMonthLabel;

  /// No description provided for @webGoalDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get webGoalDeadline;

  /// No description provided for @webGoalPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get webGoalPayments;

  /// No description provided for @webGoalNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get webGoalNoPayments;

  /// No description provided for @webGoalAddFunds.
  ///
  /// In en, this message translates to:
  /// **'Add funds'**
  String get webGoalAddFunds;

  /// No description provided for @webGoalPayReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get webGoalPayReceived;

  /// No description provided for @webGoalPaySent.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get webGoalPaySent;

  /// No description provided for @webGoalFillRest.
  ///
  /// In en, this message translates to:
  /// **'All that’s left'**
  String get webGoalFillRest;

  /// No description provided for @webGoalFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get webGoalFromAccount;

  /// No description provided for @webGoalIntoAccount.
  ///
  /// In en, this message translates to:
  /// **'Into account'**
  String get webGoalIntoAccount;

  /// No description provided for @webGoalConverted.
  ///
  /// In en, this message translates to:
  /// **'Converted to {cur} at the phone’s latest rate'**
  String webGoalConverted(String cur);

  /// No description provided for @webGoalLentChoice.
  ///
  /// In en, this message translates to:
  /// **'I lent'**
  String get webGoalLentChoice;

  /// No description provided for @webGoalBorrowedChoice.
  ///
  /// In en, this message translates to:
  /// **'I borrowed'**
  String get webGoalBorrowedChoice;

  /// No description provided for @webGoalLentHint.
  ///
  /// In en, this message translates to:
  /// **'You gave money — payments come in'**
  String get webGoalLentHint;

  /// No description provided for @webGoalBorrowedHint.
  ///
  /// In en, this message translates to:
  /// **'You owe money — payments go out'**
  String get webGoalBorrowedHint;

  /// No description provided for @webGoalPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get webGoalPerson;

  /// No description provided for @webGoalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get webGoalTarget;

  /// No description provided for @webGoalLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan amount'**
  String get webGoalLoanAmount;

  /// No description provided for @webGoalDeadlineOpt.
  ///
  /// In en, this message translates to:
  /// **'Deadline (optional)'**
  String get webGoalDeadlineOpt;

  /// No description provided for @webGoalDueBy.
  ///
  /// In en, this message translates to:
  /// **'Due by (optional)'**
  String get webGoalDueBy;

  /// No description provided for @webGoalWhatGoal.
  ///
  /// In en, this message translates to:
  /// **'Each deposit moves money out of the account you pick and is recorded as a transaction.'**
  String get webGoalWhatGoal;

  /// No description provided for @webGoalWhatLoan.
  ///
  /// In en, this message translates to:
  /// **'Each payment moves money in or out of the account you pick.'**
  String get webGoalWhatLoan;

  /// No description provided for @webGoalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String webGoalDeleteTitle(String name);

  /// No description provided for @webGoalDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get webGoalDeleteMsg;

  /// No description provided for @webGoalDeletePayments.
  ///
  /// In en, this message translates to:
  /// **'Linked payments: {n}. The money already moved between your accounts — keep them, or delete everything?'**
  String webGoalDeletePayments(int n);

  /// No description provided for @webGoalDeleteKeep.
  ///
  /// In en, this message translates to:
  /// **'Delete, keep payments'**
  String get webGoalDeleteKeep;

  /// No description provided for @webGoalDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get webGoalDeleteAll;

  /// No description provided for @webToastGoalAdded.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get webToastGoalAdded;

  /// No description provided for @webToastGoalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get webToastGoalUpdated;

  /// No description provided for @webToastGoalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get webToastGoalDeleted;

  /// No description provided for @webToastGoalPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get webToastGoalPaid;

  /// No description provided for @webBulkAdd.
  ///
  /// In en, this message translates to:
  /// **'Add several'**
  String get webBulkAdd;

  /// No description provided for @webBulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Add several transactions'**
  String get webBulkTitle;

  /// No description provided for @webBulkHint.
  ///
  /// In en, this message translates to:
  /// **'Tab moves across, Enter goes down a row, Ctrl+Enter saves. Paste rows from a spreadsheet to fill several at once.'**
  String get webBulkHint;

  /// No description provided for @webBulkAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get webBulkAddRow;

  /// No description provided for @webBulkRemoveRow.
  ///
  /// In en, this message translates to:
  /// **'Remove row'**
  String get webBulkRemoveRow;

  /// No description provided for @webBulkSave.
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get webBulkSave;

  /// No description provided for @webBulkClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get webBulkClear;

  /// No description provided for @webBulkCount.
  ///
  /// In en, this message translates to:
  /// **'Rows: {n}'**
  String webBulkCount(int n);

  /// No description provided for @webBulkEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fill in at least one row.'**
  String get webBulkEmpty;

  /// No description provided for @webBulkRowBad.
  ///
  /// In en, this message translates to:
  /// **'Check row {n}'**
  String webBulkRowBad(int n);

  /// No description provided for @webBulkPasted.
  ///
  /// In en, this message translates to:
  /// **'Rows pasted: {n}'**
  String webBulkPasted(int n);

  /// No description provided for @webBulkSaved.
  ///
  /// In en, this message translates to:
  /// **'Transactions added: {n}'**
  String webBulkSaved(int n);

  /// No description provided for @webMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move money'**
  String get webMoveTitle;

  /// No description provided for @webMoveSubmit.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get webMoveSubmit;

  /// No description provided for @webMoveFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get webMoveFrom;

  /// No description provided for @webMoveTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get webMoveTo;

  /// No description provided for @webMoveAll.
  ///
  /// In en, this message translates to:
  /// **'All of it'**
  String get webMoveAll;

  /// No description provided for @webMoveShortfall.
  ///
  /// In en, this message translates to:
  /// **'Overspent amount'**
  String get webMoveShortfall;

  /// No description provided for @webMoveHas.
  ///
  /// In en, this message translates to:
  /// **'{name} has {amount}'**
  String webMoveHas(String name, String amount);

  /// No description provided for @webMoveSame.
  ///
  /// In en, this message translates to:
  /// **'Pick two different places.'**
  String get webMoveSame;

  /// No description provided for @webMoveNotEnough.
  ///
  /// In en, this message translates to:
  /// **'{name} only has {amount}.'**
  String webMoveNotEnough(String name, String amount);

  /// No description provided for @webEnvCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get webEnvCover;

  /// No description provided for @webCoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Cover {name}'**
  String webCoverTitle(String name);

  /// No description provided for @webToastMoved.
  ///
  /// In en, this message translates to:
  /// **'Money moved'**
  String get webToastMoved;

  /// No description provided for @webToastCovered.
  ///
  /// In en, this message translates to:
  /// **'Overspending covered'**
  String get webToastCovered;

  /// No description provided for @webNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get webNavHome;

  /// No description provided for @webNavBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get webNavBudget;

  /// No description provided for @webMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get webMenu;

  /// No description provided for @webShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get webShortcuts;

  /// No description provided for @webSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get webSignOut;

  /// No description provided for @webConnChecking.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get webConnChecking;

  /// No description provided for @webConnOk.
  ///
  /// In en, this message translates to:
  /// **'Connected to phone'**
  String get webConnOk;

  /// No description provided for @webConnLost.
  ///
  /// In en, this message translates to:
  /// **'Phone not reachable'**
  String get webConnLost;

  /// No description provided for @webOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach your phone. Keep BudgetSeal open with the Web Companion running, on the same Wi‑Fi.'**
  String get webOffline;

  /// No description provided for @webOfflineShort.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach your phone'**
  String get webOfflineShort;

  /// No description provided for @webAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN you set on your phone'**
  String get webAuthSubtitle;

  /// No description provided for @webAuthFoot.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your phone. This page reads it over your Wi‑Fi.'**
  String get webAuthFoot;

  /// No description provided for @webAuthDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete digit'**
  String get webAuthDelete;

  /// No description provided for @webAuthWrongLeft.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN · {n} attempts left'**
  String webAuthWrongLeft(int n);

  /// No description provided for @webAuthLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {n} min.'**
  String webAuthLocked(int n);

  /// No description provided for @webAuthExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Enter your PIN again.'**
  String get webAuthExpired;

  /// No description provided for @webErrRequest.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Check the values and try again.'**
  String get webErrRequest;

  /// No description provided for @webErrTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many changes at once. Wait a moment.'**
  String get webErrTooMany;

  /// No description provided for @webErrNoRate.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate for this currency yet. Enter one.'**
  String get webErrNoRate;

  /// No description provided for @webNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Add an account first.'**
  String get webNeedAccount;

  /// No description provided for @webSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get webSeeAll;

  /// No description provided for @webRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get webRecent;

  /// No description provided for @webLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get webLoadMore;

  /// No description provided for @webDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get webDuplicate;

  /// No description provided for @webCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get webCsv;

  /// No description provided for @webCsvPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the export…'**
  String get webCsvPreparing;

  /// No description provided for @webCsvDone.
  ///
  /// In en, this message translates to:
  /// **'{n} rows exported'**
  String webCsvDone(int n);

  /// No description provided for @webWholeYear.
  ///
  /// In en, this message translates to:
  /// **'Whole year'**
  String get webWholeYear;

  /// No description provided for @webPrevYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get webPrevYear;

  /// No description provided for @webNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get webNextYear;

  /// No description provided for @webPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get webPrevMonth;

  /// No description provided for @webNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get webNextMonth;

  /// No description provided for @webRta.
  ///
  /// In en, this message translates to:
  /// **'Ready to assign'**
  String get webRta;

  /// No description provided for @webRtaAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get webRtaAssign;

  /// No description provided for @webNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get webNetWorth;

  /// No description provided for @webNetWorthCur.
  ///
  /// In en, this message translates to:
  /// **'Net worth · {cur}'**
  String webNetWorthCur(String cur);

  /// No description provided for @webEnvSpending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get webEnvSpending;

  /// No description provided for @webEnvFlexible.
  ///
  /// In en, this message translates to:
  /// **'Rollover'**
  String get webEnvFlexible;

  /// No description provided for @webEnvAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get webEnvAvailable;

  /// No description provided for @webEnvOverspent.
  ///
  /// In en, this message translates to:
  /// **'Overspent'**
  String get webEnvOverspent;

  /// No description provided for @webEnvSpent.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String webEnvSpent(String amount);

  /// No description provided for @webEnvOf.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String webEnvOf(String amount);

  /// No description provided for @webEnvToGo.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String webEnvToGo(String amount);

  /// No description provided for @webEnvReached.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get webEnvReached;

  /// No description provided for @webFundTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund {name}'**
  String webFundTitle(String name);

  /// No description provided for @webFundToTarget.
  ///
  /// In en, this message translates to:
  /// **'To target'**
  String get webFundToTarget;

  /// No description provided for @webFundAll.
  ///
  /// In en, this message translates to:
  /// **'All available'**
  String get webFundAll;

  /// No description provided for @webFundAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ready to assign: {amount}'**
  String webFundAvailable(String amount);

  /// No description provided for @webFundOver.
  ///
  /// In en, this message translates to:
  /// **'Ready to assign would go to {amount}'**
  String webFundOver(String amount);

  /// No description provided for @webFundOverMsg.
  ///
  /// In en, this message translates to:
  /// **'This is more than you have ready to assign. Fund anyway?'**
  String get webFundOverMsg;

  /// No description provided for @webFundAnyway.
  ///
  /// In en, this message translates to:
  /// **'Fund anyway'**
  String get webFundAnyway;

  /// No description provided for @webTxAddShort.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get webTxAddShort;

  /// No description provided for @webTxNewExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get webTxNewExpense;

  /// No description provided for @webTxNewIncome.
  ///
  /// In en, this message translates to:
  /// **'New income'**
  String get webTxNewIncome;

  /// No description provided for @webTxNewTransfer.
  ///
  /// In en, this message translates to:
  /// **'New transfer'**
  String get webTxNewTransfer;

  /// No description provided for @webTxEditExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get webTxEditExpense;

  /// No description provided for @webTxEditIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit income'**
  String get webTxEditIncome;

  /// No description provided for @webTxEditTransfer.
  ///
  /// In en, this message translates to:
  /// **'Edit transfer'**
  String get webTxEditTransfer;

  /// No description provided for @webTxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions here'**
  String get webTxEmptyTitle;

  /// No description provided for @webTxEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Add one, or pick another month.'**
  String get webTxEmptySub;

  /// No description provided for @webTxNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your search'**
  String get webTxNoMatch;

  /// No description provided for @webTxSplit.
  ///
  /// In en, this message translates to:
  /// **'Split · {n}'**
  String webTxSplit(int n);

  /// No description provided for @webTxSplitHint.
  ///
  /// In en, this message translates to:
  /// **'Items of a split are edited on your phone.'**
  String get webTxSplitHint;

  /// No description provided for @webSaveAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Save & add another'**
  String get webSaveAddAnother;

  /// No description provided for @webFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get webFormTitle;

  /// No description provided for @webFormName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get webFormName;

  /// No description provided for @webFormNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get webFormNoCategory;

  /// No description provided for @webFormInCurrency.
  ///
  /// In en, this message translates to:
  /// **'In {cur}, the source account’s currency'**
  String webFormInCurrency(String cur);

  /// No description provided for @webFormRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate: 1 {cur} = ? {base}'**
  String webFormRateLabel(String cur, String base);

  /// No description provided for @webFormRateAuto.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the phone\'s latest rate'**
  String get webFormRateAuto;

  /// No description provided for @webFormReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received in {cur}'**
  String webFormReceived(String cur);

  /// No description provided for @webFormRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get webFormRepeats;

  /// No description provided for @webFormNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next date'**
  String get webFormNextDue;

  /// No description provided for @webFormFirstDate.
  ///
  /// In en, this message translates to:
  /// **'First date'**
  String get webFormFirstDate;

  /// No description provided for @webValReceived.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount received'**
  String get webValReceived;

  /// No description provided for @webValRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid rate'**
  String get webValRate;

  /// No description provided for @webValCurrency.
  ///
  /// In en, this message translates to:
  /// **'Use a 3-letter currency code, like USD'**
  String get webValCurrency;

  /// No description provided for @webAcctAdd.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get webAcctAdd;

  /// No description provided for @webAcctNew.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get webAcctNew;

  /// No description provided for @webAcctNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main bank'**
  String get webAcctNameHint;

  /// No description provided for @webAcctOpening.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get webAcctOpening;

  /// No description provided for @webAcctOpeningHint.
  ///
  /// In en, this message translates to:
  /// **'Negative for a card you owe on'**
  String get webAcctOpeningHint;

  /// No description provided for @webAcctTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel wallet'**
  String get webAcctTravel;

  /// No description provided for @webAcctGroupBank.
  ///
  /// In en, this message translates to:
  /// **'Bank accounts'**
  String get webAcctGroupBank;

  /// No description provided for @webAcctGroupCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get webAcctGroupCash;

  /// No description provided for @webAcctGroupCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get webAcctGroupCredit;

  /// No description provided for @webAcctGroupWallet.
  ///
  /// In en, this message translates to:
  /// **'Digital wallets'**
  String get webAcctGroupWallet;

  /// No description provided for @webCatAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get webCatAdd;

  /// No description provided for @webCatNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get webCatNew;

  /// No description provided for @webCatEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get webCatEdit;

  /// No description provided for @webCatNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Groceries'**
  String get webCatNameHint;

  /// No description provided for @webCatParent.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get webCatParent;

  /// No description provided for @webCatTopLevel.
  ///
  /// In en, this message translates to:
  /// **'Main category'**
  String get webCatTopLevel;

  /// No description provided for @webCatParentLocked.
  ///
  /// In en, this message translates to:
  /// **'It has subcategories, so it stays a main category.'**
  String get webCatParentLocked;

  /// No description provided for @webCatIcon.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get webCatIcon;

  /// No description provided for @webCatColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get webCatColor;

  /// No description provided for @webCatCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get webCatCustomColor;

  /// No description provided for @webCatSubs.
  ///
  /// In en, this message translates to:
  /// **'{n} subcategories'**
  String webCatSubs(int n);

  /// No description provided for @webCatNoSubs.
  ///
  /// In en, this message translates to:
  /// **'No subcategories'**
  String get webCatNoSubs;

  /// No description provided for @webRecAdd.
  ///
  /// In en, this message translates to:
  /// **'Add recurring'**
  String get webRecAdd;

  /// No description provided for @webRecNew.
  ///
  /// In en, this message translates to:
  /// **'New recurring item'**
  String get webRecNew;

  /// No description provided for @webRecEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring item'**
  String get webRecEdit;

  /// No description provided for @webRecEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring items yet'**
  String get webRecEmpty;

  /// No description provided for @webRecEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Rent, salary, savings transfers: they post on their own.'**
  String get webRecEmptySub;

  /// No description provided for @webRecTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent'**
  String get webRecTitleHint;

  /// No description provided for @webRecNext.
  ///
  /// In en, this message translates to:
  /// **'next {date}'**
  String webRecNext(String date);

  /// No description provided for @webRecOn.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get webRecOn;

  /// No description provided for @webRecOff.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get webRecOff;

  /// No description provided for @webRecPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get webRecPaused;

  /// No description provided for @webRecPausedToast.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get webRecPausedToast;

  /// No description provided for @webRecResumed.
  ///
  /// In en, this message translates to:
  /// **'Active again'**
  String get webRecResumed;

  /// No description provided for @webRecPastHint.
  ///
  /// In en, this message translates to:
  /// **'A past date posts the missed occurrences the next time the app opens.'**
  String get webRecPastHint;

  /// No description provided for @webSubAdd.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get webSubAdd;

  /// No description provided for @webSubNew.
  ///
  /// In en, this message translates to:
  /// **'New subscription'**
  String get webSubNew;

  /// No description provided for @webSubEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get webSubEdit;

  /// No description provided for @webSubEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Track streaming, apps and memberships, with their price changes.'**
  String get webSubEmptySub;

  /// No description provided for @webSubTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Netflix'**
  String get webSubTitleHint;

  /// No description provided for @webSubMonthly.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get webSubMonthly;

  /// No description provided for @webSubYearly.
  ///
  /// In en, this message translates to:
  /// **'{amount} per year'**
  String webSubYearly(String amount);

  /// No description provided for @webRepEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded this month'**
  String get webRepEmpty;

  /// No description provided for @webRepEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Pick another month with the arrows.'**
  String get webRepEmptySub;

  /// No description provided for @webShortcutPages.
  ///
  /// In en, this message translates to:
  /// **'Go to a page in the menu'**
  String get webShortcutPages;

  /// No description provided for @wcStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start. Turn Wi‑Fi off and on, then try again.'**
  String get wcStartFailed;

  /// No description provided for @billItemN.
  ///
  /// In en, this message translates to:
  /// **'Item {n}'**
  String billItemN(int n);

  /// No description provided for @billDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this bill?'**
  String get billDiscardTitle;

  /// No description provided for @billDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The items and splits you entered will be lost.'**
  String get billDiscardBody;

  /// No description provided for @billPaidEachDesc.
  ///
  /// In en, this message translates to:
  /// **'Records only your share.'**
  String get billPaidEachDesc;

  /// No description provided for @billLinePart.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s part'**
  String billLinePart(String name);

  /// No description provided for @billLoanName.
  ///
  /// In en, this message translates to:
  /// **'Bill split · {date}'**
  String billLoanName(String date);

  /// No description provided for @billShare.
  ///
  /// In en, this message translates to:
  /// **'Share split'**
  String get billShare;

  /// No description provided for @billShareHeader.
  ///
  /// In en, this message translates to:
  /// **'Bill split · total {total}'**
  String billShareHeader(String total);

  /// No description provided for @billSharePaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String billSharePaidBy(String name);

  /// No description provided for @billReceiptMatch.
  ///
  /// In en, this message translates to:
  /// **'Matches the receipt total ({total})'**
  String billReceiptMatch(String total);

  /// No description provided for @billCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Looks like {currency} — switch?'**
  String billCurrencyHint(String currency);

  /// No description provided for @billCurrencySwitched.
  ///
  /// In en, this message translates to:
  /// **'Bill switched to {currency}, as on the receipt'**
  String billCurrencySwitched(String currency);

  /// No description provided for @billReceiptDiff.
  ///
  /// In en, this message translates to:
  /// **'Items add up to {items} · receipt total {total}'**
  String billReceiptDiff(String items, String total);

  /// No description provided for @webShortcutRefresh.
  ///
  /// In en, this message translates to:
  /// **'Reload from the phone'**
  String get webShortcutRefresh;

  /// No description provided for @currencyNameUsd.
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get currencyNameUsd;

  /// No description provided for @currencyNameEur.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyNameEur;

  /// No description provided for @currencyNameGbp.
  ///
  /// In en, this message translates to:
  /// **'British Pound'**
  String get currencyNameGbp;

  /// No description provided for @currencyNameJpy.
  ///
  /// In en, this message translates to:
  /// **'Japanese Yen'**
  String get currencyNameJpy;

  /// No description provided for @currencyNameChf.
  ///
  /// In en, this message translates to:
  /// **'Swiss Franc'**
  String get currencyNameChf;

  /// No description provided for @currencyNameCad.
  ///
  /// In en, this message translates to:
  /// **'Canadian Dollar'**
  String get currencyNameCad;

  /// No description provided for @currencyNameAud.
  ///
  /// In en, this message translates to:
  /// **'Australian Dollar'**
  String get currencyNameAud;

  /// No description provided for @currencyNameCny.
  ///
  /// In en, this message translates to:
  /// **'Chinese Yuan'**
  String get currencyNameCny;

  /// No description provided for @currencyNameInr.
  ///
  /// In en, this message translates to:
  /// **'Indian Rupee'**
  String get currencyNameInr;

  /// No description provided for @currencyNameBrl.
  ///
  /// In en, this message translates to:
  /// **'Brazilian Real'**
  String get currencyNameBrl;

  /// No description provided for @currencyNameMxn.
  ///
  /// In en, this message translates to:
  /// **'Mexican Peso'**
  String get currencyNameMxn;

  /// No description provided for @currencyNameSgd.
  ///
  /// In en, this message translates to:
  /// **'Singapore Dollar'**
  String get currencyNameSgd;

  /// No description provided for @currencyNameHkd.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong Dollar'**
  String get currencyNameHkd;

  /// No description provided for @currencyNameNok.
  ///
  /// In en, this message translates to:
  /// **'Norwegian Krone'**
  String get currencyNameNok;

  /// No description provided for @currencyNameSek.
  ///
  /// In en, this message translates to:
  /// **'Swedish Krona'**
  String get currencyNameSek;

  /// No description provided for @currencyNameNzd.
  ///
  /// In en, this message translates to:
  /// **'New Zealand Dollar'**
  String get currencyNameNzd;

  /// No description provided for @currencyNameZar.
  ///
  /// In en, this message translates to:
  /// **'South African Rand'**
  String get currencyNameZar;

  /// No description provided for @currencyNameAed.
  ///
  /// In en, this message translates to:
  /// **'UAE Dirham'**
  String get currencyNameAed;

  /// No description provided for @currencyNameLbp.
  ///
  /// In en, this message translates to:
  /// **'Lebanese Pound'**
  String get currencyNameLbp;

  /// No description provided for @currencyNameSar.
  ///
  /// In en, this message translates to:
  /// **'Saudi Riyal'**
  String get currencyNameSar;

  /// No description provided for @currencyNameKwd.
  ///
  /// In en, this message translates to:
  /// **'Kuwaiti Dinar'**
  String get currencyNameKwd;

  /// No description provided for @currencyNameTry.
  ///
  /// In en, this message translates to:
  /// **'Turkish Lira'**
  String get currencyNameTry;

  /// No description provided for @notifAlertsChannel.
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal alerts'**
  String get notifAlertsChannel;

  /// No description provided for @notifAlertsChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Low envelope and upcoming bill alerts'**
  String get notifAlertsChannelDesc;

  /// No description provided for @widgetReadyToAssign.
  ///
  /// In en, this message translates to:
  /// **'Ready to assign: {amount}'**
  String widgetReadyToAssign(String amount);

  /// No description provided for @widgetSpentToday.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent today'**
  String widgetSpentToday(String amount);

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Last sync failed — tap to check'**
  String get syncStatusFailed;

  /// No description provided for @syncStatusLast.
  ///
  /// In en, this message translates to:
  /// **'Synced {when}'**
  String syncStatusLast(String when);

  /// No description provided for @importColDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit (money out)'**
  String get importColDebit;

  /// No description provided for @importColCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit (money in)'**
  String get importColCredit;

  /// No description provided for @importDuplicatesSkipped.
  ///
  /// In en, this message translates to:
  /// **'{n} already in the app'**
  String importDuplicatesSkipped(int n);

  /// No description provided for @acctReconcileMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches — nothing to adjust'**
  String get acctReconcileMatches;

  /// No description provided for @acctReconcileDiff.
  ///
  /// In en, this message translates to:
  /// **'Difference {amount} — an adjustment will be recorded'**
  String acctReconcileDiff(String amount);

  /// No description provided for @acctReconcileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark as reconciled'**
  String get acctReconcileConfirm;

  /// No description provided for @acctReconciledMatch.
  ///
  /// In en, this message translates to:
  /// **'Balance matches — reconciled'**
  String get acctReconciledMatch;

  /// No description provided for @acctLastReconciled.
  ///
  /// In en, this message translates to:
  /// **'Reconciled {date}'**
  String acctLastReconciled(String date);

  /// No description provided for @reportsCalendarMonths.
  ///
  /// In en, this message translates to:
  /// **'Calendar months'**
  String get reportsCalendarMonths;

  /// No description provided for @reportsBudgetPeriods.
  ///
  /// In en, this message translates to:
  /// **'Budget periods'**
  String get reportsBudgetPeriods;

  /// No description provided for @upcomingPostNow.
  ///
  /// In en, this message translates to:
  /// **'Post now'**
  String get upcomingPostNow;

  /// No description provided for @upcomingPostNowDesc.
  ///
  /// In en, this message translates to:
  /// **'Record it today and move to the next date'**
  String get upcomingPostNowDesc;

  /// No description provided for @upcomingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this one'**
  String get upcomingSkip;

  /// No description provided for @upcomingSkipDesc.
  ///
  /// In en, this message translates to:
  /// **'Move to the next date without recording it'**
  String get upcomingSkipDesc;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @settingsCalendarSub.
  ///
  /// In en, this message translates to:
  /// **'Spending day by day'**
  String get settingsCalendarSub;

  /// No description provided for @calendarAddToday.
  ///
  /// In en, this message translates to:
  /// **'Add a transaction today'**
  String get calendarAddToday;

  /// No description provided for @calendarAddOn.
  ///
  /// In en, this message translates to:
  /// **'Add on this day'**
  String get calendarAddOn;

  /// No description provided for @calendarNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get calendarNothing;

  /// No description provided for @calendarFutureDay.
  ///
  /// In en, this message translates to:
  /// **'This day hasn\'t come yet'**
  String get calendarFutureDay;

  /// No description provided for @upcomingPaidOnDay.
  ///
  /// In en, this message translates to:
  /// **'Paid on another day'**
  String get upcomingPaidOnDay;

  /// No description provided for @upcomingPaidOnDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Record it on the day you paid it'**
  String get upcomingPaidOnDayDesc;

  /// No description provided for @upcomingPosted.
  ///
  /// In en, this message translates to:
  /// **'Bill posted'**
  String get upcomingPosted;

  /// No description provided for @upcomingSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped — next date updated'**
  String get upcomingSkipped;

  /// Post now on a bill past its end date
  ///
  /// In en, this message translates to:
  /// **'This bill has ended, so it isn\'t paid any more.'**
  String get upcomingBillEnded;

  /// No description provided for @recurringPostedN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 recurring item posted} other{{n} recurring items posted}}'**
  String recurringPostedN(int n);

  /// No description provided for @objSummaryPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Needed per month'**
  String get objSummaryPerMonth;

  /// No description provided for @catLinkEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Envelope'**
  String get catLinkEnvelope;

  /// No description provided for @catLinkEnvelopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Where does {name} spending go?'**
  String catLinkEnvelopeTitle(String name);

  /// No description provided for @catCreateEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Create a \"{name}\" envelope'**
  String catCreateEnvelope(String name);

  /// No description provided for @catUnlinkEnvelope.
  ///
  /// In en, this message translates to:
  /// **'No envelope (unbudgeted)'**
  String get catUnlinkEnvelope;

  /// No description provided for @allocReorderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reorder envelopes'**
  String get allocReorderTitle;

  /// No description provided for @allocReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handles. The Budget tab and funding screen follow this order.'**
  String get allocReorderHint;

  /// No description provided for @periodSummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Last period you spent {spent} of {funded} budgeted.'**
  String periodSummaryBody(String spent, String funded);

  /// No description provided for @periodSummaryUnder.
  ///
  /// In en, this message translates to:
  /// **'{amount} under budget'**
  String periodSummaryUnder(String amount);

  /// No description provided for @periodSummaryOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over budget'**
  String periodSummaryOver(String amount);

  /// No description provided for @periodSummaryFund.
  ///
  /// In en, this message translates to:
  /// **'Fund this period'**
  String get periodSummaryFund;

  /// No description provided for @enginePeriodCovered.
  ///
  /// In en, this message translates to:
  /// **'Overspending covered at period end'**
  String get enginePeriodCovered;

  /// No description provided for @periodCoverFromRta.
  ///
  /// In en, this message translates to:
  /// **'Cover from Ready to assign'**
  String get periodCoverFromRta;

  /// No description provided for @periodCoverFromRtaDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the new period at zero'**
  String get periodCoverFromRtaDesc;

  /// No description provided for @periodCarryDebt.
  ///
  /// In en, this message translates to:
  /// **'Carry the overspending'**
  String get periodCarryDebt;

  /// No description provided for @periodCarryDebtDesc.
  ///
  /// In en, this message translates to:
  /// **'The new period starts below zero'**
  String get periodCarryDebtDesc;

  /// No description provided for @allocFundToTarget.
  ///
  /// In en, this message translates to:
  /// **'To target · {amount}'**
  String allocFundToTarget(String amount);

  /// No description provided for @allocFundAllAvailable.
  ///
  /// In en, this message translates to:
  /// **'All available · {amount}'**
  String allocFundAllAvailable(String amount);

  /// No description provided for @fundPresetLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'Same as last period'**
  String get fundPresetLastPeriod;

  /// No description provided for @fundPresetSpent.
  ///
  /// In en, this message translates to:
  /// **'What I spent last period'**
  String get fundPresetSpent;

  /// No description provided for @fundPresetClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get fundPresetClear;

  /// No description provided for @txExportSelected.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get txExportSelected;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @txAllMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get txAllMonths;

  /// No description provided for @txSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get txSelectAll;

  /// No description provided for @txBulkCategory.
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get txBulkCategory;

  /// No description provided for @txBulkAccount.
  ///
  /// In en, this message translates to:
  /// **'Change account'**
  String get txBulkAccount;

  /// No description provided for @txBulkDate.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get txBulkDate;

  /// No description provided for @txBulkUpdated.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 transaction updated} other{{n} transactions updated}}'**
  String txBulkUpdated(int n);

  /// No description provided for @txBulkSkipped.
  ///
  /// In en, this message translates to:
  /// **'{n} skipped'**
  String txBulkSkipped(int n);

  /// No description provided for @txAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get txAllAccounts;

  /// No description provided for @txAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get txAllCategories;

  /// No description provided for @txClearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get txClearAllFilters;

  /// No description provided for @txClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get txClearAll;

  /// No description provided for @txSearchingAllMonths.
  ///
  /// In en, this message translates to:
  /// **'Showing all months'**
  String get txSearchingAllMonths;

  /// No description provided for @txSavedEnvelopeLeft.
  ///
  /// In en, this message translates to:
  /// **'Saved · {envelope}: {amount} left'**
  String txSavedEnvelopeLeft(String envelope, String amount);

  /// No description provided for @txSavedEnvelopeOver.
  ///
  /// In en, this message translates to:
  /// **'Saved · {envelope} is over by {amount}'**
  String txSavedEnvelopeOver(String envelope, String amount);

  /// No description provided for @allocMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move money'**
  String get allocMoveTitle;

  /// No description provided for @allocMoveDesc.
  ///
  /// In en, this message translates to:
  /// **'Move money between envelopes, or back to Ready to assign.'**
  String get allocMoveDesc;

  /// No description provided for @allocCoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Cover overspending'**
  String get allocCoverTitle;

  /// No description provided for @allocCoverDesc.
  ///
  /// In en, this message translates to:
  /// **'Take money from another envelope (or Ready to assign) to bring this one back to zero.'**
  String get allocCoverDesc;

  /// No description provided for @allocMoveFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get allocMoveFrom;

  /// No description provided for @allocMoveTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get allocMoveTo;

  /// No description provided for @allocMoveButton.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get allocMoveButton;

  /// No description provided for @allocCoverButton.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get allocCoverButton;

  /// No description provided for @allocMoveMenu.
  ///
  /// In en, this message translates to:
  /// **'Move money'**
  String get allocMoveMenu;

  /// No description provided for @allocMoveNotEnough.
  ///
  /// In en, this message translates to:
  /// **'{name} only has {amount}.'**
  String allocMoveNotEnough(String name, String amount);

  /// Move money sheet: moving more than Ready to assign holds
  ///
  /// In en, this message translates to:
  /// **'Ready to assign only has {amount}. It will go negative.'**
  String allocMoveOverRta(String amount);

  /// Archive/delete envelope dialog: the money it holds
  ///
  /// In en, this message translates to:
  /// **'It holds {amount}, which goes back to Ready to assign.'**
  String allocRemoveMoneyBack(String amount);

  /// Archive/delete envelope dialog: an overspent envelope
  ///
  /// In en, this message translates to:
  /// **'It is over by {amount}, which comes out of Ready to assign.'**
  String allocRemoveOverspent(String amount);

  /// No description provided for @allocMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved to {name}'**
  String allocMovedTo(String name);

  /// No description provided for @allocMovedFrom.
  ///
  /// In en, this message translates to:
  /// **'Moved from {name}'**
  String allocMovedFrom(String name);

  /// No description provided for @allocMoveDone.
  ///
  /// In en, this message translates to:
  /// **'Moved {amount} from {from} to {to}'**
  String allocMoveDone(String amount, String from, String to);

  /// No description provided for @tmplEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get tmplEditTitle;

  /// No description provided for @tmplSaved.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get tmplSaved;

  /// No description provided for @txAfAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get txAfAddTitle;

  /// No description provided for @txAfItemN.
  ///
  /// In en, this message translates to:
  /// **'Item {n}'**
  String txAfItemN(int n);

  /// No description provided for @txAfRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get txAfRemoveItem;

  /// No description provided for @shortcutAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get shortcutAddTransaction;

  /// No description provided for @shortcutFundEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'Fund envelopes'**
  String get shortcutFundEnvelopes;

  /// No description provided for @shortcutUpcomingBills.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bills'**
  String get shortcutUpcomingBills;

  /// No description provided for @catSheetRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get catSheetRecent;

  /// No description provided for @txFormSwapAccounts.
  ///
  /// In en, this message translates to:
  /// **'Swap accounts'**
  String get txFormSwapAccounts;

  /// No description provided for @txFormSaveAndNew.
  ///
  /// In en, this message translates to:
  /// **'Save & new'**
  String get txFormSaveAndNew;

  /// No description provided for @allocEntryWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get allocEntryWithdrawn;

  /// No description provided for @allocEntryRevaluation.
  ///
  /// In en, this message translates to:
  /// **'Revaluation'**
  String get allocEntryRevaluation;

  /// No description provided for @allocEntryMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get allocEntryMoved;

  /// No description provided for @fxSetRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate for {currency}'**
  String fxSetRateTitle(String currency);

  /// No description provided for @fxBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base currency: {currency}'**
  String fxBaseLabel(String currency);

  /// No description provided for @fxNoCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Your budget uses only one currency. Add an account in another currency to see its rate here.'**
  String get fxNoCurrencies;

  /// No description provided for @fxNoRateFor.
  ///
  /// In en, this message translates to:
  /// **'No rate for {currency} yet — tap to set one'**
  String fxNoRateFor(String currency);

  /// No description provided for @fxManualTag.
  ///
  /// In en, this message translates to:
  /// **'Your rate'**
  String get fxManualTag;

  /// No description provided for @fxLiveTag.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get fxLiveTag;

  /// Exchange rates: rate source per currency
  ///
  /// In en, this message translates to:
  /// **'Live rate'**
  String get fxSourceLive;

  /// Exchange rates: rate source per currency
  ///
  /// In en, this message translates to:
  /// **'Last rate you got'**
  String get fxSourceGot;

  /// Exchange rates: rate source per currency
  ///
  /// In en, this message translates to:
  /// **'None yet. It’s saved when you exchange money between accounts or pay with change in another currency.'**
  String get fxSourceGotNone;

  /// Exchange rates: rate source per currency
  ///
  /// In en, this message translates to:
  /// **'Your fixed rate'**
  String get fxSourceFixed;

  /// Exchange rates: rate source per currency
  ///
  /// In en, this message translates to:
  /// **'Set your own rate'**
  String get fxSourceFixedNone;

  /// Exchange rates: rate source per currency
  ///
  /// In en, this message translates to:
  /// **'Rate you got'**
  String get fxGotTag;

  /// Exchange rates: rate source per currency
  ///
  /// In en, this message translates to:
  /// **'1 {from} in {to}'**
  String fxRateSheet(String from, String to);

  /// Exchange rates: rate source per currency
  ///
  /// In en, this message translates to:
  /// **'New transactions and reports use the rate you choose. On a shared budget everyone uses the same one.'**
  String get fxSourceHint;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Pay with change'**
  String get payChangeTitle;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get payChangeButton;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Paid in one currency and got change in another? Enter what you handed over and the change you got.'**
  String get payChangeIntro;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get payChangePrice;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Optional, to work out the change'**
  String get payChangePriceHint;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'You handed over'**
  String get payChangePaid;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Change you got'**
  String get payChangeChange;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get payChangeRate;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'The shop uses its own rate? Tap to change it.'**
  String get payChangeRateHint;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String payChangeSpent(String amount);

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'{amount} change into {account}'**
  String payChangeInto(String amount, String account);

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'The change is worth all you handed over, or more.'**
  String get payChangeTooMuch;

  /// Pay with change (cash in one currency, change in another)
  ///
  /// In en, this message translates to:
  /// **'Add an account in another currency to keep change in it.'**
  String get payChangeNeedOther;

  /// Count cash by notes (cash account menu)
  ///
  /// In en, this message translates to:
  /// **'Count cash'**
  String get cashCountTitle;

  /// Count cash by notes (cash account menu)
  ///
  /// In en, this message translates to:
  /// **'How many of each note do you have? Coins and anything else go in Other.'**
  String get cashCountIntro;

  /// Count cash by notes (cash account menu)
  ///
  /// In en, this message translates to:
  /// **'Other (coins…)'**
  String get cashCountOther;

  /// Count cash by notes (cash account menu)
  ///
  /// In en, this message translates to:
  /// **'Counted {amount}'**
  String cashCountTotal(String amount);

  /// Count cash by notes (cash account menu)
  ///
  /// In en, this message translates to:
  /// **'Use this count'**
  String get cashCountUse;

  /// Count cash by notes (cash account menu)
  ///
  /// In en, this message translates to:
  /// **'How many {note}?'**
  String cashCountHowMany(String note);

  /// Envelope: optional second target in another currency
  ///
  /// In en, this message translates to:
  /// **'Add a target in another currency'**
  String get allocSecondTargetAdd;

  /// Envelope: optional second target in another currency
  ///
  /// In en, this message translates to:
  /// **'And in another currency'**
  String get allocSecondTarget;

  /// Envelope: optional second target in another currency
  ///
  /// In en, this message translates to:
  /// **'Funded and spent on its own, never added to the first.'**
  String get allocSecondTargetDesc;

  /// No description provided for @tileExchangeRatesSub.
  ///
  /// In en, this message translates to:
  /// **'Live rates, or set your own'**
  String get tileExchangeRatesSub;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get tileRules;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Fill in shared payments and bank alerts'**
  String get tileRulesSub;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'When a shared message, a receipt or a bank alert mentions this text, BudgetSeal fills in the category and account. Saving a shared payment with a category also teaches it a rule.'**
  String get rulesIntro;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'No rules yet'**
  String get rulesEmpty;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get rulesLearned;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Used once} other{Used {n} times}}'**
  String rulesUsed(int n);

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get rulesAdd;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get rulesEdit;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'When the text contains'**
  String get rulesMatch;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'e.g. Spinneys'**
  String get rulesMatchHint;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Title to use (optional)'**
  String get rulesTitleField;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Leave as is'**
  String get rulesKeep;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Enter the text to look for'**
  String get rulesNeedMatch;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Rule saved'**
  String get rulesSaved;

  /// Rules for captured payments (Settings › Rules)
  ///
  /// In en, this message translates to:
  /// **'Rule deleted'**
  String get rulesDeleted;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Bank alerts'**
  String get tileBankAlerts;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Suggest transactions from your bank’s notifications'**
  String get tileBankAlertsSub;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal can read the notifications your bank and wallet apps post, to suggest the transactions they mention. It reads only the apps you pick below, keeps their text on this phone, and never sends it anywhere. Nothing is recorded until you add it from To review.'**
  String get alertsDisclosure;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Notification access is on'**
  String get alertsAccessOn;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Notification access is off'**
  String get alertsAccessOff;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Allow in settings'**
  String get alertsAllow;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Change in settings'**
  String get alertsChange;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Apps to read'**
  String get alertsApps;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Apps show up here once they post a notification after access is on. Then pick your bank’s.'**
  String get alertsAppsEmpty;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Reading bank notifications works on Android phones only.'**
  String get alertsNotAndroid;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get reviewTitle;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get reviewEmpty;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Payments read from your bank’s notifications. Add the ones you want; nothing is recorded until you do.'**
  String get reviewIntro;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get reviewAdd;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get reviewDismiss;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get reviewDismissed;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'No amount found'**
  String get reviewNoAmount;

  /// Bank alerts (notifications from bank apps) and To review
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 payment to review} other{{n} payments to review}}'**
  String reviewCard(int n);

  /// Check an account against a screenshot of the bank list
  ///
  /// In en, this message translates to:
  /// **'Check a screenshot'**
  String get shotCheck;

  /// Check an account against a screenshot of the bank list
  ///
  /// In en, this message translates to:
  /// **'Compare with bank'**
  String get shotTitle;

  /// Check an account against a screenshot of the bank list
  ///
  /// In en, this message translates to:
  /// **'Amounts read from your screenshot, matched with what’s recorded on {account} in the last 90 days. The screenshot stays on your phone.'**
  String shotIntro(String account);

  /// Check an account against a screenshot of the bank list
  ///
  /// In en, this message translates to:
  /// **'Reading the screenshot…'**
  String get shotReading;

  /// Check an account against a screenshot of the bank list
  ///
  /// In en, this message translates to:
  /// **'Not recorded yet'**
  String get shotMissing;

  /// Check an account against a screenshot of the bank list
  ///
  /// In en, this message translates to:
  /// **'Already recorded'**
  String get shotMatched;

  /// Check an account against a screenshot of the bank list
  ///
  /// In en, this message translates to:
  /// **'Everything on the screenshot is recorded.'**
  String get shotAllMatched;

  /// Check an account against a screenshot of the bank list
  ///
  /// In en, this message translates to:
  /// **'No amounts found. Try a screenshot of your bank’s transaction list.'**
  String get shotNone;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecastTitle;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Your money over the next 90 days, from your recurring bills and incomes, planned payments and sinking funds.'**
  String get forecastIntro;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Safe to spend today'**
  String get forecastSafeToday;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'until your next income on {date}'**
  String forecastUntil(String date);

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'until your usual income around {date}'**
  String forecastUntilEst(String date);

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'for the next 30 days (no income coming up)'**
  String get forecastNoIncome;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Short by {amount} before then'**
  String forecastShort(String amount);

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Lowest {amount} on {date}'**
  String forecastLowest(String amount, String date);

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'In your accounts'**
  String get forecastCashNow;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Due before then'**
  String get forecastDue;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Kept for sinking funds'**
  String get forecastReserved;

  /// Forecast: money in savings envelopes, left out of safe to spend
  ///
  /// In en, this message translates to:
  /// **'Kept for savings goals'**
  String get forecastSaved;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get forecastUpcoming;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Usual income (estimate)'**
  String get forecastEstimate;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'Add a recurring bill or income, or a planned payment, to see what’s coming.'**
  String get forecastEmpty;

  /// Forecast: the next 90 days and safe to spend today
  ///
  /// In en, this message translates to:
  /// **'{amount} a day'**
  String forecastPerDay(String amount);

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get familyPrivate;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Private envelopes'**
  String get familyPrivateLine;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get familyPrivateSwitch;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Only its owner sees this envelope and what’s spent from it. The others see “Private” and the amount. It still syncs to their phones.'**
  String get familyPrivateSub;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Belongs to'**
  String get familyOwner;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get familyOwnerEveryone;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get tileMembers;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Grown-ups and kids on this budget'**
  String get tileMembersSub;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Kids see only their own envelopes and ask a grown-up for money; grown-ups see everything except others’ private envelopes and approve requests.'**
  String get membersIntro;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Kid'**
  String get membersKid;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Grown-up'**
  String get membersGrownup;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String membersYou(String name);

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Only a grown-up can change this.'**
  String get membersOnlyGrownups;

  /// Family: members, roles, private envelopes
  ///
  /// In en, this message translates to:
  /// **'Members appear here once they’ve joined this budget and named themselves.'**
  String get membersNone;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Money requests'**
  String get reqTitle;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Ask for money'**
  String get reqAsk;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get reqFor;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'What is it for? (e.g. school trip)'**
  String get reqNoteHint;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get reqSend;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get reqSent;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get reqApprove;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get reqDecline;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get reqApproved;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get reqDeclined;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get reqWaiting;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'To decide'**
  String get reqOpen;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get reqPast;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get reqNone;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 money request} other{{n} money requests}}'**
  String reqCard(int n);

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'{name} asks for {amount}'**
  String reqAsked(String name, String amount);

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'into {envelope}'**
  String reqInto(String envelope);

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'A grown-up needs to give you an envelope first.'**
  String get reqNoEnvelope;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'My envelopes'**
  String get kidMyEnvelopes;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Add spending'**
  String get kidAddSpending;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'My spending'**
  String get kidRecent;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'I’ve reviewed this month'**
  String get reviewFamilyDone;

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Sealed once everyone has reviewed it. Waiting for {names}.'**
  String reviewFamilyWaiting(String names);

  /// Family: money requests, kid home, monthly review
  ///
  /// In en, this message translates to:
  /// **'Reviewed by everyone'**
  String get reviewFamilySealed;

  /// No description provided for @allocArchivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived envelopes'**
  String get allocArchivedTitle;

  /// No description provided for @allocNoArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived envelopes'**
  String get allocNoArchived;

  /// No description provided for @allocUnarchived.
  ///
  /// In en, this message translates to:
  /// **'{name} unarchived'**
  String allocUnarchived(String name);

  /// No description provided for @txNoRate.
  ///
  /// In en, this message translates to:
  /// **'No rate'**
  String get txNoRate;

  /// No description provided for @allocReadyToAssign.
  ///
  /// In en, this message translates to:
  /// **'Ready to assign'**
  String get allocReadyToAssign;

  /// No description provided for @allocAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get allocAssign;

  /// No description provided for @accentGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get accentGold;

  /// No description provided for @accentWax.
  ///
  /// In en, this message translates to:
  /// **'Wax red'**
  String get accentWax;

  /// No description provided for @accentCopper.
  ///
  /// In en, this message translates to:
  /// **'Copper'**
  String get accentCopper;

  /// No description provided for @accentSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get accentSage;

  /// No description provided for @accentTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get accentTeal;

  /// No description provided for @accentSapphire.
  ///
  /// In en, this message translates to:
  /// **'Sapphire'**
  String get accentSapphire;

  /// No description provided for @accentPlum.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get accentPlum;

  /// No description provided for @accentRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get accentRose;

  /// No description provided for @accentColorPairHint.
  ///
  /// In en, this message translates to:
  /// **'Each color has a bright tone for dark mode and a deeper one for light mode, so text stays readable in both.'**
  String get accentColorPairHint;

  /// No description provided for @commonPerDay.
  ///
  /// In en, this message translates to:
  /// **'{amount}/day'**
  String commonPerDay(String amount);

  /// No description provided for @commonNOfM.
  ///
  /// In en, this message translates to:
  /// **'{n} of {m}'**
  String commonNOfM(int n, int m);

  /// No description provided for @fundAmountOfAvailable.
  ///
  /// In en, this message translates to:
  /// **'{currency}: {amount} of {available}'**
  String fundAmountOfAvailable(
      String currency, String amount, String available);

  /// No description provided for @syncNoSyncFile.
  ///
  /// In en, this message translates to:
  /// **'No budget found in this folder'**
  String get syncNoSyncFile;

  /// No description provided for @syncErrNeedsPassword.
  ///
  /// In en, this message translates to:
  /// **'The sync file is encrypted. Enter your sync password in Cloud sync to read it.'**
  String get syncErrNeedsPassword;

  /// No description provided for @travelExchangeNote.
  ///
  /// In en, this message translates to:
  /// **'Travel exchange → {currency}'**
  String travelExchangeNote(String currency);

  /// No description provided for @travelConvertBackNote.
  ///
  /// In en, this message translates to:
  /// **'Travel convert back → {currency}'**
  String travelConvertBackNote(String currency);

  /// Envelope ledger note when closing a travel wallet empties envelopes in its currency
  ///
  /// In en, this message translates to:
  /// **'Trip closed: back to Ready to assign'**
  String get travelEnvelopeReturnedNote;

  /// Convert back & close sheet: envelopes holding the wallet currency
  ///
  /// In en, this message translates to:
  /// **'Your envelopes hold {amount} of it. That goes back to Ready to assign first.'**
  String acctConvertBackEnvelopes(String amount);

  /// No description provided for @healthUnallocShort.
  ///
  /// In en, this message translates to:
  /// **'Unallocated: {amount}'**
  String healthUnallocShort(String amount);

  /// No description provided for @reportsRecurringSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} active · {amount}/month'**
  String reportsRecurringSummary(int count, String amount);

  /// No description provided for @allocRevaluationNote.
  ///
  /// In en, this message translates to:
  /// **'Revaluation: {amount} at {rate} (was {oldRate})'**
  String allocRevaluationNote(String amount, String rate, String oldRate);

  /// No description provided for @notifEveryDayAt.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String notifEveryDayAt(String time);

  /// No description provided for @periodStartsEachMonth.
  ///
  /// In en, this message translates to:
  /// **'{date} · starts on day {day} each month'**
  String periodStartsEachMonth(String date, int day);

  /// No description provided for @fundMoreThanAvailable.
  ///
  /// In en, this message translates to:
  /// **'{amount} more than available in {currency}'**
  String fundMoreThanAvailable(String amount, String currency);

  /// No description provided for @a11yPctOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of {amount}'**
  String a11yPctOfTarget(int pct, String amount);

  /// No description provided for @a11yFlexibleEnvelope.
  ///
  /// In en, this message translates to:
  /// **'flexible envelope'**
  String get a11yFlexibleEnvelope;

  /// No description provided for @a11yNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'needs review'**
  String get a11yNeedsReview;

  /// No description provided for @syncLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get syncLocalFile;

  /// No description provided for @syncGoogleSub.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account'**
  String get syncGoogleSub;

  /// No description provided for @syncOneDriveSub.
  ///
  /// In en, this message translates to:
  /// **'Requires the OneDrive app installed'**
  String get syncOneDriveSub;

  /// No description provided for @syncDropboxSub.
  ///
  /// In en, this message translates to:
  /// **'Requires the Dropbox app installed'**
  String get syncDropboxSub;

  /// No description provided for @syncLocalFileSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder on your phone (or one Dropbox or OneDrive keeps in sync)'**
  String get syncLocalFileSub;

  /// Cloud sync: folder prompt
  ///
  /// In en, this message translates to:
  /// **'Pick a folder for sync'**
  String get syncPickFolderTitle;

  /// Cloud sync: folder prompt
  ///
  /// In en, this message translates to:
  /// **'Sync now keeps each phone\'s changes in its own file, so it needs a folder instead of a single file. Pick the folder your sync file was in, or any folder your phones share.'**
  String get syncPickFolderBody;

  /// Cloud sync: folder prompt
  ///
  /// In en, this message translates to:
  /// **'Pick a folder'**
  String get syncPickFolderButton;

  /// No description provided for @syncErrGoogleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not set up for this build of the app. Use another sync option.'**
  String get syncErrGoogleNotConfigured;

  /// No description provided for @syncErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your internet connection.'**
  String get syncErrNetwork;

  /// No description provided for @syncErrConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Please try again.'**
  String get syncErrConnectFailed;

  /// No description provided for @onboardConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to {provider}'**
  String onboardConnectFailed(String provider);

  /// No description provided for @onboardNoSyncFile.
  ///
  /// In en, this message translates to:
  /// **'No budget found in this folder'**
  String get onboardNoSyncFile;

  /// No description provided for @onboardNoSyncFileShared.
  ///
  /// In en, this message translates to:
  /// **'No budget found in the shared folder'**
  String get onboardNoSyncFileShared;

  /// No description provided for @billNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill split'**
  String get billNoteTitle;

  /// No description provided for @billNoteTotal.
  ///
  /// In en, this message translates to:
  /// **'Bill: {total}'**
  String billNoteTotal(String total);

  /// No description provided for @billNoteSplitWith.
  ///
  /// In en, this message translates to:
  /// **'Split with {people} · Total: {total}'**
  String billNoteSplitWith(String people, String total);

  /// No description provided for @reportsDayN.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String reportsDayN(int n);

  /// No description provided for @reportsTipOverPace.
  ///
  /// In en, this message translates to:
  /// **'At your current pace, you\'ll exceed your budget by {amount}. Try to slow down.'**
  String reportsTipOverPace(String amount);

  /// No description provided for @reportsTipUnderPace.
  ///
  /// In en, this message translates to:
  /// **'Great pace! You\'re on track to stay {amount} under budget.'**
  String reportsTipUnderPace(String amount);

  /// No description provided for @reportsTipSavingHigh.
  ///
  /// In en, this message translates to:
  /// **'You\'re saving {percent}% of your income this month. Keep it up!'**
  String reportsTipSavingHigh(int percent);

  /// No description provided for @reportsTipSavingLow.
  ///
  /// In en, this message translates to:
  /// **'Your savings rate is low ({percent}%). Try to set aside at least 10–20%.'**
  String reportsTipSavingLow(int percent);

  /// No description provided for @reportsTipAgeLow.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Your money sits only 1 day before being spent. A buffer of 30+ days is healthier.} other{Your money sits only {days} days before being spent. A buffer of 30+ days is healthier.}}'**
  String reportsTipAgeLow(int days);

  /// No description provided for @txNoRateBetween.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate from {from} to {to}. Enter a rate for this amount, or refresh rates in Settings › Exchange rates.'**
  String txNoRateBetween(String from, String to);

  /// Posting a bill or planned payment whose account is archived or deleted
  ///
  /// In en, this message translates to:
  /// **'This payment\'s account is archived or deleted. Move it to another account first.'**
  String get txAccountUnavailable;

  /// No description provided for @acctArchiveNonZero.
  ///
  /// In en, this message translates to:
  /// **'This account still holds {amount}. Transfer it to another account or adjust the balance to zero, then archive it — archived accounts no longer count toward your money.'**
  String acctArchiveNonZero(String amount);

  /// No description provided for @acctDeleteNonZero.
  ///
  /// In en, this message translates to:
  /// **'This account still holds {amount}. Deleting it would take that money out of Ready to assign. Transfer it to another account or adjust the balance to zero first.'**
  String acctDeleteNonZero(String amount);

  /// No description provided for @acctCurrencyLocked.
  ///
  /// In en, this message translates to:
  /// **'The currency can\'t change once the account has money or transactions in it. To use another currency, add a new account.'**
  String get acctCurrencyLocked;

  /// No description provided for @acctBillsOffNote.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Its bill will be switched off.} other{Its {n} bills will be switched off.}}'**
  String acctBillsOffNote(int n);

  /// No description provided for @acctPlansDeletedNote.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Its planned payment will be deleted.} other{Its {n} planned payments will be deleted.}}'**
  String acctPlansDeletedNote(int n);

  /// No description provided for @receiptPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the photo. Check camera and photo permissions.'**
  String get receiptPickFailed;

  /// No description provided for @backupCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get backupCloseApp;

  /// No description provided for @importSkippedRows.
  ///
  /// In en, this message translates to:
  /// **'{count} rows skipped (unreadable date or amount)'**
  String importSkippedRows(int count);

  /// No description provided for @moreMoneySection.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get moreMoneySection;

  /// No description provided for @moreAppSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get moreAppSection;

  /// No description provided for @txFormNewExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get txFormNewExpense;

  /// No description provided for @txFormNewIncome.
  ///
  /// In en, this message translates to:
  /// **'New income'**
  String get txFormNewIncome;

  /// No description provided for @txFormNewTransfer.
  ///
  /// In en, this message translates to:
  /// **'New transfer'**
  String get txFormNewTransfer;

  /// No description provided for @txFormEditExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get txFormEditExpense;

  /// No description provided for @txFormEditIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit income'**
  String get txFormEditIncome;

  /// No description provided for @txFormEditTransfer.
  ///
  /// In en, this message translates to:
  /// **'Edit transfer'**
  String get txFormEditTransfer;

  /// No description provided for @reportsTxCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String reportsTxCount(int count);

  /// No description provided for @dashUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get dashUpcoming;

  /// No description provided for @dashOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashOverdue;

  /// No description provided for @dashBillsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No bills} =1{1 bill} other{{count} bills}}'**
  String dashBillsCount(int count);

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

  /// Button back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

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
  /// **'Go back'**
  String get commonGoBack;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
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

  /// About screen tagline
  ///
  /// In en, this message translates to:
  /// **'Envelope budgeting, simplified.'**
  String get appTaglineAbout;

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
  /// **'Record expenses, income and transfers, or split a bill, with the quick actions on Home. Then give your money jobs on the Budget tab.'**
  String get dashboardWelcomeBody;

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

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Quick templates'**
  String get dashboardQuickTemplates;

  /// Link text
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

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
  /// **'Last 7 days'**
  String get dashboardLast7Days;

  /// Toggle label
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboardThisMonth;

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
  /// **'Customize dashboard'**
  String get customizeTitle;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Spending overview'**
  String get dashboardSectionSpendingLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Donut chart with category breakdown'**
  String get dashboardSectionSpendingDesc;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardSectionQuickLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Expense, income, transfer, fund'**
  String get dashboardSectionQuickDesc;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Your money'**
  String get dashboardSectionMoneyLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get dashboardSectionMoneyDesc;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardSectionActivityLabel;

  /// Section description
  ///
  /// In en, this message translates to:
  /// **'Templates and recent transactions'**
  String get dashboardSectionActivityDesc;

  /// Net worth label on dashboard money card
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get dashboardNetWorth;

  /// Shows count of other currencies
  ///
  /// In en, this message translates to:
  /// **'+ {count} other'**
  String dashboardOtherCount(int count);

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

  /// Hint banner title
  ///
  /// In en, this message translates to:
  /// **'Your transactions'**
  String get txIntroTitle;

  /// Hint banner body
  ///
  /// In en, this message translates to:
  /// **'Your transactions appear here grouped by day. Swipe left to delete, right to edit. Long-press to select several.'**
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

  /// Year picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Select year'**
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

  /// Footer summary
  ///
  /// In en, this message translates to:
  /// **'Total cash flow: {amount} · {count} transaction(s)'**
  String txTotalCashFlow(String amount, int count);

  /// Semantics hint
  ///
  /// In en, this message translates to:
  /// **'Long press to select'**
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

  /// Multi-account label
  ///
  /// In en, this message translates to:
  /// **'{count} accounts'**
  String txNAccounts(int count);

  /// AppBar title creating
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
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
  /// **'Use template'**
  String get txFormUseTemplate;

  /// Auto-fill label
  ///
  /// In en, this message translates to:
  /// **'Auto-detected'**
  String get txFormAutoDetected;

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

  /// Validation error: amount over the app's limit
  ///
  /// In en, this message translates to:
  /// **'That amount is too large. One transaction can be at most {max}.'**
  String txAmountTooLarge(String max);

  /// Validation error: a transfer between two currencies has no rate
  ///
  /// In en, this message translates to:
  /// **'Enter the exchange rate from {from} to {to}'**
  String txFormSetTransferRate(String from, String to);

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

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
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
  /// **'Scan receipt'**
  String get txFormScanReceipt;

  /// Gallery button
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get txFormGallery;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
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
  /// **'Split items ({count})'**
  String txDetailSplitItems(int count);

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Line detail'**
  String get txDetailLineDetail;

  /// Fallback
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get txDetailUncategorized;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Related transaction'**
  String get txDetailRelatedSingle;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Related transactions'**
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
  /// **'Enter title'**
  String get txAfEnterTitle;

  /// Transfer note hint
  ///
  /// In en, this message translates to:
  /// **'Note (e.g. rent, savings)'**
  String get txAfTransferNoteHint;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get txAfEnterAmountButton;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get txAfSelectCategoryButton;

  /// Popup title
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get txAfSelectCategoryTitle;

  /// Search hint
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get txAfSearchCategories;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get txAfNewCategory;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get txAfEnterAmountTitle;

  /// Account label (transfer)
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get txAfFromAccount;

  /// Account label (transfer)
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get txAfToAccount;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get txAfTapToSelect;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get txAfAddAccount;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Exchange rate required'**
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
  /// **'Save transfer'**
  String get txAfSaveTransfer;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save {count} items'**
  String txAfSaveNItems(int count);

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get txAfAddTransaction;

  /// New button
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get catSheetNew;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get catSheetAdd;

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
  /// **'Transaction list'**
  String get txListTitle;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Select layout'**
  String get txListSelectLayout;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Date banner total'**
  String get txListDateBanner;

  /// Dropdown option
  ///
  /// In en, this message translates to:
  /// **'Day total'**
  String get txListDayTotal;

  /// Dropdown option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get txListNone;

  /// Setting title
  ///
  /// In en, this message translates to:
  /// **'Account label'**
  String get txListAccountLabel;

  /// Setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Show account name on each transaction'**
  String get txListAccountSubtitle;

  /// Setting title
  ///
  /// In en, this message translates to:
  /// **'Category icon'**
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
  /// **'Transaction name'**
  String get txListPreviewName;

  /// Preview note
  ///
  /// In en, this message translates to:
  /// **'This is a note that is part of the transaction.'**
  String get txListPreviewNote;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Scanning receipt...'**
  String get billScanning;

  /// Primary button
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get billScanButton;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get billAddItem;

  /// Image source
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get billTakePhoto;

  /// Image source
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get billFromGallery;

  /// OCR failure snackbar
  ///
  /// In en, this message translates to:
  /// **'No text detected. Try a clearer photo.'**
  String get billNoText;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get billAddPerson;

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

  /// Rate field hint
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get billRateHint;

  /// Default person name
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get billMe;

  /// No description provided for @billSharedEach.
  ///
  /// In en, this message translates to:
  /// **'Shared {count} ways · {amount} each'**
  String billSharedEach(int count, String amount);

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
  /// **'New transaction'**
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
  /// **'How envelopes work'**
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

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get allocSectionSpending;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Rollover'**
  String get allocSectionFlexible;

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

  /// Empty state button
  ///
  /// In en, this message translates to:
  /// **'Create envelope'**
  String get allocCreateButton;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'New envelope'**
  String get allocNewEnvelope;

  /// Fallback name
  ///
  /// In en, this message translates to:
  /// **'Envelope'**
  String get allocFallbackName;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Edit settings'**
  String get allocEditSettings;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get allocWithdrawMenu;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Revalue balances'**
  String get allocRevalueMenu;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get allocArchiveMenu;

  /// Bottom button
  ///
  /// In en, this message translates to:
  /// **'Create envelope'**
  String get allocCreateButtonDetail;

  /// Bottom button
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get allocSaveChanges;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Name & icon'**
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
  /// **'Envelope type'**
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

  /// Info text
  ///
  /// In en, this message translates to:
  /// **'Envelopes don\'t move money between accounts. They help you plan how to use the money you already have.'**
  String get allocInfoBanner;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get allocPurposeSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get allocCycleSection;

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

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Link category'**
  String get allocLinkCategory;

  /// Fund sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'From your unallocated balance'**
  String get allocFromUnallocated;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Fund anyway'**
  String get allocFundAnyway;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get allocRecentActivity;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get allocNoActivity;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Spending history'**
  String get allocSpendingHistory;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Withdraw from savings'**
  String get allocWithdrawTitle;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get allocWithdrawButton;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'No foreign-currency balances to revalue'**
  String get allocNoForeignBalances;

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
  /// **'Apply revaluation'**
  String get allocApplyRevaluation;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Archive envelope?'**
  String get allocArchiveTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This envelope will be hidden from all lists and stop taking spending. Linked categories and transaction history will be preserved.\n\nYou can unarchive it later from the Budget tab menu (⋮ › Archived envelopes).'**
  String get allocArchiveMsg;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Envelope archived'**
  String get allocArchived;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete envelope?'**
  String get allocDeleteTitle;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Archive instead'**
  String get allocArchiveInstead;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get allocDeletePermanently;

  /// Progress text
  ///
  /// In en, this message translates to:
  /// **'{pct}% saved'**
  String allocPercentSaved(int pct);

  /// No description provided for @allocFlexibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Rollover'**
  String get allocFlexibleTitle;

  /// No description provided for @allocFlexibleDesc.
  ///
  /// In en, this message translates to:
  /// **'Unspent money rolls over to the next period. Set an optional target, or leave it open.'**
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
  /// **'Monthly budget'**
  String get allocMonthlyBudget;

  /// No description provided for @allocTargetOptional.
  ///
  /// In en, this message translates to:
  /// **'Target (optional)'**
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
  /// **'Linked categories'**
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

  /// No description provided for @allocAmountSpent.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String allocAmountSpent(String amount);

  /// No description provided for @allocAmountToGo.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String allocAmountToGo(String amount);

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
  /// **'Funded from unallocated'**
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
  /// **'Period reset'**
  String get allocEntryPeriodReset;

  /// No description provided for @allocEntryCarryForward.
  ///
  /// In en, this message translates to:
  /// **'Carried forward'**
  String get allocEntryCarryForward;

  /// No description provided for @allocWithdrawDesc.
  ///
  /// In en, this message translates to:
  /// **'Move money from this envelope back to unallocated.'**
  String get allocWithdrawDesc;

  /// No description provided for @allocWithdrawAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to withdraw'**
  String get allocWithdrawAmountLabel;

  /// No description provided for @allocWithdrawSuccess.
  ///
  /// In en, this message translates to:
  /// **'Withdrew {amount} to unallocated'**
  String allocWithdrawSuccess(String amount);

  /// No description provided for @allocLinkCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Link a category'**
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
  /// **'Revalue foreign balances'**
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
  /// **'and {count} more'**
  String allocDeleteAndMore(int count);

  /// No description provided for @allocDeleteConsequences.
  ///
  /// In en, this message translates to:
  /// **'Deleting will:\n  • Unlink all categories from this envelope\n  • Remove all ledger history for this envelope\n\nConsider archiving instead to preserve history.'**
  String get allocDeleteConsequences;

  /// No description provided for @allocDeleteNoLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete envelope?'**
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

  /// Daily budget remaining
  ///
  /// In en, this message translates to:
  /// **'{amount}/day for {days} days'**
  String allocDailyBudget(String amount, int days);

  /// No description provided for @allocOtherCurrencies.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{+ 1 other currency} other{+ {count} other currencies}}'**
  String allocOtherCurrencies(int count);

  /// No description provided for @allocGoalsLoans.
  ///
  /// In en, this message translates to:
  /// **'Goals & loans'**
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

  /// No description provided for @allocNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No envelopes match \"{query}\"'**
  String allocNoMatch(String query);

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create an envelope for each thing you spend on, then fund it from Ready to assign.'**
  String get allocCreateHelp;

  /// No description provided for @allocNEnvelopesNeedReset.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 envelope needs reset} other{{count} envelopes need reset}}'**
  String allocNEnvelopesNeedReset(int count);

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Fund envelopes'**
  String get fundTitle;

  /// No description provided for @fundCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load envelopes'**
  String get fundCouldntLoad;

  /// No description provided for @fundNoAllocations.
  ///
  /// In en, this message translates to:
  /// **'No envelopes to fund'**
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
  /// **'Enter how much to put in each envelope, or use \"Quick fill\" to auto-fill periodic envelopes up to their target.'**
  String get fundStep2;

  /// No description provided for @fundStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Fund all\" to move the money into your envelopes.'**
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
  /// **'Quick fill'**
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
  /// **'Fund all  ({total})'**
  String fundAllWithTotal(String total);

  /// Warning dialog title
  ///
  /// In en, this message translates to:
  /// **'Over-funding'**
  String get fundOverfundingTitle;

  /// Warning dialog content
  ///
  /// In en, this message translates to:
  /// **'You\'re assigning {details}. Your unallocated balance will go negative.\n\nContinue anyway?'**
  String fundOverfundingMsg(String details);

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Fund anyway'**
  String get fundAnyway;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Funded from unallocated'**
  String get fundNote;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Allocations funded successfully'**
  String get fundSuccess;

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
  /// **'Total balance'**
  String get acctTotalBalance;

  /// FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get acctAddTooltip;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'New account'**
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
  /// **'Reconcile balance'**
  String get acctAdjustBalance;

  /// No description provided for @acctHideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide archived'**
  String get acctHideArchived;

  /// No description provided for @acctShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
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
  /// **'Archived'**
  String get acctArchived;

  /// No description provided for @acctNoArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived accounts'**
  String get acctNoArchived;

  /// No description provided for @acctUnarchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Unarchive account'**
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
  /// **'Current balance'**
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
  /// **'Convert back & close'**
  String get acctConvertBackClose;

  /// No description provided for @acctSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get acctSettings;

  /// No description provided for @acctNameSection.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get acctNameSection;

  /// No description provided for @acctAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get acctAccountName;

  /// No description provided for @acctTypeSection.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get acctTypeSection;

  /// No description provided for @acctCurrencySection.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get acctCurrencySection;

  /// No description provided for @acctSelectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select currency'**
  String get acctSelectCurrency;

  /// No description provided for @acctDecimalSection.
  ///
  /// In en, this message translates to:
  /// **'Decimal places'**
  String get acctDecimalSection;

  /// No description provided for @acctDecimalAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto ({count})'**
  String acctDecimalAuto(int count);

  /// No description provided for @acctOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get acctOpeningBalance;

  /// No description provided for @acctCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get acctCreateAccount;

  /// No description provided for @acctCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get acctCreated;

  /// No description provided for @acctUpdated.
  ///
  /// In en, this message translates to:
  /// **'Account updated'**
  String get acctUpdated;

  /// No description provided for @tmplCreated.
  ///
  /// In en, this message translates to:
  /// **'Template created'**
  String get tmplCreated;

  /// No description provided for @acctRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get acctRecentTransactions;

  /// No description provided for @acctNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get acctNoTransactions;

  /// No description provided for @acctAdjustDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the balance your bank (or wallet) shows. If it differs, an adjustment transaction is recorded for the difference.'**
  String get acctAdjustDesc;

  /// No description provided for @acctCurrentBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current balance: {amount}'**
  String acctCurrentBalanceLabel(String amount);

  /// No description provided for @acctEnterRealBalance.
  ///
  /// In en, this message translates to:
  /// **'Enter the real balance'**
  String get acctEnterRealBalance;

  /// No description provided for @acctApplyAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Apply adjustment'**
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
  /// **'Convert back'**
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
  /// **'Convert & archive'**
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
  /// **'Archive account'**
  String get acctArchiveTitle;

  /// No description provided for @acctArchiveMsg.
  ///
  /// In en, this message translates to:
  /// **'This account will be hidden from all lists and dropdowns. Your transactions will be preserved.\n\nTo bring it back, open Accounts → ⋮ → Show archived.'**
  String get acctArchiveMsg;

  /// No description provided for @acctDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account permanently'**
  String get acctDeleteTitle;

  /// No description provided for @acctDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'This account has no transactions. Are you sure you want to permanently delete it? This cannot be undone.'**
  String get acctDeleteMsg;

  /// No description provided for @acctArchiveInstead.
  ///
  /// In en, this message translates to:
  /// **'Archive instead'**
  String get acctArchiveInstead;

  /// No description provided for @acctHasTxnsMsg.
  ///
  /// In en, this message translates to:
  /// **'This account has {count} transaction(s). Archive it to keep everything but hide it, or delete it along with those transactions.'**
  String acctHasTxnsMsg(int count);

  /// No description provided for @acctDeleteWithTxns.
  ///
  /// In en, this message translates to:
  /// **'Delete with transactions'**
  String get acctDeleteWithTxns;

  /// No description provided for @acctDeleteSharedMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} of these are shared with other accounts (transfers or splits). Deleting will also remove them and change those accounts\' balances. Continue?'**
  String acctDeleteSharedMsg(int count);

  /// No description provided for @acctDeleteCountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this account and {count} transaction(s)? This cannot be undone.'**
  String acctDeleteCountConfirm(int count);

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
  /// **'Expense'**
  String get catSectionExpense;

  /// No description provided for @catSectionIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
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
  /// **'Delete category?'**
  String get catDeleteTitle;

  /// No description provided for @catDeleteNoTx.
  ///
  /// In en, this message translates to:
  /// **'This category has no transactions. Delete permanently?'**
  String get catDeleteNoTx;

  /// No description provided for @catDeleteSubsKept.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Its subcategory will become a top-level category.} other{Its {n} subcategories will become top-level categories.}}'**
  String catDeleteSubsKept(int n);

  /// No description provided for @catDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get catDeleted;

  /// No description provided for @catNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get catNewTitle;

  /// No description provided for @catEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
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

  /// Dialog/button cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

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
  /// **'Upcoming bills'**
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
  /// **'Price history'**
  String get subDetailPriceHistory;

  /// Date suffix
  ///
  /// In en, this message translates to:
  /// **'present'**
  String get subDetailPresent;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Change cancel date'**
  String get subDetailChangeCancel;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Set cancellation date'**
  String get subDetailSetCancel;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Past transactions'**
  String get subDetailPastTx;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get subDetailUpcoming;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'scheduled'**
  String get subDetailScheduled;

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
  /// **'New template'**
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
  /// **'Save template'**
  String get tmplSaveButton;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Goals & loans'**
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

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get objGoalsSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Loans'**
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
  /// **'New objective'**
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

  /// No description provided for @objNotePaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get objNotePaymentReceived;

  /// No description provided for @objNotePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get objNotePayment;

  /// No description provided for @objNoteGoalSavings.
  ///
  /// In en, this message translates to:
  /// **'Goal savings'**
  String get objNoteGoalSavings;

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
  /// **'Record payment'**
  String get objRecordPayment;

  /// Sheet/button
  ///
  /// In en, this message translates to:
  /// **'Add funds'**
  String get objAddFunds;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Record payment received'**
  String get objRecordReceived;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Record payment sent'**
  String get objRecordSent;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save from account'**
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
  /// **'Color'**
  String get objColorSection;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get objCannotUndo;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Saved so far'**
  String get objSavedSoFar;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Recorded so far'**
  String get objRecordedSoFar;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Add funds from one of your accounts to grow this goal.'**
  String get objEmptyHintGoal;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Record payments you receive to track repayment.'**
  String get objEmptyHintLoanLent;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Record payments you make to track what you owe.'**
  String get objEmptyHintLoanBorrowed;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Save toward a target. Each deposit moves money out of the account you pick and is recorded as a transaction.'**
  String get objWhatIsGoal;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Track money you lent or borrowed. Each recorded payment moves money in or out of the account you pick.'**
  String get objWhatIsLoan;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Optional — leave blank for an open-ended goal'**
  String get objTargetOptional;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Remove icon'**
  String get objRemoveIcon;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Goals track savings toward a target. Loans track money you lent or borrowed.'**
  String get objIntro;

  /// No description provided for @objDeleteLinkedPayments.
  ///
  /// In en, this message translates to:
  /// **'{count} linked payment(s). The money already moved between your accounts — keep them, or delete everything?'**
  String objDeleteLinkedPayments(int count);

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Delete, keep payments'**
  String get objDeleteKeep;

  /// Goals & loans
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get objDeleteAll;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get settingsMoreTitle;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get settingsToolsSection;

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
  /// **'Exchange currency for a trip'**
  String get settingsTravelSub;

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
  /// **'Track recurring subscriptions'**
  String get settingsSubscriptionsSub;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Savings goals and debt tracking'**
  String get settingsGoalsSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
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
  /// **'Auto-fill settings'**
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
  /// **'Reset everything'**
  String get resetTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL your data:\n\n• All accounts and balances\n• All transactions\n• All envelopes and categories\n• All settings\n\nThis cannot be undone. Are you absolutely sure?'**
  String get resetContent;

  /// Destructive button
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get resetButton;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Transaction colors'**
  String get txColorsTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Choose a color for each transaction type. These colors are used throughout the app to visually distinguish income, expenses, and transfers.'**
  String get txColorsDesc;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get txColorsReset;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get householdNameTitle;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Travel exchange'**
  String get tileTravelExchange;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get tileExchangeRates;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Web Companion'**
  String get tileWebCompanion;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get tileSubscriptions;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Goals & loans'**
  String get tileGoalsLoans;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
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
  /// **'Sync now'**
  String get syncNow;

  /// Button / sheet title
  ///
  /// In en, this message translates to:
  /// **'Share household'**
  String get syncShareHousehold;

  /// Button / dialog title
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get syncDisconnect;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Connect a provider'**
  String get syncConnectSection;

  /// Note
  ///
  /// In en, this message translates to:
  /// **'Receipt sync coming soon for this provider'**
  String get syncReceiptComingSoon;

  /// Info text
  ///
  /// In en, this message translates to:
  /// **'Folder uses your phone\'s file picker: keep the sync folder wherever you like. Each phone keeps its own files there. Receipt photos sync only with Google Drive.'**
  String get syncProviderInfo;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
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

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get syncShareCode;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Sync encryption'**
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
  /// **'Set sync password'**
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
  /// **'Confirm password'**
  String get syncConfirmPassword;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Set password'**
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
  /// **'Remove encryption?'**
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

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Automatic backups'**
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
  /// **'Manual backup'**
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
  /// **'Export & share'**
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
  /// **'Restore from file'**
  String get backupRestoreFromFile;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Local backups'**
  String get backupLocalSection;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
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
  /// **'Import & export'**
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
  /// **'Export report'**
  String get ieExportReport;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Generate a printable monthly report'**
  String get ieExportReportSub;

  /// AppBar title for CSV export
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportDataTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Export transactions'**
  String get exportTransTitle;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Export your transactions as a CSV file — all of them, or one period, account or category. Each amount is in its own currency. Opens in Excel, Google Sheets or any spreadsheet app.'**
  String get exportTransDesc;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReportTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
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
  /// **'Generate & share'**
  String get exportGenerateShare;

  /// HTML section
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get exportSpendingByCat;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
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
  /// **'Envelope alerts'**
  String get notifEnvelopeTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'You\'ll get a notification when envelopes are overspent or bills are coming up. The app checks when it opens or comes back to the foreground, at most once a day per alert.'**
  String get notifEnvelopeDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Upcoming bills'**
  String get notifBillsTitle;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a notification when recurring transactions are due within 2 days. Checked when the app opens or comes back, at most once a day.'**
  String get notifBillsDesc;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get fxTitle;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh rates'**
  String get fxRefreshTooltip;

  /// Info text
  ///
  /// In en, this message translates to:
  /// **'Live rates are cached for an hour and filled in when you add a transaction. Tap a currency to choose its rate: live, the last rate you got (from an exchange or change), or your own fixed rate.'**
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
  /// **'Privacy & terms'**
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
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsDataSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferencesSection;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecuritySection;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Recurring & bills'**
  String get tileRecurringBills;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Bill splitter'**
  String get tileBillSplitter;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Help guide'**
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
  /// **'Accent color'**
  String get tileAccentColor;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Transaction colors'**
  String get tileColors;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Income, expense & transfer'**
  String get tileColorsSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Entry mode'**
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
  /// **'Start screen'**
  String get tileStartScreen;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get tileFont;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get tileTextSize;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Transaction list'**
  String get tileTxList;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Layout, icons, date banner'**
  String get tileTxListSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get tileCloudSync;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Sync across devices'**
  String get tileCloudSyncSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Share household'**
  String get tileShareHousehold;

  /// Tile subtitle when connected
  ///
  /// In en, this message translates to:
  /// **'Invite someone to share your data'**
  String get tileShareHouseholdConnected;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get tileBackupRestore;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Export or restore database'**
  String get tileBackupRestoreSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Import & export'**
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
  /// **'Health check'**
  String get tileHealthCheck;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Verify data integrity & repair'**
  String get tileHealthCheckSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Sync receipts'**
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
  /// **'Base currency'**
  String get tileBaseCurrency;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Period start day'**
  String get tilePeriodStartDay;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'The day of the month when a new budget period starts.'**
  String get tilePeriodStartDayDesc;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Currency symbols'**
  String get tileCurrencySymbols;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Override how currencies are displayed'**
  String get tileCurrencySymbolsSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Number format'**
  String get tileNumberFormat;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get tileDateFormat;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Biometric lock'**
  String get tileBiometricLock;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint or face to open'**
  String get tileBiometricSub;

  /// Tile title
  ///
  /// In en, this message translates to:
  /// **'Reset everything'**
  String get tileResetEverything;

  /// Tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Erase all data and start fresh'**
  String get tileResetSub;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Entry mode'**
  String get entryModeTitle;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Choose how you add new transactions.'**
  String get entryModeDesc;

  /// Option title
  ///
  /// In en, this message translates to:
  /// **'Assisted (step-by-step)'**
  String get entryModeAssisted;

  /// Option description
  ///
  /// In en, this message translates to:
  /// **'Guides you through adding a transaction step by step. First pick a title, then a category, then enter the amount. Best for beginners.'**
  String get entryModeAssistedDesc;

  /// Option title
  ///
  /// In en, this message translates to:
  /// **'Classic (single form)'**
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
  /// **'Accent color'**
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

  /// Setting value label
  ///
  /// In en, this message translates to:
  /// **'System (Material You)'**
  String get accentColorSystemLabel;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Start screen'**
  String get startScreenTitle;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Opens when you launch the app.'**
  String get startScreenDesc;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Choose font'**
  String get chooseFontTitle;

  /// Font preview text
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog'**
  String get fontPreview;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeTitle;

  /// Preview subtitle
  ///
  /// In en, this message translates to:
  /// **'Preview text at this size'**
  String get textSizePreview;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Currency symbols'**
  String get currencySymbolsTitle;

  /// Sheet description
  ///
  /// In en, this message translates to:
  /// **'Tap any currency to change how its symbol is displayed. For example, change ل.ل to LBP.'**
  String get currencySymbolsDesc;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
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
  /// **'Number format'**
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
  /// **'Thousands separator'**
  String get numberFormatThousands;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Decimal separator'**
  String get numberFormatDecimal;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Negative numbers'**
  String get numberFormatNegative;

  /// Warning text
  ///
  /// In en, this message translates to:
  /// **'Some options are hidden because they conflict with the decimal separator.'**
  String get numberFormatConflict;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Date format'**
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
  /// **'Backup now'**
  String get backupNowButton;

  /// No description provided for @syncShareInviteText.
  ///
  /// In en, this message translates to:
  /// **'Join my BudgetSeal household! Enter this code in the app:\n{code}'**
  String syncShareInviteText(String code);

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Privacy & terms'**
  String get privacyTermsTitle;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicyTitle;

  /// Date
  ///
  /// In en, this message translates to:
  /// **'Last updated: October 2026'**
  String get privacyLastUpdated;

  /// Introduction
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal is designed with your privacy as a core principle. Your financial data belongs to you — we never collect, store, or transmit it to any server.'**
  String get privacyIntro;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'1. Data storage'**
  String get privacyDataStorageTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'All your financial data (transactions, accounts, envelopes, categories, goals, and settings) is stored locally on your device in an SQLite database. No data leaves your device unless you explicitly enable cloud sync.'**
  String get privacyDataStorageBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'2. Cloud sync (optional)'**
  String get privacyCloudSyncTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'If you choose to enable cloud sync, your data is uploaded to your personal Google Drive account or a file storage provider you select. BudgetSeal does not have access to your Google account credentials — authentication is handled by Google\'s OAuth system.\n\nYou may optionally encrypt your sync file with AES-256 encryption using a password you set. The password is stored only on your device in secure storage (Android Keystore / iOS Keychain).'**
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
  /// **'4. Analytics & tracking'**
  String get privacyAnalyticsTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal does not include any analytics SDKs, third-party crash reporting services, advertising libraries, or tracking pixels. No usage data, device identifiers, or behavioral metrics are collected. If you turn on crash reports (off by default), errors are saved on your device only, and leave it only if you choose to share them.'**
  String get privacyAnalyticsBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'5. Permissions'**
  String get privacyPermissionsTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'• Camera — used only for receipt scanning (offline OCR)\n• Notifications — daily reminders and bill alerts\n• Biometrics — optional app lock\n• Network — only for cloud sync and exchange rate fetching\n• Local Network — Web Companion server\n\nAll permissions are optional and can be denied without affecting core functionality.'**
  String get privacyPermissionsBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'6. Receipt images'**
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
  /// **'Terms of use'**
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
  /// **'2. Intended use'**
  String get termsIntendedUseTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal is a personal finance management tool for individual and household budgeting. It is not intended for commercial accounting, tax preparation, or financial advice. The app provides tools to organize your finances — it does not provide financial recommendations.'**
  String get termsIntendedUseBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'3. Data accuracy'**
  String get termsDataAccuracyTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'You are responsible for the accuracy of the data you enter. BudgetSeal calculates balances, budgets, and reports based on your input. Exchange rates fetched from external sources are approximate and may not reflect real-time market rates.'**
  String get termsDataAccuracyBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'4. No warranty'**
  String get termsNoWarrantyTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal is provided \"as is\" without warranty of any kind. While we strive for reliability, we cannot guarantee that the app will be error-free or uninterrupted. Regular backups are strongly recommended.'**
  String get termsNoWarrantyBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'5. Limitation of liability'**
  String get termsLiabilityTitle;

  /// Body
  ///
  /// In en, this message translates to:
  /// **'The developer shall not be liable for any direct, indirect, incidental, or consequential damages arising from the use of BudgetSeal, including but not limited to data loss, financial miscalculations, or sync failures.'**
  String get termsLiabilityBody;

  /// Heading
  ///
  /// In en, this message translates to:
  /// **'6. Intellectual property'**
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
  /// **'For questions or concerns about this privacy policy or terms of use, contact: fancyshark505@gmail.com'**
  String get termsContactBody;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Health check'**
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
  /// **'All clear'**
  String get healthAllClear;

  /// Status title
  ///
  /// In en, this message translates to:
  /// **'Issues found'**
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
  /// **'Balance invariant'**
  String get healthBalanceInvariant;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Account balances'**
  String get healthAccountBalances;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Envelope balances'**
  String get healthEnvelopeBalances;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Data quality'**
  String get healthDataQuality;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Repair balances'**
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
  /// **'Repair balances'**
  String get healthRepairTitle;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'This will create adjustment ledger entries to bring allocation balances back in line with account balances. A backup is recommended before proceeding.\n\nContinue?'**
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
  /// **'Purge deleted transactions'**
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

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// Hint title
  ///
  /// In en, this message translates to:
  /// **'Explore your spending patterns'**
  String get reportsHintTitle;

  /// Hint body
  ///
  /// In en, this message translates to:
  /// **'Pick a period at the top. The first card sums it up in a sentence; every report below opens for the same period.'**
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
  String reportsLessThanLast(int pct);

  /// Comparison
  ///
  /// In en, this message translates to:
  /// **'{pct}% more than last month'**
  String reportsMoreThanLast(int pct);

  /// Comparison
  ///
  /// In en, this message translates to:
  /// **'Same as last month'**
  String get reportsSameAsLast;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Spending activity'**
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
  /// **'6-month trend'**
  String get reports6MonthTrend;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Daily pace'**
  String get reportsDailyPaceToggle;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No spending this month'**
  String get reportsNoSpending;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Top spending'**
  String get reportsTopSpending;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Top transactions'**
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
  /// **'Spending velocity'**
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
  /// **'Biggest expense'**
  String get reportsBiggestExpense;

  /// Card label
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get reportsSavingsRate;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get reportsRecurringTitle;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Age of money'**
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
  /// **'Age of money measures how many days your money sits before you spend it. It traces each expense back to the income that funded it (oldest income first).'**
  String get reportsAgeExplanation;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get reportsTipsSection;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get reportsNetWorth;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get reportsAssets;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get reportsLiabilities;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Compare balances to:'**
  String get reportsCompareTo;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'End of last week'**
  String get reportsEndLastWeek;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'End of last month'**
  String get reportsEndLastMonth;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'Same time last month'**
  String get reportsSameTimeLastMonth;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'End of last quarter'**
  String get reportsEndLastQuarter;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'End of last year'**
  String get reportsEndLastYear;

  /// Compare option
  ///
  /// In en, this message translates to:
  /// **'Same time last year'**
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
  /// **'Stop server'**
  String get wcStopButton;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Start server'**
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
  /// **'No WiFi connection'**
  String get wcNoWifiTitle;

  /// Banner description
  ///
  /// In en, this message translates to:
  /// **'Connect your phone to a WiFi network to use Web Companion. The server needs WiFi to let your laptop access the budget.'**
  String get wcNoWifiDesc;

  /// Banner title
  ///
  /// In en, this message translates to:
  /// **'Public network detected'**
  String get wcPublicNetwork;

  /// Banner title
  ///
  /// In en, this message translates to:
  /// **'Network security'**
  String get wcNetworkSecurity;

  /// Warning title
  ///
  /// In en, this message translates to:
  /// **'Security warning'**
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

  /// Auth error
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get webAuthIncorrect;

  /// Toast button
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get webUndo;

  /// Warning
  ///
  /// In en, this message translates to:
  /// **'No rate'**
  String get webTxNoRate;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get webTxAdd;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Search titles and notes'**
  String get webTxSearch;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get webFormType;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get webFormFromAccount;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get webFormAccount;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get webFormToAccount;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get webFormCategory;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get webFormAmount;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get webFormCurrency;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get webFormDate;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get webFormOptional;

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
  /// **'Pick two different accounts'**
  String get webValAccountsDiffer;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Transaction added'**
  String get webToastTxAdded;

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

  /// Empty title
  ///
  /// In en, this message translates to:
  /// **'No categories here'**
  String get webCatEmptyTitle;

  /// Empty subtitle
  ///
  /// In en, this message translates to:
  /// **'Categories group your spending and income.'**
  String get webCatEmptySub;

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
  /// **'Category saved'**
  String get webToastCatUpdated;

  /// Empty title
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get webAcctEmptyTitle;

  /// Empty subtitle
  ///
  /// In en, this message translates to:
  /// **'Add the accounts you pay from to start tracking.'**
  String get webAcctEmptySub;

  /// Group label
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get webAcctTypeBank;

  /// Group label
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get webAcctTypeCash;

  /// Group label
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get webAcctTypeCredit;

  /// Group label
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get webAcctTypeWallet;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Account added'**
  String get webToastAcctAdded;

  /// Empty title
  ///
  /// In en, this message translates to:
  /// **'No envelopes yet'**
  String get webEnvEmptyTitle;

  /// Empty subtitle
  ///
  /// In en, this message translates to:
  /// **'Create envelopes in the app\'s Budget tab, then fund them from here.'**
  String get webEnvEmptySub;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get webEnvFund;

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

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get webFormEvery;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Recurring added'**
  String get webToastRecurringAdded;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get webToastUpdated;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get webValSelectStartDate;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete this recurring item?'**
  String get webConfirmDeleteRecurring;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'It stops posting. Transactions it already posted stay.'**
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

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Subscription added'**
  String get webToastSubAdded;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'A new amount is added to the price history.'**
  String get webSubPriceHint;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete this subscription?'**
  String get webConfirmDeleteSub;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'It stops posting. Payments already recorded stay.'**
  String get webConfirmDeleteSubMsg;

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
  /// **'Savings rate'**
  String get webStatSavingsRate;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Average per day'**
  String get webStatAvgDaily;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get webStatTransactions;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Day by day'**
  String get webReportDailyCashflow;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get webReportSpendingCat;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No spending this month'**
  String get webReportNoExpense;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Income by category'**
  String get webReportIncomeCat;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No income this month'**
  String get webReportNoIncome;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Biggest expenses'**
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
  /// **'Keyboard shortcuts'**
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
  /// **'Close the dialog'**
  String get webShortcutClose;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Show this help'**
  String get webShortcutHelp;

  /// Notification title
  ///
  /// In en, this message translates to:
  /// **'Low envelopes'**
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
  /// **'Upcoming bills'**
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
  /// **'Budget alert'**
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
  /// **'Daily reminder'**
  String get notifReminderChannel;

  /// Channel description
  ///
  /// In en, this message translates to:
  /// **'Daily reminder to log transactions'**
  String get notifReminderChannelDesc;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Auto-covered from unallocated'**
  String get engineAutoCovered;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Direct from income'**
  String get engineDirectIncome;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Withdrawn to unallocated'**
  String get engineWithdrawn;

  /// Ledger note
  ///
  /// In en, this message translates to:
  /// **'Period reset — returned to unallocated'**
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
  /// **'Extra large'**
  String get textScaleExtraLarge;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get defcatGroceries;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get defcatFuel;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Public transit'**
  String get defcatPublicTransit;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Parking & tolls'**
  String get defcatParkingTolls;

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
  /// **'Health'**
  String get defcatHealth;

  /// Default category
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get defcatPharmacy;

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
  /// **'Other income'**
  String get defcatOtherIncome;

  /// Default category preset group
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
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
  /// **'Dining out'**
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

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get defcatWater;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get defcatInsurance;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get defcatPets;

  /// Default category preset
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get defcatOther;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Select a folder for BudgetSeal sync'**
  String get filePickerTitle;

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
  /// **'Get started'**
  String get onboardGetStarted;

  /// Onboarding restore button
  ///
  /// In en, this message translates to:
  /// **'Restore my budget'**
  String get onboardRestoreCloud;

  /// Onboarding join button
  ///
  /// In en, this message translates to:
  /// **'Join a household'**
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
  /// **'Household'**
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
  /// **'First account'**
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
  /// **'Categories'**
  String get onboardCategoriesSection;

  /// Onboarding category option subtitle
  ///
  /// In en, this message translates to:
  /// **'30 categories with subcategories'**
  String get onboardFullSetSub;

  /// Onboarding category option subtitle
  ///
  /// In en, this message translates to:
  /// **'Create your own from scratch'**
  String get onboardEmptySub;

  /// Onboarding submit button
  ///
  /// In en, this message translates to:
  /// **'Create my budget'**
  String get onboardCreateStart;

  /// Onboarding done page title
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardAllSet;

  /// Onboarding done page subtitle
  ///
  /// In en, this message translates to:
  /// **'The checklist on Home shows your next steps: record your income, then give it jobs in envelopes.'**
  String get onboardDoneSubtitle;

  /// Onboarding done page button
  ///
  /// In en, this message translates to:
  /// **'Start using BudgetSeal'**
  String get onboardStartUsing;

  /// Onboarding restore sheet title
  ///
  /// In en, this message translates to:
  /// **'Restore your budget'**
  String get onboardRestoreTitle;

  /// Onboarding restore sheet description
  ///
  /// In en, this message translates to:
  /// **'Choose where your budget syncs: Google Drive, or a folder on this phone or one another app keeps in sync. It replaces any data on this phone.'**
  String get onboardRestoreDesc;

  /// Onboarding restore option
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get onboardGoogleDrive;

  /// Onboarding restore option
  ///
  /// In en, this message translates to:
  /// **'Pick a folder'**
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
  /// **'BS1-...'**
  String get onboardInviteHint;

  /// Onboarding join button
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get onboardJoinButton;

  /// Onboarding join validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter an invite code'**
  String get onboardEnterCodeError;

  /// Onboarding join validation error
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code. It should start with BS1-'**
  String get onboardInvalidCodeError;

  /// Join sheet button
  ///
  /// In en, this message translates to:
  /// **'Scan code'**
  String get joinScanCode;

  /// Scanner screen title
  ///
  /// In en, this message translates to:
  /// **'Scan the invite code'**
  String get joinScanTitle;

  /// Scanner screen hint
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code on the other phone.'**
  String get joinScanHint;

  /// Scanner: camera unavailable
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera. Type the code instead.'**
  String get joinScanNoCamera;

  /// Share sheet, under the QR
  ///
  /// In en, this message translates to:
  /// **'On their phone: Join a household › Scan code.'**
  String get syncShareScanHint;

  /// Cloud Sync: confirm join
  ///
  /// In en, this message translates to:
  /// **'Join a household?'**
  String get joinReplaceTitle;

  /// Cloud Sync: confirm join
  ///
  /// In en, this message translates to:
  /// **'The shared budget replaces the one on this phone. A backup of it is saved first in Backup & Restore.'**
  String get joinReplaceBody;

  /// Sync provider name
  ///
  /// In en, this message translates to:
  /// **'Household sync'**
  String get relayName;

  /// Household sync error
  ///
  /// In en, this message translates to:
  /// **'No household found for this code. Ask for a new code.'**
  String get relayErrNotFound;

  /// Household sync error
  ///
  /// In en, this message translates to:
  /// **'This household code doesn\'t work any more. Ask for a new code.'**
  String get relayErrKey;

  /// Household sync error
  ///
  /// In en, this message translates to:
  /// **'This household has reached its storage limit.'**
  String get relayErrFull;

  /// Household sync error
  ///
  /// In en, this message translates to:
  /// **'Household sync is busy. Try again in a minute.'**
  String get relayErrBusy;

  /// Household sync error
  ///
  /// In en, this message translates to:
  /// **'Household sync can\'t be reached right now. Try again later.'**
  String get relayErrServer;

  /// Joining a household whose creator never synced
  ///
  /// In en, this message translates to:
  /// **'This household has no budget yet. Ask the person who invited you to open BudgetSeal and sync.'**
  String get relayEmptyHousehold;

  /// Cloud Sync section
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdSection;

  /// Cloud Sync row / confirm button
  ///
  /// In en, this message translates to:
  /// **'Start a household'**
  String get householdStart;

  /// Cloud Sync row / Settings tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Share this budget with your partner or family'**
  String get householdStartSub;

  /// Cloud Sync row subtitle
  ///
  /// In en, this message translates to:
  /// **'Use a budget someone shared with you'**
  String get householdJoinSub;

  /// Confirm title
  ///
  /// In en, this message translates to:
  /// **'Start a household?'**
  String get householdStartTitle;

  /// Confirm message
  ///
  /// In en, this message translates to:
  /// **'Your budget will sync through BudgetSeal\'s server. It\'s encrypted on this phone first: only phones with your household\'s code can read it, not even BudgetSeal. On this phone it replaces Google Drive or folder sync.'**
  String get householdStartBody;

  /// Cloud Sync button
  ///
  /// In en, this message translates to:
  /// **'Invite someone'**
  String get householdInvite;

  /// Invite sheet title
  ///
  /// In en, this message translates to:
  /// **'Invite to your household'**
  String get householdInviteTitle;

  /// Invite sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Anyone with this code can see and change your budget. Share it only with people you trust.'**
  String get householdInviteBody;

  /// Cloud Sync button / confirm
  ///
  /// In en, this message translates to:
  /// **'Leave household'**
  String get householdLeave;

  /// Confirm title
  ///
  /// In en, this message translates to:
  /// **'Leave this household?'**
  String get householdLeaveTitle;

  /// Confirm message
  ///
  /// In en, this message translates to:
  /// **'This phone stops syncing with the household. The budget stays on this phone, and the others keep theirs.'**
  String get householdLeaveBody;

  /// SnackBar
  ///
  /// In en, this message translates to:
  /// **'Left the household'**
  String get householdLeftSnack;

  /// Join validation
  ///
  /// In en, this message translates to:
  /// **'This code is from an older version of BudgetSeal. Ask for the app to be updated on the other phone, then share again.'**
  String get joinOldCode;

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
  /// **'Need help? Check our guide anytime from More > Help guide.'**
  String get onboardHelpHint;

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

  /// Travel exchange screen title
  ///
  /// In en, this message translates to:
  /// **'Travel exchange'**
  String get travelTitle;

  /// Travel exchange info banner
  ///
  /// In en, this message translates to:
  /// **'Exchange money for your trip. A temporary travel wallet will be created automatically.'**
  String get travelInfo;

  /// Travel exchange section label
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get travelFrom;

  /// Travel exchange dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get travelSelectAccount;

  /// Travel exchange section label
  ///
  /// In en, this message translates to:
  /// **'Amount to exchange'**
  String get travelAmountToExchange;

  /// Travel exchange section label
  ///
  /// In en, this message translates to:
  /// **'Travel currency'**
  String get travelCurrencySection;

  /// Travel exchange currency picker label
  ///
  /// In en, this message translates to:
  /// **'Currency you receive'**
  String get travelCurrencyReceive;

  /// Travel exchange section label
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get travelAmountReceived;

  /// Travel exchange submit button
  ///
  /// In en, this message translates to:
  /// **'Exchange & create travel wallet'**
  String get travelExchangeButton;

  /// Travel exchange reactivate dialog title
  ///
  /// In en, this message translates to:
  /// **'Existing travel wallet'**
  String get travelExistingWallet;

  /// Travel exchange reactivate dialog text
  ///
  /// In en, this message translates to:
  /// **'You have a previous {currency} travel wallet:'**
  String travelPreviousWallet(String currency);

  /// Travel exchange reactivate dialog button
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get travelCreateNew;

  /// Travel exchange reactivate dialog button
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get travelReactivate;

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

  /// Period transition screen title
  ///
  /// In en, this message translates to:
  /// **'New period'**
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
  /// **'No envelopes are waiting for review this period.'**
  String get periodAllZero;

  /// Period transition submit button
  ///
  /// In en, this message translates to:
  /// **'Complete period transition'**
  String get periodCompleteButton;

  /// Period transition error snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to complete transition. Please try again.'**
  String get periodTransitionFailed;

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
  /// **'Return to unallocated'**
  String get periodReturnUnallocated;

  /// Period resolution option description
  ///
  /// In en, this message translates to:
  /// **'Balance returns to the pool'**
  String get periodReturnDesc;

  /// Period resolution option
  ///
  /// In en, this message translates to:
  /// **'Carry forward'**
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
  /// **'Resolve leftovers'**
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

  /// Leftover resolution error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get leftoverLoadError;

  /// Leftover resolution section label
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
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

  /// Leftover resolution error snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve leftovers. Please try again.'**
  String get leftoverResolveFailed;

  /// Error boundary retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
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

  /// Edit bill: next due moved back
  ///
  /// In en, this message translates to:
  /// **'Record {count} missed payments?'**
  String recurringCatchUpTitle(int count);

  /// Edit bill: next due moved back
  ///
  /// In en, this message translates to:
  /// **'The next due date is in the past. Next time the app opens, it records every payment due since then (up to a year back).'**
  String get recurringCatchUpMessage;

  /// Add sheet title
  ///
  /// In en, this message translates to:
  /// **'New recurring transaction'**
  String get recurringNewTitle;

  /// Add sheet title when subscription
  ///
  /// In en, this message translates to:
  /// **'New subscription'**
  String get recurringNewSubTitle;

  /// Edit sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit recurring transaction'**
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
  /// **'{age, plural, =1{1 day} other{{age} days}}'**
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
  /// **'Help guide'**
  String get helpGuideTitle;

  /// Receipt picker option
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get receiptTakePhoto;

  /// Receipt picker option
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
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
  /// **'Import from bank CSV'**
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

  /// No description provided for @importFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'This file is empty, so there\'s nothing to import.'**
  String get importFileEmpty;

  /// Row count after loading CSV
  ///
  /// In en, this message translates to:
  /// **'Found {count} rows in {fileName}'**
  String importFoundRows(int count, String fileName);

  /// Section title for column mapping
  ///
  /// In en, this message translates to:
  /// **'Column mapping'**
  String get importColumnMapping;

  /// Column mapping description
  ///
  /// In en, this message translates to:
  /// **'Assign a role to each column. Roles were auto-detected -- adjust as needed.'**
  String get importColumnMapDesc;

  /// Section title for preview
  ///
  /// In en, this message translates to:
  /// **'Import preview'**
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
  /// **'Please assign an amount column'**
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
  /// **'Payments'**
  String get objPaymentsSection;

  /// Section header for settings form
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get objSettingsSection;

  /// Section header for type toggle
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get objTypeSection;

  /// Menu item to hide settings
  ///
  /// In en, this message translates to:
  /// **'Hide settings'**
  String get objHideSettings;

  /// Menu item to show settings
  ///
  /// In en, this message translates to:
  /// **'Edit settings'**
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
  /// **'BudgetSeal health check report'**
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

  /// Currency sheet section header
  ///
  /// In en, this message translates to:
  /// **'Your accounts'**
  String get currencyYourAccounts;

  /// Currency sheet section header
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get currencyRecentlyUsed;

  /// Currency sheet section header
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get currencyAll;

  /// Snackbar after connecting sync provider
  ///
  /// In en, this message translates to:
  /// **'Connected to {provider}'**
  String syncConnectedTo(String provider);

  /// Status subtitle with last sync time
  ///
  /// In en, this message translates to:
  /// **'Last synced {time} · {suffix}'**
  String syncLastSynced(String time, String suffix);

  /// Suffix for changes merged
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change merged} other{{count} changes merged}}'**
  String syncChangesMerged(int count);

  /// Suffix when no changes
  ///
  /// In en, this message translates to:
  /// **'up to date'**
  String get syncUpToDate;

  /// Language picker subtitle for system option
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get languageSystemDesc;

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
  /// **'Planned payments'**
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

  /// Dialog body for posting all planned payments
  ///
  /// In en, this message translates to:
  /// **'Post all {count} planned payments for {month}?'**
  String plannedPostAllContent(int count, String month);

  /// Button label to post all planned payments
  ///
  /// In en, this message translates to:
  /// **'Post all'**
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
  /// **'Plan payment'**
  String get plannedPlanButton;

  /// AppBar title when editing a planned payment
  ///
  /// In en, this message translates to:
  /// **'Edit planned payment'**
  String get plannedEditTitle;

  /// Label for month picker in plan payment form
  ///
  /// In en, this message translates to:
  /// **'Target month'**
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

  /// Activity: planned payments past the next 30 days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more later} other{{count} more later}}'**
  String plannedMoreLater(int count);

  /// SnackBar after successful travel exchange
  ///
  /// In en, this message translates to:
  /// **'Exchanged {fromAmount} → {toAmount}. Open the travel wallet and use \"Convert back & close\" to return leftover money.'**
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
  /// **'Save as template'**
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
  /// **'Arabic-Indic numerals'**
  String get tileArabicDigits;

  /// Upgrade screen title
  ///
  /// In en, this message translates to:
  /// **'Upgrade to premium'**
  String get upgradeTitle;

  /// Upgrade screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Unlock every feature with a single purchase. No subscriptions, no ads.'**
  String get upgradeSubtitle;

  /// Premium feature: cloud sync
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get upgradeFeatureSync;

  /// Premium feature: web companion
  ///
  /// In en, this message translates to:
  /// **'Web Companion'**
  String get upgradeFeatureWebCompanion;

  /// Premium feature: bill splitter
  ///
  /// In en, this message translates to:
  /// **'Bill splitter'**
  String get upgradeFeatureBillSplitter;

  /// Premium feature: travel exchange
  ///
  /// In en, this message translates to:
  /// **'Travel exchange'**
  String get upgradeFeatureTravelExchange;

  /// Premium feature: planned payments
  ///
  /// In en, this message translates to:
  /// **'Planned payments'**
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
  /// **'Redeem code'**
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
  /// **'Restore purchase'**
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

  /// Switch title
  ///
  /// In en, this message translates to:
  /// **'Add suggested categories'**
  String get onboardSeedCategories;

  /// Currency sheet section header (the chosen currency)
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get currencySelected;

  /// Home empty state button (opens the income form)
  ///
  /// In en, this message translates to:
  /// **'Record your income'**
  String get dashboardRecordIncome;

  /// Snackbar: withdraw more than the envelope holds
  ///
  /// In en, this message translates to:
  /// **'This envelope doesn\'t hold that much.'**
  String get allocWithdrawTooMuch;

  /// Snackbar: funding envelopes failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fund the envelopes. Try again.'**
  String get fundFailed;

  /// Lock screen snackbar: unlock failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t unlock. Try again.'**
  String get lockUnlockFailed;

  /// Health check per-currency totals
  ///
  /// In en, this message translates to:
  /// **'Accounts: {accounts} | Envelopes: {envelopes}'**
  String healthAccountsVsEnvelopes(String accounts, String envelopes);

  /// Assisted save summary item count
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 item} other{{n} items}}'**
  String txAfItemsCount(int n);

  /// Onboarding: switch to create envelopes for the main spending groups
  ///
  /// In en, this message translates to:
  /// **'Create envelopes for main categories'**
  String get onboardSeedEnvelopes;

  /// Onboarding: subtitle of the envelopes switch
  ///
  /// In en, this message translates to:
  /// **'Food, transport, bills and more. You fund them after recording your income.'**
  String get onboardSeedEnvelopesSub;

  /// Home: getting-started checklist title
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get gsTitle;

  /// Home: checklist progress, e.g. 2 of 4
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String gsProgress(int done, int total);

  /// Home: tooltip to hide the checklist
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get gsHide;

  /// Checklist step 1
  ///
  /// In en, this message translates to:
  /// **'Record your income'**
  String get gsIncomeTitle;

  /// Checklist step 1 hint
  ///
  /// In en, this message translates to:
  /// **'Money comes in first. Then you give it jobs.'**
  String get gsIncomeBody;

  /// Checklist step 2
  ///
  /// In en, this message translates to:
  /// **'Create envelopes'**
  String get gsEnvelopesTitle;

  /// Checklist step 2 hint
  ///
  /// In en, this message translates to:
  /// **'One for each thing you spend on, like groceries or rent.'**
  String get gsEnvelopesBody;

  /// Checklist step 3
  ///
  /// In en, this message translates to:
  /// **'Fund your envelopes'**
  String get gsFundTitle;

  /// Checklist step 3 hint
  ///
  /// In en, this message translates to:
  /// **'Move money from Ready to assign into your envelopes.'**
  String get gsFundBody;

  /// Checklist step 4
  ///
  /// In en, this message translates to:
  /// **'Log an expense'**
  String get gsExpenseTitle;

  /// Checklist step 4 hint
  ///
  /// In en, this message translates to:
  /// **'It comes out of the matching envelope.'**
  String get gsExpenseBody;

  /// Customize Home: section name
  ///
  /// In en, this message translates to:
  /// **'Your budget'**
  String get dashboardSectionBudgetLabel;

  /// Customize Home: section description
  ///
  /// In en, this message translates to:
  /// **'Ready to assign, overspent envelopes, bills due'**
  String get dashboardSectionBudgetDesc;

  /// Home: card listing overspent envelopes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 envelope overspent} other{{count} envelopes overspent}}'**
  String homeOverspentTitle(int count);

  /// Home: how much an envelope is overspent
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String homeOverBy(String amount);

  /// Envelope detail: shown next to the seal when the envelope reached its target
  ///
  /// In en, this message translates to:
  /// **'Fully funded'**
  String get sealFullyFunded;

  /// Ready to assign banner when every bit of money is in an envelope
  ///
  /// In en, this message translates to:
  /// **'All sealed'**
  String get sealAllSealed;

  /// Ready to assign banner subtitle when all money is assigned
  ///
  /// In en, this message translates to:
  /// **'Every bit of your money has a job.'**
  String get sealAllSealedBody;

  /// Budget tab: card in the first week of a period about the last one, e.g. "September sealed"
  ///
  /// In en, this message translates to:
  /// **'{month} sealed'**
  String periodSealedTitle(String month);

  /// Activity row: envelope balance right after the expense, e.g. "$142.80 left" (the envelope name is shown before it)
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String txImpactLeft(String amount);

  /// Activity row / month card: how far below zero, e.g. "over by $8.00"
  ///
  /// In en, this message translates to:
  /// **'over by {amount}'**
  String txImpactOver(String amount);

  /// Activity row pill: expense whose category has no envelope
  ///
  /// In en, this message translates to:
  /// **'Not budgeted'**
  String get txImpactNotBudgeted;

  /// Activity month card title, e.g. "October budget"
  ///
  /// In en, this message translates to:
  /// **'{month} budget'**
  String txMonthBudget(String month);

  /// Activity month card line
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {budgeted} budgeted · income {income}'**
  String txMonthSpentOf(String spent, String budgeted, String income);

  /// Activity month card line when no envelope has a target
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} · income {income}'**
  String txMonthSpent(String spent, String income);

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get webGsTitle;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String webGsProgress(String done, String total);

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get webGsHide;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'Record your income'**
  String get webGsIncomeTitle;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'Money comes in first. Then you give it jobs.'**
  String get webGsIncomeBody;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'Create envelopes'**
  String get webGsEnvelopesTitle;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'One for each thing you spend on, like groceries or rent.'**
  String get webGsEnvelopesBody;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'Fund your envelopes'**
  String get webGsFundTitle;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'Move money from Ready to assign into your envelopes.'**
  String get webGsFundBody;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'Log an expense'**
  String get webGsExpenseTitle;

  /// Web Companion: getting-started checklist on Home (same as the app)
  ///
  /// In en, this message translates to:
  /// **'It comes out of the matching envelope.'**
  String get webGsExpenseBody;

  /// Web: Ready to assign banner when every bit of money is in an envelope
  ///
  /// In en, this message translates to:
  /// **'All sealed'**
  String get webSealAllSealed;

  /// Web: Ready to assign banner subtitle when all money is assigned
  ///
  /// In en, this message translates to:
  /// **'Every bit of your money has a job.'**
  String get webSealAllSealedBody;

  /// Web: envelope card tag next to the seal
  ///
  /// In en, this message translates to:
  /// **'Fully funded'**
  String get webSealFullyFunded;

  /// Web: past month within budget, e.g. "September sealed"
  ///
  /// In en, this message translates to:
  /// **'{month} sealed'**
  String webMonthSealed(String month);

  /// Web transaction row: envelope balance after, e.g. "$142.80 left"
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String webImpactLeft(String amount);

  /// Web transaction row / month card: "over by $8.00"
  ///
  /// In en, this message translates to:
  /// **'over by {amount}'**
  String webImpactOver(String amount);

  /// Web transaction row pill: no envelope for this category
  ///
  /// In en, this message translates to:
  /// **'Not budgeted'**
  String get webImpactNotBudgeted;

  /// Web transactions: month card title, e.g. "October budget"
  ///
  /// In en, this message translates to:
  /// **'{month} budget'**
  String webMonthBudget(String month);

  /// Web transactions: month card line
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {budgeted} budgeted · income {income}'**
  String webMonthSpentOf(String spent, String budgeted, String income);

  /// Web transactions: month card line without envelope targets
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} · income {income}'**
  String webMonthSpent(String spent, String income);

  /// Web Home: card listing envelopes below zero
  ///
  /// In en, this message translates to:
  /// **'Overspent envelopes'**
  String get webOverspentTitle;

  /// Web Home: overspent envelope row, e.g. "Over by $9.00"
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String webEnvOverBy(String amount);

  /// Web Home: bills due within 7 days
  ///
  /// In en, this message translates to:
  /// **'Bills due this week'**
  String get webBillsWeek;

  /// Web transaction row: split across several accounts
  ///
  /// In en, this message translates to:
  /// **'{n} accounts'**
  String webNAccounts(String n);

  /// Bill splitter: screen title
  ///
  /// In en, this message translates to:
  /// **'Split a bill'**
  String get billScreenTitle;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'Bill total'**
  String get billTotalLabel;

  /// Bill splitter: under the total, e.g. "+ tip $9.00"
  ///
  /// In en, this message translates to:
  /// **'+ tip {amount}'**
  String billPlusTip(Object amount);

  /// Bill splitter: under the total
  ///
  /// In en, this message translates to:
  /// **'+ tax or service {amount}'**
  String billPlusTax(Object amount);

  /// Bill splitter: tip chip, any amount
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get billTipCustom;

  /// Bill splitter: optional link under the tip
  ///
  /// In en, this message translates to:
  /// **'Tax or service charge'**
  String get billAddTax;

  /// Bill splitter: tax choice
  ///
  /// In en, this message translates to:
  /// **'Percentage of the bill'**
  String get billTaxPercent;

  /// Bill splitter: tax choice
  ///
  /// In en, this message translates to:
  /// **'Fixed amount'**
  String get billTaxFixed;

  /// Bill splitter: section header
  ///
  /// In en, this message translates to:
  /// **'Who\'s in'**
  String get billWhosIn;

  /// Bill splitter: split mode
  ///
  /// In en, this message translates to:
  /// **'Evenly'**
  String get billEvenly;

  /// Bill splitter: split mode
  ///
  /// In en, this message translates to:
  /// **'By item'**
  String get billByItem;

  /// Bill splitter: the user in the people list
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get billYou;

  /// Bill splitter: people from earlier splits and loans
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get billRecent;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'Tap an amount to set it by hand — the others rebalance.'**
  String get billByHandHint;

  /// Bill splitter: bottom bar label
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get billPaidBy;

  /// Bill splitter: bottom bar label, the account
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get billFrom;

  /// Bill splitter: everyone paid their own part
  ///
  /// In en, this message translates to:
  /// **'Each their own'**
  String get billEachOwn;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'{name} owes you {amount}'**
  String billOwesYouOne(String name, String amount);

  /// Bill splitter: several people
  ///
  /// In en, this message translates to:
  /// **'They owe you {amount}'**
  String billTheyOweYou(Object amount);

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String billYouOwe(String name, String amount);

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'No one owes anyone'**
  String get billNobodyOwes;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves your account until you pay {name} back.'**
  String billNothingLeaves(Object name);

  /// Bill splitter: save button
  ///
  /// In en, this message translates to:
  /// **'Save · {amount} from {account}'**
  String billSaveFrom(String amount, String account);

  /// Bill splitter: save button
  ///
  /// In en, this message translates to:
  /// **'Save · you owe {name} {amount}'**
  String billSaveOwe(String name, String amount);

  /// Bill splitter: save button
  ///
  /// In en, this message translates to:
  /// **'Save · your share {amount}'**
  String billSaveShare(Object amount);

  /// Bill splitter: by item, a person is picked
  ///
  /// In en, this message translates to:
  /// **'Tap what {name} had'**
  String billTapWhatHad(Object name);

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'Tap a person below, then the items they had.'**
  String get billPickPersonHint;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'Everyone · {amount} each'**
  String billEveryoneEach(Object amount);

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'{name} only'**
  String billOnly(Object name);

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'{name}\'s items are now shared by everyone'**
  String billItemsSharedNow(Object name);

  /// Bill splitter: SnackBar after removing a person (with Undo)
  ///
  /// In en, this message translates to:
  /// **'{name} removed from the split'**
  String billPersonRemoved(Object name);

  /// Bill splitter: Save with no account
  ///
  /// In en, this message translates to:
  /// **'Add an account first — the split is saved as a payment from one of your accounts.'**
  String get billNeedAccount;

  /// Bill splitter: a scan without prices doesn't replace typed items
  ///
  /// In en, this message translates to:
  /// **'No prices found on the receipt. Your items are kept.'**
  String get billScanKeptItems;

  /// Bill splitter: scanning a receipt with items already entered
  ///
  /// In en, this message translates to:
  /// **'Replace your items?'**
  String get billReplaceItemsTitle;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The receipt\'s items replace the item you entered.} other{The receipt\'s items replace the {count} items you entered.}}'**
  String billReplaceItemsMessage(int count);

  /// Bill splitter: confirm button
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get billReplaceItems;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'Set share'**
  String get billSetShare;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'Split it evenly again'**
  String get billResetShare;

  /// Bill splitter: receipt lines read without a price
  ///
  /// In en, this message translates to:
  /// **'Lines without a price: {count} — tap one to add it'**
  String billUnpricedLines(int count);

  /// Bill splitter: after saving
  ///
  /// In en, this message translates to:
  /// **'{total} from {account} · your share {share}'**
  String billSavedFrom(String total, String account, String share);

  /// Bill splitter: after saving
  ///
  /// In en, this message translates to:
  /// **'Your share {share} from {account}'**
  String billSavedEach(String share, String account);

  /// Bill splitter: after saving
  ///
  /// In en, this message translates to:
  /// **'Owes you'**
  String get billOwesYouTitle;

  /// Bill splitter: after saving
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get billYouOweTitle;

  /// Bill splitter
  ///
  /// In en, this message translates to:
  /// **'Tracked in Goals & loans — mark each one paid when they settle up.'**
  String get billTrackedHint;

  /// Bill splitter: accessibility label
  ///
  /// In en, this message translates to:
  /// **'Send {name} their share'**
  String billSendShare(Object name);

  /// Bill splitter: text sent to one person
  ///
  /// In en, this message translates to:
  /// **'Your share of the bill: {amount}'**
  String billPersonShareText(Object amount);

  /// Bill splitter: split an item with a quantity
  ///
  /// In en, this message translates to:
  /// **'Split into {qty}'**
  String billSplitInto(int qty);

  /// Bill splitter: add person field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get billPersonName;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
  String get emojiGroupFood;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get emojiGroupTransport;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Home & bills'**
  String get emojiGroupHome;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get emojiGroupShopping;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Health & fitness'**
  String get emojiGroupHealth;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get emojiGroupEntertainment;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Education & work'**
  String get emojiGroupWork;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get emojiGroupMoney;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Family & pets'**
  String get emojiGroupFamily;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Travel & leisure'**
  String get emojiGroupTravel;

  /// Emoji picker group label
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get emojiGroupOther;

  /// Templates: search found nothing
  ///
  /// In en, this message translates to:
  /// **'No templates match \"{query}\"'**
  String tmplNoMatch(String query);

  /// Templates: SnackBar after deleting
  ///
  /// In en, this message translates to:
  /// **'Template deleted'**
  String get tmplDeleted;

  /// Envelope: SnackBar after deleting
  ///
  /// In en, this message translates to:
  /// **'Envelope deleted'**
  String get allocDeleted;

  /// Reorder envelopes: SnackBar after saving
  ///
  /// In en, this message translates to:
  /// **'Order saved'**
  String get allocOrderSaved;

  /// Leftover screen: SnackBar after saving
  ///
  /// In en, this message translates to:
  /// **'Leftover resolved'**
  String get leftoverResolved;

  /// Period transition: SnackBar after completing
  ///
  /// In en, this message translates to:
  /// **'New period ready'**
  String get periodTransitionDone;

  /// Category: SnackBar after linking it to an envelope
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String catEnvelopeLinked(String name);

  /// Category: SnackBar after unlinking its envelope
  ///
  /// In en, this message translates to:
  /// **'Envelope unlinked'**
  String get catEnvelopeUnlinked;

  /// Confirm dialog title before removing a receipt photo from a transaction
  ///
  /// In en, this message translates to:
  /// **'Remove this receipt?'**
  String get txDetailRemoveReceiptTitle;

  /// Confirm dialog body before removing a receipt photo
  ///
  /// In en, this message translates to:
  /// **'The photo will be deleted from this transaction.'**
  String get txDetailRemoveReceiptBody;

  /// SnackBar after removing a receipt photo
  ///
  /// In en, this message translates to:
  /// **'Receipt removed'**
  String get txDetailReceiptRemoved;

  /// SnackBar when exporting selected transactions to CSV fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export the transactions'**
  String get txExportFailed;

  /// Account detail: delete confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get acctDeleteConfirmTitle;

  /// Account detail: archive confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Archive account?'**
  String get acctArchiveConfirmTitle;

  /// Accounts: unarchive confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Unarchive account?'**
  String get acctUnarchiveConfirmTitle;

  /// Account detail: SnackBar after archiving
  ///
  /// In en, this message translates to:
  /// **'{name} archived'**
  String acctArchivedSnack(String name);

  /// Account detail: SnackBar after deleting
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String acctDeletedSnack(String name);

  /// Account detail: save failed SnackBar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the account'**
  String get acctSaveFailed;

  /// Account detail: adjust balance failed SnackBar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t adjust the balance'**
  String get acctAdjustFailed;

  /// Customize dashboard sheet: SnackBar after Reset
  ///
  /// In en, this message translates to:
  /// **'Dashboard layout reset'**
  String get customizeResetDone;

  /// Export report: failure SnackBar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the report'**
  String get exportReportFailed;

  /// Export report: share sheet text
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal report – {month}'**
  String exportShareText(String month);

  /// Export report HTML: subtitle under the household name
  ///
  /// In en, this message translates to:
  /// **'Monthly report – {month}'**
  String exportHtmlSubtitle(String month);

  /// Export report HTML: transactions table heading
  ///
  /// In en, this message translates to:
  /// **'Transactions ({count})'**
  String exportHtmlTransactions(int count);

  /// Export report HTML: footer
  ///
  /// In en, this message translates to:
  /// **'Generated by BudgetSeal – {date}'**
  String exportHtmlFooter(String date);

  /// Reports Overview/Insights: empty state title
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded this month'**
  String get reportsNothingThisMonth;

  /// Reports Overview/Insights: empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Swipe or use the arrows to see other months.'**
  String get reportsNothingThisMonthHint;

  /// Global search: empty state title when nothing matches
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoMatches;

  /// Recurring list: expense filter matches nothing
  ///
  /// In en, this message translates to:
  /// **'No recurring expenses'**
  String get recurringNoExpenses;

  /// Recurring list: income filter matches nothing
  ///
  /// In en, this message translates to:
  /// **'No recurring income'**
  String get recurringNoIncome;

  /// SnackBar after pausing a recurring transaction
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction paused'**
  String get recurringPausedSnack;

  /// SnackBar after resuming a recurring transaction
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction resumed'**
  String get recurringResumedSnack;

  /// SnackBar when pausing/resuming fails
  ///
  /// In en, this message translates to:
  /// **'Could not update recurring transaction'**
  String get recurringUpdateFailed;

  /// SnackBar when deleting a recurring transaction fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete recurring transaction'**
  String get recurringDeleteFailed;

  /// SnackBar when creating/editing a recurring transaction fails
  ///
  /// In en, this message translates to:
  /// **'Could not save recurring transaction'**
  String get recurringSaveFailed;

  /// Error state on the Recurring and Upcoming bills screens
  ///
  /// In en, this message translates to:
  /// **'Could not load recurring transactions'**
  String get recurringLoadFailed;

  /// SnackBar after pausing a subscription
  ///
  /// In en, this message translates to:
  /// **'Subscription paused'**
  String get subPausedSnack;

  /// SnackBar after resuming a subscription
  ///
  /// In en, this message translates to:
  /// **'Subscription resumed'**
  String get subResumedSnack;

  /// Tooltip of the pause button on a subscription row
  ///
  /// In en, this message translates to:
  /// **'Pause subscription'**
  String get subPauseTooltip;

  /// Tooltip of the resume button on a subscription row
  ///
  /// In en, this message translates to:
  /// **'Resume subscription'**
  String get subResumeTooltip;

  /// Subscriptions list: status filter matches nothing
  ///
  /// In en, this message translates to:
  /// **'No subscriptions with this status'**
  String get subNoMatch;

  /// Error state on the Subscriptions screen
  ///
  /// In en, this message translates to:
  /// **'Could not load subscriptions'**
  String get subLoadFailed;

  /// Confirm dialog title for deleting a subscription
  ///
  /// In en, this message translates to:
  /// **'Delete subscription?'**
  String get subDeleteTitle;

  /// Confirm dialog body for deleting a subscription
  ///
  /// In en, this message translates to:
  /// **'Its past transactions stay in your history.'**
  String get subDeleteBody;

  /// SnackBar after deleting a subscription
  ///
  /// In en, this message translates to:
  /// **'Subscription deleted'**
  String get subDeleted;

  /// SnackBar when deleting a subscription fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete subscription'**
  String get subDeleteFailed;

  /// Confirm dialog title for setting a subscription's cancellation date
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription?'**
  String get subCancelConfirmTitle;

  /// SnackBar after setting a subscription's cancellation date
  ///
  /// In en, this message translates to:
  /// **'Cancellation date set'**
  String get subCancelDateSet;

  /// Confirm dialog title for deleting a planned payment
  ///
  /// In en, this message translates to:
  /// **'Delete planned payment?'**
  String get plannedDeleteConfirmTitle;

  /// Confirm dialog title for posting a month's planned payments
  ///
  /// In en, this message translates to:
  /// **'Post all payments?'**
  String get plannedPostAllConfirmTitle;

  /// Error state on the Planned payments screen
  ///
  /// In en, this message translates to:
  /// **'Could not load planned payments'**
  String get plannedLoadFailed;

  /// Confirm dialog title for deleting a goal or loan
  ///
  /// In en, this message translates to:
  /// **'Delete objective?'**
  String get objDeleteConfirmTitle;

  /// SnackBar after deleting a goal or loan
  ///
  /// In en, this message translates to:
  /// **'Objective deleted'**
  String get objDeleted;

  /// Swatch that restores the default transaction color
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get txColorDefault;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get txColorRed;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get txColorOrange;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get txColorAmber;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get txColorGreen;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get txColorTeal;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get txColorBlue;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get txColorIndigo;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get txColorPurple;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get txColorPink;

  /// Color preset name
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get txColorSlate;

  /// Thousands separator option
  ///
  /// In en, this message translates to:
  /// **'Comma (1,000)'**
  String get nfThousandsComma;

  /// Thousands separator option
  ///
  /// In en, this message translates to:
  /// **'Period (1.000)'**
  String get nfThousandsPeriod;

  /// Thousands separator option
  ///
  /// In en, this message translates to:
  /// **'Space (1 000)'**
  String get nfThousandsSpace;

  /// Thousands separator option
  ///
  /// In en, this message translates to:
  /// **'None (1000)'**
  String get nfThousandsNone;

  /// Decimal separator option
  ///
  /// In en, this message translates to:
  /// **'Period (0.50)'**
  String get nfDecimalPeriod;

  /// Decimal separator option
  ///
  /// In en, this message translates to:
  /// **'Comma (0,50)'**
  String get nfDecimalComma;

  /// Hint in the currency symbol dialog
  ///
  /// In en, this message translates to:
  /// **'e.g. {symbol}'**
  String currencySymbolExample(String symbol);

  /// Reset confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset everything?'**
  String get resetConfirmTitle;

  /// Restore confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get backupRestoreConfirmTitle;

  /// Disconnect confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Disconnect sync?'**
  String get syncDisconnectConfirmTitle;

  /// Dialog title when the cloud holds another budget
  ///
  /// In en, this message translates to:
  /// **'Use the synced budget?'**
  String get syncOtherBudgetConfirmTitle;

  /// Repair confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Repair balances?'**
  String get healthRepairConfirmTitle;

  /// Purge confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Purge deleted transactions?'**
  String get healthPurgeConfirmTitle;

  /// SnackBar after renaming the household
  ///
  /// In en, this message translates to:
  /// **'Household name saved'**
  String get householdNameSaved;

  /// SnackBar after changing base currency
  ///
  /// In en, this message translates to:
  /// **'Base currency changed to {code}'**
  String baseCurrencySaved(String code);

  /// SnackBar
  ///
  /// In en, this message translates to:
  /// **'Automatic backups on'**
  String get backupAutoOnSnack;

  /// SnackBar
  ///
  /// In en, this message translates to:
  /// **'Automatic backups off'**
  String get backupAutoOffSnack;

  /// SnackBar after changing backup frequency/retention
  ///
  /// In en, this message translates to:
  /// **'Backup settings saved'**
  String get backupSettingsSaved;

  /// SnackBar
  ///
  /// In en, this message translates to:
  /// **'Daily reminder on'**
  String get notifReminderOnSnack;

  /// SnackBar
  ///
  /// In en, this message translates to:
  /// **'Daily reminder off'**
  String get notifReminderOffSnack;

  /// SnackBar after changing reminder time or message
  ///
  /// In en, this message translates to:
  /// **'Reminder updated'**
  String get notifReminderSaved;

  /// SnackBar
  ///
  /// In en, this message translates to:
  /// **'Sync disconnected'**
  String get syncDisconnectedSnack;

  /// SnackBar
  ///
  /// In en, this message translates to:
  /// **'Biometric lock on'**
  String get biometricOnSnack;

  /// SnackBar
  ///
  /// In en, this message translates to:
  /// **'Biometric lock off'**
  String get biometricOffSnack;

  /// Web Companion: server stopped itself because Wi-Fi was lost
  ///
  /// In en, this message translates to:
  /// **'Stopped: the phone left the Wi-Fi network. Reconnect to start again.'**
  String get wcStoppedNoWifi;

  /// Backup: confirm deleting a local backup file
  ///
  /// In en, this message translates to:
  /// **'Delete this backup?'**
  String get backupDeleteTitle;

  /// Backup: delete confirm message
  ///
  /// In en, this message translates to:
  /// **'The backup file is removed from this phone. This can\'t be undone.'**
  String get backupDeleteBody;

  /// Backup: snackbar after deleting a local backup
  ///
  /// In en, this message translates to:
  /// **'Backup deleted'**
  String get backupDeleted;

  /// Backup: snackbar when deleting a local backup fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the backup'**
  String get backupDeleteFailed;

  /// One-screen add: title field hint
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get quickWhatFor;

  /// One-screen add: envelope card before a category is chosen
  ///
  /// In en, this message translates to:
  /// **'Pick a category to see what\'s left in its envelope'**
  String get quickPickCategoryHint;

  /// One-screen add: envelope card title
  ///
  /// In en, this message translates to:
  /// **'{name} envelope'**
  String quickEnvelopeName(String name);

  /// One-screen add: envelope balance after this spending
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String quickLeft(String amount);

  /// One-screen add: envelope overspent after this spending
  ///
  /// In en, this message translates to:
  /// **'over by {amount}'**
  String quickOverBy(String amount);

  /// One-screen add: what the envelope allows per day until the period ends
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left} other{{days} days left}} · about {amount} a day'**
  String quickPerDay(int days, String amount);

  /// One-screen add: chips that move money into the overspent envelope follow
  ///
  /// In en, this message translates to:
  /// **'Cover from'**
  String get quickCoverFrom;

  /// One-screen add: open the full cover sheet
  ///
  /// In en, this message translates to:
  /// **'Other…'**
  String get quickCoverOther;

  /// One-screen add: snackbar after covering
  ///
  /// In en, this message translates to:
  /// **'Moved {amount} from {name}'**
  String quickCovered(String amount, String name);

  /// One-screen add: category not linked to an envelope
  ///
  /// In en, this message translates to:
  /// **'This category has no envelope, so this spending isn\'t budgeted'**
  String get quickNotBudgeted;

  /// One-screen add: income card hint
  ///
  /// In en, this message translates to:
  /// **'After saving, Assign puts it into your envelopes.'**
  String get quickIncomeHint;

  /// One-screen add: transfer hint
  ///
  /// In en, this message translates to:
  /// **'Your envelopes and Ready to assign stay the same: the money only changes accounts.'**
  String get quickTransferHint;

  /// One-screen add: save button
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String quickSaveAmount(String amount);

  /// One-screen add: transfer save button
  ///
  /// In en, this message translates to:
  /// **'Move {amount}'**
  String quickMoveAmount(String amount);

  /// One-screen add: extras button
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get quickNote;

  /// One-screen add: extras button (split into items)
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get quickSplit;

  /// One-screen add: extras button (camera)
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get quickReceipt;

  /// One-screen add: extras button (gallery)
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get quickPhoto;

  /// One-screen add: transfer source
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quickFrom;

  /// One-screen add: transfer destination
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get quickTo;

  /// One-screen add: date and time sheet title
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get quickWhen;

  /// One-screen add: date sheet row
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get quickPickDate;

  /// One-screen add: date sheet time row
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get quickTime;

  /// One-screen add: exchange rate chip
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {rate} {to}'**
  String quickRateLine(String from, String rate, String to);

  /// One-screen add: no rate known yet
  ///
  /// In en, this message translates to:
  /// **'Set exchange rate'**
  String get quickSetRate;

  /// One-screen add: note dialog title
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get quickNoteTitle;

  /// Entry mode option: the new one-screen add
  ///
  /// In en, this message translates to:
  /// **'One screen'**
  String get entryModeOne;

  /// Entry mode option description
  ///
  /// In en, this message translates to:
  /// **'Amount first with the keypad open, and what\'s left in the envelope before you save'**
  String get entryModeOneDesc;

  /// One-screen add: Split tapped with no amount
  ///
  /// In en, this message translates to:
  /// **'Type the total first, then split it'**
  String get quickSplitNeedsTotal;

  /// One-screen add: split items add up to more than the total
  ///
  /// In en, this message translates to:
  /// **'Items are {amount} more than the total'**
  String quickItemsOverTotal(String amount);

  /// One-screen add: the first split item, which takes what is left of the total
  ///
  /// In en, this message translates to:
  /// **'The rest'**
  String get quickSplitRest;

  /// Transaction receipt: the account an expense came from
  ///
  /// In en, this message translates to:
  /// **'Paid from {account}'**
  String txReceiptPaidFrom(String account);

  /// Transaction receipt: the account income went into
  ///
  /// In en, this message translates to:
  /// **'Into {account}'**
  String txReceiptPaidInto(String account);

  /// Transaction receipt: label before the total (shown in capitals)
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get txReceiptTotal;

  /// Transaction receipt: number of lines
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 item} other{{n} items}}'**
  String txReceiptItems(int n);

  /// Transaction receipt stamp: a planned (upcoming) transaction
  ///
  /// In en, this message translates to:
  /// **'Not paid yet'**
  String get txStampNotPaid;

  /// Transaction receipt stamp: a skipped planned transaction
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get txStampSkipped;

  /// Transaction receipt stamp: a transfer between accounts
  ///
  /// In en, this message translates to:
  /// **'Envelopes unchanged'**
  String get txStampEnvelopesSame;

  /// Transaction receipt: button that covers the envelope's overspending
  ///
  /// In en, this message translates to:
  /// **'Cover {amount}'**
  String txCoverAmount(String amount);

  /// Month close: title when the month went over budget
  ///
  /// In en, this message translates to:
  /// **'{month} is done'**
  String closeDone(String month);

  /// Month close: first story line, under budget
  ///
  /// In en, this message translates to:
  /// **'You kept {amount} of what you planned.'**
  String closeStoryKept(String amount);

  /// Month close: first story line, over budget
  ///
  /// In en, this message translates to:
  /// **'You spent {amount} more than you planned.'**
  String closeStoryOverTotal(String amount);

  /// Month close: no envelope went over
  ///
  /// In en, this message translates to:
  /// **'Every envelope held.'**
  String get closeStoryAllHeld;

  /// Month close: one envelope went over
  ///
  /// In en, this message translates to:
  /// **'{name} was the only envelope that went over.'**
  String closeStoryOneOver(String name);

  /// Month close: several envelopes went over
  ///
  /// In en, this message translates to:
  /// **'{n} envelopes went over.'**
  String closeStoryNOver(int n);

  /// Month close: what envelopes had to spend this period
  ///
  /// In en, this message translates to:
  /// **'Budgeted'**
  String get closeFunded;

  /// Month close: money spent
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get closeSpent;

  /// Month close: funded minus spent, when positive
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get closeKept;

  /// Month close: funded minus spent, when negative
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get closeOver;

  /// Month close: envelopes that stayed at or above zero
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 envelope held} other{{n} envelopes held}}'**
  String closeHeld(int n);

  /// Month close: section about leftovers
  ///
  /// In en, this message translates to:
  /// **'What was left'**
  String get closeLeftover;

  /// Month close: what the period reset returned
  ///
  /// In en, this message translates to:
  /// **'{amount} from spending envelopes went back to Ready to assign.'**
  String closeReturned(String amount);

  /// Month close: nothing was reset
  ///
  /// In en, this message translates to:
  /// **'What was left in your envelopes stays there for next month.'**
  String get closeStayed;

  /// Month close: envelopes waiting for a manual reset decision
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Review 1 envelope} other{Review {n} envelopes}}'**
  String closeReview(int n);

  /// Month close: main button, opens funding for the new month
  ///
  /// In en, this message translates to:
  /// **'Plan {month}'**
  String closePlan(String month);

  /// Month close: share the recap as an image
  ///
  /// In en, this message translates to:
  /// **'Share recap'**
  String get closeShare;

  /// Budget tab period card: opens the month close screen
  ///
  /// In en, this message translates to:
  /// **'See the recap'**
  String get closeSeeRecap;

  /// Envelope screen: button to add an expense from this envelope
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get allocSpendButton;

  /// Budget tab: one-line summary under Ready to assign
  ///
  /// In en, this message translates to:
  /// **'{budgeted} budgeted · {spent} spent'**
  String allocBudgetLine(String budgeted, String spent);

  /// Budget tab: days left in the budget period
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Last day} =1{1 day left} other{{n} days left}}'**
  String allocDaysLeft(int n);

  /// Budget tab: section of overspent envelopes
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get allocNeedsAttention;

  /// Budget tab row: spending envelope progress
  ///
  /// In en, this message translates to:
  /// **'{spent} spent of {budget}'**
  String allocSpentOf(String spent, String budget);

  /// Budget tab row: spending envelope with no spending this period
  ///
  /// In en, this message translates to:
  /// **'Nothing spent yet'**
  String get allocNothingSpent;

  /// Reports: period chip
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get rptSpanMonth;

  /// Reports: period chip
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get rptSpan3;

  /// Reports: period chip
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get rptSpan6;

  /// Reports: period chip
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get rptSpan12;

  /// Reports: period chip
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get rptSpanYear;

  /// Reports: period chip, opens a month range picker
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get rptSpanCustom;

  /// Reports: the period shown and what it is compared with
  ///
  /// In en, this message translates to:
  /// **'{range} · compared with {n, plural, =1{the month before} other{the {n} months before}}'**
  String rptComparedWith(String range, int n);

  /// Reports custom range: first month
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get rptPickFrom;

  /// Reports custom range: last month
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get rptPickTo;

  /// Reports story
  ///
  /// In en, this message translates to:
  /// **'You kept {pct}% of what you earned.'**
  String rptStoryKept(int pct);

  /// Reports story
  ///
  /// In en, this message translates to:
  /// **'You spent {amount} more than you earned.'**
  String rptStoryOverspent(String amount);

  /// Reports story: no income in the period
  ///
  /// In en, this message translates to:
  /// **'You spent {amount}.'**
  String rptStorySpentOnly(String amount);

  /// Reports story
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded in this period yet.'**
  String get rptStoryNothing;

  /// Reports story
  ///
  /// In en, this message translates to:
  /// **'{category} took the most: {amount}.'**
  String rptStoryTop(String category, String amount);

  /// Reports story
  ///
  /// In en, this message translates to:
  /// **'Spending was {pct}% lower than the period before.'**
  String rptStoryLess(int pct);

  /// Reports story
  ///
  /// In en, this message translates to:
  /// **'Spending was {pct}% higher than the period before.'**
  String rptStoryMore(int pct);

  /// Reports story
  ///
  /// In en, this message translates to:
  /// **'Spending was about the same as the period before.'**
  String get rptStorySame;

  /// Reports tile
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get rptEarned;

  /// Reports tile
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get rptSpent;

  /// Reports tile
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get rptKept;

  /// Reports tile: kept as a share of income
  ///
  /// In en, this message translates to:
  /// **'{pct}% of income'**
  String rptOfIncome(int pct);

  /// Reports library section
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get rptGroupBudget;

  /// Reports library section
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get rptGroupSpending;

  /// Reports library section
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get rptGroupMoney;

  /// Reports library section
  ///
  /// In en, this message translates to:
  /// **'Commitments'**
  String get rptGroupCommitments;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Budget vs actual'**
  String get rptBudgetVsActual;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Planned vs spent each month, and every envelope\'s record'**
  String get rptBudgetVsActualSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Month insights'**
  String get rptInsights;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Pace, savings rate, age of money and tips'**
  String get rptInsightsSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Month overview'**
  String get rptOverview;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'One month against your usual, daily pace and spending activity'**
  String get rptOverviewSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Spending over time'**
  String get rptSpendingTime;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Each category, month by month'**
  String get rptSpendingTimeSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get rptCategories;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Where one month\'s money went, with the top spending'**
  String get rptCategoriesSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Places and patterns'**
  String get rptPlaces;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Where you spend most, and when'**
  String get rptPlacesSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Biggest expenses'**
  String get rptBiggest;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'The largest single payments in the period'**
  String get rptBiggestSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Income vs spending'**
  String get rptIncomeSpending;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'What came in, went out and stayed, plus net worth over time'**
  String get rptIncomeSpendingSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Balance sheet'**
  String get rptBalanceSheet;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'What you own and owe, compared with a date'**
  String get rptBalanceSheetSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get rptAccounts;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Money in and out of each account'**
  String get rptAccountsSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get rptCurrencies;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Spending in each currency you use'**
  String get rptCurrenciesSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Subscriptions and bills'**
  String get rptSubscriptions;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'What they cost per month and per year'**
  String get rptSubscriptionsSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'Goals and loans'**
  String get rptGoals;

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Progress and what\'s left'**
  String get rptGoalsSub;

  /// Report title
  ///
  /// In en, this message translates to:
  /// **'{year} in review'**
  String rptYearReview(String year);

  /// Report description
  ///
  /// In en, this message translates to:
  /// **'Your year so far, ready to share'**
  String get rptYearReviewSub;

  /// Budget vs actual: chip
  ///
  /// In en, this message translates to:
  /// **'All envelopes'**
  String get rptAllEnvelopes;

  /// Budget vs actual headline
  ///
  /// In en, this message translates to:
  /// **'Held {held} of {n, plural, =1{1 month} other{{n} months}}'**
  String rptHeldOf(int held, int n);

  /// Budget vs actual
  ///
  /// In en, this message translates to:
  /// **'Average {avg} spent of {plan} planned'**
  String rptAvgOf(String avg, String plan);

  /// Track record row
  ///
  /// In en, this message translates to:
  /// **'Avg {avg} of {plan}'**
  String rptAvgOfShort(String avg, String plan);

  /// Chart legend
  ///
  /// In en, this message translates to:
  /// **'Spent, held'**
  String get rptLegendHeld;

  /// Chart legend
  ///
  /// In en, this message translates to:
  /// **'Spent, over'**
  String get rptLegendOver;

  /// Chart legend: what the envelope had to spend
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get rptLegendPlanned;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Envelope track record'**
  String get rptTrackRecord;

  /// Track record legend
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get rptHeld;

  /// Track record legend
  ///
  /// In en, this message translates to:
  /// **'Went over'**
  String get rptWentOver;

  /// Track record legend
  ///
  /// In en, this message translates to:
  /// **'Not used'**
  String get rptNotUsed;

  /// Budget vs actual empty
  ///
  /// In en, this message translates to:
  /// **'No envelope activity in this period'**
  String get rptNoEnvelopes;

  /// Spending over time headline
  ///
  /// In en, this message translates to:
  /// **'About {amount} a month'**
  String rptAboutPerMonth(String amount);

  /// Spending over time
  ///
  /// In en, this message translates to:
  /// **'Highest in {high} ({highAmount}), lowest in {low} ({lowAmount})'**
  String rptHighLow(
      String high, String highAmount, String low, String lowAmount);

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get rptByCategory;

  /// Section note
  ///
  /// In en, this message translates to:
  /// **'a month, on average'**
  String get rptAMonthAvg;

  /// Category trend
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get rptSteady;

  /// Category trend
  ///
  /// In en, this message translates to:
  /// **'{month} {pct}% above average'**
  String rptAboveAvg(String month, int pct);

  /// Category trend
  ///
  /// In en, this message translates to:
  /// **'{month} {pct}% below average'**
  String rptBelowAvg(String month, int pct);

  /// Chart: categories folded together
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get rptOther;

  /// Chart: no category
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get rptUncategorized;

  /// Income vs spending headline
  ///
  /// In en, this message translates to:
  /// **'You kept {amount}'**
  String rptKeptAmount(String amount);

  /// Income vs spending headline
  ///
  /// In en, this message translates to:
  /// **'You spent {amount} more than you earned'**
  String rptSpentMoreAmount(String amount);

  /// Income vs spending
  ///
  /// In en, this message translates to:
  /// **'{pct}% of what came in.'**
  String rptKeptShare(int pct);

  /// Income vs spending
  ///
  /// In en, this message translates to:
  /// **'Every month ended above zero.'**
  String get rptAllAbove;

  /// Income vs spending
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 month ended below zero.} other{{n} months ended below zero.}}'**
  String rptSomeBelow(int n);

  /// Chart note
  ///
  /// In en, this message translates to:
  /// **'Bottom row: kept that month'**
  String get rptKeptRow;

  /// Net worth change
  ///
  /// In en, this message translates to:
  /// **'{amount} since {month}'**
  String rptSince(String amount, String month);

  /// Net worth note
  ///
  /// In en, this message translates to:
  /// **'Counts accounts in {currency}. Accounts in other currencies are left out, not converted.'**
  String rptNetWorthNote(String currency);

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Where you spend most'**
  String get rptWhereMost;

  /// Section note
  ///
  /// In en, this message translates to:
  /// **'by title'**
  String get rptByTitle;

  /// Places row
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 visit} other{{n} visits}} · about {avg} each'**
  String rptVisits(int n, String avg);

  /// Section
  ///
  /// In en, this message translates to:
  /// **'When you spend'**
  String get rptWhenSpend;

  /// Patterns headline
  ///
  /// In en, this message translates to:
  /// **'{day} costs the most'**
  String rptDayCostsMost(String day);

  /// Patterns
  ///
  /// In en, this message translates to:
  /// **'About {amount} on an average {day}'**
  String rptDayAverage(String amount, String day);

  /// Patterns tile
  ///
  /// In en, this message translates to:
  /// **'Busiest time'**
  String get rptBusiestTime;

  /// Patterns tile
  ///
  /// In en, this message translates to:
  /// **'{pct}% of payments'**
  String rptShareOfPayments(int pct);

  /// Patterns tile
  ///
  /// In en, this message translates to:
  /// **'No-spend days'**
  String get rptNoSpendDays;

  /// Patterns tile
  ///
  /// In en, this message translates to:
  /// **'{a} of {b}'**
  String rptNofM(int a, int b);

  /// Patterns tile
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Longest run: 1 day} other{Longest run: {n} days}}'**
  String rptLongestRun(int n);

  /// Places empty
  ///
  /// In en, this message translates to:
  /// **'Give your expenses titles to see where you spend most'**
  String get rptNoPlaces;

  /// Accounts report
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get rptIn;

  /// Accounts report
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get rptOut;

  /// Currencies report note
  ///
  /// In en, this message translates to:
  /// **'Each currency on its own, not converted.'**
  String get rptNotConverted;

  /// Subscriptions report
  ///
  /// In en, this message translates to:
  /// **'{amount} a month'**
  String rptPerMonth(String amount);

  /// Subscriptions report
  ///
  /// In en, this message translates to:
  /// **'{amount} a year'**
  String rptPerYear(String amount);

  /// Subscriptions report
  ///
  /// In en, this message translates to:
  /// **'In total'**
  String get rptInTotal;

  /// Subscriptions report empty
  ///
  /// In en, this message translates to:
  /// **'No recurring payments yet'**
  String get rptNoSubscriptions;

  /// Report empty
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded in this period'**
  String get rptNothingInPeriod;

  /// Year in review title
  ///
  /// In en, this message translates to:
  /// **'Your {year}'**
  String rptYourYear(String year);

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String rptYearSpan(String from, String to);

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'You kept'**
  String get rptYouKept;

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'{pct}% of everything that came in'**
  String rptOfEverything(int pct);

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'Months sealed'**
  String get rptMonthsSealed;

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'every envelope held'**
  String get rptEveryHeld;

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'Most reliable'**
  String get rptMostReliable;

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{held 1 month} other{held {n} months}}'**
  String rptHeldMonths(int n);

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'Biggest share'**
  String get rptBiggestShare;

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'Favourite place'**
  String get rptFavouritePlace;

  /// Year in review
  ///
  /// In en, this message translates to:
  /// **'Best month'**
  String get rptBestMonth;

  /// Year in review button
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get rptShareImage;

  /// Year in review: best month's sub-line
  ///
  /// In en, this message translates to:
  /// **'kept {amount}'**
  String rptKeptValue(String amount);

  /// Year in review: no-spend days sub-line, e.g. 269 / of 296 days
  ///
  /// In en, this message translates to:
  /// **'of {count, plural, =1{1 day} other{{count} days}}'**
  String rptOfDays(int count);

  /// Envelope type: saves monthly for payments on set dates
  ///
  /// In en, this message translates to:
  /// **'Sinking fund'**
  String get sinkTypeTitle;

  /// Short label of the sinking fund type in the type selector
  ///
  /// In en, this message translates to:
  /// **'Sinking'**
  String get sinkTypeShort;

  /// Sinking fund type description
  ///
  /// In en, this message translates to:
  /// **'Put a little aside each month for payments on set dates: yearly bills, school fees.'**
  String get sinkTypeDesc;

  /// Budget tab section title for sinking funds
  ///
  /// In en, this message translates to:
  /// **'Sinking funds'**
  String get sinkSection;

  /// What a sinking fund takes this month
  ///
  /// In en, this message translates to:
  /// **'{amount} this month'**
  String sinkThisMonth(String amount);

  /// Next payment date of a sinking fund
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String sinkNext(String date);

  /// Sinking fund status, lowercase after a dot
  ///
  /// In en, this message translates to:
  /// **'on track'**
  String get sinkOnTrack;

  /// Sinking fund status on its own line
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get sinkOnTrackCap;

  /// Sinking fund status while spreading a shortfall
  ///
  /// In en, this message translates to:
  /// **'catching up'**
  String get sinkCatchingUp;

  /// Sinking fund got its share this month
  ///
  /// In en, this message translates to:
  /// **'Funded for this month'**
  String get sinkFundedThisMonth;

  /// Sinking fund shortfall
  ///
  /// In en, this message translates to:
  /// **'Behind by {amount}'**
  String sinkBehindBy(String amount);

  /// Budget tab row of a fund that fell behind
  ///
  /// In en, this message translates to:
  /// **'Behind by {amount} · choose how to catch up'**
  String sinkBehindChoose(String amount);

  /// Sinking fund with no schedule
  ///
  /// In en, this message translates to:
  /// **'No payments planned yet'**
  String get sinkNoPayments;

  /// Fund screen hero when no payments
  ///
  /// In en, this message translates to:
  /// **'Add the payments this fund saves for (dates and amounts), and it works out what to put aside each month.'**
  String get sinkNoPaymentsHelp;

  /// Saved toward a payment, e.g. $0 of $1,500
  ///
  /// In en, this message translates to:
  /// **'{saved} of {total}'**
  String sinkOf(String saved, String total);

  /// After the saved amount in the fund hero
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String sinkOfTotal(String total);

  /// Fund hero: next payment
  ///
  /// In en, this message translates to:
  /// **'Saving for {date} · {title}'**
  String sinkSavingFor(String date, String title);

  /// Fund hero label
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get sinkThisMonthLabel;

  /// Fund hero button
  ///
  /// In en, this message translates to:
  /// **'Fund this month'**
  String get sinkFundThisMonth;

  /// Fund screen section
  ///
  /// In en, this message translates to:
  /// **'Monthly plan'**
  String get sinkMonthlyPlan;

  /// Under the monthly plan
  ///
  /// In en, this message translates to:
  /// **'Recalculated every month from what\'s saved and what\'s due next.'**
  String get sinkPlanNote;

  /// Fund screen section
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get sinkPayments;

  /// A fund payment already paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get sinkPaid;

  /// When a fund payment is due
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{today} =1{tomorrow} other{in {count} days}}'**
  String sinkInDays(int count);

  /// Tag on a fund payment that comes from a recurring bill
  ///
  /// In en, this message translates to:
  /// **'Recurring bill'**
  String get sinkRecurringBill;

  /// Fund screen button / payment screen title
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get sinkAddPayment;

  /// Payment screen title when editing
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get sinkEditPayment;

  /// Fund screen button and screen title
  ///
  /// In en, this message translates to:
  /// **'Copy from last year'**
  String get sinkCopyLastYear;

  /// Fund setting
  ///
  /// In en, this message translates to:
  /// **'When behind'**
  String get sinkWhenBehind;

  /// Help under When behind
  ///
  /// In en, this message translates to:
  /// **'If a month is missed: raise the next months, or catch up at once.'**
  String get sinkWhenBehindHelp;

  /// When behind option
  ///
  /// In en, this message translates to:
  /// **'Ask me'**
  String get sinkModeAsk;

  /// When behind option
  ///
  /// In en, this message translates to:
  /// **'Spread it out'**
  String get sinkModeSpread;

  /// When behind option
  ///
  /// In en, this message translates to:
  /// **'Top up now'**
  String get sinkModeTopUp;

  /// Fund with no linked category
  ///
  /// In en, this message translates to:
  /// **'Link a category so payments come out of this fund.'**
  String get sinkNeedsCategory;

  /// Catch-up sheet title and button
  ///
  /// In en, this message translates to:
  /// **'Catch up'**
  String get sinkCatchUpTitle;

  /// Catch-up sheet explanation
  ///
  /// In en, this message translates to:
  /// **'{name} is {amount} short of its plan.'**
  String sinkBehindExplain(String name, String amount);

  /// Spread option detail
  ///
  /// In en, this message translates to:
  /// **'Smaller steps: the monthly amount goes up until the payment.'**
  String get sinkSpreadSub;

  /// Top up option detail
  ///
  /// In en, this message translates to:
  /// **'{now} now, then {steady} a month'**
  String sinkTopUpNow(String now, String steady);

  /// Top up option detail
  ///
  /// In en, this message translates to:
  /// **'Back on track today; the monthly amount stays steady.'**
  String get sinkTopUpSub;

  /// Catch-up sheet checkbox
  ///
  /// In en, this message translates to:
  /// **'Always do this for this fund'**
  String get sinkAlways;

  /// Catch-up sheet button
  ///
  /// In en, this message translates to:
  /// **'Fund {amount}'**
  String sinkFundAmount(String amount);

  /// Account picker title for a payment part
  ///
  /// In en, this message translates to:
  /// **'Pay from'**
  String get sinkFromAccount;

  /// Payment name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sinkPaymentName;

  /// Payment name hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 2nd installment'**
  String get sinkPaymentNameHint;

  /// Payment due date label
  ///
  /// In en, this message translates to:
  /// **'Due on'**
  String get sinkDueOn;

  /// Due date placeholder / error
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get sinkPickDate;

  /// Payment amount label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sinkAmountLabel;

  /// Add the first currency part
  ///
  /// In en, this message translates to:
  /// **'Add an amount'**
  String get sinkAddAmount;

  /// Add a currency part
  ///
  /// In en, this message translates to:
  /// **'Add another currency'**
  String get sinkAddCurrency;

  /// Tooltip on a part's remove button
  ///
  /// In en, this message translates to:
  /// **'Remove this currency'**
  String get sinkRemovePart;

  /// Under the payment parts
  ///
  /// In en, this message translates to:
  /// **'Each part is saved and paid in its own currency, never converted.'**
  String get sinkPartsNote;

  /// Validation: two parts in one currency
  ///
  /// In en, this message translates to:
  /// **'Use one amount per currency.'**
  String get sinkOnePartPerCurrency;

  /// Payment screen button
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get sinkSavePayment;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Payment saved'**
  String get sinkPaymentSaved;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Payment deleted'**
  String get sinkPaymentDeleted;

  /// Confirm title
  ///
  /// In en, this message translates to:
  /// **'Delete this payment?'**
  String get sinkDeletePaymentTitle;

  /// Confirm message
  ///
  /// In en, this message translates to:
  /// **'It leaves the schedule; nothing is paid or refunded.'**
  String get sinkDeletePaymentMsg;

  /// Copy screen help
  ///
  /// In en, this message translates to:
  /// **'Last year\'s payments, one year later. Change them to the new amounts after adding, or raise them here.'**
  String get sinkCopyHelp;

  /// Copy screen: percent per currency
  ///
  /// In en, this message translates to:
  /// **'Raise all amounts'**
  String get sinkRaiseAll;

  /// Copy row that matches an existing plan
  ///
  /// In en, this message translates to:
  /// **'already planned'**
  String get sinkAlreadyPlanned;

  /// Copy row: the original amount
  ///
  /// In en, this message translates to:
  /// **'last year {amount}'**
  String sinkLastYear(String amount);

  /// Copy screen footnote
  ///
  /// In en, this message translates to:
  /// **'Use this when the new schedule is decided; nothing is copied on its own. Each payment stays editable until it\'s paid.'**
  String get sinkCopyNote;

  /// Copy screen button
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add payments} =1{Add 1 payment} other{Add {count} payments}}'**
  String sinkCopyAdd(int count);

  /// Copy screen empty
  ///
  /// In en, this message translates to:
  /// **'No payments from the past year to copy.'**
  String get sinkCopyNothing;

  /// Copy snackbar
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment added} other{{count} payments added}}'**
  String sinkCopied(int count);

  /// Subscriptions offer card title
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 yearly bill isn\'t saved for yet} other{{count} yearly bills aren\'t saved for yet}}'**
  String sinkBillOfferTitle(int count);

  /// Subscriptions offer line
  ///
  /// In en, this message translates to:
  /// **'{name} ({amount}, {date}): about {monthly} a month'**
  String sinkBillOfferBody(
      String name, String amount, String date, String monthly);

  /// Subscriptions offer button
  ///
  /// In en, this message translates to:
  /// **'Save monthly'**
  String get sinkSaveMonthly;

  /// Snackbar after Save monthly
  ///
  /// In en, this message translates to:
  /// **'Sinking fund created'**
  String get sinkFundCreated;

  /// Fund hero when the payment is named like the fund
  ///
  /// In en, this message translates to:
  /// **'Saving for {date}'**
  String sinkSavingForDate(String date);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Sinking funds'**
  String get webFundSection;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Sinking fund'**
  String get webFundKind;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String webFundNext(String date);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'{amount} this month'**
  String webFundThisMonth(String amount);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'on track'**
  String get webFundOnTrack;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get webFundOnTrackCap;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'catching up'**
  String get webFundCatchingUp;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Funded for this month'**
  String get webFundFundedMonth;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Behind by {amount}'**
  String webFundBehind(String amount);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Behind by {amount} · choose how to catch up'**
  String webFundBehindChoose(String amount);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'No payments planned yet'**
  String get webFundNoPayments;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'{saved} of {total}'**
  String webFundOf(String saved, String total);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Saving for {date}'**
  String webFundSavingFor(String date);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get webFundSchedule;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Fund this month'**
  String get webFundFundMonth;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Catch up'**
  String get webFundCatchUp;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Monthly plan'**
  String get webFundPlan;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Recalculated every month from what\'s saved and what\'s due next.'**
  String get webFundPlanNote;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get webFundPayments;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get webFundPaid;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Recurring bill'**
  String get webFundBill;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get webFundAddPayment;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get webFundEditPayment;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Copy from last year'**
  String get webFundCopy;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'When behind'**
  String get webFundWhenBehind;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Ask me'**
  String get webFundModeAsk;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Spread it out'**
  String get webFundModeSpread;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Top up now'**
  String get webFundModeTopup;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Smaller steps: the monthly amount goes up until the payment.'**
  String get webFundSpreadSub;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'{now} now, then {steady} a month'**
  String webFundTopupNow(String now, String steady);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Back on track today; the monthly amount stays steady.'**
  String get webFundTopupSub;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Always do this for this fund'**
  String get webFundAlways;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'{name} is {amount} short of its plan.'**
  String webFundBehindExplain(String name, String amount);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get webFundName;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'e.g. 2nd installment'**
  String get webFundNameHint;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Due on'**
  String get webFundDue;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Each part is saved and paid in its own currency, never converted.'**
  String get webFundPartsNote;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Add another currency'**
  String get webFundAddCurrency;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Remove this currency'**
  String get webFundRemovePart;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Use one amount per currency.'**
  String get webFundOnePerCurrency;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Payment saved'**
  String get webFundSaved;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Payment deleted'**
  String get webFundDeleted;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Delete this payment?'**
  String get webFundDeleteTitle;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'It leaves the schedule; nothing is paid or refunded.'**
  String get webFundDeleteMsg;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Last year\'s payments, one year later. Change them to the new amounts after adding, or raise them here.'**
  String get webFundCopyHelp;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Raise all amounts (%)'**
  String get webFundRaise;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'already planned'**
  String get webFundAlready;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'last year {amount}'**
  String webFundLastYear(String amount);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Use this when the new schedule is decided; nothing is copied on its own. Each payment stays editable until it\'s paid.'**
  String get webFundCopyNote;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Add payments'**
  String get webFundCopyAdd;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'No payments from the past year to copy.'**
  String get webFundCopyNone;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Payments added: {n}'**
  String webFundCopied(String n);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Link a category to this fund (in the app) so payments come out of it.'**
  String get webFundNeedCategory;

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'in {n} days'**
  String webFundInDays(String n);

  /// Web Companion: sinking funds
  ///
  /// In en, this message translates to:
  /// **'Saving · {saved} of {total}'**
  String webFundSavingChip(String saved, String total);

  /// Subscription row: a sinking fund saves for this bill
  ///
  /// In en, this message translates to:
  /// **'Saving · {saved} of {total}'**
  String sinkSavingChip(String saved, String total);

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Ask before posting'**
  String get billAskFirst;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'For bills that change: confirm the amount each time'**
  String get billAskFirstHint;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get billRemindLabel;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'{n} days before (default)'**
  String billRemindDefault(int n);

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Don\'t remind me'**
  String get billRemindOff;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'On the day'**
  String get billRemindOnDay;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day before} other{{n} days before}}'**
  String billRemindDaysBefore(int n);

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Confirm the amount'**
  String get billToConfirm;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Confirm amount and post'**
  String get billConfirmPost;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Enter what you paid this time'**
  String get billConfirmPostDesc;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Log it'**
  String get billNotifLogIt;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Remind me tomorrow'**
  String get billNotifSnooze;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Bill reminders'**
  String get billNotifChannel;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'A reminder before each bill is due'**
  String get billNotifChannelDesc;

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'{amount} is due today.'**
  String billNotifDueToday(String amount);

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'{amount} is due tomorrow.'**
  String billNotifDueTomorrow(String amount);

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'{amount} is due in {n} days.'**
  String billNotifDueInDays(String amount, int n);

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'{amount} was due {n, plural, =1{yesterday} other{{n} days ago}}.'**
  String billNotifOverdue(String amount, int n);

  /// Bills: ask before posting, reminders
  ///
  /// In en, this message translates to:
  /// **'Confirm the amount to post it.'**
  String get billNotifConfirm;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'Ask before posting'**
  String get webBillAskFirst;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'For bills that change: confirm the amount each time'**
  String get webBillAskFirstHint;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get webBillRemind;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'{n} days before (default)'**
  String webBillRemindDefault(int n);

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'Don\'t remind me'**
  String get webBillRemindOff;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'On the day'**
  String get webBillRemindOnDay;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get webBillRemindOne;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'{n} days before'**
  String webBillRemindN(int n);

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'Confirm and post'**
  String get webBillConfirmPost;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'Amount this time'**
  String get webBillConfirmDesc;

  /// Web Companion: bill options
  ///
  /// In en, this message translates to:
  /// **'confirm the amount'**
  String get webBillToConfirm;

  /// Add form: template picker
  ///
  /// In en, this message translates to:
  /// **'No templates yet. Save one from a transaction\'s ⋮ menu, or add it in Templates.'**
  String get tmplPickerEmpty;

  /// Add form: template picker
  ///
  /// In en, this message translates to:
  /// **'Manage templates'**
  String get tmplPickerManage;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'Largest first'**
  String get txSortLargest;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 result, largest first} other{{n} results, largest first}}'**
  String txSortLargestHeader(int n);

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'No settings match'**
  String get settingsSearchNone;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get exportPeriod;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get exportAllTime;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get exportLastMonth;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'Custom range…'**
  String get exportCustomRange;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String exportRangeLabel(String from, String to);

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 transaction will be exported} other{{n} transactions will be exported}}'**
  String exportCount(int n);

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'Nothing to export with these filters'**
  String get exportNone;

  /// Search, settings search, export filters
  ///
  /// In en, this message translates to:
  /// **'Export failed. Try again.'**
  String get exportFailed;

  /// Fund screen: average spending
  ///
  /// In en, this message translates to:
  /// **'Average spending'**
  String get fundPresetAverage;

  /// Fund screen: average spending
  ///
  /// In en, this message translates to:
  /// **'Usually spends {amount} a month'**
  String fundUsually(String amount);

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Change history'**
  String get tileChangeLog;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'What was added, edited or deleted, and when'**
  String get tileChangeLogSub;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get tileCrashReports;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Off · nothing is saved'**
  String get tileCrashReportsOff;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{On · none saved} =1{On · 1 saved} other{On · {count} saved}}'**
  String tileCrashReportsOn(int count);

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Save crash reports on this phone'**
  String get crashKeep;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'If something goes wrong, BudgetSeal saves what happened here. Nothing is sent: you choose whether to share a report.'**
  String get crashKeepSub;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'A report holds the error, where in the app it happened, the app version and your phone\'s system version. It doesn\'t include your budget, but an error can quote something that was on screen, so read it before you share it.'**
  String get crashWhatsIn;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'No crash reports'**
  String get crashEmpty;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'If something goes wrong, it will show here.'**
  String get crashEmptySubOn;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Turn on saving to keep a report when something goes wrong.'**
  String get crashEmptySubOff;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get crashShare;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get crashClear;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Crash reports cleared'**
  String get crashCleared;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{once} other{{count} times}}'**
  String crashTimes(int count);

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Crash reports will be saved on this phone'**
  String get crashOnSnack;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'Crash reports off. Saved reports deleted.'**
  String get crashOffSnack;

  /// Crash reports
  ///
  /// In en, this message translates to:
  /// **'BudgetSeal crash reports'**
  String get crashShareSubject;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Change history'**
  String get changeLogTitle;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'The last {n} changes to your transactions, newest first. Tap one to open it.'**
  String changeLogIntro(int n);

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'No changes yet'**
  String get changeLogEmpty;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the change history'**
  String get changeLogLoadFailed;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get changeLogAdded;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get changeLogEdited;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get changeLogDeleted;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'for {date}'**
  String changeLogForDate(String date);

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'from the Web Companion'**
  String get changeLogFromWeb;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'recurring bill'**
  String get changeLogFromBill;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get changeLogRestored;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'{field}: {from} → {to}'**
  String changeLogChange(String field, String from, String to);

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get changeLogFieldType;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Replaced by a later edit on another phone'**
  String get changeLogReplaced;

  /// Change history
  ///
  /// In en, this message translates to:
  /// **'Replaced by {name}\'s later edit'**
  String changeLogReplacedBy(String name);

  /// Onboarding backup restore, home widgets
  ///
  /// In en, this message translates to:
  /// **'Restore a backup file'**
  String get onboardRestoreBackupFile;

  /// Onboarding backup restore, home widgets
  ///
  /// In en, this message translates to:
  /// **'A .db file saved from Settings › Backup & restore. The app closes to finish; open it again.'**
  String get onboardRestoreBackupHint;

  /// Onboarding backup restore, home widgets
  ///
  /// In en, this message translates to:
  /// **'Envelopes'**
  String get widgetEnvelopesTitle;

  /// Onboarding backup restore, home widgets
  ///
  /// In en, this message translates to:
  /// **'No spending envelopes yet'**
  String get widgetEnvelopesEmpty;

  /// Onboarding backup restore, home widgets
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get widgetAddLabel;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get webHistoryBtn;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'Change history'**
  String get webHistoryTitle;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'The last {n} changes to your transactions, newest first.'**
  String webHistoryIntro(int n);

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'No changes yet'**
  String get webHistoryEmpty;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get webHistoryAdded;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get webHistoryEdited;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get webHistoryDeleted;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'for {date}'**
  String webHistoryForDate(String date);

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'from the Web Companion'**
  String get webHistoryFromWeb;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'recurring bill'**
  String get webHistoryFromBill;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get webHistoryRestored;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'{field}: {from} → {to}'**
  String webHistoryChange(String field, String from, String to);

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'Replaced by a later edit on another phone'**
  String get webHistoryReplaced;

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'Replaced by {name}\'s later edit'**
  String webHistoryReplacedBy(String name);

  /// Web Companion: change history, usual spending
  ///
  /// In en, this message translates to:
  /// **'Usually spends {amount}'**
  String webFundUsually(String amount);

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'Who\'s using this phone?'**
  String get memberAskTitle;

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'Others use this budget too. Your name shows next to what you add, in Change history and on each transaction.'**
  String get memberAskBody;

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get memberYourName;

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'Just me'**
  String get memberJustMe;

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String memberSaved(String name);

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'Saved by {name}'**
  String memberSavedBy(String name);

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'Shown next to what you add in a shared budget'**
  String get memberTileSub;

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String changeLogBy(String name);

  /// Shared budget: member names
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String webHistoryBy(String name);

  /// Bill splitter: split in base currency
  ///
  /// In en, this message translates to:
  /// **'Split in {currency}'**
  String billSplitInBase(String currency);

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'See totals'**
  String get billSeeTotals;

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get billTotalsTitle;

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'Each person pays'**
  String get billTotalsEach;

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'Edit split'**
  String get billEditSplit;

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'Save · {amount}'**
  String billSaveAmount(String amount);

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get billShareShort;

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'Before tip'**
  String get billBeforeTipLabel;

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'Tax or service'**
  String get billTaxLabel;

  /// Bill splitter: totals page
  ///
  /// In en, this message translates to:
  /// **'{amount} + tip {tip}'**
  String billBeforeTipLine(String amount, String tip);

  /// Bill splitter: item quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get billQuantity;

  /// Bill splitter: item quantity
  ///
  /// In en, this message translates to:
  /// **'One less'**
  String get billQuantityLess;

  /// Bill splitter: item quantity
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get billQuantityMore;

  /// Bill splitter: item quantity
  ///
  /// In en, this message translates to:
  /// **'The amount is for all {qty}'**
  String billQuantityHint(int qty);

  /// Settings: change base currency
  ///
  /// In en, this message translates to:
  /// **'Change base currency to {code}?'**
  String baseChangeTitle(String code);

  /// Settings: change base currency
  ///
  /// In en, this message translates to:
  /// **'Amounts you\'ve recorded stay as they are. Totals and reports in {code} count them at this rate:'**
  String baseChangeBody(String code);

  /// Settings: change base currency
  ///
  /// In en, this message translates to:
  /// **'No rate known yet. Enter one to continue.'**
  String get baseChangeNoRate;

  /// Settings: change base currency
  ///
  /// In en, this message translates to:
  /// **'Change rate'**
  String get baseChangeEditRate;

  /// Settings: change base currency
  ///
  /// In en, this message translates to:
  /// **'1 {from} in {to}'**
  String baseChangeRateSheet(String from, String to);

  /// Settings: change base currency
  ///
  /// In en, this message translates to:
  /// **'It changes for everyone who shares this budget.'**
  String get baseChangeSharedNote;
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
