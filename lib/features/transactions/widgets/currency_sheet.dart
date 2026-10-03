import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/section_header.dart';

// ---------------------------------------------------------------------------
// Currencies (ISO 4217, generated from a table — keep it sorted by code)
// ---------------------------------------------------------------------------

/// Every circulating ISO 4217 currency: (code, English name).
const kCurrencies = [
  ('AED', 'UAE Dirham'),
  ('AFN', 'Afghan Afghani'),
  ('ALL', 'Albanian Lek'),
  ('AMD', 'Armenian Dram'),
  ('ANG', 'Netherlands Antillean Guilder'),
  ('AOA', 'Angolan Kwanza'),
  ('ARS', 'Argentine Peso'),
  ('AUD', 'Australian Dollar'),
  ('AWG', 'Aruban Florin'),
  ('AZN', 'Azerbaijani Manat'),
  ('BAM', 'Bosnia-Herzegovina Convertible Mark'),
  ('BBD', 'Barbadian Dollar'),
  ('BDT', 'Bangladeshi Taka'),
  ('BGN', 'Bulgarian Lev'),
  ('BHD', 'Bahraini Dinar'),
  ('BIF', 'Burundian Franc'),
  ('BMD', 'Bermudian Dollar'),
  ('BND', 'Brunei Dollar'),
  ('BOB', 'Bolivian Boliviano'),
  ('BRL', 'Brazilian Real'),
  ('BSD', 'Bahamian Dollar'),
  ('BTN', 'Bhutanese Ngultrum'),
  ('BWP', 'Botswana Pula'),
  ('BYN', 'Belarusian Ruble'),
  ('BZD', 'Belize Dollar'),
  ('CAD', 'Canadian Dollar'),
  ('CDF', 'Congolese Franc'),
  ('CHF', 'Swiss Franc'),
  ('CLP', 'Chilean Peso'),
  ('CNY', 'Chinese Yuan'),
  ('COP', 'Colombian Peso'),
  ('CRC', 'Costa Rican Colón'),
  ('CUP', 'Cuban Peso'),
  ('CVE', 'Cape Verdean Escudo'),
  ('CZK', 'Czech Koruna'),
  ('DJF', 'Djiboutian Franc'),
  ('DKK', 'Danish Krone'),
  ('DOP', 'Dominican Peso'),
  ('DZD', 'Algerian Dinar'),
  ('EGP', 'Egyptian Pound'),
  ('ERN', 'Eritrean Nakfa'),
  ('ETB', 'Ethiopian Birr'),
  ('EUR', 'Euro'),
  ('FJD', 'Fijian Dollar'),
  ('FKP', 'Falkland Islands Pound'),
  ('GBP', 'British Pound'),
  ('GEL', 'Georgian Lari'),
  ('GHS', 'Ghanaian Cedi'),
  ('GIP', 'Gibraltar Pound'),
  ('GMD', 'Gambian Dalasi'),
  ('GNF', 'Guinean Franc'),
  ('GTQ', 'Guatemalan Quetzal'),
  ('GYD', 'Guyanese Dollar'),
  ('HKD', 'Hong Kong Dollar'),
  ('HNL', 'Honduran Lempira'),
  ('HTG', 'Haitian Gourde'),
  ('HUF', 'Hungarian Forint'),
  ('IDR', 'Indonesian Rupiah'),
  ('ILS', 'Israeli New Shekel'),
  ('INR', 'Indian Rupee'),
  ('IQD', 'Iraqi Dinar'),
  ('IRR', 'Iranian Rial'),
  ('ISK', 'Icelandic Króna'),
  ('JMD', 'Jamaican Dollar'),
  ('JOD', 'Jordanian Dinar'),
  ('JPY', 'Japanese Yen'),
  ('KES', 'Kenyan Shilling'),
  ('KGS', 'Kyrgyzstani Som'),
  ('KHR', 'Cambodian Riel'),
  ('KMF', 'Comorian Franc'),
  ('KPW', 'North Korean Won'),
  ('KRW', 'South Korean Won'),
  ('KWD', 'Kuwaiti Dinar'),
  ('KYD', 'Cayman Islands Dollar'),
  ('KZT', 'Kazakhstani Tenge'),
  ('LAK', 'Lao Kip'),
  ('LBP', 'Lebanese Pound'),
  ('LKR', 'Sri Lankan Rupee'),
  ('LRD', 'Liberian Dollar'),
  ('LSL', 'Lesotho Loti'),
  ('LYD', 'Libyan Dinar'),
  ('MAD', 'Moroccan Dirham'),
  ('MDL', 'Moldovan Leu'),
  ('MGA', 'Malagasy Ariary'),
  ('MKD', 'Macedonian Denar'),
  ('MMK', 'Myanmar Kyat'),
  ('MNT', 'Mongolian Tögrög'),
  ('MOP', 'Macanese Pataca'),
  ('MRU', 'Mauritanian Ouguiya'),
  ('MUR', 'Mauritian Rupee'),
  ('MVR', 'Maldivian Rufiyaa'),
  ('MWK', 'Malawian Kwacha'),
  ('MXN', 'Mexican Peso'),
  ('MYR', 'Malaysian Ringgit'),
  ('MZN', 'Mozambican Metical'),
  ('NAD', 'Namibian Dollar'),
  ('NGN', 'Nigerian Naira'),
  ('NIO', 'Nicaraguan Córdoba'),
  ('NOK', 'Norwegian Krone'),
  ('NPR', 'Nepalese Rupee'),
  ('NZD', 'New Zealand Dollar'),
  ('OMR', 'Omani Rial'),
  ('PAB', 'Panamanian Balboa'),
  ('PEN', 'Peruvian Sol'),
  ('PGK', 'Papua New Guinean Kina'),
  ('PHP', 'Philippine Peso'),
  ('PKR', 'Pakistani Rupee'),
  ('PLN', 'Polish Złoty'),
  ('PYG', 'Paraguayan Guaraní'),
  ('QAR', 'Qatari Riyal'),
  ('RON', 'Romanian Leu'),
  ('RSD', 'Serbian Dinar'),
  ('RUB', 'Russian Ruble'),
  ('RWF', 'Rwandan Franc'),
  ('SAR', 'Saudi Riyal'),
  ('SBD', 'Solomon Islands Dollar'),
  ('SCR', 'Seychellois Rupee'),
  ('SDG', 'Sudanese Pound'),
  ('SEK', 'Swedish Krona'),
  ('SGD', 'Singapore Dollar'),
  ('SHP', 'Saint Helena Pound'),
  ('SLE', 'Sierra Leonean Leone'),
  ('SOS', 'Somali Shilling'),
  ('SRD', 'Surinamese Dollar'),
  ('SSP', 'South Sudanese Pound'),
  ('STN', 'São Tomé and Príncipe Dobra'),
  ('SYP', 'Syrian Pound'),
  ('SZL', 'Swazi Lilangeni'),
  ('THB', 'Thai Baht'),
  ('TJS', 'Tajikistani Somoni'),
  ('TMT', 'Turkmenistan Manat'),
  ('TND', 'Tunisian Dinar'),
  ('TOP', 'Tongan Paʻanga'),
  ('TRY', 'Turkish Lira'),
  ('TTD', 'Trinidad and Tobago Dollar'),
  ('TWD', 'New Taiwan Dollar'),
  ('TZS', 'Tanzanian Shilling'),
  ('UAH', 'Ukrainian Hryvnia'),
  ('UGX', 'Ugandan Shilling'),
  ('USD', 'US Dollar'),
  ('UYU', 'Uruguayan Peso'),
  ('UZS', 'Uzbekistani Som'),
  ('VES', 'Venezuelan Bolívar'),
  ('VND', 'Vietnamese Đồng'),
  ('VUV', 'Vanuatu Vatu'),
  ('WST', 'Samoan Tālā'),
  ('XAF', 'Central African CFA Franc'),
  ('XCD', 'East Caribbean Dollar'),
  ('XOF', 'West African CFA Franc'),
  ('XPF', 'CFP Franc'),
  ('YER', 'Yemeni Rial'),
  ('ZAR', 'South African Rand'),
  ('ZMW', 'Zambian Kwacha'),
  ('ZWG', 'Zimbabwe Gold'),
];

