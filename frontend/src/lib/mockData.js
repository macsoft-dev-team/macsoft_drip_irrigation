export const initialFields = [
  {
    id: 1,
    name: "North Orchard",
    location: "Sector A-1",
    area: "12.5 acres",
    soilType: "Sandy Loam",
    motorStatus: "Off",
    zones: [
      {
        id: 101,
        name: "Apple Trees",
        location: "Row 1-10",
        moisture: 45.2,
        valves: [
          { id: 201, name: "Orchard Main Valve", type: "Solenoid", status: "Closed", flowRate: 0, capacity: 15.0 },
          { id: 202, name: "Orchard Secondary Valve", type: "Drip", status: "Closed", flowRate: 0, capacity: 8.5 }
        ]
      },
      {
        id: 102,
        name: "Vineyard Rows",
        location: "Row 11-25",
        moisture: 38.4,
        valves: [
          { id: 203, name: "Vineyard Main Drip", type: "Drip", status: "Closed", flowRate: 0, capacity: 12.0 }
        ]
      }
    ]
  },
  {
    id: 2,
    name: "South Pasture",
    location: "Sector B-3",
    area: "15.0 acres",
    soilType: "Clay Loam",
    motorStatus: "Off",
    zones: [
      {
        id: 103,
        name: "Vegetable Beds",
        location: "Sector C-2",
        moisture: 48.0,
        valves: [
          { id: 204, name: "Veggie Spray Valve", type: "Sprinkler", status: "Closed", flowRate: 0, capacity: 18.0 }
        ]
      }
    ]
  },
  {
    id: 3,
    name: "Greenhouse Herbs",
    location: "Greenhouse-1",
    area: "2.0 acres",
    soilType: "Peat Mix",
    motorStatus: "Off",
    zones: [
      {
        id: 104,
        name: "Misting Zone",
        location: "Greenhouse-1",
        moisture: 21.5,
        valves: [
          { id: 205, name: "Micro Mist Valve", type: "Mister", status: "Closed", flowRate: 0, capacity: 5.0 }
        ]
      }
    ]
  }
]

export const initialUsers = [
  {
    id: 1,
    name: "Admin User",
    email: "admin@macsoft.com",
    role: "Admin",
    status: "Active",
    mobile: "+1 555-0101",
  },
  {
    id: 2,
    name: "Field Engineer",
    email: "engineer@macsoft.com",
    role: "Field_Engineer",
    status: "Active",
    mobile: "+1 555-0102",
  },
  {
    id: 3,
    name: "Farmer John",
    email: "john@macsoft.com",
    role: "Farmer",
    status: "Active",
    mobile: "+1 555-0103",
    fieldId: 1,
  },
  {
    id: 4,
    name: "Inactive User",
    email: "inactive@macsoft.com",
    role: "Farmer",
    status: "Inactive",
    mobile: "+1 555-0104",
    fieldId: 2,
  },
  {
    id: 5,
    name: "Farmer Sarah",
    email: "sarah@macsoft.com",
    role: "Farmer",
    status: "Active",
    mobile: "+1 555-0105",
    fieldId: 2,
  },
  {
    id: 6,
    name: "Farmer Michael",
    email: "michael@macsoft.com",
    role: "Farmer",
    status: "Active",
    mobile: "+1 555-0106",
    fieldId: 3,
  }
]
