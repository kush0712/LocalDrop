<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta name="description" content="Upload files to the local network"/>
    <title>Upload File — LocalDrop</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>

<nav class="navbar">
    <a href="${pageContext.request.contextPath}/" class="navbar-brand">
        <span class="nav-logo">📁</span>
        <span class="nav-title">Local<span>Drop</span></span>
    </a>
    <ul class="navbar-nav">
        <li><a href="${pageContext.request.contextPath}/"          class="nav-link">🏠 Dashboard</a></li>
        <li><a href="${pageContext.request.contextPath}/files"     class="nav-link">📁 Files</a></li>
        <li><a href="${pageContext.request.contextPath}/upload"    class="nav-link active">⬆️ Upload</a></li>
        <li><a href="${pageContext.request.contextPath}/transfers" class="nav-link">↔️ Transfers</a></li>
    </ul>
</nav>

<main class="container">
    <div class="page-header">
        <h1 class="page-title">Upload File</h1>
        <p class="page-subtitle">Share a file with the local network</p>
    </div>

    <c:if test="${not empty error}">
        <div class="alert alert-error">⚠ ${error}</div>
    </c:if>

    <div style="max-width:640px;">
        <div class="card">
            <form id="uploadForm" action="${pageContext.request.contextPath}/upload"
                  method="post" enctype="multipart/form-data">

                <!-- Drop Zone -->
                <div class="drop-zone" id="dropZone" onclick="document.getElementById('fileInput').click()">
                    <span class="drop-zone-icon">📂</span>
                    <p class="drop-zone-text" id="dropZoneText">Drop file here or click to browse</p>
                    <p class="drop-zone-hint">Max file size: 500 MB &nbsp;|&nbsp; Any file type accepted</p>
                    <input type="file" id="fileInput" name="file" style="display:none"
                           onchange="handleFileSelect(this)"/>
                </div>

                <!-- Selected file preview -->
                <div id="filePreview" style="display:none;margin-top:1rem;">
                    <div class="card" style="background:rgba(79,142,247,0.06);border-color:rgba(79,142,247,0.2);padding:1rem;">
                        <div style="display:flex;align-items:center;gap:12px;">
                            <span id="previewIcon" style="font-size:2rem;">📄</span>
                            <div style="flex:1;">
                                <div id="previewName" style="font-weight:700;color:var(--text-primary);">—</div>
                                <div id="previewSize" style="font-size:0.8rem;color:var(--text-secondary);">—</div>
                            </div>
                            <button type="button" onclick="clearFile()" class="btn btn-danger btn-sm">✕</button>
                        </div>
                    </div>
                </div>

                <!-- Upload Progress -->
                <div class="upload-progress-wrap" id="progressWrap">
                    <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                        <span style="font-size:0.85rem;color:var(--text-secondary);">Uploading…</span>
                        <span id="progressPct" style="font-family:var(--font-mono);font-size:0.85rem;color:var(--accent-cyan);">0%</span>
                    </div>
                    <div class="progress-bar-wrap">
                        <div class="progress-bar-fill" id="progressBar" style="width:0%"></div>
                    </div>
                </div>

                <div style="display:flex;gap:1rem;margin-top:1.5rem;">
                    <button type="submit" id="submitBtn" class="btn btn-primary btn-lg" style="flex:1;">
                        ⬆️ Upload to Network
                    </button>
                    <a href="${pageContext.request.contextPath}/files" class="btn btn-ghost btn-lg">Cancel</a>
                </div>
            </form>
        </div>

        <!-- Info Card -->
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">ℹ️ Upload Info</h2>
            </div>
            <ul style="list-style:none;display:flex;flex-direction:column;gap:0.75rem;">
                <li style="display:flex;gap:10px;color:var(--text-secondary);font-size:0.875rem;">
                    <span style="color:var(--accent-green);">✓</span>
                    Files are stored and shared across the local network
                </li>
                <li style="display:flex;gap:10px;color:var(--text-secondary);font-size:0.875rem;">
                    <span style="color:var(--accent-green);">✓</span>
                    SHA-256 checksum is computed for integrity verification
                </li>
                <li style="display:flex;gap:10px;color:var(--text-secondary);font-size:0.875rem;">
                    <span style="color:var(--accent-green);">✓</span>
                    Files are stored on the server and accessible to anyone on the local network
                </li>
                <li style="display:flex;gap:10px;color:var(--text-secondary);font-size:0.875rem;">
                    <span style="color:var(--accent-green);">✓</span>
                    Maximum file size: 500 MB per file
                </li>
            </ul>
        </div>
    </div>
