package fittrack.model;

import java.time.LocalDate;

/**
 * A member's membership as the dashboard shows it: one Membership row plus
 * its MembershipTier.TierName and the days left until EndDate.
 */
public class Membership {
    private int membershipId;
    private int memberId;
    private String tierName;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;              // ACTIVE, EXPIRED, or CANCELLED
    private int daysLeft;               // DATEDIFF(EndDate, CURDATE())

    public int getMembershipId(){ 
        return membershipId; 
    }
    public void setMembershipId(int v){ 
        membershipId = v; 
    }
    public int getMemberId(){ 
        return memberId; 
    }
    public void setMemberId(int v){ 
        memberId = v; 
    }
    public String getTierName(){ 
        return tierName; 
    }
    public void setTierName(String v){ 
        tierName = v; 
    }
    public LocalDate getStartDate(){ 
        return startDate; 
    }
    public void setStartDate(LocalDate v) { 
        startDate = v; 
    }
    public LocalDate getEndDate() { 
        return endDate; 
    }
    public void setEndDate(LocalDate v){ 
        endDate = v; 
    }
    public String getStatus() { 
        return status; 
    }
    public void setStatus(String v) { 
        status = v; 
    }
    public int getDaysLeft(){ 
        return daysLeft; 
    }
    public void setDaysLeft(int v){ 
        daysLeft = v; 
    }
}
