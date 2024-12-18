import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;
PostFX fx;

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

int group, count;
Flock flock;

// osc receive
float face_x, face_y;
boolean faceRecognitionActive = false;
boolean multiObjectTrackingActive = false;
boolean manual_control = false;
boolean double_draw = false;
boolean screen_print = true;
int render_target = 0;

// moving boids playing 60 bpm: simulate pure data /clock message
boolean clock_active = false;
boolean internal_clock = true;
boolean executor_visualization = true;
int timer = 0 ;

int max_number_executors = 4;

float thresh = 250.0;

void setup() {
  size(1280, 720, P2D);
  //size(1920, 1080, P2D);
  //fullScreen(P2D);
  fx = new PostFX(this);
  fx.preload(BloomPass.class);
  fx.preload(BlurPass.class);

  flock = new Flock();
  float x, y;

  color c;
  PVector t;
  for (group = 0; group < 4; group++) {
    x = random(50, width-50);
    y = random(50, height-50);
    c = paletteGenerator();
    //count = poisson(4);
    count = 1;
    for (int i = 0; i < count; i++) {
      t = new PVector(random(0, width), random(0, height));
      flock.addBoid(new Boid(x+random(-45, 45), y+random(-45, 45), group, c, t));
    }
  }

  oscP5 = new OscP5(this, 3000);  // incoming osc messages OSC PORT = 3000
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);
}

void draw() {
  background(0);
  colorMode(RGB, 255);
  flock.run();

  fx.render().bloom(0.1, 100, 10).compose();

  if ( internal_clock && clock_active && (millis() - timer >= 1000)) {
    for ( int i = 0; i < flock.executors.size(); i++) {
      if ( flock.playing_executors.contains(i) ) oscP5.send(flock.computeMarkovMsg(i), myRemoteLocation);
    }
    timer = millis();
  }
}

// Add a new boid into the System
void mousePressed() {
  if (mouseButton == LEFT) {
    int count = poisson(4);
    //int count = 1;
    color c = paletteGenerator();
    float x = mouseX;
    float y = mouseY;
    PVector t;
    for (int i = 0; i < count; i++) {
      t = new PVector(random(0, width), random(0, height));
      flock.addBoid(new Boid(x+random(-50, 50), y+random(-50, 50), group, c, t));
    }
    print(flock.boids.size()+"\n");
    group++;
  } else { // RIGHT button
    // restart
    // throw away all boids and create only one
    flock = new Flock();
    group = 0;
    color c = paletteGenerator();
    PVector t;
    t = new PVector(random(0, width), random(0, height));
    //flock.addBoid(new Boid(mouseX, mouseY, group, c, t));
    //group++;
    clock_active = false;
    faceRecognitionActive = false;
    manual_control = false;
    multiObjectTrackingActive = false;
    flock.clear_executors();
  }
}

void keyPressed() {
  switch(key) {
  case 'x':
    double_draw = !double_draw;
    break;
  case 'z': // kill a specific boid
    int index = flock.find_closest_boid(new PVector(mouseX, mouseY));
    if (index > -1) {
      flock.addDeadBoid(flock.boids.get(index).position);
      flock.removeBoid(index);
    }
    if ( N == 0 ) flock.clear_executors();
    break;
  case 'm': // manual control (drag boid)
    index = flock.find_closest_boid(new PVector(mouseX, mouseY));
    if (index > -1) {
      flock.manual_boid_group = index;
      manual_control = !manual_control;
    }
    break;
  case 'r':
    flock.randomize();
    break;
  case 't':
    render_target = (render_target + 1) % 3;
    break;
  case 'd':
    flock.addDeadBoid(new PVector(mouseX, mouseY));
    break;
  case 'p':
    print("\n\n");
    if ( flock.boids.size() > 0) {
      print("\nflocksize: ", flock.boids.size());
      print("\nmax force: ", flock.boids.get(0).maxforce);
      print("\nmaxspeed:  ", flock.boids.get(0).maxspeed);
    } else {
      print("empyty flock");
    }
    print("\npaying_executors:  ", flock.playing_executors);
    print("\npaused_executors:  ", flock.paused_executors);
    print("\nmanual  :  ", manual_control);
    print("\nframerate: ", frameRate);
    print("\n");
    //looping = !looping; // (un)freeze the execution
    delay(1000);
    break;
  case 'f':
    group = max(200, group+1); // just set an offset to avoid interference with other boids 
    Boid b = new Boid(group);
    b.is_fixed = true;
    flock.addBoid(b);
    break;
  case 'c':
    //if (flock.paused_executors.size() > 0 ) {
    //  flock.playing_executors.add(0, flock.paused_executors.remove(0));
    //  //executors.get(playing_executors.get(0)).current_state = clusters.get(playing_executors.get(0)).get_random_index();
    //  flock.executors.get(flock.playing_executors.get(0)).boid = flock.boids.get(flock.clusters.get(flock.playing_executors.get(0)).get_random_index());
    //}
    clock_active = !clock_active;
    break;
  case 'v':
    executor_visualization = !executor_visualization;
    break;
  case 'e':
    flock.add_executor();
    //if (flock.paused_executors.size() > 0 && N > 0) {
    //  flock.playing_executors.add(flock.playing_executors.size(), flock.paused_executors.remove(0));
    //  flock.executors.get(flock.playing_executors.get(flock.playing_executors.size()-1)).boid = flock.boids.get( flock.clusters.get(flock.clusters.size()-1).get_random_index() );
    //}
    break;
  case 'k': // kill all
    synchronized(flock) {
      flock.clear_executors();
      for (int i = flock.boids.size()-1; i>=0; i--) {
        flock.addDeadBoid(flock.boids.get(i).position);
        flock.removeBoid(i);
      }
    }
    break;
  case 'h':
    thresh += 30;
    break;
  case 'g':
    thresh = max( thresh-30, 50);
    break;
  case 'i':
    screen_print = ! screen_print;
    break;
  }


  // keys that need iteration for each boids
  for (Boid b : flock.boids) {
    switch(key) {
    case 'w':
      b.maxspeed = flock.boids.get(0).maxspeed+0.25;
      break;
    case 'q':
      b.maxspeed = flock.boids.get(0).maxspeed-0.25;
      break;
    case 'a':
      b.maxforce = flock.boids.get(0).maxforce-0.008 * 0.3;
      break;
    case 's':
      b.maxforce = flock.boids.get(0).maxforce+0.008 * 0.3;
      break;
    }
  }
}

