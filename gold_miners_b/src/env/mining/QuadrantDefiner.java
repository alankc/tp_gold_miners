// CArtAgO artifact code for project gold_miners_b

package mining;

import cartago.*;
import jason.asSyntax.Atom;
import jason.environment.grid.Location;
import jason.util.Pair;

import java.util.HashMap;
import java.util.Map;

public class QuadrantDefiner extends Artifact {
	
	WorldModel model = null;
	
	//Agent, its location
	Map<String, Location> nonAllocatedMiners;
	
	//Agent, <StartQuatrand, EndQuadrant>
	Map<String, Pair<Location, Location>> quadrants;
	
	void init(int worldModel) {
		initWorld(worldModel);
		nonAllocatedMiners = new HashMap<String, Location>();
		quadrants = new HashMap<String, Pair<Location, Location>>();
		
		defineObsProperty("quadrant", new Atom("none"), 0, 0, 0, 0);
	}
	
	public synchronized void initWorld(int w) {
        try {
            if (model == null) {
                switch (w) {
                case 1: model = WorldModel.world1(); break;
                case 2: model = WorldModel.world2(); break;
                case 3: model = WorldModel.world3(); break;
                case 4: model = WorldModel.world4(); break;
                case 5: model = WorldModel.world5(); break;
                case 6: model = WorldModel.world6(); break;
                default:
                	failed("Invalid index!");
                    return;
                }
            }
        } catch (Exception e) {
        	failed("Error creating world "+ e);
            e.printStackTrace();
        }
    }

	@OPERATION
	void addMiner(String name, int x, int y) {
		nonAllocatedMiners.put(name, new Location(x, y));
	}
	
	
	@OPERATION
	void computeQuadrants() //Divides agents equally among quadrants
	{
		Location start, end;
		int widthSize = model.getWidth();
		int heightSize = model.getHeight();
		
		System.out.println("****** SIZE: " + widthSize + ", " + heightSize);
		
		if (nonAllocatedMiners.size() < 4)
			failed("It is necessary at least 4 miners!");
		
		while (nonAllocatedMiners.size() != 0)
		{	
			//Quadrant 1
			// # 0
			// 0 0
			start 	= new Location(0, 0);
			end 	= new Location(widthSize / 2 - 1, heightSize / 2 - 1);
			addAgentToQuadrant(start, end);
			
			//Quadrant 2
			// 0 #
			// 0 0
			start 	= new Location(widthSize / 2, 0);
			end 	= new Location(widthSize - 1, heightSize / 2 - 1);
			addAgentToQuadrant(start, end);
			
			//Quadrant 3
			// 0 0
			// # 0
			start 	= new Location(0, heightSize / 2);
			end 	= new Location(widthSize / 2 - 1, heightSize - 1);
			addAgentToQuadrant(start, end);
			
			//Quadrant 4
			// 0 0
			// 0 #
			start 	= new Location(widthSize / 2, heightSize / 2);
			end 	= new Location(widthSize - 1, heightSize - 1);
			addAgentToQuadrant(start, end);
		}
	}
	
	private void addAgentToQuadrant(Location start, Location end) {
		String miner = computeClosest(start);
		quadrants.put(miner, new Pair<Location, Location>(start, end));
		nonAllocatedMiners.remove(miner);
		
		System.out.println("name: " + miner + " added to (" + start + ") and (" + end + ")");
	}
	
	private String computeClosest(Location l)
	{
		String closest = null;
		int bestDistance = Integer.MAX_VALUE;
		
		for (Map.Entry<String, Location> entry : nonAllocatedMiners.entrySet()) {
			int distance = entry.getValue().distance(l);
			if (distance < bestDistance) {
				closest = entry.getKey();
				bestDistance = distance;
			}
		}
		
		return closest;
	}
	
	@OPERATION
	void updatePropQuadrant(String name){

		Pair<Location, Location> quadrant = quadrants.get(name);
		int startX = quadrant.getFirst().x;
		int startY = quadrant.getFirst().y;
		int endX = quadrant.getSecond().x;
		int endY = quadrant.getSecond().y;
		getObsProperty("quadrant").updateValues(new Atom(name), startX, endX, startY, endY);
	}
}

