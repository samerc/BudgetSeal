import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand (same in both themes) ────────────────────────────
  static const primary = Color(0xFF1A2B4A);
  static const primaryLight = Color(0xFF2A3F6A);
  static const accent = Color(0xFF6366F1);
  static const accentLight = Color(0xFFE0E7FF);

  // ── Semantic (same in both themes) ─────────────────────────
  static const healthy = Color(0xFF10B981);
  static const healthyLight = Color(0xFFD1FAE5);
  static const caution = Color(0xFFF59E0B);
  static const cautionLight = Color(0xFFFEF3C7);
  static const overspent = Color(0xFFEF4444);
  static const overspentLight = Color(0xFFFEE2E2);

  // ── Theme-aware surface/text colors ────────────────────────
  // Call these from build() methods where you have a BuildContext.
  static Color bg(BuildContext c) =>
      _dark(c) ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  static Color sf(BuildContext c) =>
      _dark(c) ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color sfv(BuildContext c) =>
      _dark(c) ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
  static Color tp(BuildContext c) =>
      _dark(c) ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E);
  static Color ts(BuildContext c) =>
      _dark(c) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color th(BuildContext c) =>
      _dark(c) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  static Color bd(BuildContext c) =>
      _dark(c) ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  // ── Legacy const values (for const contexts / hint styles) ─
  // These return light-mode values. Use the methods above when possible.
  static const background = Color(0xFFF1F5F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);

  // Dark const values (used by theme definitions)
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceVariant = Color(0xFF334155);
  static const darkTextPrimary = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextHint = Color(0xFF64748B);
}
