# Robotarium

Programming game about little robots

## To Do List

- [x] Fix Robot Spawning
- [x] Move Lua Files to Config Directory
- [x] Global Tick Count
- [x] Add Proper Logging
- [x] Add Robot Names Above Their Head
- [x] Add Home Names Above Their Head
- [x] Add a standard for what is on a tile
- [x] Inventory System
- [x] Add Chunking
- [x] Add Button To Center On Home
- [x] Save world to file
- [x] Read world from file
- [ ] Get Better Serialization
- [ ] Serialize All Entities Aswell

- [ ] Add Coords at top of screen
- [ ] Add rendering optimisations to all entities
- [ ] Fix bug that robots see themselves if they are larger than 1x1
- [ ] Add stacks of items to the game
- [ ] Add more generated buildings
- [ ] Proper Gui
- [ ] Add animations to robots
- [ ] Save world generations
- [ ] Only render part of the map player is looking at
- [ ] Expand Robot Lua API ( See Below )
- [ ] Add one robot lua api creation method
- [ ] Look Into Servers
- [ ] Refactor if going Multiplayer route
- [ ] Possibly Add A Robot Move Stack System ( Only can move one tile per tick )
- [ ] Add actual textures for things
- [ ] Add Different Robot Types
- [ ] Robots have amounts of energy
- [ ] Crafting Recipes
- [ ] Interfaces To Things
- [ ] Method to bind a robot to a script

### Lua Robot API Goals

- [x] move(dir), Moves 1 tile in any direction
- [x] canMove(dir), Returns true if robot can move in the direction
- [x] moveCooldown(), Returns true if robot can actually move this tick
- [ ] scan(), Scans Tile Underneath Robot
- [ ] scan(dir), Scans Tile in direction of robot
- [x] inventory(), Returns table of personal inventory of robot
- [ ] invSize(), Returns Size of inventory
- [ ] deposit(item, dir), Deposits item in dir
- [ ] harvest(), If on top of harvestable tile
- [ ] canHarvest(), Returns true if tile is harvestable
- [ ] mine(), If on top of harvestable tile
- [x] canMine(), Returns true if tile is harvestable
- [ ] drop(item), drop item
- [ ] pickup(), pickup item on tile
- [ ] attack(dir), attack in dir
- [ ] broadcast(channel, msg), Broadcast arbitraty data on channel
- [ ] listen(channel), Receive messages on channel
- [ ] getMessages(channel), Get all messages in channel or something

- Maybe some sort of memory / storage

## Gameplay

- Robots can move within their homes' range
- Robots can mine / harvest resources
- Can use those resources to build waypoints and expand range

- Remove Entity Type union enum
