package fittrack.model;

import java.math.BigDecimal;

// One row of MembershipTier (Basic, Silver, Gold, ...). Fee is what one
// purchase or renewal of this tier costs (Payment.Amount).
public class MembershipTier {
    private int tierId;
    private String tierName;
    private int tierLevel;
    private BigDecimal fee;
    private String description;

    public int getTierId(){
        return tierId;
    }
    public void setTierId(int v){
        tierId = v;
    }
    public String getTierName(){
        return tierName;
    }
    public void setTierName(String v){
        tierName = v;
    }
    public int getTierLevel(){
        return tierLevel;
    }
    public void setTierLevel(int v){
        tierLevel = v;
    }
    public BigDecimal getFee(){
        return fee;
    }
    public void setFee(BigDecimal v){
        fee = v;
    }
    public String getDescription(){
        return description;
    }
    public void setDescription(String v){
        description = v;
    }
}
