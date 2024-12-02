model wumpus_world
global {
    int worldSize <- 4;

    init {
        create wumpus number: 1;
        create pit number: 3;
        create treasure number: 3;
        create player number: 1;
    }
}

grid cell width: worldSize height: worldSize neighbors: 4 {
    bool hasWumpus <- false;
    bool hasPit <- false;
    bool hasTreasure <- false;
    bool hasStench <- false;
    bool hasBreeze <- false;
    bool hasGlitter <- false;
    rgb color <- #white;

    aspect default {
        draw square(1) color: color border: #black;
    }
}

species wumpus {
    init {
        cell current_cell <- one_of(cell);
        location <- current_cell.location;
        current_cell.hasWumpus <- true;
        current_cell.color <- #red;

        ask current_cell.neighbors {
            hasStench <- true;
            color <- color + #brown;
        }
    }
}

species pit {
    init {
        cell current_cell <- one_of(cell where (!each.hasWumpus and !each.hasPit));
        location <- current_cell.location;
        current_cell.hasPit <- true;
        current_cell.color <- #black;

        ask current_cell.neighbors {
            hasBreeze <- true;
            color <- color + #blue;
        }
    }
}

species treasure {
    init {
        cell current_cell <- one_of(cell where (!each.hasWumpus and !each.hasPit and !each.hasTreasure));
        location <- current_cell.location;
        current_cell.hasTreasure <- true;
        current_cell.hasGlitter <- true;
        current_cell.color <- #yellow;
    }
}

species player control: simple_bdi skills: [moving] {
    bool alive <- true;
    int treasuresCollected <- 0;
    cell current_cell;

    predicate patrol_desire <- new_predicate("patrol");
    predicate collect_gold <- new_predicate("collect_gold");
    predicate avoid_danger <- new_predicate("avoid_danger");

    init {
        current_cell <- cell[0, worldSize - 1];
        location <- current_cell.location;
        do add_desire(patrol_desire);
    }

   perceive target: cell {
        if (target.hasBreeze) {
            do add_belief(new_predicate("breeze_detected", map("location", target.location));
            do add_desire(avoid_danger, 2.0);}
        if (target.hasStench) {
            do add_belief(new_predicate("stench_detected", map("location", target.location)));
            do add_desire(avoid_danger, 2.0);
        }
        if (target.hasGlitter) {
            do add_belief(new_predicate("glitter_detected", map("location", target.location)));
            do add_desire(collect_gold, 3.0);
        }
        if (target.hasPit) {
            do add_belief(new_predicate("pit_detected", map("location", target.location)));
            do add_desire(avoid_danger, 3.0); 
        }
        if (target.hasWumpus) {
            do add_belief(new_predicate("wumpus_detected", map("location", target.location)));
            do add_desire(avoid_danger, 3.0); 
        }
    }

    plan patrol intention: patrol_desire {
        cell next_cell <- one_of(current_cell.neighbors where (!each.hasPit and !each.hasWumpus));
        if (next_cell != nil) {
            current_cell <- next_cell;
            location <- next_cell.location;
        }
    }

    plan collect_treasure intention: collect_gold {
        if (current_cell.hasTreasure) {
            treasuresCollected <- treasuresCollected + 1;
            current_cell.hasTreasure <- false;
            current_cell.hasGlitter <- false;
            current_cell.color <- #white;
            do remove_intention(collect_gold, true);
        }
    }

    plan avoid_pit intention: avoid_danger {
        cell safe_cell <- one_of(current_cell.neighbors where (!each.hasBreeze and !each.hasStench));
        if (safe_cell != nil) {
            current_cell <- safe_cell;
            location <- safe_cell.location;
        }
    }

    reflex check_death when: alive {
        if (current_cell.hasWumpus or current_cell.hasPit) {
            alive <- false;
            write "Game Over! Player died!";
            do die;
        }
    }

    aspect default {
        draw circle(0.5) color: #green;
    }
}

experiment wumpus_simulation type: gui {
    output {
        display main_display {
            grid cell;
            species wumpus aspect: default;
            species pit aspect: default;
            species treasure aspect: default;
            species player aspect: default;
        }
    }
}