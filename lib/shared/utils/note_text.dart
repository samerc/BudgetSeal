final _objTag = RegExp(r'\s*\[obj:[^\]]*\]');

/// A transaction note as shown to the user: without the internal
/// `[obj:ID|amount]` tag that links goal/loan payments to their objective.
/// Keep the raw note when editing, so the link survives.
String visibleNote(String note) => note.replaceAll(_objTag, '');
