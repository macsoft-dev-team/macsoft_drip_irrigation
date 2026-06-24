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
  ChevronDown
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
  SidebarMenuSub,
  SidebarMenuSubItem,
  SidebarFooter,
  SidebarRail,
  SidebarInset,
  SidebarTrigger,
} from "@/components/ui/sidebar"
import { TooltipProvider } from "@/components/ui/tooltip"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"

// --- Dummy Data for the Drip Irrigation Admin Panel ---
const navMain = [
  { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard },
  { title: "Zones & Valves", url: "/zones", icon: Droplet },
  { title: "Schedules", url: "/schedules", icon: Calendar },
  { title: "Sensors", url: "/sensors", icon: Activity, badge: "Live" },
]

const navSettings = [
  {
    title: "Settings",
    url: "/settings",
    icon: Settings,
    items: [
      { title: "System Config", url: "/settings/config", icon: Cpu },
      { title: "Alert Limits", url: "/settings/alerts", icon: Sprout },
      { title: "Notifications", url: "/settings/notifications", icon: Bell },
    ],
  },
]

export default function SaasLayout({ children, currentPath = "/dashboard", navigate }) {
  const handleNavClick = (e, url) => {
    e.preventDefault()
    if (navigate) {
      navigate(url)
    }
  }

  // Get current active view title for page header
  const getHeaderTitle = () => {
    if (currentPath === "/zones") return "Zones & Valves"
    if (currentPath === "/schedules") return "Watering Schedules"
    if (currentPath === "/sensors") return "Sensor Telemetry"
    if (currentPath === "/settings/config") return "System Configuration"
    if (currentPath === "/settings/alerts") return "Alert Thresholds"
    if (currentPath === "/settings/notifications") return "Notification Preferences"
    if (currentPath === "/diagnostics") return "System Diagnostics"
    return "Dashboard Overview"
  }

  return (
    <TooltipProvider>
      <SidebarProvider>
        {/* 1. The Sidebar Itself */}
        <Sidebar>
          
          {/* Header: App Logo / Name */}
          <SidebarHeader className="p-4">
            <div className="flex items-center gap-2 font-bold text-lg">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-500 text-white">
                <Droplet className="h-5 w-5 fill-current" />
              </div>
              <span>DripAdmin</span>
            </div>
          </SidebarHeader>

          {/* Content: Main Navigation */}
          <SidebarContent>
            
            {/* First Group: Main Menu */}
            <SidebarGroup>
              <SidebarGroupLabel>Management</SidebarGroupLabel>
              {/* Quick Action Button on the Group Label */}
              <SidebarGroupAction title="Add Zone" onClick={(e) => handleNavClick(e, "/zones")}>
                <Plus className="h-4 w-4" />
                <span className="sr-only">Add Zone</span>
              </SidebarGroupAction>
              
              <SidebarGroupContent>
                <SidebarMenu>
                  {navMain.map((item) => {
                    const isActive = currentPath === item.url
                    return (
                      <SidebarMenuItem key={item.title}>
                        <SidebarMenuButton asChild isActive={isActive}>
                          <a href={item.url} onClick={(e) => handleNavClick(e, item.url)}>
                            <item.icon className="h-4 w-4" />
                            <span>{item.title}</span>
                          </a>
                        </SidebarMenuButton>
                        {/* Badge Example */}
                        {item.badge && (
                          <SidebarMenuBadge>{item.badge}</SidebarMenuBadge>
                        )}
                      </SidebarMenuItem>
                    )
                  })}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>

            {/* Second Group: Settings with Collapsible Sub-menu */}
            <SidebarGroup>
              <SidebarGroupLabel>Configuration</SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu>
                  {navSettings.map((item) => {
                    const isAnySubActive = item.items?.some(sub => sub.url === currentPath)
                    return (
                      <Collapsible
                        key={item.title}
                        defaultOpen={isAnySubActive || currentPath.startsWith("/settings")}
                        className="group/collapsible"
                      >
                        <SidebarMenuItem>
                          <CollapsibleTrigger asChild>
                            <SidebarMenuButton isActive={isAnySubActive}>
                              {item.icon && <item.icon className="h-4 w-4" />}
                              <span>{item.title}</span>
                              <ChevronDown className="ml-auto h-4 w-4 transition-transform duration-200 group-data-[state=open]/collapsible:rotate-180" />
                            </SidebarMenuButton>
                          </CollapsibleTrigger>
                          
                          {item.items?.length ? (
                            <CollapsibleContent>
                              <SidebarMenuSub>
                                {item.items.map((subItem) => {
                                  const isSubActive = currentPath === subItem.url
                                  return (
                                    <SidebarMenuSubItem key={subItem.title}>
                                      <SidebarMenuButton asChild isActive={isSubActive}>
                                        <a href={subItem.url} onClick={(e) => handleNavClick(e, subItem.url)}>
                                          <subItem.icon className="h-4 w-4 mr-2 text-muted-foreground" />
                                          <span>{subItem.title}</span>
                                        </a>
                                      </SidebarMenuButton>
                                    </SidebarMenuSubItem>
                                  )
                                })}
                              </SidebarMenuSub>
                            </CollapsibleContent>
                          ) : null}
                        </SidebarMenuItem>
                      </Collapsible>
                    )
                  })}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>

            {/* Third Group: Diagnostics */}
            <SidebarGroup>
              <SidebarGroupContent>
                <SidebarMenu>
                  <SidebarMenuItem>
                    <SidebarMenuButton asChild isActive={currentPath === "/diagnostics"}>
                      <a href="/diagnostics" onClick={(e) => handleNavClick(e, "/diagnostics")}>
                        <Wrench className="h-4 w-4" />
                        <span>Diagnostics</span>
                      </a>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>

          </SidebarContent>

          {/* Footer: User Profile / Logout */}
          <SidebarFooter className="p-4 border-t border-sidebar-border">
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton className="w-full justify-start text-red-500 hover:text-red-600 hover:bg-red-50">
                  <LogOut className="h-4 w-4" />
                  <span>Log out</span>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarFooter>

          {/* Rail: Enables hover-to-expand behavior when collapsed */}
          <SidebarRail />
        </Sidebar>

        {/* 2. The Main Content Area */}
        <SidebarInset>
          <header className="flex h-16 shrink-0 items-center gap-2 border-b px-4 lg:px-6 bg-background">
            {/* Hamburger Menu Trigger for Mobile / Collapse toggle for Desktop */}
            <SidebarTrigger className="-ml-2" />
            <div className="w-px h-4 bg-border mx-2" /> {/* Divider */}
            <h1 className="font-semibold text-sm">{getHeaderTitle()}</h1>
          </header>
          
          <main className="flex flex-1 flex-col gap-4 p-4 lg:p-6 bg-muted/20">
            {/* Main Page Content goes here */}
            {children}
          </main>
        </SidebarInset>
      </SidebarProvider>
    </TooltipProvider>
  )
}
