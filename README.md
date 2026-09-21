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
└── fittrack/                     the Eclipse project
    └── src/main/webapp/
        ├── home.jsp              the home page
        └── WEB-INF/lib/
            └── mysql-connector-j-*.jar


## Stuff to Install
- JDK: your version that is comaptible with Tomcat 10.1
- MySQL Community Server: 8.0
- MySQL Workbench
- Tomcat: 10.1

## Steps
1. Setup database
    - Open MySQL Workbench and connect to your local server

    - First time: run on file

        + File -> Open SQL Script -> sql/01_setup.sql

        + Click the lightning bolt (execute all)

        + At the bottom, the first result grid lists eight tables. Every count should be greater than zero.
    
    - 01_setup.sql drops and rebuilds the fittrack database every time, so it is safe to re-run whenever your data gets messy. It touches nothing else on your MySQL server.

    - Next time run order:

        + If want to setup from nothing -> 01_setup.sql

        + Same thing, in two step -> 02_schema.sql then 03_seed.sql

        + Reset sample data, keep tables -> run only 03_seed.sql

        + 01_setup contains same statement as 02 and 03 combined

        + If you want to change sample data, change both 01 and 03

2. Import to Eclipse
    - Clone our repo

    - In Eclipse: File -> Import -> General -> Existing Projects into Workspace

    - Select root directory -> choose fittrack folder inside the clone, finish

3. Register Tomcat 10.1
    - As shown in homework 1, but choose your directory that you have installed tomcat 10.1

4. Rember to set your MySQL Password 
    - Open fittrack/src/main/webapp/home.jsp and change this line to your own MySQL root password:

        ```String password = "CHANGE_ME"```
    
5. Start a Server
    - As shown in homework 1, but link should be:
        ```localhost:8080/fittrack/home.jsp```