/// Translated name for a [kCurrencies] code; falls back to the code.
String currencyName(S s, String code) => switch (code) {
    'AED' => s.currencyNameAed,
    'AFN' => s.currencyNameAfn,
    'ALL' => s.currencyNameAll,
    'AMD' => s.currencyNameAmd,
    'ANG' => s.currencyNameAng,
    'AOA' => s.currencyNameAoa,
    'ARS' => s.currencyNameArs,
    'AUD' => s.currencyNameAud,
    'AWG' => s.currencyNameAwg,
    'AZN' => s.currencyNameAzn,
    'BAM' => s.currencyNameBam,
    'BBD' => s.currencyNameBbd,
    'BDT' => s.currencyNameBdt,
    'BGN' => s.currencyNameBgn,
    'BHD' => s.currencyNameBhd,
    'BIF' => s.currencyNameBif,
    'BMD' => s.currencyNameBmd,
    'BND' => s.currencyNameBnd,
    'BOB' => s.currencyNameBob,
    'BRL' => s.currencyNameBrl,
    'BSD' => s.currencyNameBsd,
    'BTN' => s.currencyNameBtn,
    'BWP' => s.currencyNameBwp,
    'BYN' => s.currencyNameByn,
    'BZD' => s.currencyNameBzd,
    'CAD' => s.currencyNameCad,
    'CDF' => s.currencyNameCdf,
    'CHF' => s.currencyNameChf,
    'CLP' => s.currencyNameClp,
    'CNY' => s.currencyNameCny,
    'COP' => s.currencyNameCop,
    'CRC' => s.currencyNameCrc,
    'CUP' => s.currencyNameCup,
    'CVE' => s.currencyNameCve,
    'CZK' => s.currencyNameCzk,
    'DJF' => s.currencyNameDjf,
    'DKK' => s.currencyNameDkk,
    'DOP' => s.currencyNameDop,
    'DZD' => s.currencyNameDzd,
    'EGP' => s.currencyNameEgp,
    'ERN' => s.currencyNameErn,
    'ETB' => s.currencyNameEtb,
    'EUR' => s.currencyNameEur,
    'FJD' => s.currencyNameFjd,
    'FKP' => s.currencyNameFkp,
    'GBP' => s.currencyNameGbp,
    'GEL' => s.currencyNameGel,
    'GHS' => s.currencyNameGhs,
    'GIP' => s.currencyNameGip,
    'GMD' => s.currencyNameGmd,
    'GNF' => s.currencyNameGnf,
    'GTQ' => s.currencyNameGtq,
    'GYD' => s.currencyNameGyd,
    'HKD' => s.currencyNameHkd,
    'HNL' => s.currencyNameHnl,
    'HTG' => s.currencyNameHtg,
    'HUF' => s.currencyNameHuf,
    'IDR' => s.currencyNameIdr,
    'ILS' => s.currencyNameIls,
    'INR' => s.currencyNameInr,
    'IQD' => s.currencyNameIqd,
    'IRR' => s.currencyNameIrr,
    'ISK' => s.currencyNameIsk,
    'JMD' => s.currencyNameJmd,
    'JOD' => s.currencyNameJod,
    'JPY' => s.currencyNameJpy,
    'KES' => s.currencyNameKes,
    'KGS' => s.currencyNameKgs,
    'KHR' => s.currencyNameKhr,
    'KMF' => s.currencyNameKmf,
    'KPW' => s.currencyNameKpw,
    'KRW' => s.currencyNameKrw,
    'KWD' => s.currencyNameKwd,
    'KYD' => s.currencyNameKyd,
    'KZT' => s.currencyNameKzt,
    'LAK' => s.currencyNameLak,
    'LBP' => s.currencyNameLbp,
    'LKR' => s.currencyNameLkr,
    'LRD' => s.currencyNameLrd,
    'LSL' => s.currencyNameLsl,
    'LYD' => s.currencyNameLyd,
    'MAD' => s.currencyNameMad,
    'MDL' => s.currencyNameMdl,
    'MGA' => s.currencyNameMga,
    'MKD' => s.currencyNameMkd,
    'MMK' => s.currencyNameMmk,
    'MNT' => s.currencyNameMnt,
    'MOP' => s.currencyNameMop,
    'MRU' => s.currencyNameMru,
    'MUR' => s.currencyNameMur,
    'MVR' => s.currencyNameMvr,
    'MWK' => s.currencyNameMwk,
    'MXN' => s.currencyNameMxn,
    'MYR' => s.currencyNameMyr,
    'MZN' => s.currencyNameMzn,
    'NAD' => s.currencyNameNad,
    'NGN' => s.currencyNameNgn,
    'NIO' => s.currencyNameNio,
    'NOK' => s.currencyNameNok,
    'NPR' => s.currencyNameNpr,
    'NZD' => s.currencyNameNzd,
    'OMR' => s.currencyNameOmr,
    'PAB' => s.currencyNamePab,
    'PEN' => s.currencyNamePen,
    'PGK' => s.currencyNamePgk,
    'PHP' => s.currencyNamePhp,
    'PKR' => s.currencyNamePkr,
    'PLN' => s.currencyNamePln,
    'PYG' => s.currencyNamePyg,
    'QAR' => s.currencyNameQar,
    'RON' => s.currencyNameRon,
    'RSD' => s.currencyNameRsd,
    'RUB' => s.currencyNameRub,
    'RWF' => s.currencyNameRwf,
    'SAR' => s.currencyNameSar,
    'SBD' => s.currencyNameSbd,
    'SCR' => s.currencyNameScr,
    'SDG' => s.currencyNameSdg,
    'SEK' => s.currencyNameSek,
    'SGD' => s.currencyNameSgd,
    'SHP' => s.currencyNameShp,
    'SLE' => s.currencyNameSle,
    'SOS' => s.currencyNameSos,
    'SRD' => s.currencyNameSrd,
    'SSP' => s.currencyNameSsp,
    'STN' => s.currencyNameStn,
    'SYP' => s.currencyNameSyp,
    'SZL' => s.currencyNameSzl,
    'THB' => s.currencyNameThb,
    'TJS' => s.currencyNameTjs,
    'TMT' => s.currencyNameTmt,
    'TND' => s.currencyNameTnd,
    'TOP' => s.currencyNameTop,
    'TRY' => s.currencyNameTry,
    'TTD' => s.currencyNameTtd,
    'TWD' => s.currencyNameTwd,
    'TZS' => s.currencyNameTzs,
    'UAH' => s.currencyNameUah,
    'UGX' => s.currencyNameUgx,
    'USD' => s.currencyNameUsd,
    'UYU' => s.currencyNameUyu,
    'UZS' => s.currencyNameUzs,
    'VES' => s.currencyNameVes,
    'VND' => s.currencyNameVnd,
    'VUV' => s.currencyNameVuv,
    'WST' => s.currencyNameWst,
    'XAF' => s.currencyNameXaf,
    'XCD' => s.currencyNameXcd,
    'XOF' => s.currencyNameXof,
    'XPF' => s.currencyNameXpf,
    'YER' => s.currencyNameYer,
    'ZAR' => s.currencyNameZar,
    'ZMW' => s.currencyNameZmw,
    'ZWG' => s.currencyNameZwg,
    _ => code,
  };

