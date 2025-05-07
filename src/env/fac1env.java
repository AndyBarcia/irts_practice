// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com

// Note this is a very limited environment just for experimenting

import jason.asSyntax.*;

import jason.environment.*;

import jason.asSyntax.parser.*;



import java.util.logging.*;

import java.util.Random;
import java.util.Arrays;


import java.awt.Dimension;
import java.awt.BorderLayout;
import java.awt.Canvas;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics;

import javax.swing.*;
import java.awt.*;

import javax.swing.JFrame;


public class fac1env extends Environment {



	public static final int bins = 6; // number of bins
	public static final int parts = 6; // number of parts
	public static final int holders = 6; // number of holders
	public static final int joints = 5; // number of joints
	public static final int lockareas = 2; // number of sub-assembly areas for locking

	public static final int[] partLengths = new int[]{ 55,410,452,256,275,167 };
	public static final int[][] holderPositions = new int[][]{ {910,210},{757,183},{785,270},{500,309},{422,309},{449,448} };
	public static final int[] armPosition = new int[] {600, 613};	
	public static final int[] welderRobotPosition = new int[] {1000, 70};
	public static final int[] moverRobotPosition = new int[] {300, 70};		
	public static final int[][] binPositions = new int[][]{{270,538},{270,568},{270,598},{270,628},{270,658},{270,688}};
	public static final int[][] jointPositions = new int[][]{{914,194},{501,197},{534,460},{501,215},{358,459}};
	public static final int[][] partPositions = new int[][]{{917,198,344},{705,194,90},{727,328,55},{515,327,352},{428,335,30},{445,458,90}};

	
    private Logger logger = Logger.getLogger("factory1.mas2j."+fac1env.class.getName());



    private FactoryModel model;
    private FactoryView  view;
	
    /** Called before the MAS execution with the args informed in .mas2j */

    @Override

    public void init(String[] args) {

        super.init(args);

		
		model = new FactoryModel();
        view  = new FactoryView(model);
        model.setView(view);
        updatePercepts();
	
    }



    @Override

    public boolean executeAction(String ag, Structure action) {


        // logger.info("executing: "+action+" on behalf of "+ag+"!");
		
		try {
	    	if (action.getFunctor().equals("pick_part")) {
                int x = (int)((NumberTerm)action.getTerm(0)).solve();
                model.pickPart(ag,x);
	    	} else if (action.getFunctor().equals("refill_bin")) {
                int x = (int)((NumberTerm)action.getTerm(0)).solve();
                model.refillBin(x);
	    	} else if (action.equals(Literal.parseLiteral("release_part"))) {
                model.releasePart(ag);
	    	} else if (action.getFunctor().equals("hold_part")) {
                int x = (int)((NumberTerm)action.getTerm(0)).solve();
                model.holdPart(x);
	    	} else if (action.getFunctor().equals("lock_area")) {
                int x = (int)((NumberTerm)action.getTerm(0)).solve();
                model.lockArea(x);
	    	} else if (action.getFunctor().equals("unlock_area")) {
                int x = (int)((NumberTerm)action.getTerm(0)).solve();
                model.unlockArea(x);
	    	} else if (action.getFunctor().equals("unhold_part")) {
                int x = (int)((NumberTerm)action.getTerm(0)).solve();
                model.unholdPart(x);
			} else if (action.getFunctor().equals("move_towards")) {
            	int x = (int)((NumberTerm)action.getTerm(0)).solve();
                int y = (int)((NumberTerm)action.getTerm(1)).solve();
				int z = (int)((NumberTerm)action.getTerm(2)).solve();
                model.moveTowards(ag,x,y,z);
	    	} else if (action.equals(Literal.parseLiteral("weld"))) {
                model.weld();
			}
        } catch (Exception e) {
            e.printStackTrace();
        }

		updatePercepts();
		/*
        try {
            Thread.sleep(100);
        } catch (Exception e) {}
		*/
        informAgsEnvironmentChanged();

		
        return true; // the action was executed with success

    }



