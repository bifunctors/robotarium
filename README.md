# Scan

Programming game about little robots

## To Do List

- [x] Fix Robot Spawning
- [x] Move Lua Files to Config Directory
- [x] Global Tick Count
- [x] Add Proper Logging
- [x] Add Robot Names Above Their Head
- [x] Add Home Names Above Their Head
- [x] Add a standard for what is on a tile
- [ ] Add stacks of items to the game
- [ ] Inventory System
- [ ] Add animations to robots
- [ ] Add more generated buildings
- [ ] Save world generations
- [ ] Only render part of the map player is looking at
- [ ] Expand Robot Lua API ( See Below )
- [ ] Look Into Servers
- [ ] Refactor if going Multiplayer route
- [ ] Possibly Add A Robot Move Stack System ( Only can move one tile per tick )
- [ ] Add actual textures for things
- [ ] Different Robot Types
- [ ] Robots have amounts of energy

### Lua Robot API Goals

- [x] move(dir), Moves 1 tile in any direction
- [x] canMove(dir), Returns true if robot can move in the direction
- [x] moveCooldown(), Returns true if robot can actually move this tick
- [ ] scan(), Scans Tile Underneath Robot
- [ ] scan(dir), Scans Tile in direction of robot
- [ ] inventory(), Returns table of personal inventory of robot
- [ ] invSize(), Returns Size of inventory
- [ ] deposit(item, dir), Deposits item in dir
- [ ] harvest(), If on top of harvestable tile
- [ ] canHarvest(), Returns true if tile is harvestable
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
