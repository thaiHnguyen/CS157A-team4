package fittrack.model;

import java.time.LocalDateTime;

/**
 * One scheduled class (the `Class` table) plus the columns the pages show
 * with it: ClassType.Title, the trainer's name, and the live BOOKED count.
 * Called GymClass because java.lang.Class already uses the name.
 */
public class GymClass {
    private int classId;
    private LocalDateTime startTime;
    private String title;             
    private String trainerName;         
    private String roomNumber;
    private int capacity;
    private int booked;                
    private String myStatus;            // signed-in member's booking: BOOKED, CANCELLED, or null

    public int getClassId(){ 
        return classId; 
    }
    public void setClassId(int v) { classId = v; }
    public LocalDateTime getStartTime(){
        return startTime; 
    }
    public void setStartTime(LocalDateTime v)  {
        startTime = v;}
    public String getTitle() {
        return title; 
    }
    public void setTitle(String v) { 
        title = v; 
    }
    public String getTrainerName() { 
        return trainerName; 
    }
    public void setTrainerName(String v){ 
        trainerName = v; 
    }
    public String getRoomNumber() { 
        return roomNumber; 
    }
    public void setRoomNumber(String v){ 
        roomNumber = v; 
    }
    public int getCapacity(){ 
        return capacity; 
    }
    public void setCapacity(int v) { 
        capacity = v; 
    }
    public int getBooked() { 
        return booked; 
    }
    public void setBooked(int v) {
        booked = v; 
    }
    public String getMyStatus()  { 
        return myStatus;
    }
    public void setMyStatus(String v) {
        myStatus = v; 
    }

    // Capacity minus BOOKED rows; 0 or less means full
    public int getSpotsLeft() { 
        return capacity - booked; 
    }

    // True if the signed-in member currently holds a spot
    public boolean isBookedByMe(){ 
        return "BOOKED".equals(myStatus); 
    }

    // True once the start time has passed
    public boolean hasStarted() { 
        return !startTime.isAfter(LocalDateTime.now()); 
    }
}