    /*
    * LOOK HERE to see how the percepts change in the environment
    */
    synchronized void updatePercepts() {
		
		// make sure all environment constants are available as percepts
		addPercept(Literal.parseLiteral("bins("+Integer.toString(bins)+")"));
		addPercept(Literal.parseLiteral("parts("+Integer.toString(parts)+")"));
		addPercept(Literal.parseLiteral("holders("+Integer.toString(holders)+")"));
		addPercept(Literal.parseLiteral("joints("+Integer.toString(joints)+")"));
		addPercept(Literal.parseLiteral("armPosition("+Integer.toString(armPosition[0])+","+Integer.toString(armPosition[1])+")"));
		addPercept(Literal.parseLiteral("welderRobotPosition("+Integer.toString(welderRobotPosition[0])+","+Integer.toString(welderRobotPosition[1])+")"));
		for (int i=0; i<parts; i++) {
			addPercept(Literal.parseLiteral("partLength("+Integer.toString(i+1)+","+Integer.toString(partLengths[i])+")"));
			addPercept(Literal.parseLiteral("holderPosition("+Integer.toString(i+1)+","+Integer.toString(holderPositions[i][0])+","+Integer.toString(holderPositions[i][1])+")"));
			addPercept(Literal.parseLiteral("partPosition("+Integer.toString(i+1)+","+Integer.toString(partPositions[i][0])+","+Integer.toString(partPositions[i][1])+","+Integer.toString(partPositions[i][2])+")"));
			addPercept(Literal.parseLiteral("binPosition("+Integer.toString(i+1)+","+Integer.toString(binPositions[i][0])+","+Integer.toString(binPositions[i][1])+")"));
		}
		for (int i=0; i<joints; i++) {
			addPercept(Literal.parseLiteral("jointPosition("+Integer.toString(i+1)+","+Integer.toString(jointPositions[i][0])+","+Integer.toString(jointPositions[i][1])+")"));
		}
		for (int i=0; i<bins; i++) {
			Literal percept = Literal.parseLiteral("binfull("+Integer.toString(i+1)+")");
			if (model.binfull[i]) {
				addPercept(percept);
			} else {
				removePercept(percept);
			}
		}
		
	
		// Update gripper percept
		Literal newGripperPercept = Literal.parseLiteral("gripper("+Integer.toString(model.gripperPosition[0])+","+Integer.toString(model.gripperPosition[1])+","+Integer.toString(model.gripperAngle)+")");
		if (newGripperPercept != model.gripperPercept) {
			removePercept(model.gripperPercept);
			model.gripperPercept = newGripperPercept;
			addPercept(model.gripperPercept);
		}

		// Update welder percept
		Literal newWelderPercept = Literal.parseLiteral("welder("+Integer.toString(model.welderPosition[0])+","+Integer.toString(model.welderPosition[1])+")");
		if (newWelderPercept != model.welderPercept) {
			removePercept(model.welderPercept);
			model.welderPercept = newWelderPercept;
			addPercept(model.welderPercept);
		}

		// Update mover percept
		Literal newMoverPercept = Literal.parseLiteral("mover("+Integer.toString(model.moverPosition[0])+","+Integer.toString(model.moverPosition[1])+")");
		if (newMoverPercept != model.moverPercept) {
			removePercept(model.moverPercept);
			model.moverPercept = newMoverPercept;
			addPercept(model.moverPercept);
		}
		
    }

    class FactoryModel {
        
		public Boolean[] binfull = new Boolean[bins];
		public int gripperPart = -1;    // gripper does not hold anything
		public int gripperAngle = 90;   // initial gripper angle
		public boolean welding = false; // welder not in action
		public boolean moving = false;  // mover not holding a frame
		public Boolean[] holding  = new Boolean[bins];
		public Boolean[] joint  = new Boolean[joints];
		public Boolean[] lockArea  = new Boolean[lockareas];
		public int[] gripperPosition = new int[] {270, 613, 90};
		public int[] welderPosition = new int[] {1000, 470};
		public int[] moverPosition = new int[] {500, 70};
		public Literal gripperPercept = Literal.parseLiteral("gripper(270,613,90)");
		public Literal welderPercept = Literal.parseLiteral("welder(1000,470)");
		public Literal moverPercept = Literal.parseLiteral("mover(500,70)");
				
