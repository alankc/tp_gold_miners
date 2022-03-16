// CArtAgO artifact code for project gold_miners_b

package mining;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import cartago.*;
import jason.asSyntax.Atom;
import jason.environment.grid.Location;
import jason.util.Pair;

public class GoldMap extends Artifact {

	// Agent, quadrant(start(x,y), end(x,y))
	private Map<String, Pair<Location, Location>> miners;
	// Location of golds
	private ArrayList<Location> golds;
	// Used to test if must restrict agent to golds in the quadrant
	private boolean quadrantExclusive;

	void init() {
		defineObsProperty("best_gold", new Atom("none"), new Atom("none"), new Atom("none"));

		miners = new HashMap<String, Pair<Location, Location>>();
		golds = new ArrayList<Location>();
		quadrantExclusive = false;
	}

	@OPERATION
	void addMiner(String minerName, int startX, int endX, int startY, int endY) {
		Location start = new Location(startX, startY);
		Location end = new Location(endX, endY);
		miners.put(minerName, new Pair<Location, Location>(start, end));
	}

	@OPERATION
	void addGold(int x, int y) {

		for (int i = 0; i < golds.size(); i++) {
			if (golds.get(i).x == x && golds.get(i).y == y)
				return;
		}
		System.out.println("################################");
		System.out.println("ADD GOLD IN: (" + x + "," + y + ")");
		System.out.println("################################");
		golds.add(new Location(x, y));
	}

	@OPERATION
	void removeGold(int x, int y) {
		int toRemove = -1;
		for (int i = 0; i < golds.size(); i++) {
			if (golds.get(i).x == x && golds.get(i).y == y)
				toRemove = i;
				break;
		}
		if (toRemove > -1)
			golds.remove(toRemove);
		
		System.out.println("################################");
		System.out.println("REMOVE GOLD IN: (" + x + "," + y + ")");
		System.out.println("################################");
	}

	@OPERATION
	void setQuadrantExclusive(boolean quadrantExclusive) {
		this.quadrantExclusive = quadrantExclusive;
	}

	@OPERATION
	void getGold(String minerName, int x, int y) {
		if (golds.isEmpty()) {
			getObsProperty("best_gold").updateValues(new Atom(minerName), new Atom("none"), new Atom("none"));
		} else {
			if (quadrantExclusive)
				getGoldInQuadrant(minerName, x, y);
			else
				getGoldInMap(minerName, x, y);
		}
	}

	void getGoldInQuadrant(String minerName, int x, int y) {

		Pair<Location, Location> quadrant = miners.get(minerName);
		Location start = quadrant.getFirst();
		Location end = quadrant.getSecond();

		int bestDistance = Integer.MAX_VALUE;
		int bestGold = -1;
		Location ml = new Location(x, y);

		for (int i = 0; i < golds.size(); i++) {

			Location gl = golds.get(i);

			if ((start.x <= gl.x) && (gl.x <= end.x) && (start.y <= gl.y) && (gl.y <= end.y)) {

				int distance = gl.distance(ml);

				if (distance < bestDistance) {
					bestDistance = distance;
					bestGold = i;
				}
			}
		}

		// Maybe there is no gold in the quadrant
		if (bestGold == -1)
			getObsProperty("best_gold").updateValues(new Atom(minerName), new Atom("none"), new Atom("none"));
		else {
			getObsProperty("best_gold").updateValues(new Atom(minerName), golds.get(bestGold).x, golds.get(bestGold).y);
			// apagar bestGold
			golds.remove(bestGold);
		}

	}

	void getGoldInMap(String minerName, int x, int y) {

		int bestDistance = Integer.MAX_VALUE;
		int bestGold = -1;
		Location ml = new Location(x, y);

		for (int i = 0; i < golds.size(); i++) {

			int distance = golds.get(i).distance(ml);

			if (distance < bestDistance) {
				bestDistance = distance;
				bestGold = i;
			}
		}

		getObsProperty("best_gold").updateValues(new Atom(minerName), golds.get(bestGold).x, golds.get(bestGold).y);
		// apagar bestGold
		golds.remove(bestGold);

	}
}
