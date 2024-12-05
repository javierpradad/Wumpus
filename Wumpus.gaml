/**
* Name:Wumpus
* Author: Javier Prada de Francisco
* Tags: 
*/

model Wumpus

global {
	predicate patrol_desire <- new_predicate("patrol");
	predicate gold_desire <- new_predicate("gold");
	predicate goBack_desire <- new_predicate("goBack");
	string glitterLocation <- "glitterLocation";
	string odorLocation <- "odorLocation";
	string breezeLocation <- "breezeLocation";
	bool orden <- false;
	
	list<float> moveValue <- [0.0, 90.0, 180.0, 270.0];
	
	init {
		list<gworld> occupied_cells <- [];
		
		create goldArea number:1;
		create wumpusArea number: rnd(1,2);
		create pitArea number: rnd(1,5);
		create player number: 1;
	}
	
	reflex stop when: length(goldArea) = 0 {
		do pause;
	}
}

species player skills: [moving] control: simple_bdi{
	
	rgb color <- #green;
	float mov;
	point lastPosition <- {-1, -1};
	bool wrongPlace <- false;
	list<point> visitedLocations <- [];
	int explorationDirection <- 0;
    list<float> systematicMoveValues <- [0.0, 90.0, 180.0, 270.0];
	
	init {
		gworld place <- one_of(gworld);
		location<-place.location;
		mov <- 0.0;
		do add_desire(patrol_desire);
	}
	
	perceive target:wumpusArea in: 1{ 
		ask myself{
			do die;
			ask world{
				do pause;
			}
		} 
	}
	
	perceive target:pitArea in: 1{ 
		ask myself{
			do die;
			ask world{
				do pause;
			}
		} 
	}
	
	perceive target:wumpusNearby in: 1{ 
        focus id:"wumpusNearbyLocation" var:location strength:10.0; 
        ask myself {
            // Eliminar la muerte inmediata
            wrongPlace <- true;
            
            // Forzar un movimiento en una dirección diferente
            list<float> safeDirections <- list(moveValue);
            remove mov from: safeDirections;
            
            mov <- one_of(safeDirections);
            do move heading: mov speed: 4.0;
            
            do remove_desire(patrol_desire);
            do add_desire(goBack_desire);
        } 
    }
	
	perceive target:pitNearby in: 1{ 
        focus id:"pitNearbyLocation" var:location strength:10.0; 
        ask myself {
            // Eliminar la muerte inmediata
            wrongPlace <- true;
            
            // Forzar un movimiento en una dirección diferente
            list<float> safeDirections <- list(moveValue);
            remove mov from: safeDirections;
            
            mov <- one_of(safeDirections);
            do move heading: mov speed: 4.0;
            
            do remove_desire(patrol_desire);
            do add_desire(goBack_desire);
        } 
    }
	
	perceive target:goldNearby in: 1{ 
		focus id:"glitterLocation" var:location strength:10.0; 
		ask myself{
			do remove_intention(patrol_desire, true);
		} 
	}
	
	perceive target:goldArea in: 1{ 
		
		ask goldNearby{
			do die;
		} 
		
		ask goldArea{
			do die;
			ask world{
				do pause;
			}
		} 
	}
	
	// Reglas
	rule belief: new_predicate("glitterLocation") new_desire: get_predicate(get_belief_with_name("glitterLocation"));
	
	plan patrolling intention: patrol_desire {
        // Estrategia de exploración sistemática
        mov <- systematicMoveValues[explorationDirection];
        explorationDirection <- (explorationDirection + 1) mod 4;
        
        // Evitar movimientos a lugares ya visitados
        point nextLocation <- location + {cos(mov), sin(mov)} * 4.0;
        
        if (!(nextLocation in visitedLocations)) {
            do move heading: mov speed: 4.0;
            add location to: visitedLocations;
        } else {
            // Si el lugar ya fue visitado, cambiar de dirección
            explorationDirection <- (explorationDirection + 1) mod 4;
        }
        
        lastPosition <- location;
    }
	
	plan goBack intention: goBack_desire {
        // Cambiar a una dirección completamente diferente
        list<float> backDirections <- list(moveValue);
        remove mov from: backDirections;
        
        mov <- one_of(backDirections);
        
        do move heading: mov speed: 4.0;
        
        wrongPlace <- false;
        do remove_desire(goBack_desire);
        do add_desire(patrol_desire);
    }
	
	plan get_gold intention: new_predicate("glitterLocation") priority:5{
		
		if orden = true{
			if mov = 0.0{
				mov <- 180.0;
			}else if mov = 90.0{
				mov <- 270.0;
			}else if mov = 180.0{
				mov <- 0.0;
			}else{
				mov <- 90.0;
			}
			
			do move heading: mov speed: 4.0;
			orden <- false;
		}else{
			mov <- one_of(moveValue);
			
			do move heading: mov speed: 4.0;
			orden <- true;
		}
	}
	
	
	aspect bdi {
		draw circle(1) color:color rotate: 90 + heading;
	}
}

species wumpusNearby{
	aspect base {
	  draw square(4) color: #crimson border: #black;		
	}
}


species wumpusArea{
	init {
		gworld place <- one_of(gworld);
		location <- place.location;
		
		list<gworld> neighborhood <- [];
		ask place {
			neighborhood <- neighbors;
		}
		
		loop i over: neighborhood {
			create wumpusNearby{
				location <- i.location;
			}
		}
	}
	aspect base {
	  draw square(4) color: #red border: #black;		
	}
}

species goldNearby{
	aspect base {
	  draw square(4) color: #yellow border: #black;		
	}
}

species goldArea{
	init {
		gworld place <- one_of(gworld);
		location <- place.location;
		
		list<gworld> vecinos <- [];
		ask place {
			vecinos <- neighbors;
		}
		
		loop i over: vecinos {
			create goldNearby{
				location <- i.location;
			}
		}
	}
	
	
	perceive target:player in: 1{
		ask myself{
			do die;
		} 
	}
	
	aspect base {
	  draw square(4) color: #gold border: #black;		
	}
}

species pitNearby{
	aspect base {
	  draw square(4) color: #lightgrey border: #black;		
	}
}

species pitArea{
	init {
		gworld place <- one_of(gworld);
		location <- place.location;
		
		list<gworld> vecinos <- [];
		ask place {
			vecinos <- neighbors;
		}
		
		loop i over: vecinos {
			create pitNearby{
				location <- i.location;
			}
		}
	}
	
	aspect base {
	  draw square(4) color: #black border: #black;		
	}
}

grid gworld width: 25 height: 25 neighbors:4 {
	rgb color <- #white;
}


experiment Wumpus_1 type: gui {
	float minimum_cycle_duration <- 0.05;
	output {					
		display view1 { 
			grid gworld border: #darkgreen;
			species goldArea aspect:base;
			species goldNearby aspect:base;
			species wumpusArea aspect:base;
			species wumpusNearby aspect:base;
			species pitNearby aspect:base;
			species pitArea aspect:base;
			species player aspect:bdi;
		}
	}
}