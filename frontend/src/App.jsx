import React, { useState, useEffect } from "react"
import SaasLayout from "@/components/SaasLayout"
import Dashboard from "@/views/Dashboard"
import Fields from "@/views/Fields"
import Zones from "@/views/Zones"
import Schedules from "@/views/Schedules"
import Sensors from "@/views/Sensors"
import SystemConfig from "@/views/SystemConfig"
import AlertLimits from "@/views/AlertLimits"
import Notifications from "@/views/Notifications"
import Diagnostics from "@/views/Diagnostics"
import Login from "@/views/Login"
import Users from "@/views/Users"
import Inventory from "@/views/Inventory"
import ActivityLogs from "@/views/ActivityLogs"
import Customers from "@/views/Customers"

function App() {
  const [currentPath, setCurrentPath] = useState(window.location.pathname)
  const [preselectedZone, setPreselectedZone] = useState("")
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    return localStorage.getItem("drip_admin_auth") === "true"
  })

  useEffect(() => {
    const handleLocationChange = () => {
      setCurrentPath(window.location.pathname)
    }

    // Redirect root "/" to "/dashboard" for clean routing entry point
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
      case "/fields":
        return <Fields navigate={navigate} />
      case "/zones":
        return <Zones navigate={navigate} setPreselectedZone={setPreselectedZone} />
      case "/schedules":
        return <Schedules preselectedZone={preselectedZone} setPreselectedZone={setPreselectedZone} />
      case "/sensors":
        return <Sensors />
      case "/settings/config":
        return <SystemConfig />
      case "/settings/alerts":
        return <AlertLimits />
      case "/settings/notifications":
        return <Notifications />
      case "/users":
        return <Users />
      case "/customers":
        return <Customers />
      case "/inventory":
        return <Inventory />
      case "/diagnostics":
        return <Diagnostics />
      case "/activity-logs":
        return <ActivityLogs />
      case "/dashboard":
      default:
        return <Dashboard />
    }
  }

  if (!isAuthenticated || currentPath === "/login") {
    return (
      <Login
        onLogin={() => {
          localStorage.setItem("drip_admin_auth", "true")
          setIsAuthenticated(true)
          navigate("/dashboard")
        }}
      />
    )
  }

  return (
    <SaasLayout
      currentPath={currentPath}
      navigate={navigate}
      onLogout={() => {
        localStorage.removeItem("drip_admin_auth")
        setIsAuthenticated(false)
        navigate("/login")
      }}
    >
      {renderView()}
    </SaasLayout>
  )
}

export default App