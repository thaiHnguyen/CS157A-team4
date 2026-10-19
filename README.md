# CS157AProject - Team 4

FitTrack: Gym Membership System

CS157A Fall 2026, Team 4
Wesley Kieu (lead), Thai Nguyen, Hari Sowmith Reddy Vedanaparthi. 
Instructor: Mike Wu.

A three-tier web application: the browser talks to a JSP running on Apache Tomcat 10, and the JSP reads from MySQL 8.0 over JDBC. The current milestone is the home page, which lists upcoming sessions with live remaining spots and the membership tiers.

## Repository Structure

CS157AProject/
├── sql/
│   ├── 01_setup.sql              first-time setup: database, tables, sample data
│   ├── 02_fittrack_schema.sql    tables only
│   └── 03_seed.sql               sample data only
└── fittrack/                     the web project
    └── src/main/webapp/
        ├── index.jsp             public landing page
        ├── login.jsp             FR 3.1.1 sign in (members, trainers, staff)
        ├── register.jsp          FR 3.1.1 member sign-up
        ├── home.jsp              dashboard after sign-in
        ├── logout.jsp
        ├── css/style.css
        └── WEB-INF/
            ├── jspf/common.jspf  DB settings + shared helpers
            ├── jspf/topbar.jspf  navigation bar
            └── lib/mysql-connector-j-*.jar
            
## What changed in the Login branch (FR 3.1.1 Register and Login)

This branch implements FR 3.1.1 Register and Login from the proposal and updates the pages it touches so they work with the current ERD schema. No other FRs are included yet.

# New Files:
- `register.jsp`: Member sign-up form. Inserts a UserAccount row (Role = MEMBER) and a linked Member row in one transaction, then signs the new member in.

- `WEB-INF/jspf/common.jspf`: Shared code included by every page: the MySQL settings (the only place the password lives now), password hashing, HTML escaping, input helpers, and the session values (userId, role, fullName).

- `WEB-INF/jspf/topbar.jspf`: Shared navigation bar and one-time success/error message. Shows Sign in / Join when signed out, Dashboard / Log out when signed in.

# Updated Files
- `login.jsp`: Checks the password against a salted hash instead of plain text. Uses the shared header. Same error message for a wrong email or a wrong password, so the form does not reveal which emails exist. Creates a new session id after login. Demo hint now lists real seed accounts.

- `home.jsp`:	Rewritten for the current schema (Class, ClassType, Booking, Membership). The old version queried Schedule / SessionBooking, which no longer exist, and had its own copy of the DB password. Members see their membership status and upcoming bookings; everyone sees the next five classes with live spots left.

- `index.jsp`: Uses the shared header. Adds a Become a member button.

- `css/style.css`: Update Styling	

- `sql/01_setup.sql`, `sql/03_seed.sql`: New UPDATE right after the UserAccount insert that hashes every demo password. Both files stay identical in their seed section. Works with Workbench safe-update mode.

# After you pull this branch
- Re-run sql/01_setup.sql once. Old databases still have plain-text passwords and nobody will be able to log in.

- Set your MySQL password in WEB-INF/jspf/common.jspf (no longer in home.jsp).

- Republish / restart Tomcat

## Stuff to Install
- JDK: your version that is comaptible with Tomcat 10.1
- MySQL Community Server: 8.0
- MySQL Workbench
- Tomcat: 10.1

## Steps
1. Setup database
- Open MySQL Workbench and connect to your local server

- First time: run one file
    + File -> Open SQL Script -> sql/01_setup.sql
    + Click the lightning bolt (execute all)
    + At the bottom, the first result grid lists the tables. Every count should be greater than zero.

- 01_setup.sql drops and rebuilds the fittrack database every time, so it is safe to re-run whenever your data gets messy. It touches nothing else on your MySQL server.

- Next time run order:
    + If want to setup from nothing -> 01_setup.sql
    + Same thing, in two steps -> 02_fittrack_schema.sql then 03_seed.sql
    + Reset sample data, keep tables -> run only 03_seed.sql

- Open the project
    + Clone our repo
    + Eclipse: File -> Import -> General -> Existing Projects into Workspace, then choose the fittrack folder inside the clone
    + VS Code (Community Server Connector): right-click Tomcat -> Add Deployment -> Exploded -> select fittrack/src/main/webapp, leave the assembly file blank

- Register Tomcat 10.1
    + As shown in homework 1, but choose your directory that you have installed tomcat 10.1

- Remember to set your MySQL password
    + Open fittrack/src/main/webapp/WEB-INF/jspf/common.jspf and change this line to your own MySQL root password:

```bash 
static final String DB_PASSWORD = "CHANGE_ME";
```

- Every page includes this file, so this is the only place to change it.

- **Do not commit your real password.** Change it back to `CHANGE_ME` before committing.

5. Start a Server - Eclipse: as shown in homework 1. VS Code: right-click Tomcat -> Publish Server (Full) after any change.

- Open ```localhost:8080/fittrack/``` (in VS Code the name may be the deployment name, e.g. `localhost:8080/webapp/`)