        Random random = new Random(System.currentTimeMillis());

        private FactoryModel() {
            Arrays.fill(binfull, Boolean.FALSE);
			Arrays.fill(holding, Boolean.FALSE);
			Arrays.fill(joint, Boolean.FALSE);
			Arrays.fill(lockArea, Boolean.FALSE);
        }
		
		public boolean holding() {
			for (int i = 0; i<holders; i++) if (holding[i]) return true;
			return false;
		}
        
        void pickPart(String ag, int partnum) {
			if (ag.equals("movingagent") && 
			    moverPosition[0] == partPositions[3][0] &&
			    moverPosition[1] == partPositions[3][1]) {
				moving = true;
			} else if (ag.equals("roboticarmagent") && 
			           gripperPosition[0] == binPositions[partnum-1][0] &&
					   gripperPosition[1] == binPositions[partnum-1][1]) {
				gripperPart = partnum;
				binfull[partnum-1] = false;
			}
        }
		
        void weld() {
			for (int i=0; i<joints; i++) {
				if (welderPosition[0] == jointPositions[i][0] &&
			     	welderPosition[1] == jointPositions[i][1]) {
						logger.info("Welding");
					welding = true;
					try { Thread.sleep(5000); } catch (Exception e) {}
					joint[i] = true;
					welding = false;
				}
			}
		}

        void releasePart(String ag) {
			if (ag.equals("roboticarmagent")) { 
				gripperPart = -1;
			} else if (ag.equals("movingagent")) {
				moving = false;
				Arrays.fill(joint, Boolean.FALSE);
			}
        }
		
        void moveTowards(String ag, int x, int y, int z) {
			
			if (ag.equals("roboticarmagent")) {
				if (gripperPosition[0] > x) {
					gripperPosition[0] = Math.max(x, gripperPosition[0]-5);
				} else {
					gripperPosition[0] = Math.min(x, gripperPosition[0]+5);
				}
				if (gripperPosition[1] > y) {
					gripperPosition[1] = Math.max(y, gripperPosition[1]-5);
				} else {
					gripperPosition[1] = Math.min(y, gripperPosition[1]+5);
				}
				if (gripperAngle > z || gripperAngle+360-z < 180) {
					gripperAngle -= 1;
					if (gripperAngle < 0) { gripperAngle = 359; };
				} else {
					gripperAngle += 1;
				}
			}
		
			if (ag.equals("weldingagent")) {
				if (welderPosition[0] > x) {
					welderPosition[0] = Math.max(x, welderPosition[0]-5);
				} else {
					welderPosition[0] = Math.min(x, welderPosition[0]+5);
				}
				if (welderPosition[1] > y) {
					welderPosition[1] = Math.max(y, welderPosition[1]-5);
				} else {
					welderPosition[1] = Math.min(y, welderPosition[1]+5);
				}
			}
			
			if (ag.equals("movingagent")) {
				if (moverPosition[0] > x) {
					moverPosition[0] = Math.max(x, moverPosition[0]-5);
				} else {
					moverPosition[0] = Math.min(x, moverPosition[0]+5);
				}
				if (moverPosition[1] > y) {
					moverPosition[1] = Math.max(y, moverPosition[1]-5);
				} else {
					moverPosition[1] = Math.min(y, moverPosition[1]+5);
				}
			}
			
			try {
            	Thread.sleep(10);
        	} catch (Exception e) {}
			
        }

        void refillBin(int x) {
			binfull[x-1] = true;
			logger.info("executing refill!");
        }
		
        void lockArea(int area) {
			lockArea[area-1] = true;
        }

        void unlockArea(int area) {
			lockArea[area-1] = false;
        }
		
        void holdPart(int partnum) {
			holding[partnum-1] = true;
        }

        void unholdPart(int partnum) {
			holding[partnum-1] = false;
        }
		
		public void setView(FactoryView v) {
			view = v;
		}
		

    }
    
    class FactoryView extends JFrame {

