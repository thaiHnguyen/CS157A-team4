package fittrack.model;

public class ClassType {
    private final int classTypeId;
    private final String title;

    public ClassType(int classTypeId, String title) {
        this.classTypeId = classTypeId;
        this.title = title;
    }

    public int getClassTypeId() { return classTypeId; }
    public String getTitle()    { return title; }
}
