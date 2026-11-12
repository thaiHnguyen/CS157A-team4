package fittrack.model;

import java.time.LocalDateTime;

// One row of Attendance: a member checking in at the gym
// classId is null for a plain gym visit, or the class they checked in for
// classTitle / classStart come from the joined Class / ClassType rows
// (null for a normal visit)
public class Attendance {
    private int attendanceId;
    private int memberId;
    private Integer classId;
    private LocalDateTime checkInTime;
    private String classTitle;
    private LocalDateTime classStart;

    public int getAttendanceId(){
        return attendanceId;
    }
    public void setAttendanceId(int v){
        attendanceId = v;
    }
    public int getMemberId(){
        return memberId;
    }
    public void setMemberId(int v){
        memberId = v;
    }
    public Integer getClassId(){
        return classId;
    }
    public void setClassId(Integer v){
        classId = v;
    }
    public LocalDateTime getCheckInTime(){
        return checkInTime;
    }
    public void setCheckInTime(LocalDateTime v){
        checkInTime = v;
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
    public void setClassStart(LocalDateTime v){
        classStart = v;
    }

    // True for a plain gym visit (no class booked)
    public boolean isGymVisit(){
        return classId == null;
    }
}
