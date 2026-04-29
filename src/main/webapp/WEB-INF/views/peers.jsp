<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta name="description" content="Manage peers in the P2P network"/>
    <title>Peer Network — P2PShare</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>

<nav class="navbar">
    <a href="${pageContext.request.contextPath}/" class="navbar-brand">
        <span class="nav-logo">⚡</span>
        <span class="nav-title">P2P<span>Share</span></span>
    </a>
    <ul class="navbar-nav">
        <li><a href="${pageContext.request.contextPath}/"          class="nav-link">🏠 Dashboard</a></li>
        <li><a href="${pageContext.request.contextPath}/files"     class="nav-link">📁 Files</a></li>
        <li><a href="${pageContext.request.contextPath}/upload"    class="nav-link">⬆️ Upload</a></li>
        <li><a href="${pageContext.request.contextPath}/peers"     class="nav-link active">🌐 Peers</a></li>
        <li><a href="${pageContext.request.contextPath}/transfers" class="nav-link">↔️ Transfers</a></li>
    </ul>
</nav>

<main class="container">
    <div class="page-header">
        <h1 class="page-title">Peer Network</h1>
        <p class="page-subtitle">
            <span id="peerCount">${onlineCount}</span> peer(s) online
            &nbsp;·&nbsp; Total: ${peers.size()}
        </p>
    </div>

    <!-- Alerts -->
    <c:if test="${not empty param.success}">
        <div class="alert alert-success">✓ ${param.success}</div>
    </c:if>
    <c:if test="${not empty param.error}">
        <div class="alert alert-error">⚠ ${param.error}</div>
    </c:if>

    <div style="display:grid;grid-template-columns:1fr 340px;gap:1.5rem;align-items:start;">

        <!-- Peer Grid -->
        <div>
            <div class="peer-grid" id="peerGrid">
                <c:forEach var="p" items="${peers}">
                <div class="peer-card" id="peer-${p.peerId}">
                    <div class="peer-card-header">
                        <div class="peer-avatar">${p.peerName.charAt(0)}</div>
                        <div style="flex:1;">
                            <div class="peer-name"><c:out value="${p.peerName}"/></div>
                            <div class="peer-address">${p.ipAddress}:${p.port}</div>
                        </div>
                        <c:choose>
                            <c:when test="${p.status == 'ONLINE'}">
                                <span class="badge badge-online">Online</span>
                            </c:when>
                            <c:when test="${p.status == 'BUSY'}">
                                <span class="badge badge-busy">Busy</span>
                            </c:when>
                            <c:otherwise>
                                <span class="badge badge-offline">Offline</span>
                            </c:otherwise>
                        </c:choose>
                    </div>

                    <div class="peer-meta">
                        <span class="badge badge-info" style="font-size:0.7rem;">ID #${p.peerId}</span>
                        <span style="font-size:0.75rem;color:var(--text-muted);">
                            Joined ${p.formattedJoinedAt}
                        </span>
                    </div>

                    <div style="display:flex;gap:6px;margin-top:0.75rem;">
                        <!-- Status Toggle -->
                        <form action="${pageContext.request.contextPath}/peers/status" method="post" style="flex:1;">
                            <input type="hidden" name="peerId" value="${p.peerId}"/>
                            <c:choose>
                                <c:when test="${p.status == 'ONLINE'}">
                                    <input type="hidden" name="status" value="BUSY"/>
                                    <button type="submit" class="btn btn-ghost btn-sm" style="width:100%;">Set Busy</button>
                                </c:when>
                                <c:otherwise>
                                    <input type="hidden" name="status" value="ONLINE"/>
                                    <button type="submit" class="btn btn-success btn-sm" style="width:100%;">Set Online</button>
                                </c:otherwise>
                            </c:choose>
                        </form>
                        <!-- Delete -->
                        <form action="${pageContext.request.contextPath}/peers/delete" method="post"
                              onsubmit="return confirm('Remove this peer?');">
                            <input type="hidden" name="peerId" value="${p.peerId}"/>
                            <button type="submit" class="btn btn-danger btn-sm">✕</button>
                        </form>
                    </div>
                </div>
                </c:forEach>

                <c:if test="${empty peers}">
                <div style="grid-column:1/-1;text-align:center;padding:3rem;color:var(--text-muted);">
                    <p style="font-size:3rem;margin-bottom:1rem;">🌐</p>
                    <p>No peers registered yet. Add one using the form →</p>
                </div>
                </c:if>
            </div>
        </div>

        <!-- Register Peer Form -->
        <div>
            <div class="card" style="position:sticky;top:80px;">
                <div class="card-header">
                    <h2 class="card-title">➕ Register Peer</h2>
                </div>
                <form action="${pageContext.request.contextPath}/peers/register" method="post">
                    <div class="form-group">
                        <label class="form-label" for="peerName">Peer Name *</label>
                        <input type="text" id="peerName" name="peerName" class="form-control"
                               placeholder="e.g. MyLaptop" required maxlength="100"/>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="ipAddress">IP Address *</label>
                        <input type="text" id="ipAddress" name="ipAddress" class="form-control"
                               placeholder="e.g. 192.168.1.10" required
                               pattern="^(\d{1,3}\.){3}\d{1,3}$|^localhost$|^127\.0\.0\.1$"/>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="port">Port</label>
                        <input type="number" id="port" name="port" class="form-control"
                               value="8080" min="1024" max="65535"/>
                    </div>
                    <button type="submit" class="btn btn-primary" style="width:100%;">
                        🌐 Join Network
                    </button>
                </form>
            </div>

            <!-- Live refresh indicator -->
            <div style="text-align:center;margin-top:1rem;color:var(--text-muted);font-size:0.8rem;">
                <span class="spinner"></span>
                &nbsp;Auto-refreshing every 15s
            </div>
        </div>
    </div>
</main>

<script>
// Auto-refresh peer list via AJAX
function refreshPeers() {
    fetch('${pageContext.request.contextPath}/peers?format=json')
        .then(r => r.json())
        .then(data => {
            document.getElementById('peerCount').textContent = data.count || 0;
        })
        .catch(() => {});
}
setInterval(refreshPeers, 15000);
</script>

</body>
</html>
