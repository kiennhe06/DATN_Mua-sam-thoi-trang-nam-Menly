/**
 * Vietnam Timezone (GMT+7, Asia/Ho_Chi_Minh) Date Utilities
 * Ensures accurate, real-time date/time formatting and day-range comparisons
 * with zero 1-day offset across client & SSR environments.
 */

export const VN_TIMEZONE = 'Asia/Ho_Chi_Minh';

/**
 * Format a Date, ISO string, or timestamp into 'YYYY-MM-DD' in Vietnam timezone (GMT+7)
 */
export function toVNLocalDateString(d?: Date | string | number | null): string {
  if (!d) return '';
  try {
    const dateObj = typeof d === 'string' || typeof d === 'number' ? new Date(d) : d;
    if (isNaN(dateObj.getTime())) return '';
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: VN_TIMEZONE,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(dateObj);
  } catch {
    return typeof d === 'string' ? d.slice(0, 10) : '';
  }
}

/**
 * Format a Date, ISO string, or timestamp into 'YYYY-MM' in Vietnam timezone (GMT+7)
 */
export function toVNLocalMonthString(d?: Date | string | number | null): string {
  const s = toVNLocalDateString(d);
  return s ? s.slice(0, 7) : '';
}

/**
 * Parse a 'YYYY-MM-DD' string safely in local context
 */
export function parseVNLocalDate(s: string): Date {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(y, (m || 1) - 1, d || 1);
}

/**
 * Shift days from a 'YYYY-MM-DD' or Date and return 'YYYY-MM-DD' in VN timezone
 */
export function shiftVNDays(base: Date | string, days: number): string {
  const d = typeof base === 'string' ? parseVNLocalDate(base) : new Date(base);
  d.setDate(d.getDate() + days);
  return toVNLocalDateString(d);
}

/**
 * Format Date/time into Vietnamese components { time, date, full } in Asia/Ho_Chi_Minh
 */
export function formatVNDateTime(dateStr?: string | Date | null): {
  time: string;
  date: string;
  full: string;
} {
  if (!dateStr) return { time: '--:--', date: '--/--/----', full: '--' };
  try {
    const d = typeof dateStr === 'string' ? new Date(dateStr) : dateStr;
    if (isNaN(d.getTime())) {
      return { time: '--:--', date: String(dateStr), full: String(dateStr) };
    }
    const time = d.toLocaleTimeString('vi-VN', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
      timeZone: VN_TIMEZONE,
    });
    const date = d.toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      timeZone: VN_TIMEZONE,
    });
    return { time, date, full: `${time} - ${date}` };
  } catch {
    return { time: '--:--', date: String(dateStr), full: String(dateStr) };
  }
}

/**
 * Format 'YYYY-MM-DD' into Vietnamese readable 'DD/MM/YYYY'
 */
export function formatVNDayDisplay(s?: string | null): string {
  if (!s) return '';
  return s.split('-').reverse().join('/');
}

/**
 * Get Today's date string in Vietnam (YYYY-MM-DD)
 */
export function getVNToday(): string {
  return toVNLocalDateString(new Date());
}

/**
 * Get Yesterday's date string in Vietnam (YYYY-MM-DD)
 */
export function getVNYesterday(): string {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return toVNLocalDateString(d);
}

/**
 * Get current Month string in Vietnam (YYYY-MM)
 */
export function getVNThisMonth(): string {
  return toVNLocalMonthString(new Date());
}
