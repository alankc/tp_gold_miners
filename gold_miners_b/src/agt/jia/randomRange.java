// Internal action code for project gold_miners_b

package jia;

import java.util.Iterator;
import java.util.Random;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

public class randomRange extends DefaultInternalAction {

	private Random random = new Random();

	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
		try {
            if (!args[0].isVar()) {
                throw new JasonException("The first argument of the internal action 'random' is not a variable.");
            }
            if (!args[1].isNumeric()) {
                throw new JasonException("The second argument of the internal action 'random' is not a number.");
            }
            if (!args[2].isNumeric()) {
                throw new JasonException("The third argument of the internal action 'random' is not a number.");
            }
            final int min = (int)((NumberTerm)args[1]).solve();
            final int max = (int)((NumberTerm)args[2]).solve();

            final int maxIter = args.length < 4 ? Integer.MAX_VALUE : (int)((NumberTerm)args[3]).solve();

            return new Iterator<Unifier>() {
                int i = 0;

                // we always have a next random number
                public boolean hasNext() {
                    return i < maxIter && ts.getUserAgArch().isRunning();
                }

                public Unifier next() {
                    i++;
                    Unifier c = un.clone();
                    c.unifies(args[0], new NumberTermImpl(random.nextInt((max - min) + 1) + min));
                    return c;
                }

                public void remove() {}
            };

        } catch (ArrayIndexOutOfBoundsException e) {
            throw new JasonException("The internal action 'random' has not received the required argument.");
        } catch (Exception e) {
            throw new JasonException("Error in internal action 'random': " + e, e);
        }
	}
}