		JFrame frame = new JFrame("Assembly Factory");


        public FactoryView(FactoryModel model) {
			JFrame frame = new JFrame("Assembly Factory");
			
      	    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.setSize(1080, 750);
			frame.setLocationRelativeTo(null);
			frame.add(new FactoryCanvas());
			frame.setVisible(true);
		}

    }    

	class FactoryCanvas extends JComponent {

		private int lastX = 0;

		public FactoryCanvas() {
			Thread animationThread = new Thread(new Runnable() {
				public void run() {
					while (true) {
						repaint();
						try {Thread.sleep(30);} catch (Exception ex) {}
					}
				}
			});
			animationThread.start();
		}
		
		private void paintPart(Graphics2D gg, int partnum, int rotation, int x, int y) {
			double radians = Math.toRadians(90-rotation); 
			int x1 = (int) (Math.cos(radians)*partLengths[partnum-1]/2);
			int y1 = (int) (Math.sin(radians)*partLengths[partnum-1]/2);
			gg.setColor(Color.BLACK);
			gg.setStroke(new BasicStroke(5));
			gg.drawLine(x, y, x+x1, y-y1);	
			gg.drawLine(x, y, x-x1, y+y1);	
		}
		
		private void paintJoints(Graphics2D gg, int x, int y) {
			for (int i=0; i<joints; i++) {
				gg.setColor(Color.BLACK);
				if (model.joint[i]) {
					gg.fillOval(x+jointPositions[i][0]-10,y+jointPositions[i][1]-10, 20,20);
				}
			}
		}
		
		private void paintFrame(Graphics2D gg, int x, int y) {
			for (int partnum=1; partnum<=parts; partnum++) {
				paintPart(gg, partnum, partPositions[partnum-1][2], partPositions[partnum-1][0]+x,partPositions[partnum-1][1]+y);
			}
			paintJoints(gg, x, y);
		}

