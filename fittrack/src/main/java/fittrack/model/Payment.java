package fittrack.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// One row of Payment, a weak entity owned by Membership

// Key = (MembershipId, PaymentNo); PaymentNo counts 1, 2, 3, ... per membership
// tierName comes from the joined Membership/MembershipTier, for the history table
public class Payment {
    private int membershipId;
    private int paymentNo;
    private BigDecimal amount;
    private LocalDateTime payDate;
    private String method;           // CARD, CASH, or ONLINE
    private String tierName;

    public int getMembershipId(){
        return membershipId;
    }
    public void setMembershipId(int v){
        membershipId = v;
    }
    public int getPaymentNo(){
        return paymentNo;
    }
    public void setPaymentNo(int v){
        paymentNo = v;
    }
    public BigDecimal getAmount(){
        return amount;
    }
    public void setAmount(BigDecimal v){
        amount = v;
    }
    public LocalDateTime getPayDate(){
        return payDate;
    }
    public void setPayDate(LocalDateTime v){
        payDate = v;
    }
    public String getMethod(){
        return method;
    }
    public void setMethod(String v){
        method = v;
    }
    public String getTierName(){
        return tierName;
    }
    public void setTierName(String v){
        tierName = v;
    }
}
