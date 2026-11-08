package fittrack.model;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * A member's membership as the dashboard shows it: one Membership row plus
 * its MembershipTier.TierName and the days left until EndDate
 */
public class Membership {
    private int membershipId;
    private int memberId;
    private String tierName;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;              // ACTIVE, EXPIRED, or CANCELLED
    private int daysLeft;               // DATEDIFF(EndDate, CURDATE())
    private int tierId;
    private BigDecimal totalPaid;       // SUM(Payment.Amount) for this membership

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

    public int getTierId(){
        return tierId;
    }
    public void setTierId(int v){
        tierId = v;
    }
    public BigDecimal getTotalPaid(){
        return totalPaid;
    }
    public void setTotalPaid(BigDecimal v){
        totalPaid = v;
    }

    // ACTIVE but StartDate is after today: a renewal waiting to start
    public boolean isUpcoming(){
        return "ACTIVE".equals(status) && startDate.isAfter(LocalDate.now());
    }

    // What the history table shows. A row still marked ACTIVE whose EndDate passed shows EXPIRED
    public String getDisplayStatus(){
        if (isUpcoming()) return "UPCOMING";
        if ("ACTIVE".equals(status) && endDate.isBefore(LocalDate.now())) return "EXPIRED";
        return status;
    }
}
