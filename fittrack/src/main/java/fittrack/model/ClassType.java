
package fittrack.model;

public class ClassType {

    private final int classTypeId;
    private final String title;
    private final String description;

    // Existing constructor: preserves compatibility
    public ClassType(int classTypeId, String title) {
        this(classTypeId, title, null);
    }

    // New constructor: includes description
    public ClassType(int classTypeId, String title, String description) {
        this.classTypeId = classTypeId;
        this.title = title;
        this.description = description;
    }

    public int getClassTypeId() {
        return classTypeId;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }
}