</main>

<script>
const dropZone   = document.getElementById('dropZone');
const fileInput  = document.getElementById('fileInput');
const form       = document.getElementById('uploadForm');
const progressWrap = document.getElementById('progressWrap');
const progressBar  = document.getElementById('progressBar');
const progressPct  = document.getElementById('progressPct');

// Drag & Drop
['dragenter','dragover'].forEach(e => dropZone.addEventListener(e, ev => {
    ev.preventDefault(); dropZone.classList.add('drag-over');
}));
['dragleave','drop'].forEach(e => dropZone.addEventListener(e, ev => {
    ev.preventDefault(); dropZone.classList.remove('drag-over');
}));
dropZone.addEventListener('drop', ev => {
    const files = ev.dataTransfer.files;
    if (files.length) { fileInput.files = files; handleFileSelect(fileInput); }
});

function handleFileSelect(input) {
    const file = input.files[0];
    if (!file) return;

    document.getElementById('previewName').textContent = file.name;
    document.getElementById('previewSize').textContent = formatBytes(file.size);
    document.getElementById('previewIcon').textContent = getFileIcon(file.name);
    document.getElementById('filePreview').style.display = 'block';
    document.getElementById('dropZoneText').textContent  = 'File selected ✓';
}

function clearFile() {
    fileInput.value = '';
    document.getElementById('filePreview').style.display = 'none';
    document.getElementById('dropZoneText').textContent  = 'Drop file here or click to browse';
}

function formatBytes(b) {
    if (b < 1024)        return b + ' B';
    if (b < 1048576)     return (b/1024).toFixed(1) + ' KB';
    if (b < 1073741824)  return (b/1048576).toFixed(1) + ' MB';
    return (b/1073741824).toFixed(2) + ' GB';
}

function getFileIcon(name) {
    const ext = name.split('.').pop().toLowerCase();
    const icons = {
        pdf:'📕', doc:'📝', docx:'📝', txt:'📄', md:'📝',
        jpg:'🖼', jpeg:'🖼', png:'🖼', gif:'🎞', svg:'🎨', webp:'🖼',
        mp4:'🎬', avi:'🎬', mov:'🎬', mkv:'🎬',
        mp3:'🎵', wav:'🎵', flac:'🎵',
        zip:'🗜', rar:'🗜', tar:'🗜', gz:'🗜',
        exe:'⚙', msi:'⚙', dmg:'⚙',
        py:'🐍', js:'🟨', java:'☕', cpp:'💻', ts:'🔷',
        html:'🌐', css:'🎨', json:'📋', xml:'📋'
    };
    return icons[ext] || '📄';
}

// Simulate upload progress (visual feedback via XHR)
form.addEventListener('submit', ev => {
    ev.preventDefault();
    if (!fileInput.files[0]) {
        alert("⚠️ Please select a file to upload first!");
        return;
    }
    progressWrap.classList.add('visible');
    document.getElementById('submitBtn').disabled = true;

    const xhr = new XMLHttpRequest();
    xhr.open('POST', form.action);

    xhr.upload.addEventListener('progress', e => {
        if (e.lengthComputable) {
            const pct = Math.round(e.loaded / e.total * 100);
            progressBar.style.width = pct + '%';
            progressPct.textContent = pct + '%';
        }
    });

    xhr.onload = () => {
        if (xhr.status < 400) {
            // Follow redirect manually
            window.location.href = '${pageContext.request.contextPath}/files?success=File+uploaded+successfully';
        } else {
            alert("⚠️ Server Error: Failed to upload file (HTTP " + xhr.status + "). Please check server logs or try a smaller file.");
            progressWrap.classList.remove('visible');
            document.getElementById('submitBtn').disabled = false;
        }
    };

    xhr.send(new FormData(form));
});
</script>

</body>
</html>
