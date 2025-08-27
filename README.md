# Scan

Programming game about little robots

- [ ] Possibly use SpacetimeDB

## Lua overview

- 'main.lua'
- Robots can send signals?
- Use global table of robots in lua?

- Home Base, Coordinates are relative to it?

- Only move set radius away from base / waypoint?

- Have Robots Spawn in radius around home

- Notification System, Robots can notify
- Custom Colours for notifications

## To Do List

- [ ] Fix Robot Spawning
- [ ] Add Robot Names Above Their Head
- [ ] Expand Robot Lua API ( See Below )
- [ ] Look Into Servers
- [ ] Refactor if going Multiplayer route
- [ ] Possibly Add A Robot Move Stack System ( Only can move one tile per tick )

### Lua Robot API Goals

- move(dir), Moves 1 tile in any direction
- canMove(dir), Returns true if robot can move in the direction
- scan(), Scans Tile Underneath Robot
- scan(dir), Scans Tile in direction of robot
- inventory(), Returns table of personal inventory of robot
- deposit(item, dir), Deposits item in dir
- harvest(), If on top of harvestable tile
- canHarvest(), Returns true if tile is harvestable
- drop(item), drop item
- pickup(), pickup item on tile
- attack(dir), attack in dir
- broadcast(channel, msg), Broadcast arbitraty data on channel
- listen(channel), Receive messages on channel
- getMessages(channel), Get all messages in channel or something
- Maybe some sort of memory / storage