		public void paintComponent(Graphics g) {
			Graphics2D gg = (Graphics2D) g;
			Random random = new Random(System.currentTimeMillis());

			gg.setFont(new Font("Serif", Font.PLAIN, 12));
			
			// Paint assembly areas 
			gg.setColor(Color.lightGray);
			if (!model.lockArea[0]) {
				gg.drawRect(350,150,350,350);	
			} else {
				gg.fillRect(350,150,350,350);
			}
			
			if (!model.lockArea[1]) {
				gg.drawRect(705,150,250,350);	
			} else {
				gg.fillRect(705,150,250,350);
			}
			
			// Paint bin status
			for (int i=1; i<=bins; i++) {
     			gg.setColor(Color.lightGray);
				gg.setStroke(new BasicStroke(2));
				gg.fillRect(5,495+i*30, 500, 25);	
				gg.setColor(Color.BLACK);
				gg.setFont(new Font("SansSerif", Font.PLAIN, 12));
				gg.drawString("Bin "+Integer.toString(i), 10,510+i*30);
				if (model.binfull[i-1]) paintPart(gg, i, 90, binPositions[i-1][0], binPositions[i-1][1]);
			}
			
			// Paint holder status
			for (int i=0; i<parts; i++) {
				gg.setColor(Color.BLACK);
				gg.drawString("Holder "+Integer.toString(i+1), holderPositions[i][0]+15,holderPositions[i][1]);
				if (model.holding[i]) {
					paintPart(gg, i+1, partPositions[i][2], partPositions[i][0],partPositions[i][1]);
					gg.setColor(Color.RED);
				} else {
					gg.setColor(Color.GREEN);
				}
				gg.fillOval(holderPositions[i][0],holderPositions[i][1], 25,25);
			}
			
			// Paint joints
			if (model.holding()) paintJoints(gg, 0, 0);
			
			// Paint robotic arm
			gg.setColor(Color.BLUE);
			gg.drawString("Robotic Arm",armPosition[0]+30, armPosition[1]);
			gg.setStroke(new BasicStroke(15));
			gg.drawLine(armPosition[0], armPosition[1], model.gripperPosition[0], model.gripperPosition[1]);
			gg.drawLine(armPosition[0]-50, armPosition[1]-50, armPosition[0]+50, armPosition[1]+50);
			gg.drawLine(armPosition[0]-50, armPosition[1]+50, armPosition[0]+50, armPosition[1]-50);
			gg.fillOval(armPosition[0]-20, armPosition[1]-20, 40, 40);
			gg.setColor(Color.WHITE);
			gg.setStroke(new BasicStroke(5));
			gg.drawLine(armPosition[0], armPosition[1], model.gripperPosition[0], model.gripperPosition[1]);
			if (model.gripperPart < 0) {
				gg.setColor(Color.BLUE);
			} else {
				paintPart(gg, model.gripperPart, model.gripperAngle, model.gripperPosition[0],model.gripperPosition[1]);
				gg.setColor(Color.RED);
			}
			gg.fillOval(model.gripperPosition[0]-12,model.gripperPosition[1]-12, 24,24);
				
			// Paint welder robot
			if (model.welding) {
				if (random.nextBoolean()) {
					gg.setColor(Color.orange);
					gg.fillOval(model.welderPosition[0]-22,model.welderPosition[1]-22, 44,44);
				}
				gg.setColor(Color.RED);
				gg.fillOval(model.welderPosition[0]-14,model.welderPosition[1]-14, 28,28);
			} else {
				gg.setColor(Color.BLUE);
				gg.fillOval(model.welderPosition[0]-14,model.welderPosition[1]-14, 28,28);
			}
			gg.setColor(Color.BLUE);
			gg.drawString("Welding Bot",welderRobotPosition[0]-150, welderRobotPosition[1]);
			gg.setStroke(new BasicStroke(15));
			gg.drawLine(welderRobotPosition[0], welderRobotPosition[1], model.welderPosition[0], model.welderPosition[1]);
			gg.drawLine(welderRobotPosition[0]-50, welderRobotPosition[1]-50, welderRobotPosition[0]+50, welderRobotPosition[1]+50);
			gg.drawLine(welderRobotPosition[0]-50, welderRobotPosition[1]+50, welderRobotPosition[0]+50, welderRobotPosition[1]-50);
			gg.fillOval(welderRobotPosition[0]-20, welderRobotPosition[1]-20, 40, 40);
			gg.setColor(Color.WHITE);
			gg.setStroke(new BasicStroke(5));
			gg.drawLine(welderRobotPosition[0], welderRobotPosition[1], model.welderPosition[0], model.welderPosition[1]);			

			// Paint moving robot 
			if (model.moving) {
				paintFrame(gg, model.moverPosition[0]-partPositions[3][0], model.moverPosition[1]-partPositions[3][1]);
				gg.setColor(Color.RED);
				gg.fillOval(model.moverPosition[0]-14,model.moverPosition[1]-14, 28,28);
			} else {
				gg.setColor(Color.BLUE);
				gg.fillOval(model.moverPosition[0]-14,model.moverPosition[1]-14, 28,28);
			}
			gg.setColor(Color.BLUE);
			gg.drawString("Moving Bot",moverRobotPosition[0]-30, moverRobotPosition[1]+55);
			gg.setStroke(new BasicStroke(15));
			gg.drawLine(moverRobotPosition[0], moverRobotPosition[1], model.moverPosition[0], model.moverPosition[1]);
			gg.drawLine(moverRobotPosition[0]-50, moverRobotPosition[1]-50, moverRobotPosition[0]+50, moverRobotPosition[1]+50);
			gg.drawLine(moverRobotPosition[0]-50, moverRobotPosition[1]+50, moverRobotPosition[0]+50, moverRobotPosition[1]-50);
			gg.fillOval(moverRobotPosition[0]-20, moverRobotPosition[1]-20, 40, 40);
			gg.setColor(Color.WHITE);
			gg.setStroke(new BasicStroke(5));
			gg.drawLine(moverRobotPosition[0], moverRobotPosition[1], model.moverPosition[0], model.moverPosition[1]);			
		}
		
	}
	
    /** Called before the end of MAS execution */

    @Override

    public void stop() {

        super.stop();

    }

}


