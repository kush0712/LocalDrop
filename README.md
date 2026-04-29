# P2P File Sharing System

A **distributed Peer-to-Peer file sharing web application** built with Java Servlets, JSP, JDBC, and MySQL — deployed on Apache Tomcat.

## 🚀 Features

- **File Upload & Download** — supports files up to 500 MB via buffered streaming (8 KB chunks)
- **Peer Management** — tracks connected peers with IP address, port, status, and join time
- **Transfer Lifecycle Engine** — records each session with status transitions: `IN_PROGRESS → COMPLETED / FAILED`
- **Download Analytics** — tracks download count per file
- **File Search** — search shared files by name
- **Soft Delete** — files are deactivated (not hard deleted) for audit integrity
- **Real-time Stats Dashboard** — total files, peers, and transfers on the home page

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Backend | Java 17, Jakarta Servlet 6.0, JSP 3.1 |
| Database | MySQL 8, JDBC (PreparedStatements) |
| Build | Maven 3, WAR packaging |
| Server | Apache Tomcat 10.1 |
| Frontend | JSP, JSTL 3.0 |

## 📁 Project Structure

```
src/
├── main/
│   ├── java/com/p2pshare/
│   │   ├── MainServlet.java    # Central request dispatcher (upload, download, peers, transfers)
│   │   ├── Database.java       # JDBC data access layer
│   │   └── Models.java         # POJOs: Peer, SharedFile, Transfer
│   ├── webapp/
│   │   ├── WEB-INF/views/      # JSP pages (index, files, upload, peers, transfers, error)
│   │   └── css/                # Stylesheets
│   └── resources/
│       └── logback.xml
db/
└── schema.sql                  # Database schema
pom.xml
```

## 🗄️ Database Schema

Three core tables:
- **`peers`** — peer nodes with IP, port, status
- **`shared_files`** — file metadata (name, size, type, hash, download count)
- **`transfers`** — per-session logs with file size, bytes transferred, status, timestamps

## ⚙️ Setup & Run

### Prerequisites
- Java 17+
- Maven 3.8+
- MySQL 8.0+
- Apache Tomcat 10.1

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-username>/p2p-fileshare.git
   cd p2p-fileshare
   ```

2. **Set up the database**
   ```bash
   mysql -u root -p < db/schema.sql
   ```

3. **Configure DB credentials** in `Database.java` (line 14):
   ```java
   DriverManager.getConnection("jdbc:mysql://localhost:3306/p2p_fileshare", "root", "yourpassword");
   ```

4. **Build the WAR**
   ```bash
   mvn clean package
   ```

5. **Deploy** `target/p2p-fileshare.war` to Tomcat's `webapps/` directory and start Tomcat.

6. **Access** the app at: `http://localhost:8080/p2p-fileshare`

## 📸 Key Design Decisions

- **Buffered I/O** — files are streamed in 8 KB chunks to avoid loading large payloads into heap memory
- **PreparedStatements** — all queries parameterized to prevent SQL injection
- **Transfer logging** — every upload/download creates a transfer record, enabling audit trails
- **Soft deletes** — `is_active = 0` instead of `DELETE`, preserving referential integrity

## 📄 License

MIT License — free to use for educational purposes.
