// contains information about connected boids (cluster)
class Cluster {

  int group_number;
  ArrayList<Integer> boids_indexes;

  Cluster (int group_number) {
    this.group_number = group_number;
    boids_indexes = new ArrayList<Integer>();
  }
  
  int get_random_index(){
    return boids_indexes.get(int(random(-0.5, boids_indexes.size()-0.5)));
  }

  String toString() {
    String text = "group " + group_number + ": ";
    //for(int i : boids_indexes)
    text += boids_indexes.toString();
    return text;
  }
  
}
