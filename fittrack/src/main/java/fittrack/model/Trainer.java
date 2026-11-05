package fittrack.model;

/** A trainer (Trainer row + the name from UserAccount), e.g. for the schedule filter. */
public class Trainer {
    private final int userId;
    private final String name;

    public Trainer(int userId, String name) {
        this.userId = userId;
        this.name = name;
    }

    public int getUserId(){ 
        return userId; 
    }
    public String getName() { 
        return name; 
    }
}
