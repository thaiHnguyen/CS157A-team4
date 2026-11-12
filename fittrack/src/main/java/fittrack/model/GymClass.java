package fittrack.model;

import java.time.LocalDateTime;

/**
 * One scheduled class (the `Class` table) plus the columns the pages show
 * with it: ClassType.Title, the trainer's name, and the live BOOKED count
 * Called GymClass because java.lang.Class already uses the name
 */
public class GymClass {
    private int classId;
    private LocalDateTime startTime;
    private String title;
    private String trainerName; 
    private String roomNumber;
    private int capacity;
    private int booked;                 // BOOKED rows in Booking for this class
    private String myStatus;            // signed-in member's booking: BOOKED, CANCELLED, or null
    private LocalDateTime checkedInAt;  // signed-in member's check-in for this class, or null
    private String checkInState;        // NOT_YET, OPEN, or CLOSED (worked out by MySQL, see ClassDAO)

    // FR 1.1.7: members can check in for a class from 30 minutes before it
    // starts until 15 minutes after it starts
    public static final int CHECK_IN_OPENS_MINUTES_BEFORE = 30;
    public static final int CHECK_IN_CLOSES_MINUTES_AFTER = 15;

    public int getClassId() { 
        return classId; 
    }
    public void setClassId(int v) { 
        classId = v; }
    public LocalDateTime getStartTime() { 
        return startTime; 
    }
    public void setStartTime(LocalDateTime v){ 
        startTime = v; 
    }
    public String getTitle() { 
        return title; 
    }
    public void setTitle(String v){ 
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
    public void setRoomNumber(String v) { 
        roomNumber = v; 
    }
    public int getCapacity(){ 
        return capacity; 
    }
    public void setCapacity(int v) { 
        capacity = v; 
    }
    public int getBooked(){ 
        return booked; 
    }
    public void setBooked(int v){ 
        booked = v; 
    }
    public String getMyStatus() { 
        return myStatus; 
    }
    public void setMyStatus(String v){ 
        myStatus = v; 
    }

    // Capacity minus BOOKED rows; 0 or less means full
    public int getSpotsLeft(){ 
        return capacity - booked; 
    }

    // True if the signed-in member currently holds a spot
    public boolean isBookedByMe(){ 
        return "BOOKED".equals(myStatus); 
    }

    // True once the start time has passed
    public boolean hasStarted(){ 
        return !startTime.isAfter(LocalDateTime.now()); 
    }

    
    public LocalDateTime getCheckedInAt(){
        return checkedInAt;
    }
    public void setCheckedInAt(LocalDateTime v){
        checkedInAt = v;
    }

    // First moment a member can check in for this class
    public LocalDateTime getCheckInOpens(){
        return startTime.minusMinutes(CHECK_IN_OPENS_MINUTES_BEFORE);
    }

    // Last moment a member can check in for this class
    public LocalDateTime getCheckInCloses(){
        return startTime.plusMinutes(CHECK_IN_CLOSES_MINUTES_AFTER);
    }

    public String getCheckInState(){
        return checkInState;
    }
    public void setCheckInState(String v){
        checkInState = v;
    }

    // True if check-in for this class is open right now
    public boolean isCheckInOpen(){
        return "OPEN".equals(checkInState);
    }
}
