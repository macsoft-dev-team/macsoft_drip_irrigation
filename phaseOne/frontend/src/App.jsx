import React, { useState, useEffect } from "react"
import SaasLayout from "@/components/SaasLayout"
import Dashboard from "@/views/Dashboard"
import Users from "@/views/Users"
import Farmers from "@/views/Farmers"
import FieldWorkspace from "@/views/FieldWorkspace"
import Support from "@/views/Support"
import Settings from "@/views/Settings"
import Login from "@/views/Login"
import { loadDb, saveDb } from "@/lib/mockDb"
import { fetchDbFromApi, reconcileDbWithApi } from "@/lib/syncEngine"

function App() {
  const [currentPath, setCurrentPath] = useState(window.location.pathname)
  const [db, setDb] = useState(() => loadDb())
  const [selectedFarmerId, setSelectedFarmerId] = useState(() => {
    const saved = localStorage.getItem("drip_selected_farmer_id")
    return saved ? Number(saved) : 1 // default to Ramesh Kumar
  })
  const [selectedFieldId, setSelectedFieldId] = useState(() => {
    const saved = localStorage.getItem("drip_selected_field_id")
    return saved ? Number(saved) : 101 // default to North Orchard
  })
  const [activeWorkspaceTab, setActiveWorkspaceTab] = useState(() => {
    return localStorage.getItem("drip_workspace_tab") || "overview"
  })

  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    return localStorage.getItem("drip_admin_auth") === "true"
  })

  // Sync selected farmer and field to local storage
  useEffect(() => {
    if (selectedFarmerId) localStorage.setItem("drip_selected_farmer_id", selectedFarmerId.toString())
  }, [selectedFarmerId])

  useEffect(() => {
    if (selectedFieldId) localStorage.setItem("drip_selected_field_id", selectedFieldId.toString())
  }, [selectedFieldId])

  useEffect(() => {
    localStorage.setItem("drip_workspace_tab", activeWorkspaceTab)
  }, [activeWorkspaceTab])

  // Periodic API fetch cycle
  useEffect(() => {
    if (!isAuthenticated) return

    const initialFetch = async () => {
      const remoteDb = await fetchDbFromApi(db.settings)
      if (remoteDb) setDb(remoteDb)
    }
    initialFetch()

    const interval = setInterval(async () => {
      const remoteDb = await fetchDbFromApi(db.settings)
      if (remoteDb) setDb(remoteDb)
    }, 5000)

    return () => clearInterval(interval)
  }, [isAuthenticated])

  // Sync database state changes to local storage and backend API
  const syncSetDb = async (nextDbOrFn) => {
    let nextDb
    if (typeof nextDbOrFn === "function") {
      nextDb = nextDbOrFn(db)
    } else {
      nextDb = nextDbOrFn
    }

    setDb(nextDb)
    saveDb(nextDb)

    try {
      await reconcileDbWithApi(db, nextDb)
    } catch (error) {
      console.error("Failed to sync database updates with backend API", error)
    }
  }

  // Periodic Soil Moisture & Valve Simulation (real-time demo feel)
  useEffect(() => {
    const interval = setInterval(() => {
      setDb(prevDb => {
        let dbChanged = false;
        const updatedFields = prevDb.fields.map(field => {
          // Only simulate fields with Online Master Controllers
          if (field.masterDevice?.status !== "Online") return field;

          let fieldChanged = false;
          const updatedZones = field.zones.map(zone => {
            // Find active valves linked to this zone
            const zoneValves = field.valves.filter(v => zone.valveIds.includes(v.id))
            const openValves = zoneValves.filter(v => v.status === "Open")

            let nextMoisture = zone.moisture
            if (openValves.length > 0) {
              const increaseRate = 0.1 * openValves.length
              nextMoisture = Math.min(nextMoisture + increaseRate, 90.0)
            } else {
              nextMoisture = Math.max(nextMoisture - 0.02, 10.0)
            }

            if (nextMoisture !== zone.moisture) {
              fieldChanged = true;
              return { ...zone, moisture: parseFloat(nextMoisture.toFixed(2)) }
            }
            return zone;
          })

          const updatedValves = field.valves.map(valve => {
            if (valve.status === "Open") {
              // Add a bit of realistic noise to flowRate
              const noise = (Math.random() - 0.5) * 0.2
              const nextFlow = Math.max(0, valve.capacity + noise)
              fieldChanged = true;
              return { ...valve, flowRate: parseFloat(nextFlow.toFixed(1)) }
            } else if (valve.flowRate > 0) {
              fieldChanged = true;
              return { ...valve, flowRate: 0 }
            }
            return valve;
          })

          // Calculate pump state based on whether any valves are open
          const hasOpenValves = updatedValves.some(v => v.status === "Open")
          const nextPumpStatus = hasOpenValves ? "On" : "Off"
          const nextLoadAmps = hasOpenValves ? parseFloat((8.5 + Math.random()).toFixed(1)) : 0.0

          let updatedPump = field.pump
          if (field.pump.status !== nextPumpStatus || field.pump.loadAmps !== nextLoadAmps) {
            fieldChanged = true;
            updatedPump = {
              ...field.pump,
              status: nextPumpStatus,
              loadAmps: nextLoadAmps
            }
          }

          if (fieldChanged) {
            dbChanged = true;
            return {
              ...field,
              zones: updatedZones,
              valves: updatedValves,
              pump: updatedPump
            }
          }
          return field;
        })

        if (dbChanged) {
          return { ...prevDb, fields: updatedFields };
        }
        return prevDb;
      })
    }, 2000)

    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    const handleLocationChange = () => {
      setCurrentPath(window.location.pathname)
    }

    if (window.location.pathname === "/" || window.location.pathname === "") {
      window.history.replaceState({}, "", "/dashboard")
      setCurrentPath("/dashboard")
    }

    window.addEventListener("popstate", handleLocationChange)
    return () => {
      window.removeEventListener("popstate", handleLocationChange)
    }
  }, [])

  // Sync route path with authentication state
  useEffect(() => {
    if (!isAuthenticated && currentPath !== "/login") {
      window.history.replaceState({}, "", "/login")
      setCurrentPath("/login")
    } else if (isAuthenticated && currentPath === "/login") {
      window.history.replaceState({}, "", "/dashboard")
      setCurrentPath("/dashboard")
    }
  }, [isAuthenticated, currentPath])

  const navigate = (to) => {
    window.history.pushState({}, "", to)
    setCurrentPath(to)
  }

  // Routing switch logic
  const renderView = () => {
    switch (currentPath) {
      case "/users":
        return <Users db={db} setDb={syncSetDb} />
      case "/farmers":
        return (
          <Farmers 
            navigate={navigate} 
            db={db} 
            setDb={syncSetDb} 
            selectedFarmerId={selectedFarmerId}
            setSelectedFarmerId={setSelectedFarmerId}
            setSelectedFieldId={setSelectedFieldId}
          />
        )
      case "/field-workspace":
        return (
          <FieldWorkspace 
            navigate={navigate} 
            db={db} 
            setDb={syncSetDb} 
            selectedFarmerId={selectedFarmerId}
            selectedFieldId={selectedFieldId}
            activeTab={activeWorkspaceTab}
            setActiveTab={setActiveWorkspaceTab}
          />
        )
      case "/support":
        return <Support db={db} setDb={syncSetDb} />
      case "/settings":
        return <Settings db={db} setDb={syncSetDb} />
      case "/dashboard":
      default:
        return (
          <Dashboard 
            navigate={navigate} 
            db={db} 
            setDb={syncSetDb} 
            setSelectedFarmerId={setSelectedFarmerId}
            setSelectedFieldId={setSelectedFieldId}
          />
        )
    }
  }

  if (!isAuthenticated || currentPath === "/login") {
    return (
      <Login
        onLogin={async (username, password) => {
          const phone = username.replace(/[^0-9]/g, "") || "9999999999";
          try {
            const res = await fetch("/api/v1/auth/login", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ phone, password })
            });
            if (res.ok) {
              const data = await res.json();
              if (data.data && data.data.token) {
                localStorage.setItem("drip_token", data.data.token);
                localStorage.setItem("drip_admin_auth", "true");
                setIsAuthenticated(true);
                navigate("/dashboard");
                return;
              }
            }
            alert("Invalid phone or password. Try 9999999999 / admin12345.");
          } catch (err) {
            console.error("Login error", err);
            alert("Connection error to API");
          }
        }}
      />
    )
  }

  return (
    <SaasLayout
      currentPath={currentPath}
      navigate={navigate}
      db={db}
      selectedFarmerId={selectedFarmerId}
      selectedFieldId={selectedFieldId}
      activeWorkspaceTab={activeWorkspaceTab}
      setActiveWorkspaceTab={setActiveWorkspaceTab}
      onLogout={() => {
        localStorage.removeItem("drip_admin_auth")
        localStorage.removeItem("drip_token")
        setIsAuthenticated(false)
        navigate("/login")
      }}
    >
      {renderView()}
    </SaasLayout>
  )
}

export default App