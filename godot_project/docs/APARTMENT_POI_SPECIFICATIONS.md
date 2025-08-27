# Interactive Apartment POI Specifications

## Room Layout with POIs

```
████████████████████████████
█..........█.......█.......█  Living Room | Kitchen | Pantry
█....@.....█..■....█..π....█  
█..........█..╥....█.......█  @ = Player start
█..........+.......+.......█  ■ = Fridge POI
█████████████████████+██████  π = Cupboard POI  
█.........█.................█  ╥ = Chair (decoration)
█..Θ......█.................█  + = Doors
█..π......+...╤.............█  
█.........█...Æ.............█  Bedroom | Study
█.........█.................█  Θ = Bed POI, π = Closet POI
█████████████████████████████  ╤ = Desk POI, Æ = Drawer POI
```

## Point of Interest Definitions

### 1. Desk (Study Room)
- **Character**: ╤ (209) - Table
- **Name**: "Detective's Desk"
- **Description**: "A cluttered oak desk covered in case files and coffee stains. The surface is littered with old reports, empty coffee cups, and a few personal mementos from solved cases."
- **Actions**: ["Search surface", "Check computer", "Review files", "Open drawer"]

### 2. Desk Drawer (Study Room) ⭐ **MAIN LOOT SOURCE**
- **Character**: Æ (146) - Chest 
- **Name**: "Desk Drawer"
- **Description**: "The bottom drawer of your desk, slightly ajar. Inside you can see the glint of metal and some personal items you keep close at hand."
- **Actions**: ["Take service pistol", "Take whiskey bottle", "Take leather jacket", "Close drawer"]

#### 🔫 **Service Pistol** (First Equipment)
- **Full Name**: "Old Model 10 Service Pistol (.38 Special)"
- **Description**: "Your trusty old Model 10 revolver in .38 Special. The blued steel shows wear from years of service, but it's been meticulously maintained. Six shots, double-action, and reliable as the day you graduated from the academy. The wooden grips are worn smooth from your hands."
- **Type**: Weapon (equippable)
- **Stats**: `{"damage": 10, "accuracy": 95, "ammo": 6, "range": "medium"}`
- **Action Text**: "You holster the familiar weight of your service weapon."

#### 🥃 **Whiskey Bottle** (Healing Item)
- **Full Name**: "Mostly Empty Bottle of Bourbon"  
- **Description**: "A half-empty bottle of cheap bourbon whiskey. The amber liquid sloshes around the bottom - just enough left for a few good swigs. Might help steady your nerves and clear that pounding hangover from last night's bender."
- **Type**: Consumable (3 uses)
- **Effects**: `{"heal": 10, "remove_status": "hungover", "add_status": "steady_nerves"}`
- **Action Text**: "The bourbon burns, but you feel more human already."

#### 🧥 **Leather Jacket** (Defense Equipment)
- **Full Name**: "Brown Leather Jacket"
- **Description**: "Your old brown leather jacket, worn soft from years of wear. The leather is scuffed and stained but still sturdy - it's saved you from more than a few scrapes over the years. Has that lived-in smell of cigarettes, coffee, and the streets."
- **Type**: Armor (equippable)  
- **Stats**: `{"defense": 5, "durability": 80, "style": "detective"}`
- **Action Text**: "You slip on the familiar weight of your jacket. Ready for whatever the day brings."

### 3. Refrigerator (Kitchen)
- **Character**: ■ (219) - Solid block
- **Name**: "Kitchen Refrigerator"
- **Description**: "A humming white refrigerator that's seen better days. Mostly empty except for takeout containers, expired milk, and a six-pack of beer from last week."
- **Actions**: ["Open fridge", "Take beer", "Check leftovers"]

### 4. Closet (Bedroom)
- **Character**: π (227) - Cabinet
- **Name**: "Bedroom Closet"
- **Description**: "A narrow closet with a few hanging shirts and an old winter coat. Smells faintly of mothballs and forgotten laundry."
- **Actions**: ["Search clothes", "Check coat pockets", "Look for hidden items"]

### 5. Bed (Bedroom)
- **Character**: Θ (233) - Bed
- **Name**: "Unmade Bed"
- **Description**: "Your unmade bed with rumpled sheets and a pillow that still holds the shape of your head. You can still feel the weight of last night's poor decisions."
- **Actions**: ["Rest (restore energy)", "Search under bed", "Make bed"]

### 6. Bedside Table (Bedroom)
- **Character**: ╥ (210) - Chair/Table
- **Name**: "Bedside Table"
- **Description**: "A small wooden nightstand with a dim lamp and a digital alarm clock blinking 12:00. The drawer is slightly open, revealing shadows within."
- **Actions**: ["Open drawer", "Check clock", "Turn on lamp"]

### 7. Kitchen Cupboard (Kitchen)
- **Character**: π (227) - Cabinet
- **Name**: "Kitchen Cupboard"
- **Description**: "Upper kitchen cabinet with mismatched dishes, a few canned goods, and the remnants of better-stocked days."
- **Actions**: ["Search shelves", "Check supplies", "Look for coffee"]

### 8. Living Room Chair (Living Room)
- **Character**: ╥ (210) - Chair/Table
- **Name**: "Living Room Chair"
- **Description**: "A comfortable armchair with a few stains and a well-worn cushion. Perfect for sinking into with a good book or a drink."
- **Actions**: ["Sit down", "Search cushions", "Adjust position"]  

### 9. Apartment Door (Entryway)
- **Character**: ▓ (178) - Door
- **Name**: "Apartment Door"
- **Description**: "A sturdy wooden door with a brass doorknob. It looks like it could use a fresh coat of paint."
- **Actions**: ["Open door", "Knock", "Check peephole"] 


## Item Integration Notes

### Equipment System
- **Service Pistol**: Automatically equips when taken (player's main weapon)
- **Leather Jacket**: Equips as armor, provides defense bonus
- **Whiskey**: Consumable, limited uses, removes hangover status

### Status Effects
- **Hungover**: Starting condition, reduces accuracy/energy
- **Steady Nerves**: Temporary buff from whiskey (+accuracy)
- **Detective Style**: Bonus from wearing full detective outfit

### Progressive Discovery
1. **First Visit**: Player notices drawer is ajar, prompting investigation
2. **After Interaction**: Drawer becomes "empty" or shows remaining items
3. **Equipment Check**: Player can view equipped items in ActionPanel

## Implementation Priorities

### Phase 1: Core Items (Essential)
- Service Pistol (combat functionality)
- Whiskey Bottle (healing/status system) 
- Leather Jacket (defense system)

### Phase 2: Extended Interactions (Future)
- Additional consumables in fridge
- Hidden items in other POIs
- Equipment upgrade system

This gives the detective apartment a strong sense of character and provides immediate gameplay value with the essential starting equipment!
