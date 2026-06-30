import React from "react"
import { 
  LayoutDashboard, 
  Droplet,
  Sprout,
  Calendar,
  Activity,
  Cpu,
  Bell,
  Settings,
  Wrench,
  Plus,
  LogOut,
  ChevronDown,
  Users,
  Package,
  History,
  ArrowLeft,
  Settings2,
  AlertTriangle,
  Play,
  Heart
} from "lucide-react"

import {
  SidebarProvider,
  Sidebar,
  SidebarHeader,
  SidebarContent,
  SidebarGroup,
  SidebarGroupLabel,
  SidebarGroupAction,
  SidebarGroupContent,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
  SidebarMenuBadge,
  SidebarFooter,
  SidebarRail,
  SidebarInset,
  SidebarTrigger,
} from "@/components/ui/sidebar"
import { TooltipProvider } from "@/components/ui/tooltip"

export default function SaasLayout({ 
  children, 
  currentPath = "/dashboard", 
  navigate, 
  onLogout,
  db,
  selectedFarmerId,
  selectedFieldId,
  activeWorkspaceTab = "overview",
  setActiveWorkspaceTab
}) {
  
  const handleNavClick = (e, url) => {
    e.preventDefault()
    if (navigate) {
      navigate(url)
    }
  }

  // Find selected field and farmer for workspace labeling
  const selectedFarmer = db?.farmers?.find(f => f.id === selectedFarmerId)
  const selectedField = db?.fields?.find(f => f.id === selectedFieldId)

  // Is the Field Workspace sidebar active?
  const isWorkspaceMode = currentPath === "/field-workspace" && selectedField

  // Get active view header title
  const getHeaderTitle = () => {
    if (isWorkspaceMode) {
      return `${selectedField.name} Workspace — ${activeWorkspaceTab.toUpperCase()}`
    }
    if (currentPath === "/farmers") return "Farmers & Customers"
    if (currentPath === "/users") return "User Administration"
    if (currentPath === "/support") return "Support Center Tickets"
    if (currentPath === "/settings") return "System Settings & Configuration"
    return "Dashboard Overview"
  }

  // Workspace sub-navigation items
  const workspaceItems = [
    { key: "overview", title: "Overview", icon: Sprout },
    { key: "devices", title: "Devices", icon: Cpu },
    { key: "zones", title: "Zones", icon: LayersIcon }, // Custom mapping or fallback
    { key: "irrigation", title: "Irrigation", icon: Droplet },
    { key: "schedules", title: "Schedules", icon: Calendar },
    { key: "monitoring", title: "Monitoring", icon: Activity },
    { key: "settings", title: "Settings", icon: Settings2 }
  ]

  // Fallback for LayersIcon
  function LayersIcon(props) {
    return (
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        {...props}
      >
        <path d="m12 3-10 5 10 5 10-5-10-5Z" />
        <path d="m2 17 10 5 10-5" />
        <path d="m2 12 10 5 10-5" />
      </svg>
    )
  }

  return (
    <TooltipProvider>
      <SidebarProvider>
        {/* The Sidebar */}
        <Sidebar>
          
          {/* Header: Dynamic brand or Workspace context */}
          <SidebarHeader className="p-4 border-b border-sidebar-border bg-emerald-500/5 dark:bg-emerald-950/5">
            {isWorkspaceMode ? (
              <div className="flex flex-col gap-2">
                <button
                  onClick={() => navigate("/farmers")}
                  className="flex items-center gap-1 text-[10px] font-bold text-emerald-600 dark:text-emerald-400 hover:underline text-left cursor-pointer"
                >
                  <ArrowLeft className="h-3 w-3" />
                  <span>Exit Workspace</span>
                </button>
                <div className="flex flex-col">
                  <span className="font-extrabold text-sm text-foreground truncate">{selectedField.name}</span>
                  <span className="text-[10px] text-muted-foreground font-semibold truncate">{selectedFarmer?.name || "Farmer"}</span>
                </div>
              </div>
            ) : (
              <div className="flex items-center gap-2 font-bold text-lg text-emerald-600 dark:text-emerald-400">
                <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-tr from-emerald-500 to-teal-400 text-white shadow-md shadow-emerald-500/20">
                  <Droplet className="h-5 w-5 fill-current" />
                </div>
                <span className="tracking-wide">DripAdmin</span>
              </div>
            )}
          </SidebarHeader>

          {/* Content: Main Navigation vs Workspace Sub Navigation */}
          <SidebarContent>
            {isWorkspaceMode ? (
              // Field Workspace Sidebar Navigation
              <SidebarGroup>
                <SidebarGroupLabel>Field Workspace</SidebarGroupLabel>
                <SidebarGroupContent>
                  <SidebarMenu>
                    {workspaceItems.map((item) => {
                      const isActive = activeWorkspaceTab === item.key
                      return (
                        <SidebarMenuItem key={item.key}>
                          <SidebarMenuButton
                            isActive={isActive}
                            onClick={() => setActiveWorkspaceTab(item.key)}
                            className={`transition-all duration-200 cursor-pointer ${
                              isActive 
                                ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400 border-l-2 border-emerald-500 font-bold" 
                                : "hover:bg-emerald-50/50 dark:hover:bg-emerald-950/10 hover:text-emerald-600 dark:hover:text-emerald-400 text-muted-foreground"
                            }`}
                          >
                            <item.icon className={`h-4 w-4 ${isActive ? "text-emerald-600 dark:text-emerald-400" : "text-muted-foreground"}`} />
                            <span>{item.title}</span>
                          </SidebarMenuButton>
                        </SidebarMenuItem>
                      )
                    })}
                  </SidebarMenu>
                </SidebarGroupContent>
              </SidebarGroup>
            ) : (
              // Main Sidebar Navigation
              <>
                <SidebarGroup>
                  <SidebarGroupLabel>Management</SidebarGroupLabel>
                  <SidebarGroupContent>
                    <SidebarMenu>
                      {/* Dashboard Link */}
                      <SidebarMenuItem>
                        <SidebarMenuButton 
                          isActive={currentPath === "/dashboard"}
                          className={`transition-all duration-200 ${
                            currentPath === "/dashboard" 
                              ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400 border-l-2 border-emerald-500 font-bold" 
                              : "hover:bg-emerald-50/50 dark:hover:bg-emerald-950/10 hover:text-emerald-600 dark:hover:text-emerald-400 text-muted-foreground"
                          }`}
                        >
                          <a href="/dashboard" onClick={(e) => handleNavClick(e, "/dashboard")} className="flex items-center gap-2">
                            <LayoutDashboard className="h-4 w-4" />
                            <span>Dashboard</span>
                          </a>
                        </SidebarMenuButton>
                      </SidebarMenuItem>

                      {/* Users Link */}
                      <SidebarMenuItem>
                        <SidebarMenuButton 
                          isActive={currentPath === "/users"}
                          className={`transition-all duration-200 ${
                            currentPath === "/users" 
                              ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400 border-l-2 border-emerald-500 font-bold" 
                              : "hover:bg-emerald-50/50 dark:hover:bg-emerald-950/10 hover:text-emerald-600 dark:hover:text-emerald-400 text-muted-foreground"
                          }`}
                        >
                          <a href="/users" onClick={(e) => handleNavClick(e, "/users")} className="flex items-center gap-2">
                            <Users className="h-4 w-4" />
                            <span>Users</span>
                          </a>
                        </SidebarMenuButton>
                      </SidebarMenuItem>

                      {/* Farmers Link */}
                      <SidebarMenuItem>
                        <SidebarMenuButton 
                          isActive={currentPath === "/farmers"}
                          className={`transition-all duration-200 ${
                            currentPath === "/farmers" 
                              ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400 border-l-2 border-emerald-500 font-bold" 
                              : "hover:bg-emerald-50/50 dark:hover:bg-emerald-950/10 hover:text-emerald-600 dark:hover:text-emerald-400 text-muted-foreground"
                          }`}
                        >
                          <a href="/farmers" onClick={(e) => handleNavClick(e, "/farmers")} className="flex items-center gap-2">
                            <Sprout className="h-4 w-4" />
                            <span>Farmers</span>
                          </a>
                        </SidebarMenuButton>
                      </SidebarMenuItem>

                      {/* Support Link */}
                      <SidebarMenuItem>
                        <SidebarMenuButton 
                          isActive={currentPath === "/support"}
                          className={`transition-all duration-200 ${
                            currentPath === "/support" 
                              ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400 border-l-2 border-emerald-500 font-bold" 
                              : "hover:bg-emerald-50/50 dark:hover:bg-emerald-950/10 hover:text-emerald-600 dark:hover:text-emerald-400 text-muted-foreground"
                          }`}
                        >
                          <a href="/support" onClick={(e) => handleNavClick(e, "/support")} className="flex items-center gap-2">
                            <Wrench className="h-4 w-4" />
                            <span>Support</span>
                          </a>
                        </SidebarMenuButton>
                      </SidebarMenuItem>

                      {/* Settings Link */}
                      <SidebarMenuItem>
                        <SidebarMenuButton 
                          isActive={currentPath === "/settings"}
                          className={`transition-all duration-200 ${
                            currentPath === "/settings" 
                              ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400 border-l-2 border-emerald-500 font-bold" 
                              : "hover:bg-emerald-50/50 dark:hover:bg-emerald-950/10 hover:text-emerald-600 dark:hover:text-emerald-400 text-muted-foreground"
                          }`}
                        >
                          <a href="/settings" onClick={(e) => handleNavClick(e, "/settings")} className="flex items-center gap-2">
                            <Settings className="h-4 w-4" />
                            <span>Settings</span>
                          </a>
                        </SidebarMenuButton>
                      </SidebarMenuItem>
                    </SidebarMenu>
                  </SidebarGroupContent>
                </SidebarGroup>
              </>
            )}
          </SidebarContent>

          {/* Footer: Logout */}
          <SidebarFooter className="p-4 border-t border-sidebar-border bg-sidebar/50">
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton 
                  className="w-full justify-start text-red-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/20 cursor-pointer"
                  onClick={onLogout}
                >
                  <LogOut className="h-4 w-4" />
                  <span>Log out</span>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarFooter>

          <SidebarRail />
        </Sidebar>

        {/* Main Content Area */}
        <SidebarInset>
          <header className="flex h-16 shrink-0 items-center gap-2 border-b px-4 lg:px-6 bg-background">
            <SidebarTrigger className="-ml-2" />
            <div className="w-px h-4 bg-border mx-2" />
            <h1 className="font-bold text-sm tracking-tight">{getHeaderTitle()}</h1>
          </header>
          
          <main className="flex flex-1 flex-col gap-4 p-4 lg:p-6 bg-muted/20 overflow-y-auto">
            {children}
          </main>
        </SidebarInset>
      </SidebarProvider>
    </TooltipProvider>
  )
}

