float step = 5.0; // random walker step
//int maxCount = 25;
float  time_to_life = 1; // time to get to full life

// The Boid class

class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  int group, index;
  color groupColor;
  PVector target;
  float humanization;
  float life;
  boolean is_active;
  boolean is_fixed;
  float lifetime;

  Boid(float x, float y, int g, color c, PVector t) {
    acceleration = new PVector(0, 0);

    float angle = random(TWO_PI);
    velocity = new PVector(cos(angle), sin(angle));

    position = new PVector(x, y);

    r = 1.0;

    maxspeed = 3; // 0.3;
    maxforce = 0.1; // 0.008;

    group = g;
    groupColor = c;

    target = t;

    humanization = random(0.5, 1.5); // todo: keep humanization?
    humanization = 1;

    life = 1;
    is_active = true;

    is_fixed = false;
    
    lifetime = 1;
  }

  // overload contructor
  Boid(int group) {
    this(mouseX, mouseY, group, paletteGenerator(), new PVector(mouseX, mouseY));
  }


  void run(ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    flock(boids, dist); // compute force
    update();           // move boid
    borders();
    render(boids, dist);
  }

  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    PVector sep = separate(boids, dist);   // Separation
    PVector ali = align(boids, dist);      // Alignment
    PVector coh = cohesion(boids, dist);   // Cohesion
    PVector walk = walker();        // Target
    // Arbitrarily weight these forces
    sep.mult(1.5*humanization);
    ali.mult(1.0*humanization);
    coh.mult(2.0*humanization);
    walk.mult(3.0*humanization);
    // Add the force vectors to acceleration
    //applyForce(sep); // todo: maybe remove those behaviours
    //applyForce(ali);
    //applyForce(coh);
    applyForce(walk);
  }

  // Method to update position
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    position.add(velocity);
    // Reset accelertion to 0 each cycle
    acceleration.mult(0);

    if (is_active) {
      increase_life();
    } else {
      decrease_life();
    }
  }

  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED - VELOCITY
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);  // A vector pointing from the position to the target
    // Scale to maximum speed
    float d = desired.mag();
    desired.normalize();

    desired.mult(maxspeed);
    if ( d < 60 ) {
      // avoid overshoot: reduce the force when arriving near to the target
      desired.mult(pow(map(d, 0, 100, 0, 1), 1.2));
    }

    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }

  void render(ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    stroke(255, 255*life);
    fill(255, 255*life);
    int mul = 3;
    //if (group==0 && ( manual_control  || faceRecognitionActive )) { // cange appearance for the human point
    //  stroke(#ffcc00, 255*pow(life, 0.8));
    //  fill(#ffcc00, 255*pow(life, 0.8));
    //  mul = 6;
    //}
    ellipse(position.x, position.y, r*mul, r*mul);
    if (render_target>0) renderTarget();
    //print(position.x,position.y); // added for debugging
    int i, count = 0;
    float d, T=thresh; // todo: maybe reduce the threshold
    // distance for 0 to index
    for (i = 0; i < index; i++) {
      float other_life = boids.get(i).life;
      d = dist.get(index).get(i);
      if ((d > 0) && (d < T)) { // && (count < maxCount)
        stroke(255, 255*pow((T-d)/T, 0.8)*min(life, other_life));
        strokeWeight(1.5);
        line(position.x, position.y, boids.get(i).position.x, boids.get(i).position.y);
        count++;
      }
    }
    // distance for index to N
    // not necessary: it print double each line.. result is brighter lines (press x to toggle)
    if (double_draw) {
      for (i = boids.size()-1; i > index; i--) {
        d = dist.get(index).get(i);
        float other_life = boids.get(i).life;
        if ((d > 0) && (d < T)) { //  && (count < maxCount)
          stroke(255, 255*pow((T-d)/T, 0.8)*min(life, other_life));
          strokeWeight(1.5);
          line(position.x, position.y, boids.get(i).position.x, boids.get(i).position.y);
          count++;
        }
      }
    }
  }

  // overload function for dead boids rendering
  void render(ArrayList<Boid> all_boids, int i) {
    // circle
    stroke(255, 255*life);
    fill(255, 255*life);
    int mul = 3;
    ellipse(position.x, position.y, r*mul, r*mul);

    // connection lines
    float d, T=thresh;
    for (int j = i+1; j < all_boids.size(); j++) {
      float other_life = all_boids.get(j).life;
      d = PVector.dist(position, all_boids.get(j).position);
      if ((d > 0) && (d < T)) {
        stroke(255, 255*pow((T-d)/T, 0.8)*min(life, other_life));
        strokeWeight(1.5);
        line(position.x, position.y, all_boids.get(j).position.x, all_boids.get(j).position.y);
      }
    }
  }

  // for developing/debugging
  void renderTarget() {
    stroke(#ff0000, 255*pow(life, 1));
    fill(#ff0000, 255*life);
    strokeWeight(1.5);
    ellipse(target.x, target.y, r*2, r*2);
    if ( render_target == 2) {
      // kind of verbosity of the target printing
      line(position.x, position.y, target.x, target.y);
    }
  }

  // Wraparound
  //void borders() {
  //  if (position.x < -r) position.x = width+r;
  //  if (position.y < -r) position.y = height+r;
  //  if (position.x > width+r) position.x = -r;
  //  if (position.y > height+r) position.y = -r;
  //}

  //Reflect
  void borders() {
    if (position.x < -r*2) velocity.x = -velocity.x;
    if (position.y < -r*2) velocity.y = -velocity.y;
    if (position.x > width+r*2) velocity.x = -velocity.x;
    if (position.y > height+r*2) velocity.y = -velocity.y;
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    float desiredseparation = 30.0f, d;
    PVector steer = new PVector(0, 0, 0);
    int count = 0, i;
    // For every boid in the system, check if it's too close
    // distance for 0 to index
    for (i = 0; i < index; i++) {
      d = dist.get(index).get(i);
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(position, boids.get(i).position);
        diff.normalize();
        diff.div(pow(d, 2));        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // distance for index to N
    for (i = boids.size()-1; i > index; i--) {
      d = dist.get(index).get(i);
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(position, boids.get(i).position);
        diff.normalize();
        diff.div(pow(d, 2));        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    PVector sum = new PVector(0, 0);
    int count = 0, i;
    float d;
    // Check distance from other boids
    // distance for 0 to index
    for (i = 0; i < index; i++) {
      d = dist.get(index).get(i);
      if ((d > 0) && (group == boids.get(i).group)) {
        sum.add(boids.get(i).velocity);
        count++;
      }
    }
    // distance for index to N
    for (i = boids.size()-1; i > index; i--) {
      d = dist.get(index).get(i);
      if ((d > 0) && (group == boids.get(i).group)) {
        sum.add(boids.get(i).velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      // Implement Reynolds: Steering = Desired - Velocity
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average position (i.e. center) of all nearby boids, calculate steering vector towards that position
  PVector cohesion (ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all positions
    int count = 0, i;
    float d;
    // Check distance from other boids
    // distance for 0 to index
    for (i = 0; i < index; i++) {
      d = dist.get(index).get(i);
      if ((d > 0) && (group == boids.get(i).group)) {
        sum.add(boids.get(i).position);
        count++;
      }
    }
    // distance for index to N
    for (i = boids.size()-1; i > index; i--) {
      d = dist.get(index).get(i);
      if ((d > 0) && (group == boids.get(i).group)) {
        sum.add(boids.get(i).position);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the position
    } else {
      return new PVector(0, 0);
    }
  }

  // Target
  // For the group target position, calculate steering vector towards that position
  PVector walker() {
    if (!is_fixed && !multiObjectTrackingActive) {
      move_target();
    }
    PVector steer = seek(target);
    steer.normalize();
    steer.mult(maxspeed);
    steer.sub(velocity);
    steer.limit(maxforce);
    return steer;
  }

  // randomly move target
  void move_target() {
    target.x = target.x + random(-step, step);
    target.y = target.y + random(-step, step);
    if (target.x < -r*2) target.x = width+r*2;
    if (target.y < -r*2) target.y = height+r*2;
    if (target.x > width+r*2) target.x = -r*2;
    if (target.y > height+r*2) target.y = -r*2;
  }

  // overload the function to move target in desired position
  void set_target(float x, float y) {
    target.x = x;
    target.y = y;
  }
  void set_target(float[] xy) {
    target.x = xy[0];
    target.y = xy[1];
  }

  void decrease_life() {
    life = max(life - 1/frameRate/lifetime, 0); // if use this change deadBoids lifetime to 1
    //life = max(pow(life - 1/frameRate/lifetime, 1.02), 0); // deadBoids lifetime to 2
  }

  void increase_life() {
    life = min(1, pow(life + 1/frameRate/time_to_life, 1)); // power 1 linear increment
    //life = min(1, pow(life + 0.1, 1)); // todo remove: for debugging
  }
}
