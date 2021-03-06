// miner agent

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }

/*
 * By Joao Leite
 * Based on implementation developed by Rafael Bordini, Jomi Hubner and Maicon Zatelli
 */

/* beliefs */
last_dir(null). // the last movement I did
free.

/*Exerc?cio C */
score(0).

/* rules */
/* this agent program doesn't have any rules */


/* plans for sending the initial position to leader */
/* Adapted from Jason Example */
+gsize(S,_,_) : true // S is the simulation Id
  <- !send_init_pos(S).
+!send_init_pos(S) : pos(X,Y)
  <- .send(leader,tell,init_pos(S,X,Y)).
+!send_init_pos(S) : not pos(_,_) // if I do not know my position yet
  <- .wait("+pos(X,Y)", 500);     // wait for it and try again
     !!send_init_pos(S).


/* When free, agents wonder around. This is encoded with a plan that executes
 * when agents become free (which happens initially because of the belief "free"
 * above, but can also happen during the execution of the agent (as we will see below).
 *
 * The plan simply gets two random numbers within the scope of the size of the grid
 * (using an internal action jia.random), and then calls the subgoal go_near. Once the
 * agent is near the desired position, if free, it deletes and adds the atom free to
 * its belief base, which will trigger the plan to go to a random location again.
 */

+free : quadrant(SX, EX, SY, EY) & jia.randomRange(RX,SX,EX) & jia.randomRange(RY,SY,EY)
   <-  .print("I am going to go near (",RX,",", RY,")");
       !go_near(RX,RY);
       !choose_gold;
       .
+free  // gsize is unknown yet
   <- .wait(100); -+free.

/* When the agent comes to believe it is near the location and it is still free,
 * it updates the atom "free" so that it can trigger the plan to go to a random
 * location again.
 */
+near(X,Y) : free <- -+free.

/*Exerc?cio H */
+winning(Ag,S)[source(leader)] //I am winning
	: .my_name(Ag) 
	<- 	-winning(Ag,S);
		.print("I am winning with ",S," pieces of gold!").
		
+winning(Ag,S)[source(leader)] //I am not winning
	: 	true
	<- 	-winning(Ag,S).		



/* The following plans encode how an agent should go to near a location X,Y.
 * Since the location might not be reachable, the plans succeed
 * if the agent is near the location, given by the internal action jia.neighbour,
 * or if the last action was skip, which happens when the destination is not
 * reachable, given by the plan next_step as the result of the call to the
 * internal action jia.get_direction.
 * These plans are only used when exploring the grid, since reaching the
 * exact location is not really important.
 */

+!go_near(X,Y) : free
  <- -near(_,_);
     -last_dir(_);
     !near(X,Y).


// I am near to some location if I am near it
+!near(X,Y) : (pos(AgX,AgY) & jia.neighbour(AgX,AgY,X,Y))
   <- .print("I am at ", "(",AgX,",", AgY,")", " which is near (",X,",", Y,")");
      +near(X,Y).

// I am near to some location if the last action was skip
// (meaning that there are no paths to there)
+!near(X,Y) : pos(AgX,AgY) & last_dir(skip)
   <- .print("I am at ", "(",AgX,",", AgY,")", " and I can't get to' (",X,",", Y,")");
      +near(X,Y).

+!near(X,Y) : not near(X,Y)
   <- !next_step(X,Y);
      !near(X,Y).
+!near(X,Y) : true
   <- !near(X,Y).


/* These are the plans to have the agent execute one step in the direction of X,Y.
 * They are used by the plans go_near above and pos below. It uses the internal
 * action jia.get_direction which encodes a search algorithm.
 */

+!next_step(X,Y) : pos(AgX,AgY) // I already know my position
   <- jia.get_direction(AgX, AgY, X, Y, D);
      -+last_dir(D);
      jia.randomRange(RX,0,50);
      .wait(RX); //
      D.
+!next_step(X,Y) : not pos(_,_) // I still do not know my position
   <- !next_step(X,Y).
-!next_step(X,Y) : true  // failure handling -> start again!
   <- -+last_dir(null);
      !next_step(X,Y).


/* The following plans encode how an agent should go to an exact position X,Y.
 * Unlike the plans to go near a position, this one assumes that the
 * position is reachable. If the position is not reachable, it will loop forever.
 */

+!pos(X,Y) : pos(X,Y)
   <- .print("I've reached ",X,"x",Y).
+!pos(X,Y) : not pos(X,Y)
   <- !next_step(X,Y);
      !pos(X,Y).



/* Gold-searching Plans */

/* The following plan encodes how an agent should deal with a newly found piece
 * of gold, when it is not carrying gold and it is free.
 * The first step changes the belief so that the agent no longer believes it is free.
 * Then it adds the belief that there is gold in position X,Y, and
 * prints a message. Finally, it calls a plan to handle that piece of gold.
 */
 
 +cell(X,Y,gold) <- +cell_gold(X,Y,gold).

// perceived golds are included as self beliefs (to not be removed once not seen anymore)
@pgold[atomic]           // atomic: so as not to handle another event until handle gold is initialised
+cell_gold(X,Y,gold)
  :  not carrying_gold & free
  <- -free;
     .print("Gold perceived: ",gold(X,Y));
     //removed gold from the general list. If it is there...
     lookupArtifact(gldMp,IdGM);
	 focus(IdGM);
	 removeGold(X,Y)[artifact_id(IdGM)];
     +gold(X,Y);
     !init_handle(gold(X,Y)).
     