/// Currency code to flag emoji (none for regional currencies).
const kCurrencyFlags = <String, String>{
  'AED': '\u{1F1E6}\u{1F1EA}',
  'AFN': '\u{1F1E6}\u{1F1EB}',
  'ALL': '\u{1F1E6}\u{1F1F1}',
  'AMD': '\u{1F1E6}\u{1F1F2}',
  'ANG': '\u{1F1E8}\u{1F1FC}',
  'AOA': '\u{1F1E6}\u{1F1F4}',
  'ARS': '\u{1F1E6}\u{1F1F7}',
  'AUD': '\u{1F1E6}\u{1F1FA}',
  'AWG': '\u{1F1E6}\u{1F1FC}',
  'AZN': '\u{1F1E6}\u{1F1FF}',
  'BAM': '\u{1F1E7}\u{1F1E6}',
  'BBD': '\u{1F1E7}\u{1F1E7}',
  'BDT': '\u{1F1E7}\u{1F1E9}',
  'BGN': '\u{1F1E7}\u{1F1EC}',
  'BHD': '\u{1F1E7}\u{1F1ED}',
  'BIF': '\u{1F1E7}\u{1F1EE}',
  'BMD': '\u{1F1E7}\u{1F1F2}',
  'BND': '\u{1F1E7}\u{1F1F3}',
  'BOB': '\u{1F1E7}\u{1F1F4}',
  'BRL': '\u{1F1E7}\u{1F1F7}',
  'BSD': '\u{1F1E7}\u{1F1F8}',
  'BTN': '\u{1F1E7}\u{1F1F9}',
  'BWP': '\u{1F1E7}\u{1F1FC}',
  'BYN': '\u{1F1E7}\u{1F1FE}',
  'BZD': '\u{1F1E7}\u{1F1FF}',
  'CAD': '\u{1F1E8}\u{1F1E6}',
  'CDF': '\u{1F1E8}\u{1F1E9}',
  'CHF': '\u{1F1E8}\u{1F1ED}',
  'CLP': '\u{1F1E8}\u{1F1F1}',
  'CNY': '\u{1F1E8}\u{1F1F3}',
  'COP': '\u{1F1E8}\u{1F1F4}',
  'CRC': '\u{1F1E8}\u{1F1F7}',
  'CUP': '\u{1F1E8}\u{1F1FA}',
  'CVE': '\u{1F1E8}\u{1F1FB}',
  'CZK': '\u{1F1E8}\u{1F1FF}',
  'DJF': '\u{1F1E9}\u{1F1EF}',
  'DKK': '\u{1F1E9}\u{1F1F0}',
  'DOP': '\u{1F1E9}\u{1F1F4}',
  'DZD': '\u{1F1E9}\u{1F1FF}',
  'EGP': '\u{1F1EA}\u{1F1EC}',
  'ERN': '\u{1F1EA}\u{1F1F7}',
  'ETB': '\u{1F1EA}\u{1F1F9}',
  'EUR': '\u{1F1EA}\u{1F1FA}',
  'FJD': '\u{1F1EB}\u{1F1EF}',
  'FKP': '\u{1F1EB}\u{1F1F0}',
  'GBP': '\u{1F1EC}\u{1F1E7}',
  'GEL': '\u{1F1EC}\u{1F1EA}',
  'GHS': '\u{1F1EC}\u{1F1ED}',
  'GIP': '\u{1F1EC}\u{1F1EE}',
  'GMD': '\u{1F1EC}\u{1F1F2}',
  'GNF': '\u{1F1EC}\u{1F1F3}',
  'GTQ': '\u{1F1EC}\u{1F1F9}',
  'GYD': '\u{1F1EC}\u{1F1FE}',
  'HKD': '\u{1F1ED}\u{1F1F0}',
  'HNL': '\u{1F1ED}\u{1F1F3}',
  'HTG': '\u{1F1ED}\u{1F1F9}',
  'HUF': '\u{1F1ED}\u{1F1FA}',
  'IDR': '\u{1F1EE}\u{1F1E9}',
  'ILS': '\u{1F1EE}\u{1F1F1}',
  'INR': '\u{1F1EE}\u{1F1F3}',
  'IQD': '\u{1F1EE}\u{1F1F6}',
  'IRR': '\u{1F1EE}\u{1F1F7}',
  'ISK': '\u{1F1EE}\u{1F1F8}',
  'JMD': '\u{1F1EF}\u{1F1F2}',
  'JOD': '\u{1F1EF}\u{1F1F4}',
  'JPY': '\u{1F1EF}\u{1F1F5}',
  'KES': '\u{1F1F0}\u{1F1EA}',
  'KGS': '\u{1F1F0}\u{1F1EC}',
  'KHR': '\u{1F1F0}\u{1F1ED}',
  'KMF': '\u{1F1F0}\u{1F1F2}',
  'KPW': '\u{1F1F0}\u{1F1F5}',
  'KRW': '\u{1F1F0}\u{1F1F7}',
  'KWD': '\u{1F1F0}\u{1F1FC}',
  'KYD': '\u{1F1F0}\u{1F1FE}',
  'KZT': '\u{1F1F0}\u{1F1FF}',
  'LAK': '\u{1F1F1}\u{1F1E6}',
  'LBP': '\u{1F1F1}\u{1F1E7}',
  'LKR': '\u{1F1F1}\u{1F1F0}',
  'LRD': '\u{1F1F1}\u{1F1F7}',
  'LSL': '\u{1F1F1}\u{1F1F8}',
  'LYD': '\u{1F1F1}\u{1F1FE}',
  'MAD': '\u{1F1F2}\u{1F1E6}',
  'MDL': '\u{1F1F2}\u{1F1E9}',
  'MGA': '\u{1F1F2}\u{1F1EC}',
  'MKD': '\u{1F1F2}\u{1F1F0}',
  'MMK': '\u{1F1F2}\u{1F1F2}',
  'MNT': '\u{1F1F2}\u{1F1F3}',
  'MOP': '\u{1F1F2}\u{1F1F4}',
  'MRU': '\u{1F1F2}\u{1F1F7}',
  'MUR': '\u{1F1F2}\u{1F1FA}',
  'MVR': '\u{1F1F2}\u{1F1FB}',
  'MWK': '\u{1F1F2}\u{1F1FC}',
  'MXN': '\u{1F1F2}\u{1F1FD}',
  'MYR': '\u{1F1F2}\u{1F1FE}',
  'MZN': '\u{1F1F2}\u{1F1FF}',
  'NAD': '\u{1F1F3}\u{1F1E6}',
  'NGN': '\u{1F1F3}\u{1F1EC}',
  'NIO': '\u{1F1F3}\u{1F1EE}',
  'NOK': '\u{1F1F3}\u{1F1F4}',
  'NPR': '\u{1F1F3}\u{1F1F5}',
  'NZD': '\u{1F1F3}\u{1F1FF}',
  'OMR': '\u{1F1F4}\u{1F1F2}',
  'PAB': '\u{1F1F5}\u{1F1E6}',
  'PEN': '\u{1F1F5}\u{1F1EA}',
  'PGK': '\u{1F1F5}\u{1F1EC}',
  'PHP': '\u{1F1F5}\u{1F1ED}',
  'PKR': '\u{1F1F5}\u{1F1F0}',
  'PLN': '\u{1F1F5}\u{1F1F1}',
  'PYG': '\u{1F1F5}\u{1F1FE}',
  'QAR': '\u{1F1F6}\u{1F1E6}',
  'RON': '\u{1F1F7}\u{1F1F4}',
  'RSD': '\u{1F1F7}\u{1F1F8}',
  'RUB': '\u{1F1F7}\u{1F1FA}',
  'RWF': '\u{1F1F7}\u{1F1FC}',
  'SAR': '\u{1F1F8}\u{1F1E6}',
  'SBD': '\u{1F1F8}\u{1F1E7}',
  'SCR': '\u{1F1F8}\u{1F1E8}',
  'SDG': '\u{1F1F8}\u{1F1E9}',
  'SEK': '\u{1F1F8}\u{1F1EA}',
  'SGD': '\u{1F1F8}\u{1F1EC}',
  'SHP': '\u{1F1F8}\u{1F1ED}',
  'SLE': '\u{1F1F8}\u{1F1F1}',
  'SOS': '\u{1F1F8}\u{1F1F4}',
  'SRD': '\u{1F1F8}\u{1F1F7}',
  'SSP': '\u{1F1F8}\u{1F1F8}',
  'STN': '\u{1F1F8}\u{1F1F9}',
  'SYP': '\u{1F1F8}\u{1F1FE}',
  'SZL': '\u{1F1F8}\u{1F1FF}',
  'THB': '\u{1F1F9}\u{1F1ED}',
  'TJS': '\u{1F1F9}\u{1F1EF}',
  'TMT': '\u{1F1F9}\u{1F1F2}',
  'TND': '\u{1F1F9}\u{1F1F3}',
  'TOP': '\u{1F1F9}\u{1F1F4}',
  'TRY': '\u{1F1F9}\u{1F1F7}',
  'TTD': '\u{1F1F9}\u{1F1F9}',
  'TWD': '\u{1F1F9}\u{1F1FC}',
  'TZS': '\u{1F1F9}\u{1F1FF}',
  'UAH': '\u{1F1FA}\u{1F1E6}',
  'UGX': '\u{1F1FA}\u{1F1EC}',
  'USD': '\u{1F1FA}\u{1F1F8}',
  'UYU': '\u{1F1FA}\u{1F1FE}',
  'UZS': '\u{1F1FA}\u{1F1FF}',
  'VES': '\u{1F1FB}\u{1F1EA}',
  'VND': '\u{1F1FB}\u{1F1F3}',
  'VUV': '\u{1F1FB}\u{1F1FA}',
  'WST': '\u{1F1FC}\u{1F1F8}',
  'YER': '\u{1F1FE}\u{1F1EA}',
  'ZAR': '\u{1F1FF}\u{1F1E6}',
  'ZMW': '\u{1F1FF}\u{1F1F2}',
  'ZWG': '\u{1F1FF}\u{1F1FC}',
};

