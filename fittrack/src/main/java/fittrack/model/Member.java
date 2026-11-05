package fittrack.model;

public class Member {
    private int userId;
    private String emergencyPhone;      

    public Member() { }

    public Member(int userId, String emergencyPhone) {
        this.userId = userId;
        this.emergencyPhone = emergencyPhone;
    }

    public int getUserId()                  {return userId;}
    public void setUserId(int v)            {userId = v;}
    public String getEmergencyPhone()       {return emergencyPhone;}
    public void setEmergencyPhone(String v) {emergencyPhone = v;}
}
