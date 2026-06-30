// Sync Engine for Drip Irrigation SaaS (Transparent state mapping & reconciliation)

export async function fetchDbFromApi(dbSettings) {
  const token = localStorage.getItem("drip_token");
  if (!token) return null;

  const headers = {
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json"
  };

  try {
    // 1. Fetch Users
    const usersRes = await fetch("/api/v1/users", { headers });
    const usersData = await usersRes.json();

    // 2. Fetch Farmers
    const farmersRes = await fetch("/api/v1/farmers", { headers });
    const farmersData = await farmersRes.json();

    // 3. Fetch Fields
    const fieldsRes = await fetch("/api/v1/fields", { headers });
    const fieldsData = await fieldsRes.json();

    // 4. Fetch Support Tickets
    const ticketsRes = await fetch("/api/v1/tickets", { headers });
    const ticketsData = await ticketsRes.json();

    // 5. Fetch Activity Logs/History
    const logsRes = await fetch("/api/v1/irrigation/history", { headers });
    const logsData = await logsRes.json();

    // Map users
    const mappedUsers = Array.isArray(usersData.data) ? usersData.data.map(u => ({
      id: Number(u.id),
      name: u.name,
      email: u.email || "",
      role: u.role === "admin" ? "Super Admin" : u.role.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' '),
      status: u.status === "active" ? "Active" : "Suspended",
      joinedAt: u.createdAt ? u.createdAt.split('T')[0] : "2026-06-29"
    })) : [];

    // Map farmers
    const mappedFarmers = Array.isArray(farmersData.data) ? farmersData.data.map(f => ({
      id: Number(f.id),
      name: f.user?.name || "Unknown",
      phone: f.user?.phone || "",
      email: f.user?.email || "",
      address: f.address || "",
      village: f.village || "",
      district: f.district || "",
      state: f.state || "Maharashtra",
      pincode: f.pincode || "",
      status: f.user?.status === "active" ? "Active" : "Suspended",
      servicePlan: f.servicePlans && f.servicePlans.length > 0 ? f.servicePlans[0].planName : "Starter",
      registeredAt: f.createdAt ? f.createdAt.split('T')[0] : "2026-06-29"
    })) : [];

    // Map fields
    const mappedFields = Array.isArray(fieldsData.data) ? fieldsData.data.map(f => {
      // Build slaves, valves, zones, schedules
      const slaves = Array.isArray(f.masterController?.slaveBoards) ? f.masterController.slaveBoards.map(sb => ({
        id: Number(sb.id),
        name: sb.name,
        ipAddress: `192.168.1.${100 + sb.modbusAddress}`,
        port: "502",
        unitId: sb.modbusAddress,
        outputs: 8
      })) : [];

      const valves = [];
      if (f.zones) {
        f.zones.forEach(z => {
          if (z.valves) {
            z.valves.forEach(v => {
              if (!valves.find(val => val.id === Number(v.id))) {
                valves.push({
                  id: Number(v.id),
                  name: v.name,
                  type: "Drip",
                  capacity: 12.0,
                  modbusAddress: v.coilAddress,
                  slaveId: Number(v.slaveBoardId),
                  status: v.status === "open" ? "Open" : "Closed",
                  flowRate: v.status === "open" ? 12.0 : 0
                });
              }
            });
          }
        });
      }

      // Add loose valves (valves not in any zones but attached to slave boards)
      if (f.masterController && f.masterController.slaveBoards) {
        f.masterController.slaveBoards.forEach(sb => {
          if (sb.valves) {
            sb.valves.forEach(v => {
              if (!valves.find(val => val.id === Number(v.id))) {
                valves.push({
                  id: Number(v.id),
                  name: v.name,
                  type: "Drip",
                  capacity: 12.0,
                  modbusAddress: v.coilAddress,
                  slaveId: Number(v.slaveBoardId),
                  status: v.status === "open" ? "Open" : "Closed",
                  flowRate: v.status === "open" ? 12.0 : 0
                });
              }
            });
          }
        });
      }

      const zones = Array.isArray(f.zones) ? f.zones.map(z => ({
        id: Number(z.id),
        name: z.name,
        location: z.description || "N/A",
        valveIds: Array.isArray(z.valves) ? z.valves.map(v => Number(v.id)) : [],
        moisture: 45.0
      })) : [];

      return {
        id: Number(f.id),
        farmerId: Number(f.farmerId),
        name: f.name,
        location: f.locationName || "N/A",
        area: `${f.areaAcres || 5.0} acres`,
        cropType: "General Crops",
        masterDevice: f.masterController ? {
          model: "Raspberry Pi 4 Model B",
          status: f.masterController.status === "online" ? "Online" : "Offline",
          connectionType: "MQTT Broker",
          mqttTopic: f.masterController.deviceUid,
          latency: "45ms",
          lastHeartbeat: "Just now",
          firmware: f.masterController.firmwareVersion || "v2.4.2-stable",
          ipAddress: f.masterController.lastIp || "192.168.1.100"
        } : null,
        slaves,
        valves,
        pump: {
          status: f.masterController?.motorStatus === "on" || f.masterController?.motorStatus === "open" ? "On" : "Off",
          loadAmps: f.masterController?.motorStatus === "on" ? 9.2 : 0.0,
          mode: "Auto",
          voltage: 415,
          frequency: 50.0
        },
        zones,
        schedules: [],
        irrigationHistory: [],
        telemetry: {
          moistureHistory: [40, 40, 40],
          flowRateHistory: [0, 0, 0],
          pressureHistory: [0, 0, 0],
          timestamps: ["12:00 PM", "01:00 PM", "02:00 PM"]
        },
        modbusRegisters: []
      };
    }) : [];

    // Fetch schedules for all fields
    for (const field of mappedFields) {
      const schedRes = await fetch(`/api/v1/schedules/fields/${field.id}/schedules`, { headers });
      if (schedRes.ok) {
        const schedData = await schedRes.json();
        if (Array.isArray(schedData.data)) {
          field.schedules = schedData.data.map(s => ({
            id: Number(s.id),
            name: s.name,
            type: s.scheduleType || "timeBased",
            zoneName: s.targetType === "zone" ? `Zone ${s.targetId}` : `Valve ${s.targetId}`,
            startTime: s.startTime,
            duration: s.durationMinutes,
            days: s.repeatType === "daily" ? "Daily" : "Custom",
            rtcZones: s.zoneIds || [],
            timerSequence: s.sequenceData || []
          }));
        }
      }
    }

    // Map tickets
    const mappedTickets = Array.isArray(ticketsData.data) ? ticketsData.data.map(t => ({
      id: Number(t.id),
      farmerId: Number(t.farmerId),
      title: t.title,
      category: t.ticketType === "installation" ? "Installation" : "Service",
      priority: t.priority.charAt(0).toUpperCase() + t.priority.slice(1),
      assignedTechnician: t.assignedToUser ? t.assignedToUser.name : "Unassigned",
      status: t.status === "open" ? "Open" : t.status === "inProgress" ? "In Progress" : "Closed",
      createdAt: t.createdAt ? t.createdAt.split('T')[0] : "2026-06-29"
    })) : [];

    // Map logs
    const mappedLogs = Array.isArray(logsData.data) ? logsData.data.map(l => ({
      id: Number(l.id),
      timestamp: l.createdAt ? l.createdAt.replace('T', ' ').substring(0, 19) : "",
      user: l.requestedByUser?.name || "System",
      action: `${l.targetType.toUpperCase()} ${l.action.toUpperCase()}`,
      details: `Command ${l.commandUid} executed on target ${l.targetId}`
    })) : [];

    return {
      users: mappedUsers,
      farmers: mappedFarmers,
      fields: mappedFields,
      tickets: mappedTickets,
      settings: dbSettings,
      logs: mappedLogs
    };

  } catch (error) {
    console.error("API Fetch Error", error);
    return null;
  }
}

