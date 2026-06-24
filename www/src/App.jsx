import React, { useState, useEffect } from "react"
import SaasLayout from "@/components/SaasLayout"
import Dashboard from "@/views/Dashboard"
import Zones from "@/views/Zones"
import Schedules from "@/views/Schedules"
import Sensors from "@/views/Sensors"
import SystemConfig from "@/views/SystemConfig"
import AlertLimits from "@/views/AlertLimits"
import Notifications from "@/views/Notifications"
import Diagnostics from "@/views/Diagnostics"

function App() {
  const [currentPath, setCurrentPath] = useState(window.location.pathname)

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

  const navigate = (to) => {
    window.history.pushState({}, "", to)
    setCurrentPath(to)
  }

  // Routing switch logic
  const renderView = () => {
    switch (currentPath) {
      case "/zones":
        return <Zones />
      case "/schedules":
        return <Schedules />
      case "/sensors":
        return <Sensors />
      case "/settings/config":
        return <SystemConfig />
      case "/settings/alerts":
        return <AlertLimits />
      case "/settings/notifications":
        return <Notifications />
      case "/diagnostics":
        return <Diagnostics />
      case "/dashboard":
      default:
        return <Dashboard />
    }
  }

  return (
    <SaasLayout currentPath={currentPath} navigate={navigate}>
      {renderView()}
    </SaasLayout>
  )
}

export default App