"""
Compare PocketPlan translations against Cashew app translations.
Finds matching English strings and flags Arabic/French differences.
"""

import json
import os
import re
from difflib import SequenceMatcher

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def load_arb(path):
    """Load ARB file, return dict of key -> value (skip @-prefixed metadata keys)."""
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return {k: v for k, v in data.items() if not k.startswith('@')}

def load_cashew(path):
    """Load Cashew JSON array, return list of {key, en, fr, ar}."""
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def normalize(s):
    """Normalize string for comparison: lowercase, strip, collapse whitespace."""
    if not s:
        return ''
    s = s.lower().strip()
    # Remove placeholders like {count}, {amount}, etc.
    s = re.sub(r'\{[^}]+\}', '', s)
    # Collapse whitespace
    s = re.sub(r'\s+', ' ', s).strip()
    return s

def is_arabic(text):
    """Check if text contains Arabic characters."""
    if not text:
        return False
    return any('\u0600' <= c <= '\u06FF' or '\u0750' <= c <= '\u077F' for c in text)

def is_latin_only(text):
    """Check if text is only Latin/ASCII (i.e., untranslated English)."""
    if not text:
        return True
    return all(ord(c) < 0x0600 for c in text if not c.isspace() and c not in '.,;:!?()-/')

def similarity(a, b):
    """Return similarity ratio between two strings."""
    return SequenceMatcher(None, normalize(a), normalize(b)).ratio()

