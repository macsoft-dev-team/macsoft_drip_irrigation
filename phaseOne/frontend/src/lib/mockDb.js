// Database Manager for Drip Irrigation SaaS Admin Panel (Clean State)

export const initialUsers = [
  { id: 1, name: "Super Admin", email: "admin@dripirrigation.com", role: "Super Admin", status: "Active", joinedAt: "2026-06-29" },
  { id: 2, name: "Aditi Rao", email: "aditi.rao@dripirrigation.com", role: "Technician", status: "Active", joinedAt: "2026-06-29" },
  { id: 3, name: "Vikram Malhotra", email: "vikram@dripirrigation.com", role: "Support Staff", status: "Active", joinedAt: "2026-06-29" },
  { id: 4, name: "Rajesh Patel", email: "rajesh.patel@dripirrigation.com", role: "Technician", status: "Suspended", joinedAt: "2026-06-29" }
];

export const initialFarmers = [];

export const initialFields = [];

export const initialTickets = [];

export const initialSystemSettings = {
  company: {
    name: "Macsoft Irrigation Solutions",
    email: "support@macsoftdrip.com",
    phone: "+91 9900998877",
    address: "401, Agri-Tech Park, Pune, Maharashtra - 411001",
    logo: ""
  },
  mqtt: {
    brokerUrl: "mqtts://broker.hivemq.com:8883",
    clientId: "macsoft_drip_admin_prod",
    username: "macsoft_admin",
    password: "••••••••••••••••",
    sslEnabled: true,
    keepAlive: 60,
    cleanSession: true
  },
  general: {
    systemLogsRetentionDays: 90,
    autoBackupEnabled: true,
    backupIntervalHours: 24,
    defaultTimeZone: "Asia/Kolkata",
    notificationChannels: {
      email: true,
      sms: true,
      push: false
    }
  }
};

export const initialActivityLogs = [
  { id: 1, timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19), user: "System", action: "Database Initialized", details: "Clean sandbox state loaded successfully." }
];

// LocalStorage Helper to load database
export function loadDb() {
  const dbVer = "1.2"; // Incremented to trigger reset
  if (localStorage.getItem("drip_db_version") !== dbVer) {
    localStorage.removeItem("drip_users");
    localStorage.removeItem("drip_farmers");
    localStorage.removeItem("drip_fields");
    localStorage.removeItem("drip_tickets");
    localStorage.removeItem("drip_settings");
    localStorage.removeItem("drip_logs");
    localStorage.setItem("drip_db_version", dbVer);
  }

  const loadItem = (key, initialVal) => {
    const saved = localStorage.getItem(key);
    if (!saved) {
      localStorage.setItem(key, JSON.stringify(initialVal));
      return initialVal;
    }
    return JSON.parse(saved);
  };

  return {
    users: loadItem("drip_users", initialUsers),
    farmers: loadItem("drip_farmers", initialFarmers),
    fields: loadItem("drip_fields", initialFields),
    tickets: loadItem("drip_tickets", initialTickets),
    settings: loadItem("drip_settings", initialSystemSettings),
    logs: loadItem("drip_logs", initialActivityLogs)
  };
}

// LocalStorage Helper to save database
export function saveDb(db) {
  localStorage.setItem("drip_users", JSON.stringify(db.users));
  localStorage.setItem("drip_farmers", JSON.stringify(db.farmers));
  localStorage.setItem("drip_fields", JSON.stringify(db.fields));
  localStorage.setItem("drip_tickets", JSON.stringify(db.tickets));
  localStorage.setItem("drip_settings", JSON.stringify(db.settings));
  localStorage.setItem("drip_logs", JSON.stringify(db.logs));
}

// Add an activity log helper
export function addLog(db, user, action, details) {
  const newLog = {
    id: Date.now(),
    timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
    user: user || "System",
    action,
    details
  };
  db.logs = [newLog, ...db.logs];
  saveDb(db);
  return db;
}
