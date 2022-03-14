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

//the start goal only works after execise j)
//!start.
//+!start <- tweet("a new mining is starting! (posted by jason agent)").

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