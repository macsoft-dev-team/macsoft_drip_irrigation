import React, { useState, useEffect } from "react"
import { Clock, Plus, Trash2, Calendar, Droplets } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function Schedules({ preselectedZone, setPreselectedZone }) {
  const [schedules, setSchedules] = useState([
    { id: 1, name: "Morning Soak", zone: "Front Lawn", time: "06:00 AM", duration: 25, days: ["Mon", "Wed", "Fri"], active: true },
    { id: 2, name: "Orchard Mist", zone: "Orchard & Vines", time: "08:30 AM", duration: 15, days: ["Tue", "Thu", "Sat"], active: true },
    { id: 3, name: "Veggie Hydration", zone: "Vegetable Beds", time: "05:30 PM", duration: 20, days: ["Daily"], active: true },
    { id: 4, name: "Greenhouse Cool", zone: "Greenhouse Herbs", time: "01:00 PM", duration: 10, days: ["Daily"], active: false }
  ])

  // Form states
  const [name, setName] = useState("")
  const [zone, setZone] = useState("Front Lawn")
  const [time, setTime] = useState("08:00 AM")
  const [duration, setDuration] = useState(15)
  const [days, setDays] = useState("Daily")

  // Load preselected zone if passed from the zones card click
  useEffect(() => {
    if (preselectedZone) {
      setZone(preselectedZone)
      // Reset after loading so direct visits to the page are fresh
      if (setPreselectedZone) {
        setPreselectedZone("")
      }
    }
  }, [preselectedZone, setPreselectedZone])

  const addSchedule = (e) => {
    e.preventDefault()
    if (!name.trim()) return

    const newSched = {
      id: Date.now(),
      name,
      zone,
      time,
      duration: parseInt(duration) || 10,
      days: days === "Daily" ? ["Daily"] : days.split(",").map(d => d.trim()),
      active: true
    }

    setSchedules([...schedules, newSched])
    setName("")
  }

  const deleteSchedule = (id) => {
    setSchedules(schedules.filter(s => s.id !== id))
  }

  const toggleSchedule = (id) => {
    setSchedules(schedules.map(s => s.id === id ? { ...s, active: !s.active } : s))
  }

  return (
    <div className="grid gap-6 md:grid-cols-3">
      {/* Schedule List */}
      <div className="md:col-span-2 flex flex-col gap-4">
        <div>
          <h2 className="text-sm font-semibold tracking-tight">Active Automation Schedules</h2>
          <p className="text-[11px] text-muted-foreground">Watering rules deployed to the irrigation controller</p>
        </div>

        <div className="flex flex-col gap-3">
          {schedules.map((s) => (
            <Card key={s.id} className={`shadow-xs border border-border relative overflow-hidden transition-all duration-200 ${
              !s.active ? "opacity-60 bg-muted/20" : ""
            }`}>
              <CardContent className="p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`p-2.5 rounded-lg ${s.active ? "bg-blue-50 dark:bg-blue-950/20 text-blue-500" : "bg-muted text-muted-foreground"}`}>
                    <Clock className="h-4 w-4" />
                  </div>
                  <div>
                    <h3 className="text-xs font-bold text-foreground">{s.name}</h3>
                    <div className="text-[10px] text-muted-foreground mt-0.5 flex flex-wrap gap-x-2 gap-y-0.5">
                      <span>Zone: {s.zone}</span>
                      <span>•</span>
                      <span>Time: {s.time}</span>
                      <span>•</span>
                      <span>Duration: {s.duration} min</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  {/* Days pill */}
                  <span className="text-[9px] font-semibold bg-muted text-muted-foreground px-2 py-0.5 rounded-full uppercase tracking-wider font-mono">
                    {s.days.join(", ")}
                  </span>
                  
                  {/* Toggle Switch */}
                  <button 
                    type="button"
                    onClick={() => toggleSchedule(s.id)}
                    className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out outline-hidden ${
                      s.active ? "bg-blue-500" : "bg-border"
                    }`}
                  >
                    <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out ${
                      s.active ? "translate-x-4" : "translate-x-0"
                    }`} />
                  </button>

                  {/* Delete Button */}
                  <button 
                    type="button"
                    onClick={() => deleteSchedule(s.id)}
                    className="p-1.5 text-muted-foreground hover:text-red-500 rounded-md transition-colors"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Add Schedule Form */}
      <div>
        <Card className="shadow-xs border border-border">
          <CardHeader>
            <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
              <Calendar className="h-4 w-4 text-blue-500" />
              <span>Create Schedule</span>
            </CardTitle>
            <CardDescription className="text-[10px]">Add irrigation sequence rule</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={addSchedule} className="flex flex-col gap-3.5 text-xs">
              <div className="flex flex-col gap-1">
                <label className="font-semibold text-muted-foreground">Rule Name</label>
                <input 
                  type="text" 
                  placeholder="e.g. Mid-day Mist" 
                  value={name} 
                  onChange={(e) => setName(e.target.value)}
                  className="p-2 border border-border rounded-md bg-transparent text-foreground outline-hidden focus:border-blue-500"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="font-semibold text-muted-foreground">Target Zone</label>
                <select 
                  value={zone} 
                  onChange={(e) => setZone(e.target.value)}
                  className="p-2 border border-border rounded-md bg-transparent dark:bg-card text-foreground outline-hidden focus:border-blue-500"
                >
                  <option value="Front Lawn">Front Lawn</option>
                  <option value="Orchard & Vines">Orchard & Vines</option>
                  <option value="Vegetable Beds">Vegetable Beds</option>
                  <option value="Greenhouse Herbs">Greenhouse Herbs</option>
                </select>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div className="flex flex-col gap-1">
                  <label className="font-semibold text-muted-foreground">Start Time</label>
                  <input 
                    type="text" 
                    placeholder="e.g. 08:00 AM" 
                    value={time} 
                    onChange={(e) => setTime(e.target.value)}
                    className="p-2 border border-border rounded-md bg-transparent text-foreground outline-hidden focus:border-blue-500"
                  />
                </div>
                <div className="flex flex-col gap-1">
                  <label className="font-semibold text-muted-foreground">Duration (mins)</label>
                  <input 
                    type="number" 
                    value={duration} 
                    onChange={(e) => setDuration(e.target.value)}
                    className="p-2 border border-border rounded-md bg-transparent text-foreground outline-hidden focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="flex flex-col gap-1">
                <label className="font-semibold text-muted-foreground">Watering Days</label>
                <input 
                  type="text" 
                  placeholder="Daily, or Mon, Wed, Fri" 
                  value={days} 
                  onChange={(e) => setDays(e.target.value)}
                  className="p-2 border border-border rounded-md bg-transparent text-foreground outline-hidden focus:border-blue-500"
                />
              </div>

              <button 
                type="submit" 
                className="w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 rounded-md transition-all flex items-center justify-center gap-1 mt-2 shadow-xs"
              >
                <Plus className="h-4 w-4" />
                <span>Save Schedule</span>
              </button>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
