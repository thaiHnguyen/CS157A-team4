package fittrack.model;

import java.time.LocalDateTime;

/**
 * One row of Booking, plus the class title and start time from the joined
 * Class / ClassType rows (the booking and cancel messages need them).
 */
public class Booking {
    private int bookingId;
    private int memberId;
    private int classId;
    private String status;              // BOOKED or CANCELLED
    private String classTitle;
    private LocalDateTime classStart;

    public int getBookingId(){ 
        return bookingId; 
    }
    public void setBookingId(int v) { 
        bookingId = v; 
    }
    public int getMemberId(){ 
        return memberId; 
    }
    public void setMemberId(int v){ 
        memberId = v; 
    }
    public int getClassId() { 
        return classId; 
    }
    public void setClassId(int v){ 
        classId = v; 
    }
    public String getStatus(){ 
        return status; 
    }
    public void setStatus(String v){ 
        status = v; 
    }
    public String getClassTitle(){ 
        return classTitle; 
    }
    public void setClassTitle(String v){ 
        classTitle = v; 
    }
    public LocalDateTime getClassStart(){ 
        return classStart; 
    }
    public void setClassStart(LocalDateTime v) { 
        classStart = v; 
    }

    public boolean isBooked(){ 
        return "BOOKED".equals(status); 
    }
    public boolean isCancelled(){ 
        return "CANCELLED".equals(status); 
    }
}
