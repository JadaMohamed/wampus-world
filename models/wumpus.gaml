model AdventureWorld

global {
    // Configuration settings for the grid and entities
    int world_size <- 4;
    point starting_point <- {1, 1};
    file icon_player <- file("../includes/player.png");
    file icon_glitter <- file("../includes/glitter.png");
    file icon_breeze <- file("../includes/breeze.png");
    file icon_stench <- file("../includes/stench.png");
    int total_pits <- 2;
    int total_wumpus <- 1;
    int total_treasures <- 1;

    // Calculate breeze indicators
    action calculate_breeze {
        loop cell over: AdventureCell {
            list<AdventureCell> neighbors <- cell neighbors_at 1;
            cell.has_breeze <- not empty(neighbors where (each.has_pit));
        }
    }

    // Calculate stench indicators
    action calculate_stench {
        loop cell over: AdventureCell {
            list<AdventureCell> neighbors <- cell neighbors_at 1;
            cell.has_stench <- not empty(neighbors where (each.has_wumpus));
        }
    }

    // Calculate glitter indicators
    action calculate_glitter {
        loop cell over: AdventureCell {
            list<AdventureCell> neighbors <- cell neighbors_at 1;
            cell.has_glitter <- not empty(neighbors where (each.has_treasure));
        }
    }

    // Generate all indicators
    action generate_indicators {
        do calculate_breeze;
        do calculate_stench;
        do calculate_glitter;
    }

    // Initialize the game world
    init {
        // Populate the grid with pits
        loop times: total_pits {
            AdventureCell pit <- one_of(AdventureCell where (each.type = "empty"));
            pit.type <- "pit";
            pit.has_pit <- true;
        }

        // Place the Wumpus in the grid
        loop times: total_wumpus {
            AdventureCell wumpus <- one_of(AdventureCell where (each.type = "empty"));
            wumpus.type <- "wumpus";
            wumpus.has_wumpus <- true;
        }

        // Add treasures to the grid
        loop times: total_treasures {
            AdventureCell treasure <- one_of(AdventureCell where (each.type = "empty"));
            treasure.type <- "treasure";
            treasure.has_treasure <- true;
        }

        // Spawn the player character
        create Explorer number: 1 {
            location <- starting_point;
        }

        // Generate environmental indicators
        do generate_indicators;
    }
}

// Grid structure representing the environment
grid AdventureCell width: world_size height: world_size {
    string type <- "empty";
    bool has_pit <- false;
    bool has_wumpus <- false;
    bool has_treasure <- false;
    bool has_breeze <- false;
    bool has_stench <- false;
    bool has_glitter <- false;

    // Update visual representation based on cell state
    reflex update_visual {
        if (type = "wumpus") {
            color <- #red; // Red for Wumpus
        } else if (type = "treasure") {
            color <- #gold; // Gold for treasure
        } else if (type = "pit") {
            color <- #darkblue; // Black for pits
        } else if (has_breeze) {
            color <- #lightgray; // Gray for breeze
        } else if (has_stench) {
            color <- #orange; // Orange for stench
        } else if (has_glitter) {
            color <- #pink; // Purple for glitter
        } else {
            color <- #white; // White for empty cells
        }
    }
}

// Player entity for navigating the grid
species Explorer {
    float movement_speed <- 0.01;
    list<point> safe_locations <- [];
    list<point> danger_locations <- [];
    list<point> visited_locations <- [];
    bool carrying_treasure <- false;
    bool alive <- true;
    bool glitter_detected <- false;
    point treasure_coords <- nil;

    // Observe the current environment
    reflex scan_environment {
        AdventureCell current <- AdventureCell(location);

        if (!(location in visited_locations)) {
            add location to: visited_locations;
            add location to: safe_locations;
        }

        list<AdventureCell> neighbors <- AdventureCell(location) neighbors_at 1;
        
        // Détection du Wumpus
        list<AdventureCell> wumpus_cells <- neighbors where (each.has_wumpus);
        if (not empty(wumpus_cells)) {
            write "DANGER IMMINENT ! Un Wumpus est dans une cellule adjacente !";
        }

        // Détection des puits
        list<AdventureCell> pit_cells <- neighbors where (each.has_pit);
        if (not empty(pit_cells)) {
            write "DANGER IMMINENT ! Un puits est dans une cellule adjacente !";
        }


        // Handle dangers and treasure collection
        if (current.has_pit or current.has_wumpus) {
            alive <- false;
            write "Game Over! Explorer perished.";
            do die;
        } else if (current.has_treasure) {
            carrying_treasure <- true;
            current.has_treasure <- false;
            current.type <- "empty";
            write "Treasure secured!";
            do leave_grid;
        }

        // Update known safe and dangerous areas
        do evaluate_cells;
    }

    // Make decisions on movement
    reflex navigate when: alive {
        if (glitter_detected and treasure_coords != nil) {
            location <- treasure_coords;
            write "Heading directly to treasure!";
            glitter_detected <- false;
            return;
        }

        list<AdventureCell> safe_neighbors <- AdventureCell(location) neighbors_at 1 
            where (!(each.has_pit) and !(each.has_wumpus));

        if (not empty(safe_neighbors) and (cycle mod int(1/movement_speed) = 0)) {
            AdventureCell next <- one_of(safe_neighbors);
            location <- next.location;
        } else {
            write "No safe path available!";
        }
    }

    action leave_grid {
        write "Explorer has exited the grid.";
        alive <- false;
        do die;
    }

    action evaluate_cells {
        safe_locations <- [];
        danger_locations <- [];
        loop cell over: AdventureCell {
            if (cell.location != location and !(cell.location in visited_locations)) {
                add cell.location to: (cell.has_pit or cell.has_wumpus ? danger_locations : safe_locations);
            }
        }
    }

    aspect default {
        draw image(icon_player) size: {12, 12};
    }
}

// Experiment to run the simulation in a graphical environment
experiment AdventureSimulation type: gui {
    output {
        display AdventureMap {
            grid AdventureCell lines: #black;
            species Explorer;
        }
    }
}