/*Exerc?cio I: agent is going to pick-up gold and detects another */
@pgold_exer[atomic] 
+cell_gold(X,Y,gold)
	: 	not carrying_gold & not free &
		.desire(handle(gold(PX,PY))) & //previous gold's X and Y
		pos(AgX, AgY) &
		jia.dist(X, Y, AgX, AgY, NGoldDist) & //new distance
		jia.dist(PX, PY, AgX, AgY, PGoldDist) & //previous distance
		NGoldDist < PGoldDist
	<- 	.drop_desire(handle(gold(PX, PY)));
		.print("Dropping ", gold(PX, PY), "to perform ", gold(X,Y));
		//removed gold from the general list. If it is there...
		lookupArtifact(gldMp,IdGM);
	 	focus(IdGM);
	 	removeGold(X,Y)[artifact_id(IdGM)];
		addGold(PX,PY)[artifact_id(IdGM)];
		+gold(X,Y);
		-gold(PX, PY);
		!init_handle(gold(X,Y)).

@pgold_gold[atomic]		
+cell_gold(X,Y,gold) 
	<-  lookupArtifact(gldMp,ArtId);
		addGold(X,Y)[artifact_id(ArtId)];
		.		
		

/* The next plans encode how to handle a piece of gold.
 * The first one drops the desire to be near some location,
 * which could be true if the agent was just randomly moving around looking for gold.
 * The second one simply calls the goal to handle the gold.
 * The third plan is the one that actually results in dealing with the gold.
 * It raises the goal to go to position X,Y, then the goal to pickup the gold,
 * then to go to the position of the depot, and then to drop the gold and remove
 * the belief that there is gold in the original position.
 * Finally, it prints a message and raises a goal to choose another gold piece.
 * The remaining two plans handle failure.
 */

@pih1[atomic]
+!init_handle(Gold)
  :  .desire(near(_,_))
  <- .print("Dropping near(_,_) desires and intentions to handle ",Gold);
     .drop_desire(near(_,_));
     !init_handle(Gold).
@pih2[atomic]
+!init_handle(Gold)
  :  pos(X,Y)
  <- .print("Going for ",Gold);
     !!handle(Gold). // must use !! to perform "handle" as not atomic

+!handle(gold(X,Y))
  :  not free
  <- .print("Handling ",gold(X,Y)," now.");
     !pos(X,Y);
     !ensure(pick,gold(X,Y));
     .broadcast(tell, picked(gold(X,Y)));
     ?depot(_,DX,DY); /* Exer D */
     !pos(DX,DY); /* Exer D */
     !ensure(drop, 0);
     .print("Finish handling ",gold(X,Y));
     ?score(S); /* Exer C */
     -+score(S+1); /* Exer C */
     .send(leader, tell, dropped); /* Exer D */
     !!choose_gold.

// if ensure(pick/drop) failed, pursue another gold
-!handle(G) : G
  <- .print("failed to catch gold ",G);
     .abolish(G); // ignore source
     !!choose_gold.
-!handle(G) : true
  <- .print("failed to handle ",G,", it isn't in the BB anyway");
     !!choose_gold.

//Used from jason example
@ppgd[atomic]
+picked(G)[source(A)]
  :  .desire(handle(G)) | .desire(init_handle(G))
  <- .print(A," has taken ",G," that I am pursuing! Dropping my intention.");
     .abolish(G);
     .drop_desire(handle(G));
     !!choose_gold.

/* The next plans deal with picking up and dropping gold. */

+!ensure(pick,_) : pos(X,Y) & gold(X,Y)
  <- pick;
     ?carrying_gold;
     -gold(X,Y).
// fail if no gold there or not carrying_gold after pick!
// handle(G) will "catch" this failure.

+!ensure(drop, _) : carrying_gold & depot(_,DX,DY) & pos(DX,DY)
  <- drop.


/* The next plans encode how the agent can choose the next gold piece
 * to pursue (the closest one to its current position) or,
 * if there is no known gold location, makes the agent believe it is free.
 */
 /* 
+!choose_gold
  :  not gold(_,_)
  <- -+free.

// Finished one gold, but others left
// find the closest gold among the known options,
+!choose_gold
  :  gold(_,_)
  <- .findall(gold(X,Y),gold(X,Y),LG);
     !calc_gold_distance(LG,LD);
     .length(LD,LLD); LLD > 0;
     .print("Gold distances: ",LD,LLD);
     .min(LD,d(_,NewG));
     .print("Next gold is ",NewG);
     !!handle(NewG).
*/
     
+!choose_gold
	:	pos(AgX, AgY)
	<-	.my_name(Ag);
		//focusing in the Gold map
		lookupArtifact(gldMp,IdGM);
		focus(IdGM);
		getGold(Ag, AgX, AgY)[artifact_id(IdGM)];
		.     
//+!choose_gold <- .wait(10); !choose_gold.

-!choose_gold <- -+free.

+best_gold(Ag, GX, GY)[artifact_id(IdGM)] 
	: .my_name(Ag) & GX \== none & GY \== none 
	<-	+gold(GX, GY);
		!init_handle(gold(GX, GY)).
	
+best_gold(Ag, GX, GY)[artifact_id(IdGM)] 
	: .my_name(Ag) & GX == none & GY == none 
	<-	-+free;
		.	

/*
+!calc_gold_distance([],[]).
+!calc_gold_distance([gold(GX,GY)|R],[d(D,gold(GX,GY))|RD])
  :  pos(IX,IY)
  <- jia.dist(IX,IY,GX,GY,D);
     !calc_gold_distance(R,RD).
+!calc_gold_distance([_|R],RD)
  <- !calc_gold_distance(R,RD).

*/

/* end of a simulation */

+end_of_simulation(S,_) : true
  <- .drop_all_desires;
     .abolish(gold(_,_));
     .abolish(picked(_));
     -+free;
     .print("-- END ",S," --").