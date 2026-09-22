<%--
  logout.jsp -- ends the session and returns to the landing page.
  invalidate() drops userId, role, and fullName in one call.
--%>
<%
    session.invalidate();
    response.sendRedirect(request.getContextPath() + "/index.jsp?loggedOut=1");
%>