/// Currency code to symbol mapping.
const kCurrencySymbols = <String, String>{
  'USD': '\$',
  'EUR': '\u20AC',
  'GBP': '\u00A3',
  'JPY': '\u00A5',
  'CHF': 'CHF',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'CNY': '\u00A5',
  'INR': '\u20B9',
  'BRL': 'R\$',
  'MXN': 'MX\$',
  'SGD': 'S\$',
  'HKD': 'HK\$',
  'NOK': 'kr',
  'SEK': 'kr',
  'NZD': 'NZ\$',
  'ZAR': 'R',
  'AED': '\u062F.\u0625',
  'LBP': '\u0644.\u0644',
  'SAR': '\uFDFC',
  'KWD': 'KD',
  'TRY': '\u20BA',
};

class CurrencySheet extends StatefulWidget {
  final String current;

  /// Optional list of currency codes to show in a "Recently Used" section.
  final List<String> recentCurrencies;

  /// Currency codes from user's accounts — pinned at the top.
  final List<String> accountCurrencies;

  /// Codes that can't be picked here (e.g. the source currency of an
  /// exchange).
  final Set<String> exclude;

  const CurrencySheet({
    super.key,
    required this.current,
    this.recentCurrencies = const [],
    this.accountCurrencies = const [],
    this.exclude = const {},
  });