export async function reconcileDbWithApi(db, nextDb) {
  const token = localStorage.getItem("drip_token");
  if (!token) return;

  const headers = {
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json"
  };

  // 1. Sync Users
  if (nextDb.users.length > db.users.length) {
    const newUser = nextDb.users.find(u => !db.users.some(ou => ou.id === u.id));
    if (newUser) {
      await fetch("/api/v1/users", {
        method: "POST",
        headers,
        body: JSON.stringify({
          name: newUser.name,
          phone: `91${Math.floor(10000000 + Math.random() * 90000000)}`, // mock phone since UI only has name/email
          email: newUser.email,
          password: "password12345",
          role: newUser.role === "Super Admin" ? "admin" : newUser.role.toLowerCase().replace(' ', '_')
        })
      });
    }
  }

  // 2. Sync Farmers
  if (nextDb.farmers.length > db.farmers.length) {
    const newFarmer = nextDb.farmers.find(f => !db.farmers.some(of => of.id === f.id));
    if (newFarmer) {
      const res = await fetch("/api/v1/farmers", {
        method: "POST",
        headers,
        body: JSON.stringify({
          name: newFarmer.name,
          phone: newFarmer.phone,
          email: newFarmer.email || undefined,
          password: "farmer12345",
          address: newFarmer.address || "",
          village: newFarmer.village || "",
          district: newFarmer.district || "",
          state: newFarmer.state || "Maharashtra",
          pincode: newFarmer.pincode || ""
        })
      });
      if (res.ok) {
        const payload = await res.json();
        if (payload.data && payload.data.farmer) {
          // Replace temp ID with real DB ID
          newFarmer.id = Number(payload.data.farmer.id);
        }
      }
    }
  }

  // 3. Sync Fields
  if (nextDb.fields.length > db.fields.length) {
    const newField = nextDb.fields.find(f => !db.fields.some(of => of.id === f.id));
    if (newField) {
      const res = await fetch(`/api/v1/farmers/${newField.farmerId}/fields`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          name: newField.name,
          locationName: newField.location,
          areaAcres: parseFloat(newField.area) || 5.0
        })
      });
      if (res.ok) {
        const payload = await res.json();
        if (payload.data) {
          newField.id = Number(payload.data.id);
          // Onboard Master Controller for this field
          if (newField.masterDevice) {
            await fetch(`/api/v1/fields/${newField.id}/master`, {
              method: "POST",
              headers,
              body: JSON.stringify({
                deviceUid: newField.masterDevice.mqttTopic || `mc-${Date.now()}`,
                connectionType: "wifi"
              })
            });
          }
        }
      }
    }
  }

  // 4. Sync Valves (Manual Actuations)
  for (const nextField of nextDb.fields) {
    const prevField = db.fields.find(f => f.id === nextField.id);
    if (prevField) {
      // Check if a valve status changed
      for (const nextValve of nextField.valves) {
        const prevValve = prevField.valves.find(v => v.id === nextValve.id);
        if (prevValve && prevValve.status !== nextValve.status) {
          const action = nextValve.status === "Open" ? "open" : "close";
          await fetch(`/api/v1/valves/${nextValve.id}/${action}`, {
            method: "POST",
            headers
          });
        }
      }

      // Check if a new slave board was added
      if (nextField.slaves.length > prevField.slaves.length) {
        const newSlave = nextField.slaves.find(s => !prevField.slaves.some(os => os.id === s.id));
        if (newSlave && nextField.masterDevice) {
          // Find master controller ID from masterDevice or field structure
          const masterRes = await fetch(`/api/v1/fields/${nextField.id}/master`, { headers });
          if (masterRes.ok) {
            const masterPayload = await masterRes.json();
            if (masterPayload.data) {
              const masterId = masterPayload.data.id;
              const res = await fetch(`/api/v1/masters/${masterId}/slaves`, {
                method: "POST",
                headers,
                body: JSON.stringify({
                  name: newSlave.name,
                  deviceUid: `slave-${Date.now()}`,
                  modbusAddress: parseInt(newSlave.unitId) || 1
                })
              });
              if (res.ok) {
                const payload = await res.json();
                if (payload.data) {
                  newSlave.id = Number(payload.data.id);
                }
              }
            }
          }
        }
      }

      // Check if a new valve was added
      if (nextField.valves.length > prevField.valves.length) {
        const newValve = nextField.valves.find(v => !prevField.valves.some(ov => ov.id === v.id));
        if (newValve) {
          const res = await fetch(`/api/v1/slaves/${newValve.slaveId}/valves`, {
            method: "POST",
            headers,
            body: JSON.stringify({
              name: newValve.name,
              deviceUid: `valve-${Date.now()}`,
              coilAddress: parseInt(newValve.modbusAddress) || 0
            })
          });
          if (res.ok) {
            const payload = await res.json();
            if (payload.data) {
              newValve.id = Number(payload.data.id);
            }
          }
        }
      }

      // Check if a new zone was added
      if (nextField.zones.length > prevField.zones.length) {
        const newZone = nextField.zones.find(z => !prevField.zones.some(oz => oz.id === z.id));
        if (newZone) {
          const res = await fetch(`/api/v1/fields/${nextField.id}/zones`, {
            method: "POST",
            headers,
            body: JSON.stringify({
              name: newZone.name,
              description: newZone.location
            })
          });
          if (res.ok) {
            const payload = await res.json();
            if (payload.data) {
              newZone.id = Number(payload.data.id);
              // Associate valves
              if (newZone.valveIds && newZone.valveIds.length > 0) {
                await fetch(`/api/v1/zones/${newZone.id}/valves`, {
                  method: "PUT",
                  headers,
                  body: JSON.stringify({
                    valveIds: newZone.valveIds.map(String)
                  })
                });
              }
            }
          }
        }
      }

      // Check if a new schedule was added
      if (nextField.schedules.length > prevField.schedules.length) {
        const newSched = nextField.schedules.find(s => !prevField.schedules.some(os => os.id === s.id));
        if (newSched) {
          // Parse start time to HH:MM format
          let startTime = "08:00";
          if (newSched.startTime) {
            const match = newSched.startTime.match(/(\d+):(\d+)\s*(AM|PM)/i);
            if (match) {
              let h = parseInt(match[1]);
              const m = match[2];
              const pm = match[3].toUpperCase() === "PM";
              if (pm && h < 12) h += 12;
              if (!pm && h === 12) h = 0;
              startTime = `${String(h).padStart(2, '0')}:${m}`;
            }
          }

          const res = await fetch(`/api/v1/schedules/fields/${nextField.id}/schedules`, {
            method: "POST",
            headers,
            body: JSON.stringify({
              name: newSched.name,
              scheduleType: newSched.type || "timeBased",
              startTime,
              durationMinutes: parseInt(newSched.duration) || 15,
              repeatType: "daily",
              zoneIds: newSched.rtcZones || [],
              sequenceData: newSched.timerSequence || []
            })
          });
          if (res.ok) {
            const payload = await res.json();
            if (payload.data) {
              newSched.id = Number(payload.data.id);
            }
          }
        }
      }

      // Check if a schedule was deleted
      if (nextField.schedules.length < prevField.schedules.length) {
        const deletedSched = prevField.schedules.find(s => !nextField.schedules.some(os => os.id === s.id));
        if (deletedSched) {
          await fetch(`/api/v1/schedules/${deletedSched.id}`, {
            method: "DELETE",
            headers
          });
        }
      }
    }
  }

  // 5. Sync Support Tickets
  if (nextDb.tickets.length > db.tickets.length) {
    const newTicket = nextDb.tickets.find(t => !db.tickets.some(ot => ot.id === t.id));
    if (newTicket) {
      const res = await fetch("/api/v1/tickets", {
        method: "POST",
        headers,
        body: JSON.stringify({
          farmerId: String(newTicket.farmerId),
          title: newTicket.title,
          description: newTicket.description || "",
          priority: newTicket.priority.toLowerCase(),
          ticketType: newTicket.category === "Installation" ? "installation" : "service"
        })
      });
      if (res.ok) {
        const payload = await res.json();
        if (payload.data) {
          newTicket.id = Number(payload.data.id);
        }
      }
    }
  }
}
