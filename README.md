# CS157AProject - Team 4

FitTrack: Gym Membership System

CS157A Fall 2026, Team 4
Wesley Kieu (lead), Thai Nguyen, Hari Sowmith Reddy Vedanaparthi. 
Instructor: Mike Wu.

A three-tier web application: the browser talks to a JSP running on Apache Tomcat 10, and the JSP reads from MySQL 8.0 over JDBC. The current milestone is the home page, which lists upcoming sessions with live remaining spots and the membership tiers.

## Database password in `.env` (branch `env-config`)
The MySQL password no longer lives in `common.jspf`. Each teammate keeps it in their own
`fittrack/src/main/webapp/WEB-INF/.env`, which git ignores.

- `WEB-INF/jspf/common.jspf`: `getConnection()` reads `DB_PASSWORD` (and optional `DB_USER`, `DB_URL`) from `WEB-INF/.env`. Shows a clear error if the file or the password is missing.
- `WEB-INF/.env.example`: template to copy. Committed, no real password.
- `.gitignore`: ignores `.env` everywhere, keeps `.env.example`.

Why `WEB-INF` and not the repo root: Tomcat runs a copy of the `webapp` folder, so a `.env` at the repo root would not be deployed. Files in `WEB-INF` are deployed with the app and can never be opened from the browser.

## Repository Structure

```text
CS157AProject/
├── .gitignore                    ignores .env (your password) and Eclipse/Tomcat files
├── sql/
│   ├── 01_setup.sql              first-time setup: database, tables, sample data
│   ├── 02_fittrack_schema.sql    tables only
│   └── 03_seed.sql               sample data only
└── fittrack/                     the web project
    └── src/main/webapp/
        ├── index.jsp             public landing page
        ├── login.jsp             FR 1.1.1 sign in (members, trainers, staff)
        ├── register.jsp          FR 1.1.1 member sign-up
        ├── home.jsp              dashboard after sign-in
        ├── profile.jsp           FR 1.1.2 update profile
        ├── schedule.jsp          FR 1.1.4 browse classes with filters
        ├── book.jsp              FR 1.1.5 book a class (no page, redirects back)
        ├── cancel.jsp            FR 1.1.6 cancel a booking (no page, redirects back)
        ├── logout.jsp
        ├── css/style.css
        ├── assets/img/
        └── WEB-INF/
            ├── .env.example      template for your DB settings (copy to .env)
            ├── .env              YOUR DB user + password, not committed (you create it)
            ├── jspf/common.jspf  DB connection + shared helpers
            ├── jspf/topbar.jspf  navigation bar
            └── lib/mysql-connector-j-*.jar
```

# After you pull this branch
- Re-run sql/01_setup.sql once. Old databases still have plain-text passwords and nobody will be able to log in.

- Set your MySQL password in `WEB-INF/.env` (see "Set your MySQL password" below).

- Republish / restart Tomcat

## Stuff to Install
- JDK: your version that is comaptible with Tomcat 10.1
- MySQL Community Server: 8.0
- MySQL Workbench
- Tomcat: 10.1

## Steps
### Setup database
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
    + As shown in homework 1, but choose your directory that you have installed tomcat 10- Set your MySQL password (once, in a `.env` file)
    + Go to `fittrack/src/main/webapp/WEB-INF/`
    + Copy `.env.example` and name the copy `.env` (same folder)
    + Open `.env` and put your own MySQL root password after `DB_PASSWORD=`

```bash
DB_USER=root
DB_PASSWORD=your_mysql_password_here
```

- `common.jspf` reads this file every time a page connects to MySQL, so you never edit Java code for your password.

- `.env` is in `.gitignore`, so **your password is never committed**. Only `.env.example` (no real password) is on GitHub. `git status` should never list `.env`.

- If a page says `WEB-INF/.env not found`, the file is missing or in the wrong folder (it must be next to `.env.example`, inside `WEB-INF`). In VS Code, run Publish Server (Full) after creating it.

- If a page says `Access denied for user 'root'`, the password in `.env` is wrong.

### Start a Server - Eclipse: as shown in homework 1. VS Code: right-click Tomcat -> Publish Server (Full) after any change.

- Open ```localhost:8080/fittrack/``` (in VS Code the name may be the deployment name, e.g. `localhost:8080/webapp/`)