  @override
  State<CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<CurrencySheet>
    with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  final _sheetCtrl = DraggableScrollableController();
  String _query = '';
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final bottomInset =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final nowVisible = bottomInset > 100;
    if (nowVisible && !_keyboardVisible) {
      _keyboardVisible = true;
      if (_sheetCtrl.isAttached) {
        _sheetCtrl.animateTo(0.92,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    } else if (!nowVisible && _keyboardVisible) {
      _keyboardVisible = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final q = _query.toLowerCase();
    // Search matches the code, the translated name and the English name.
    final filtered = kCurrencies
        .where((c) => !widget.exclude.contains(c.$1))
        .where((c) =>
            c.$1.contains(_query.toUpperCase()) ||
            currencyName(tr, c.$1).toLowerCase().contains(q) ||
            c.$2.toLowerCase().contains(q))
        .toList();
    final accountCodes = widget.accountCurrencies
        .where((c) => !widget.exclude.contains(c))
        .toList();

    // Build the recently-used list (only when not searching, max 3).
    final recentCodes = _query.isEmpty
        ? widget.recentCurrencies
            .where((c) =>
                !widget.exclude.contains(c) &&
                kCurrencies.any((k) => k.$1 == c))
            .take(3)
            .toList()
        : <String>[];

    // A Material (not a coloured Container) so the rows' ripple and
    // selected highlight show.
    return Material(
      color: AppColors.sf(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: DraggableScrollableSheet(
        controller: _sheetCtrl,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        snap: true,
        snapSizes: const [0.6, 0.92],
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(S.of(context).commonCurrency,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: S.of(context).commonSearchHint,
                  prefixIcon:
                      const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: AppColors.sfv(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.bd(context)),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Account currencies (pinned at top)
                  if (_query.isEmpty && accountCodes.isNotEmpty) ...[
                    SectionHeader(S.of(context).currencyYourAccounts,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4)),
                    for (final code in accountCodes)
                      _buildCurrencyTile(code, currencyName(tr, code)),
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: AppColors.bd(context),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Recently used section
                  if (recentCodes.isNotEmpty) ...[
                    SectionHeader(S.of(context).currencyRecentlyUsed,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4)),
                    for (final code in recentCodes)
                      _buildCurrencyTile(code, currencyName(tr, code)),
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: AppColors.bd(context),
                    ),
                    const SizedBox(height: 4),
                    SectionHeader(S.of(context).currencyAll,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4)),
                  ],
                  // Full filtered list
                  for (final (code, _) in filtered)
                    _buildCurrencyTile(code, currencyName(tr, code)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(String code, String name) {
    final isSelected = code == widget.current;
    final flag = kCurrencyFlags[code];
    final symbol = kCurrencySymbols[code];

    final color = isSelected ? AppColors.accent : AppColors.tp(context);
    return ListTile(
      leading: SizedBox(
        width: 32,
        child: Center(
          child: flag != null
              ? Text(flag, style: const TextStyle(fontSize: 22))
              : Icon(Icons.payments_outlined,
                  size: 20, color: AppColors.ts(context)),
        ),
      ),
      title: Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        symbol != null ? '$code · $symbol' : code,
        style: TextStyle(fontSize: 12, color: AppColors.ts(context)),
      ),
      trailing: isSelected
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, AppColors.accent,
                    light: 0.85, dark: 0.78),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_rounded,
                  color: AppColors.accent, size: 16),
            )
          : null,
      selected: isSelected,
      selectedTileColor: AppColors.accentLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () => Navigator.pop(context, code),
    );
  }
}
