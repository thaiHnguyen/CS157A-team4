<%--
    membership.jsp - FR 1.1.3 View and Renew Membership
    A member sees their current plan, picks a tier and a payment method, and
    buys or renews a membership. The form posts back to this page

    Renewing runs in one transaction:
        1. lock the member's row (MemberDAO.lockById) so two clicks at the same
            time cannot both create a membership with the same dates
        2. StartDate = the day after the member's latest ACTIVE membership ends
            (MembershipDAO.findLatestActiveEndDate), or today if they have none,
            and EndDate = one year after StartDate
        3. INSERT the Membership (Status ACTIVE)              MembershipDAO.insert
        4. INSERT its Payment: Amount = the tier's Fee,
            PaymentNo = next number for that membership        PaymentDAO.nextPaymentNo / insert
    Staff selling memberships at the front desk is FR 3.3.1, not this one
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }
    if (!isMember) {                            // only members hold memberships
        response.sendRedirect(ctx + "/home.jsp");
        return;
    }

    // Payment methods a member can use online. CASH is for the front desk.
    String[][] METHODS = { {"CARD", "Card"}, {"ONLINE", "Online (PayPal, bank transfer)"} };

    List<String> errors = new ArrayList<>();
    Integer tierId = toInt(param(request, "tierId"));
    String method = param(request, "method");

    // ---- renew / buy ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        boolean knownMethod = false;
        for (String[] m : METHODS) if (m[0].equals(method)) knownMethod = true;
        if (tierId == null) errors.add("Choose a membership plan.");
        if (!knownMethod)   errors.add("Choose a payment method.");

        if (errors.isEmpty()) {
            Connection con = null;
            try {
                con = getConnection();
                con.setAutoCommit(false);

                // 1. lock first, so every read below sees the latest committed rows
                new MemberDAO(con).lockById(userId);

                MembershipTier tier = new MembershipTierDAO(con).findById(tierId);
                if (tier == null) {
                    errors.add("That membership plan does not exist.");
                    con.rollback();
                } else {
                    // 2. dates: start after the current membership, or today
                    MembershipDAO memberships = new MembershipDAO(con);
                    LocalDate latestEnd = memberships.findLatestActiveEndDate(userId);
                    LocalDate start = latestEnd == null ? LocalDate.now() : latestEnd.plusDays(1);
                    LocalDate end = start.plusYears(1);

                    // 3. the membership
                    int membershipId = memberships.insert(userId, tier.getTierId(), start, end);

                    // 4. its payment
                    PaymentDAO payments = new PaymentDAO(con);
                    Payment pay = new Payment();
                    pay.setMembershipId(membershipId);
                    pay.setPaymentNo(payments.nextPaymentNo(membershipId));
                    pay.setAmount(tier.getFee());
                    pay.setMethod(method);
                    payments.insert(pay);

                    con.commit();
                    String dates = start.equals(LocalDate.now())
                        ? "It is active now, until " + day(end) + "."
                        : "It starts " + day(start) + ", right after your current one, and runs until " + day(end) + ".";
                    session.setAttribute("flash", "ok:Paid " + money(tier.getFee()) + " for "
                        + tier.getTierName() + ". " + dates);
                    response.sendRedirect(ctx + "/membership.jsp");
                    return;
                }
            } catch (Exception e) {
                rollback(con);
                errors.add("Could not complete the purchase: " + e.getMessage());
            } finally {
                close(con);
            }
        }
    }

    // load the page data
    Membership active = null;
    List<MembershipTier> tiers = new ArrayList<>();
    List<Membership> history = new ArrayList<>();
    List<Payment> paymentList = new ArrayList<>();
    LocalDate nextStart = LocalDate.now();
    String loadError = null;

    Connection con = null;
    try {
        con = getConnection();
        MembershipDAO memberships = new MembershipDAO(con);
        active = memberships.findActive(userId);
        LocalDate latestEnd = memberships.findLatestActiveEndDate(userId);
        if (latestEnd != null) nextStart = latestEnd.plusDays(1);
        history = memberships.findAllForMember(userId);
        tiers = new MembershipTierDAO(con).findAll();
        paymentList = new PaymentDAO(con).findByMember(userId);
    } catch (Exception e) {
        loadError = "Could not load your membership: " + e.getMessage();
    } finally {
        close(con);
    }

    Membership upcoming = null;  // a renewal already paid for
     // list is newest first, so this keeps the earliest
    for (Membership m : history) if (m.isUpcoming()) upcoming = m;  
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Membership - FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>
<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="wrap">
    <main>
        <h1 class="page-title">Your membership</h1>
    <% if (loadError != null) { %>
        <p class="error"><%= esc(loadError) %></p>
    <% } else { %>

        <%-- current plan --%>
        <% if (active != null) { %>
        <div class="status-card ok">
            <div>
                <div class="muted small">Current plan</div>
                <div class="big"><%= esc(active.getTierName()) %></div>
                <div class="muted">Active until <%= day(active.getEndDate()) %>
                    (<%= active.getDaysLeft() %> days left)</div>
                <% if (upcoming != null) { %>
                <div class="muted">Next: <%= esc(upcoming.getTierName()) %>, <%= day(upcoming.getStartDate()) %>
                    to <%= day(upcoming.getEndDate()) %></div>
                <% } %>
            </div>
        </div>
        <% } else { %>
        <div class="status-card none">
            <div>
                <div class="muted small">Current plan</div>
                <div class="big">No active membership</div>
                <div class="muted">You need one to book classes.</div>
                <% if (upcoming != null) { %>
                <div class="muted">Starting soon: <%= esc(upcoming.getTierName()) %>, <%= day(upcoming.getStartDate()) %>
                    to <%= day(upcoming.getEndDate()) %></div>
                <% } %>
            </div>
        </div>
        <% } %>

        <%-- renew / buy --%>
        <h2><%= active != null || upcoming != null ? "Renew your membership" : "Buy a membership" %></h2>
        <p class="note">
            Your new membership will run from <strong><%= day(nextStart) %></strong>
            to <strong><%= day(nextStart.plusYears(1)) %></strong> (one year).
            <% if (!nextStart.equals(LocalDate.now())) { %>It starts the day after your current one ends, so you don't lose any days.<% } %>
        </p>

        <% if (!errors.isEmpty()) { %>
            <div class="error">
                <% for (String err : errors) { %><div><%= esc(err) %></div><% } %>
            </div>
        <% } %>

        <form method="post" action="<%= ctx %>/membership.jsp">
            <table>
                <tr><th></th><th>Plan</th><th>Level</th><th>Includes</th><th>Price</th></tr>
            <%
                for (MembershipTier t : tiers) {
                    boolean picked = Integer.valueOf(t.getTierId()).equals(tierId);
            %>
                <tr>
                    <td><input type="radio" id="tier<%= t.getTierId() %>" name="tierId"
                                value="<%= t.getTierId() %>" <%= picked ? "checked" : "" %> required></td>
                    <td><label class="inline" for="tier<%= t.getTierId() %>"><strong><%= esc(t.getTierName()) %></strong></label></td>
                    <td><%= t.getTierLevel() %></td>
                    <td><%= esc(t.getDescription()) %></td>
                    <td class="nowrap"><%= money(t.getFee()) %></td>
                </tr>
            <%
                }
            %>
            </table>

            <div class="filters" style="margin-top: 20px;">
                <div>
                    <label for="method">Payment method</label>
                    <select id="method" name="method" required>
                        <option value="">Choose...</option>
                    <% for (String[] m : METHODS) { %>
                        <option value="<%= m[0] %>" <%= m[0].equals(method) ? "selected" : "" %>><%= esc(m[1]) %></option>
                    <% } %>
                    </select>
                </div>
            </div>
            <div class="filter-actions">
                <button class="btn" type="submit">Pay and <%= active != null || upcoming != null ? "renew" : "buy" %></button>
            </div>
        </form>

        <%-- history --%>
        <h2>Membership history</h2>
        <table>
            <tr><th>Plan</th><th>Start</th><th>End</th><th>Status</th><th>Paid</th></tr>
        <% for (Membership m : history) { %>
            <tr>
                <td><%= esc(m.getTierName()) %></td>
                <td class="nowrap"><%= day(m.getStartDate()) %></td>
                <td class="nowrap"><%= day(m.getEndDate()) %></td>
                <td><%= esc(m.getDisplayStatus().charAt(0) + m.getDisplayStatus().substring(1).toLowerCase()) %></td>
                <td class="nowrap"><%= money(m.getTotalPaid()) %></td>
            </tr>
        <% } %>
        <% if (history.isEmpty()) { %>
            <tr><td colspan="5" class="muted">No memberships yet.</td></tr>
        <% } %>
        </table>

        <h2>Payments</h2>
        <table>
            <tr><th>Date</th><th>Plan</th><th>Payment #</th><th>Method</th><th>Amount</th></tr>
        <% for (Payment p : paymentList) { %>
            <tr>
                <td class="nowrap"><%= when(p.getPayDate()) %></td>
                <td><%= esc(p.getTierName()) %></td>
                <td><%= p.getPaymentNo() %></td>
                <td><%= esc(p.getMethod().charAt(0) + p.getMethod().substring(1).toLowerCase()) %></td>
                <td class="nowrap"><%= money(p.getAmount()) %></td>
            </tr>
        <% } %>
        <% if (paymentList.isEmpty()) { %>
            <tr><td colspan="5" class="muted">No payments yet.</td></tr>
        <% } %>
        </table>
    <% } %>
    </main>
    </div>

</body>

</html>
