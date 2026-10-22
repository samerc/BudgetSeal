/// Whole calendar days from [from] to [to], comparing dates only (negative
/// when [to] is earlier).
///
/// Counts on UTC dates: `DateTime.difference().inDays` on local dates is off
/// by one across a daylight-saving change (a 23- or 25-hour day), which made
/// a bill due in 2 days read "tomorrow".
int calendarDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;
