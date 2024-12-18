float lifetime = 2;
color[] colors  = {
  #f5ec42,
  #f58d42,
  #ed0505,
  #05eda7,
  #0520ed,
  #d605ed 
};

class Executor {

  int current_state; // boid index
  PVector position;
  int number;
  boolean isActive;
  float life;
  Boid boid;


  Executor(int number) {
    this.number = number;
    life = 1;
  }

  void render() {
    // print executor
    stroke(colors[number], life*255);
    //stroke(#00ff00, 255); // for static green
    fill(255, 0);
    strokeWeight(6);
    //ellipse(flock.boids.get(current_state).position.x, flock.boids.get(current_state).position.y, 10, 10);
    //ellipse(boid.position.x, boid.position.y, 10*(number+1), 10*(number+1));
    ellipse(boid.position.x, boid.position.y, (1-life)*30+3,(1-life)*30+3);
    stroke(colors[number], 255);
    strokeWeight(4);
    ellipse(boid.position.x, boid.position.y, 4, 4);
    strokeWeight(4);
    decrease_life();
  }

  void decrease_life() {
    life = max(life - 1/frameRate/lifetime, 0); // if use this change deadBoids lifetime to 1
  }
  
  public void maxLife(){
    life = 1;
  }
}