color paletteGenerator() {
  colorMode(HSB, 100);  // Use HSB with scale of 0-100
  color randomColor = color(int(random(0, 100)), 100, 100);
  colorMode(RGB, 255);

  return randomColor;
}

int poisson(int mean) {

  double L = exp(-mean);
  int k=0;
  double p = random(0, 1);

  while (p > L) {
    p = p * random(0, 1);
    k++;
  } 

  return k+1;
}


void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/position")==true) {
    faceRecognitionActive = true;
    int python_webcam_dimension = 300;
    face_x = width-theOscMessage.get(0).floatValue()/python_webcam_dimension*width;
    face_y = theOscMessage.get(1).floatValue()/python_webcam_dimension*height;
    print("osc message from python", face_x, face_y);
  }

  if (theOscMessage.checkAddrPattern("/multi_tracker_off")==true) {
    multiObjectTrackingActive = false;
    print("multi obj track off");
  }

  if (theOscMessage.checkAddrPattern("/active_tracks")==true) {
    try {
      multiObjectTrackingActive = true;

      int n_tracks = theOscMessage.get(0).intValue();
      ArrayList<Integer> groups_list = new ArrayList<Integer>();
      ArrayList<Boolean> is_new_id = new ArrayList<Boolean>();
      ArrayList<float[]> xy_list = new ArrayList<float[]>();


      for (int i=0; i < n_tracks; i++) {
        //print(i);
        groups_list.add(theOscMessage.get(i*4+1).intValue() + 1);  // note: this + 1 offset allows to have group 0 boids that 
        //allow implementation of fade out effect of dead detected track ids  
        is_new_id.add(theOscMessage.get(i*4+2).intValue()==1);
        float[] xy = {theOscMessage.get(i*4+3).floatValue() * width, theOscMessage.get(i*4+4).floatValue() * height};
        xy_list.add(xy);
        //print(groups_list.get(groups_list.size()));
        //print(is_new_id.get(is_new_id.size()));
        //print(xy_list.get(xy_list.size()));
      }
      // eventyually convert to array, but list is more convenient
      //Integer[] groups = new Integer[groups_list.size()];
      //groups = groups_list.toArray(groups);

      flock.move_targets(groups_list, xy_list, is_new_id);
    } 
    catch(Exception e) {
      println("ERROR");
      e.printStackTrace();
    }
  }

  if (theOscMessage.checkAddrPattern("/clock")==true) {
    int currentState = theOscMessage.get(0).intValue();
    print("osc message from SC, current state: ", currentState);

    OscMessage MarkovMsg = new OscMessage("/markov");
    //OscMessage BPMMsg = new OscMessage("/BPM");
    flock.computeMarkovMsg(MarkovMsg, currentState);

    oscP5.send(MarkovMsg, myRemoteLocation);

    MarkovMsg.print();
    print("\n");
  }

  // clock from puredata
  for ( int i = 0; i < max_number_executors; i++) {
    if (theOscMessage.checkAddrPattern("/new_clock" + i)==true) {
      internal_clock = false; // stop internal metronome
      // send message iif the executor is playing
      if ( flock.playing_executors.contains(i) ) oscP5.send(flock.computeMarkovMsg(i), myRemoteLocation);
    }
  }
}
