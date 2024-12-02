model wumpus_world

global {
    // Define the size of the grid
    int gridWidth <- 5;
    int gridHeight <- 5;
    
    // Initialize the environment
    init {
        // Create the Wumpus (random position)
        create Wumpus number: 1 {
            location <- one_of(Cell).location;
        }
        
        // Create pits (20% chance per cell, excluding Wumpus location)
        create Pit number: int(gridWidth * gridHeight * 0.2) {
            location <- one_of(Cell where (empty(Wumpus inside each))).location;
        }
        
        // Create treasure (random position)
        create Treasure number: 1 {
            location <- one_of(Cell where (empty(Wumpus inside each) and empty(Pit inside each))).location;
        }
    }
}

// Define the grid
grid Cell width: gridWidth height: gridHeight neighbors: 4 {
    bool has_breeze <- false;
    bool has_stench <- false;
    bool has_glitter <- false;
    rgb cell_color <- #white;
    
    aspect default {
        draw square(1) color: cell_color border: #black;
    }
}

// Define the Wumpus species
species Wumpus {
    aspect default {
        draw circle(1) color: #red;
    }
}

// Define the Pit species
species Pit {
    aspect default {
        draw square(1) color: #black;
    }
}

// Define the Treasure species
species Treasure {
    aspect default {
        draw circle(1) color: #yellow;
    }
}	


experiment wumpus_simulation type: gui {
    output {
        display main_display {
            grid Cell border: #black;
            species Wumpus;
            species Pit;
            species Treasure;
        }
    }
}