# PackFast – Project Overview

Quick map of the app so you’re not lost.

## How the app runs

1. **Entry point:** `packfast/packfastApp.swift`  
   - Creates the SwiftData container and shows **TripListView** as the root.

2. **Home:** `packfast/Views/TripListView.swift`  
   - List of all trips, progress (X/Y packed), create / duplicate / delete trips.  
   - Tap a trip → **TripDetailView**.

3. **Packing screen:** `packfast/Views/TripDetailView.swift`  
   - Toggle **By Location** (default) or **By Category**.  
   - Tap row = toggle packed (with haptic). Tap again = edit. Swipe = delete.  
   - “+” opens **AddEditItemView**.

4. **Add/Edit item:** `packfast/Views/AddEditItemView.swift`  
   - Name, Category picker, Location picker.  
   - “Add new category…” / “Add new location…” save to SwiftData and appear in future pickers.

## Data (SwiftData)

| File | What it is |
|------|------------|
| `packfast/Models/Trip.swift` | Trip: name, date, list of items. |
| `packfast/Models/Item.swift` | Item: name, category, location, isPacked. |
| `packfast/Models/PackingCategory.swift` | Global list of category names (Clothes, Tech, etc.). |
| `packfast/Models/PackingLocation.swift` | Global list of location/room names (Bedroom, Bathroom, etc.). |
| `packfast/Services/DataSeeder.swift` | Seeds default categories and locations on first launch. |

## Summary

- **No ContentView** – the app starts at TripListView.  
- **All of the “Methodical Packing” changes are kept** – SwiftData models, home list, trip detail (by location/category), add/edit item with custom category/location, duplicate trip, swipe delete, haptics.

To run: open `packfast.xcodeproj` in Xcode and run on simulator or device.
