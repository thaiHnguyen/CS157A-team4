package fittrack.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * One row of UserAccount. Members, trainers, and staff all have one
 */
public class UserAccount {
    private int userId;
    private String email;
    private String passwordHash;        // "salt$hash", see common.jspf
    private String role;                // MEMBER, TRAINER, or STAFF
    private String name;
    private String phone;
    private LocalDate dateOfBirth;
    private LocalDateTime createdAt;

    public int getUserId() { 
        return userId; 
    }
    public void setUserId(int v) { 
        userId = v; 
    }

    public String getEmail(){ 
        return email; 
    }
    public void setEmail(String v) {
        email = v; 
    }
    public String getPasswordHash() {
        return passwordHash; 
    }
    public void setPasswordHash(String v) { 
        passwordHash = v; 
    }
    public String getRole() { 
        return role; 
    }
    public void setRole(String v) { 
        role = v; 
    }
    public String getName()  { 
        return name; 
    }
    public void setName(String v) { 
        name = v; 
    }
    public String getPhone(){
        return phone; 
    }
    public void setPhone(String v) { 
        phone = v; 
    }
    public LocalDate getDateOfBirth() { 
        return dateOfBirth; 
    }
    public void setDateOfBirth(LocalDate v){ 
        dateOfBirth = v; 
    }
    public LocalDateTime getCreatedAt()  { 
        return createdAt; 
    }
    public void setCreatedAt(LocalDateTime v) { 
        createdAt = v; 
    }
}