def main():
    # Load files
    en = load_arb(os.path.join(BASE, 'lib', 'l10n', 'app_en.arb'))
    ar = load_arb(os.path.join(BASE, 'lib', 'l10n', 'app_ar.arb'))
    fr = load_arb(os.path.join(BASE, 'lib', 'l10n', 'app_fr.arb'))
    cashew = load_cashew(os.path.join(BASE, 'docs', 'cashew_translations.json'))

    print(f"PocketPlan: {len(en)} English keys")
    print(f"Cashew: {len(cashew)} entries")
    print()

    # Build Cashew lookup by normalized English
    cashew_by_en = {}
    for entry in cashew:
        norm = normalize(entry.get('en', ''))
        if norm and len(norm) >= 2:
            if norm not in cashew_by_en:
                cashew_by_en[norm] = entry

    # Also build a list for fuzzy matching
    cashew_norms = [(normalize(e.get('en', '')), e) for e in cashew if e.get('en')]

    # High-value categories to prioritize
    high_value_en = {
        # Common words
        'cancel', 'delete', 'save', 'ok', 'edit', 'add', 'close', 'back', 'next',
        'done', 'confirm', 'loading', 'search', 'retry', 'reset', 'undo',
        'share', 'export', 'import', 'none', 'all', 'select', 'copy',
        # Navigation
        'home', 'transactions', 'budget', 'reports', 'settings', 'more',
        'accounts', 'categories', 'subscriptions',
        # Transaction types
        'income', 'expense', 'transfer', 'transaction',
        # Account types
        'cash', 'bank', 'credit card', 'savings',
        # Financial terms
        'balance', 'amount', 'category', 'account', 'total', 'net worth',
        'unallocated', 'allocated', 'currency', 'exchange rate',
        # Actions
        'create', 'backup', 'restore', 'archive', 'sync',
        # Time
        'today', 'yesterday', 'daily', 'weekly', 'monthly', 'yearly',
        'date', 'period',
        # Other common
        'name', 'note', 'notes', 'title', 'description', 'type',
        'recurring', 'notification', 'notifications',
    }

    # Track results
    exact_matches = []
    fuzzy_matches = []
    ar_differences = []
    fr_differences = []
    untranslated_ar = []

    for pp_key, pp_en in en.items():
        if pp_key == '@@locale':
            continue
        pp_norm = normalize(pp_en)
        if not pp_norm or len(pp_norm) < 2:
            continue

        pp_ar = ar.get(pp_key, '')
        pp_fr = fr.get(pp_key, '')

        # Try exact match
        cashew_entry = cashew_by_en.get(pp_norm)
        match_type = 'exact'

        # If no exact match, try fuzzy for short high-value strings
        if not cashew_entry and pp_norm in high_value_en:
            best_score = 0
            best_entry = None
            for cn, ce in cashew_norms:
                if cn == pp_norm:
                    best_entry = ce
                    best_score = 1.0
                    break
            if best_entry:
                cashew_entry = best_entry
                match_type = 'exact-hv'

        # Fuzzy match for longer strings (>= 4 words)
        if not cashew_entry and len(pp_norm.split()) >= 3:
            best_score = 0
            best_entry = None
            for cn, ce in cashew_norms:
                if not cn:
                    continue
                score = similarity(pp_norm, cn)
                if score > best_score and score >= 0.75:
                    best_score = score
                    best_entry = ce
            if best_entry:
                cashew_entry = best_entry
                match_type = f'fuzzy({best_score:.0%})'

        if not cashew_entry:
            continue

        c_ar = cashew_entry.get('ar', '')
        c_fr = cashew_entry.get('fr', '')
        c_en = cashew_entry.get('en', '')

        is_high_value = pp_norm in high_value_en

        # Check Arabic
        if c_ar and pp_ar:
            if normalize(pp_ar) != normalize(c_ar):
                ar_differences.append({
                    'key': pp_key,
                    'en': pp_en,
                    'cashew_en': c_en,
                    'pp_ar': pp_ar,
                    'cashew_ar': c_ar,
                    'match_type': match_type,
                    'high_value': is_high_value,
                })

        # Check if PP Arabic is just English (untranslated)
        if pp_ar and is_latin_only(pp_ar) and c_ar and is_arabic(c_ar):
            untranslated_ar.append({
                'key': pp_key,
                'en': pp_en,
                'pp_ar': pp_ar,
                'cashew_ar': c_ar,
            })

        # Check French
        if c_fr and pp_fr:
            if normalize(pp_fr) != normalize(c_fr):
                fr_differences.append({
                    'key': pp_key,
                    'en': pp_en,
                    'cashew_en': c_en,
                    'pp_fr': pp_fr,
                    'cashew_fr': c_fr,
                    'match_type': match_type,
                    'high_value': is_high_value,
                })

    # =========================================================================
    # REPORT
    # =========================================================================

    print("=" * 80)
    print("SECTION 1: UNTRANSLATED ARABIC (PocketPlan has English, Cashew has Arabic)")
    print("=" * 80)
    if untranslated_ar:
        for item in untranslated_ar:
            print(f"\n  Key: {item['key']}")
            print(f"  English:    {item['en']}")
            print(f"  PP Arabic:  {item['pp_ar']}  <-- UNTRANSLATED")
            print(f"  Cashew AR:  {item['cashew_ar']}")
    else:
        print("  None found.")

    print()
    print("=" * 80)
    print("SECTION 2: HIGH-VALUE ARABIC DIFFERENCES")
    print("=" * 80)
    hv_ar = [d for d in ar_differences if d['high_value']]
    hv_ar.sort(key=lambda x: x['en'].lower())
    if hv_ar:
        for item in hv_ar:
            print(f"\n  [{item['match_type']}] \"{item['en']}\"" +
                  (f" ~ \"{item['cashew_en']}\"" if item['en'] != item['cashew_en'] else ""))
            print(f"    PP Arabic:     {item['pp_ar']}")
            print(f"    Cashew Arabic: {item['cashew_ar']}")
    else:
        print("  None found.")

    print()
    print("=" * 80)
    print("SECTION 3: HIGH-VALUE FRENCH DIFFERENCES")
    print("=" * 80)
    hv_fr = [d for d in fr_differences if d['high_value']]
    hv_fr.sort(key=lambda x: x['en'].lower())
    if hv_fr:
        for item in hv_fr:
            print(f"\n  [{item['match_type']}] \"{item['en']}\"" +
                  (f" ~ \"{item['cashew_en']}\"" if item['en'] != item['cashew_en'] else ""))
            print(f"    PP French:     {item['pp_fr']}")
            print(f"    Cashew French: {item['cashew_fr']}")
    else:
        print("  None found.")

    print()
    print("=" * 80)
    print("SECTION 4: OTHER ARABIC DIFFERENCES (non-high-value exact matches)")
    print("=" * 80)
    other_ar = [d for d in ar_differences if not d['high_value'] and d['match_type'] == 'exact']
    other_ar.sort(key=lambda x: x['en'].lower())
    count = 0
    for item in other_ar:
        print(f"\n  \"{item['en']}\"")
        print(f"    PP:     {item['pp_ar']}")
        print(f"    Cashew: {item['cashew_ar']}")
        count += 1
        if count >= 80:
            remaining = len(other_ar) - count
            if remaining > 0:
                print(f"\n  ... and {remaining} more")
            break

    print()
    print("=" * 80)
    print("SECTION 5: OTHER FRENCH DIFFERENCES (non-high-value exact matches)")
    print("=" * 80)
    other_fr = [d for d in fr_differences if not d['high_value'] and d['match_type'] == 'exact']
    other_fr.sort(key=lambda x: x['en'].lower())
    count = 0
    for item in other_fr:
        print(f"\n  \"{item['en']}\"")
        print(f"    PP:     {item['pp_fr']}")
        print(f"    Cashew: {item['cashew_fr']}")
        count += 1
        if count >= 80:
            remaining = len(other_fr) - count
            if remaining > 0:
                print(f"\n  ... and {remaining} more")
            break

    # Summary
    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    total_matches = len(set(d['key'] for d in ar_differences + fr_differences))
    print(f"  Total PocketPlan keys matched to Cashew: {total_matches}")
    print(f"  Untranslated Arabic (English text in AR): {len(untranslated_ar)}")
    print(f"  Arabic differences (high-value): {len(hv_ar)}")
    print(f"  Arabic differences (other): {len(other_ar)}")
    print(f"  French differences (high-value): {len(hv_fr)}")
    print(f"  French differences (other): {len(other_fr)}")


if __name__ == '__main__':
    main()
