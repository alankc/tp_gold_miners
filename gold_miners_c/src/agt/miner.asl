// miner agent

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$moiseJar/asl/org-obedient.asl") }

/*
 * By Joao Leite
 * Based on implementation developed by Rafael Bordini, Jomi Hubner and Maicon Zatelli
 */

/* beliefs */
last_dir(null). // the last movement I did
//free. run_miner do that!

/*Exercício C */
score(0).

/* rules */
// next line is the bottom of the quadrant
// if 2 lines bellow is too far
calc_new_y(AgY,QuadY2,QuadY2) :- AgY+2 > QuadY2.

// otherwise, the next line is 2 lines bellow
calc_new_y(AgY,_,Y) :- Y = AgY+2.


/* plans for sending the initial position to leader */
/* Adapted from Jason Example */

+!send_start_position <- !start_gsize.
	
+!start_gsize
	: not gsize(_,_,_)
	<- 	.wait("+gsize(S,_,_)", 500);
		!start_gsize.
+!start_gsize <- !start_position.	
				
+!start_position
	: not pos(_,_)
	<- 	.wait("+pos(X,Y)", 500);
		!start_position.
+!start_position <- !send_position.		

+!send_position
	: gsize(S,_,_) & pos(X,Y)
	<- 	//.send(leader,tell,init_pos(S,X,Y)); from old version
		.my_name(A);
		qd::addMiner(A, X, Y);
		.wait(50). //waiting leader receive information
		
+qd::quadrant(Ag, SX, EX, SY, EY) 
	:	.my_name(Ag)
	<-	+quadrant(SX, EX, SY, EY);
		.  		
		
/*Exercício H */
+winning(Ag,S)[source(leader)] //I am winning
	: .my_name(Ag) 
	<- 	-winning(Ag,S);
		.print("I am winning with ",S," pieces of gold!").
		
+winning(Ag,S)[source(leader)] //I am not winning
	: 	true
	<- 	-winning(Ag,S).			

/* When free, agents wonder around. This is encoded with a plan that executes
 * when agents become free (which happens initially because of the belief "free"
 * above, but can also happen during the execution of the agent (as we will see below).
 *
 * The plan simply gets two random numbers within the scope of the size of the grid
 * (using an internal action jia.random), and then calls the subgoal go_near. Once the
 * agent is near the desired position, if free, it deletes and adds the atom free to
 * its belief base, which will trigger the plan to go to a random location again.
 */

+free[source(leader)] <- -free[source(leader)]; -+free.
   
/* plans for wandering in my quadrant when I'm free */

+free : quadrant(X1,X2,Y1,Y2) <- !prep_around(X1,Y1).
+free : true				  <- .wait(100); -+free.
   
// if I am around the upper-left corner, move to upper-right corner
+around(X1,Y1) : quadrant(X1,X2,Y1,Y2) & free
  <- .print("in Q1 to ",X2,"x",Y1);
     !prep_around(X2,Y1).

// if I am around the bottom-right corner, move to upper-left corner
+around(X2,Y2) : quadrant(X1,X2,Y1,Y2) & free
  <- .print("in Q4 to ",X1,"x",Y1);
     !prep_around(X1,Y1).

// if I am around the right side, move to left side two lines bellow
+around(X2,Y) : quadrant(X1,X2,Y1,Y2) & free
  <- ?calc_new_y(Y,Y2,YF);
     .print("in Q2 to ",X1,"x",YF);
     !prep_around(X1,YF).

// if I am around the left side, move to right side two lines bellow
+around(X1,Y) : quadrant(X1,X2,Y1,Y2) & free
  <- ?calc_new_y(Y,Y2,YF);
     .print("in Q3 to ", X2, "x", YF);
     !prep_around(X2,YF).

// last "around" was none of the above, go back to my quadrant
+around(X,Y) : quadrant(X1,X2,Y1,Y2) & free & Y <= Y2 & Y >= Y1
  <- .print("in no Q, going to X1");
     !prep_around(X1,Y).
+around(X,Y) : quadrant(X1,X2,Y1,Y2) & free & X <= X2 & X >= X1
  <- .print("in no Q, going to Y1");
     !prep_around(X,Y1).

+around(X,Y) : quadrant(X1,X2,Y1,Y2)
  <- .print("It should never happen!!!!!! - go home");
     !prep_around(X1,Y1).

+!prep_around(X,Y) : free
  <- -around(_,_); -last_dir(_); !around(X,Y).

+!around(X,Y)
   :  // I am around to some location if I am near it or
      // the last action was skip (meaning that there are no paths to there)
      (pos(AgX,AgY) & jia.neighbour(AgX,AgY,X,Y)) | last_dir(skip)
   <- +around(X,Y).
+!around(X,Y) : not around(X,Y)
   <- !next_step(X,Y);
      !!around(X,Y).
+!around(X,Y) : true
   <- !!around(X,Y).


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
	 gd::removeGold(X,Y);
     +gold(X,Y);
     !init_handle(gold(X,Y)).
     
/*Exercício I: agent is going to pick-up gold and detects another */
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
	 	gd::removeGold(X,Y);
		gd::addGold(PX,PY);
		+gold(X,Y);
		-gold(PX, PY);
		!init_handle(gold(X,Y)).

@pgold_gold[atomic]		
+cell_gold(X,Y,gold) 
	<-  gd::addGold(X,Y);
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
  :  .desire(around(_,_)) //oldversion .desire(near(_,_))
  <- .print("Dropping near(_,_) desires and intentions to handle ",Gold);
     //oldversion .drop_desire(near(_,_));
     .drop_desire(around(_,_));
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
		gd::getGold(Ag, AgX, AgY);
		.     
//+!choose_gold <- .wait(10); !choose_gold.

-!choose_gold <- -+free.

+gd::best_gold(Ag, GX, GY)[artifact_id(IdGM)] 
	:	.my_name(Ag) & GX \== none & GY \== none 
	<-	+gold(GX, GY);
		!init_handle(gold(GX, GY))
		.
	
+gd::best_gold(Ag, GX, GY)[artifact_id(IdGM)] 
	:	.my_name(Ag) & GX == none & GY == none 
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