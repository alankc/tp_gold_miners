// leader agent

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$moiseJar/asl/org-obedient.asl") }

/*
 * By Joao Leite
 * Based on implementation developed by Rafael Bordini, Jomi Hubner and Maicon Zatelli
 */


score(miner1,0).
score(miner2,0).
score(miner3,0).
score(miner4,0).
winning(none,0). /* Exer F*/

@pd1[atomic]
+dropped[source(A)] : score(A,S) & winning(Ag,Scr) & S + 1 > Scr /* Exer F */
   <- -score(A,S);
   	  +score(A,S+1);
      -dropped[source(A)];
      -+winning(A,S+1);
      .print("Agent ",A," has dropped ",S+1," pieces of gold and is WINING!");
      .broadcast(tell, winning(A,S+1)); /* Exer G */
      .

@pd2[atomic]
+dropped[source(A)] : score(A,S)
   <- -score(A,S+1);
   	  +score(A,S+1);
      -dropped[source(A)];
      .print("Agent ",A," has dropped ",S+1," pieces of gold").
 

/* plans for receiving the initial position from miners */
/* Adapted from Jason Example */

+init_pos(S,X,Y)[source(A)]
	<-	.print("* InitPos ",A," is ",X,"x",Y);
		
		joinWorkspace(mining, WspId);
		lookupArtifact(qdf,ArtId);
		focus(ArtId)[wid(WspId)];
		
     	addMiner(A, X, Y)[artifact_id(ArtId)];
     	.

+!set_artifacts <- !wait_miners.
	
+!wait_miners
	: not .count(init_pos(S,X,Y), 4) 
	<- 	.wait(100);
		!wait_miners.

+!wait_miners <- !quadrants.		
   	
+!quadrants
	<- 	joinWorkspace(mining, WspId);
		lookupArtifact(qdf,IdQdf);
		focus(IdQdf)[wid(WspId)];
	
		computeQuadrants[artifact_id(IdQdf)];
		
		updatePropQuadrant(miner1)[artifact_id(IdQdf)];
		updatePropQuadrant(miner2)[artifact_id(IdQdf)];
		updatePropQuadrant(miner3)[artifact_id(IdQdf)];
		updatePropQuadrant(miner4)[artifact_id(IdQdf)];
		
		lookupArtifact(gldMp,IgGM);
		focus(IgGM)[wid(WspId)];
		setQuadrantExclusive(true)[artifact_id(IgGM)];
		.     	    	    

/* plans for send the quadrant to miners */
+quadrant(Ag, SX, EX, SY, EY) 
	:	Ag \== none 
	<-	.send(Ag, tell, quadrant(SX, EX, SY, EY));
		lookupArtifact(gldMp,IgGM);
		addMiner(Ag, SX, EX, SY, EY)[artifact_id(IgGM)];
		.
	
	
	
	
	
	
	
	
	
	
	