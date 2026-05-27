const NOTIFICATION_KEY = 'obat_lansia_notif_enabled';

class BrowserNotificationService {
  constructor() {
    this._permission = 'default';
    this._checkInterval = null;
    this._reminders = [];
    this._firedSet = new Set();
  }

  get isSupported() {
    return 'Notification' in window;
  }

  get isEnabled() {
    return localStorage.getItem(NOTIFICATION_KEY) === 'true';
  }

  get permission() {
    return this.isSupported ? Notification.permission : 'denied';
  }

  async requestPermission() {
    if (!this.isSupported) return 'denied';
    const result = await Notification.requestPermission();
    this._permission = result;
    if (result === 'granted') {
      localStorage.setItem(NOTIFICATION_KEY, 'true');
    }
    return result;
  }

  enable() {
    localStorage.setItem(NOTIFICATION_KEY, 'true');
  }

  disable() {
    localStorage.setItem(NOTIFICATION_KEY, 'false');
    this.stopChecking();
  }

  showNotification(title, body, options = {}) {
    if (!this.isSupported || this.permission !== 'granted') return null;

    const notif = new Notification(title, {
      body,
      icon: '/favicon.ico',
      badge: '/favicon.ico',
      tag: options.tag || `obat-${Date.now()}`,
      requireInteraction: true,
      vibrate: [200, 100, 200, 100, 200],
      ...options,
    });

    notif.onclick = () => {
      window.focus();
      notif.close();
      if (options.onClick) options.onClick();
    };

    return notif;
  }

  setReminders(reminders) {
    this._reminders = reminders;
  }

  startChecking(reminders, onAlarm) {
    this.stopChecking();
    this._reminders = reminders;
    this._onAlarm = onAlarm;

    this._checkInterval = setInterval(() => {
      this._checkReminders();
    }, 30000);

    this._checkReminders();
  }

  stopChecking() {
    if (this._checkInterval) {
      clearInterval(this._checkInterval);
      this._checkInterval = null;
    }
  }

  _checkReminders() {
    if (!this.isEnabled || !this._reminders.length) return;

    const now = new Date();
    const currentDay = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'][now.getDay()];
    const currentMinutes = now.getHours() * 60 + now.getMinutes();

    for (const reminder of this._reminders) {
      if (!reminder.is_active) continue;

      const days = reminder.days_of_week || [];
      if (!days.includes(currentDay)) continue;

      const time = reminder.scheduled_time || '';
      const [h, m] = time.split(':').map(Number);
      if (isNaN(h) || isNaN(m)) continue;

      const reminderMinutes = h * 60 + m;
      const diff = Math.abs(currentMinutes - reminderMinutes);

      const fireKey = `${reminder.id}-${now.toDateString()}-${time}`;
      if (diff <= 1 && !this._firedSet.has(fireKey)) {
        this._firedSet.add(fireKey);

        this.showNotification(
          'Waktunya Minum Obat!',
          `${reminder.patient_name || 'Pasien'} — ${reminder.medication_name || 'Obat'}\nJadwal: ${time.substring(0, 5)}`,
          {
            tag: `reminder-${reminder.id}`,
            onClick: () => {
              if (this._onAlarm) this._onAlarm(reminder);
            },
          }
        );

        if (this._onAlarm) {
          this._onAlarm(reminder);
        }
      }
    }

    // Clean up old fired entries daily
    if (this._firedSet.size > 500) {
      this._firedSet.clear();
    }
  }

  clearFiredHistory() {
    this._firedSet.clear();
  }
}

export const notificationService = new BrowserNotificationService();
export default notificationService;
