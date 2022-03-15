// leader agent

{ include("$jacamoJar/templates/common-cartago.asl") }

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
  :	 .count(init_pos(S,_,_),4) // if all miners have sent their position
  <- .print("* InitPos ",A," is ",X,"x",Y);
     lookupArtifact(qdf,ArtId);
     addMiner(A, X, Y)[artifact_id(ArtId)];
     .wait(100);
     !quadrant;
     . 
         
+init_pos(S,X,Y)[source(A)]
	<-	.print("* InitPos ",A," is ",X,"x",Y);
		lookupArtifact(qdf,ArtId);
     	addMiner(A, X, Y)[artifact_id(ArtId)];
     	.    
     	 
+!quadrant 
	<- 	lookupArtifact(qdf,IdQdf);
		computeQuadrants[artifact_id(IdQdf)];
		updatePropQuadrant(miner1)[artifact_id(IdQdf)];
		updatePropQuadrant(miner2)[artifact_id(IdQdf)];
		updatePropQuadrant(miner3)[artifact_id(IdQdf)];
		updatePropQuadrant(miner4)[artifact_id(IdQdf)];
		
		lookupArtifact(gldMp,IgGM);
		setQuadrantExclusive(true)[artifact_id(IgGM)];
		.      

/* plans for send the quadrant to miners */
+quadrant(Ag, SX, EX, SY, EY) 
	:	Ag \== none 
	<-	.send(Ag, tell, quadrant(SX, EX, SY, EY));
		lookupArtifact(gldMp,IgGM);
		addMiner(Ag, SX, EX, SY, EY)[artifact_id(IgGM)];
		.
	
	
	
	
	
	
	
	
	
	
	