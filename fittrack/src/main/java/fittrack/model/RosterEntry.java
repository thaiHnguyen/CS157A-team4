package fittrack.model;

import java.time.LocalDateTime;

/** One member booked into a class, for the trainer's roster (FR 1.2.1). */
public class RosterEntry {
    private int memberId;
    private String name;
    private String email;
    private String phone;
    private LocalDateTime bookedAt;

    public int getMemberId() { return memberId; }
    public void setMemberId(int v) { memberId = v; }
    public String getName() { return name; }
    public void setName(String v) { name = v; }
    public String getEmail() { return email; }
    public void setEmail(String v) { email = v; }
    public String getPhone() { return phone; }
    public void setPhone(String v) { phone = v; }
    public LocalDateTime getBookedAt() { return bookedAt; }
    public void setBookedAt(LocalDateTime v) { bookedAt = v; }
}