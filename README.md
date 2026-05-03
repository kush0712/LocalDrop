# LocalDrop — LAN File Sharing System

A **centralised Local Area Network (LAN) file sharing web application** built with Java Servlets, JSP, JDBC, and MySQL — deployed on Apache Tomcat.

The server acts as a **tracker-style hub**: it stores files on disk, tracks metadata in MySQL, and serves any device on the same local Wi-Fi network. Peers simply open the server's IP address in a browser — no client software required.

---

## 🚀 Features

| Feature | Detail |
|---|---|
| **LAN File Sharing** | Any device on the same Wi-Fi can browse, upload, and download |
| **File Upload & Download** | Supports up to **500 MB** per file via buffered 8 KB streaming |
| **SHA-256 Integrity Check** | Every upload is checksummed on-the-fly; hash stored in the database |
| **File Search** | Server-side `LIKE` search across all shared file names |
| **Transfer Lifecycle Engine** | Full status machine: `IN_PROGRESS → COMPLETED / FAILED / CANCELLED` |
| **Transfer Cancellation** | In-progress transfers can be cancelled from the Transfers page |
| **Download Analytics** | Per-file download counter, incremented on each successful download |
| **Real-time Stats Dashboard** | Overview of active files, active transfers, and total storage used |
| **LAN URL Display** | Dashboard auto-detects the server's local IP and displays a shareable link |
| **Dashboard Auto-refresh** | Dashboard polls and reloads every 30 seconds for live stats |
| **Persistent Uploads** | Files are saved to `~/LANShare_Uploads` — survives Tomcat restarts |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Backend | Java 17, Jakarta Servlet 6.0, JSP 3.1 |
| Connection Pool | HikariCP 5.1 |
| Database | MySQL 8, JDBC (PreparedStatements) |
| Build | Maven 3, WAR packaging |
| Server | Apache Tomcat 10.1 |
| Frontend | JSP, JSTL 3.0 (GlassFish impl 3.0.1) |
| Logging | Logback (SLF4J) |

---

## 📁 Project Structure

```
src/
├── main/
│   ├── java/com/p2pshare/
│   │   ├── MainServlet.java    # Central request dispatcher (upload, download, transfers, delete, cancel)
│   │   ├── Database.java       # JDBC data-access layer backed by HikariCP connection pool
│   │   └── Models.java         # POJOs: SharedFile, Transfer (with formatting helpers)
│   ├── webapp/
│   │   ├── WEB-INF/
│   │   │   ├── web.xml         # Jakarta EE 6.0 deployment descriptor (error pages, session config)
│   │   │   └── views/          # JSP pages: index, files, upload, transfers, error
│   │   ├── css/                # Stylesheet(s)
│   │   └── index.jsp           # Entry-point redirect
│   └── resources/
│       ├── db.properties       # ⚠ Gitignored — must be created manually (see Setup)
│       └── logback.xml         # Logback configuration
db/
└── schema.sql                  # Database schema + useful SQL views
pom.xml
```

---

## 🗄️ Database Schema

Two core tables (defined in `db/schema.sql`):

**`shared_files`** — file metadata

| Column | Type | Notes |
|---|---|---|
| `file_id` | `BIGINT` PK | Auto-increment |
| `filename` | `VARCHAR(255)` | Stored name (timestamp-prefixed) |
| `original_name` | `VARCHAR(500)` | User-visible name |
| `file_size` | `BIGINT` | Bytes |
| `file_type` | `VARCHAR(100)` | MIME type |
| `file_hash` | `VARCHAR(64)` | SHA-256 hex digest |
| `upload_time` | `TIMESTAMP` | Default `CURRENT_TIMESTAMP` |
| `download_count` | `INT` | Incremented on each download |
| `is_active` | `TINYINT(1)` | Soft-delete flag |

**`transfers`** — per-session audit log

| Column | Type | Notes |
|---|---|---|
| `transfer_id` | `BIGINT` PK | Auto-increment |
| `file_id` | `BIGINT` FK | References `shared_files` |
| `transfer_type` | `ENUM` | `UPLOAD` or `DOWNLOAD` |
| `status` | `ENUM` | `PENDING → IN_PROGRESS → COMPLETED / FAILED / CANCELLED` |
| `start_time` / `end_time` | `TIMESTAMP` | Session duration |
| `file_size` / `bytes_transferred` | `BIGINT` | Progress tracking |
| `error_message` | `TEXT` | Populated on failure |

Two SQL views are also created: `v_active_files` and `v_transfer_stats`.

---

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

3. **Create `src/main/resources/db.properties`**

   > ⚠️ This file is in `.gitignore` and is **not** included in the repository. You must create it manually.

   ```properties
   db.url=jdbc:mysql://127.0.0.1:3306/p2p_fileshare?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
   db.username=root
   # Leave blank or override via the DB_PASSWORD environment variable
   db.password=yourpassword
   ```

4. **Build the WAR**
   ```bash
   mvn clean package
   ```

5. **Deploy** `target/p2p-fileshare.war` to Tomcat's `webapps/` directory and start Tomcat.

6. **Access** the app at: `http://localhost:8080/p2p-fileshare`

   The dashboard will display the machine's local IP address (e.g. `http://192.168.x.x:8080/p2p-fileshare`) that other devices on the same Wi-Fi can use to connect.

---

## 📡 URL Routes

| Method | Path | Description |
|---|---|---|
| GET | `/` or `/index` | Dashboard (stats, recent files & transfers) |
| GET | `/files` | File browser (with optional `?search=` query) |
| GET | `/upload` | Upload form |
| POST | `/upload` | Process file upload |
| GET | `/download?id=` | Stream file download |
| POST | `/files/delete` | Soft-delete a file |
| GET | `/transfers` | Transfer log (HTML) |
| GET | `/transfers?format=json` | Transfer log (JSON — used by live polling) |
| POST | `/transfers/cancel` | Cancel an in-progress transfer |

---

## 📸 Key Design Decisions

- **Buffered I/O** — Files are streamed in 8 KB chunks during both upload and download, avoiding loading large payloads into heap memory. Supports up to 500 MB per request.
- **Single-pass SHA-256** — The file hash is computed during the upload stream, with no extra read pass required.
- **HikariCP connection pool** — A pool of up to 10 connections is maintained to handle concurrent requests efficiently.
- **PreparedStatements** — All SQL queries are parameterised to prevent SQL injection.
- **Soft deletes** — `is_active = 0` instead of `DELETE`, preserving referential integrity with the transfer log.
- **Persistent upload directory** — Files are stored in `~/LANShare_Uploads` (outside the Tomcat `webapps/` directory), so they survive WAR redeployments and server restarts.
- **Transfer logging** — Every upload and download creates a transfer record, enabling a full audit trail with duration and status.
- **LAN IP auto-detection** — The server enumerates network interfaces at request time to return the active IPv4 LAN address, skipping loopback and virtual adapters.

---

## 📄 License

MIT License — free to use for educational purposes.
