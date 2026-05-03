<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Error — LocalDrop</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>

<nav class="navbar">
    <a href="${pageContext.request.contextPath}/" class="navbar-brand">
        <span class="nav-logo">📁</span>
        <span class="nav-title">Local<span>Drop</span></span>
    </a>
</nav>

<main class="container">
    <div style="max-width:600px;margin:4rem auto;text-align:center;">
        <div style="font-size:5rem;margin-bottom:1.5rem;">⚠️</div>

        <h1 style="font-size:1.5rem;font-weight:800;color:var(--accent-red);margin-bottom:0.75rem;">
            Something went wrong
        </h1>

        <c:choose>
            <c:when test="${not empty errorMessage}">
                <div class="alert alert-error" style="text-align:left;margin:1.5rem 0;">
                    ${errorMessage}
                </div>
            </c:when>
            <c:when test="${not empty pageContext.errorData.throwable}">
                <div class="alert alert-error" style="text-align:left;margin:1.5rem 0;">
                    ${pageContext.errorData.throwable.message}
                </div>
            </c:when>
        </c:choose>

        <c:if test="${not empty pageContext.errorData.statusCode}">
            <p style="color:var(--text-muted);font-size:0.875rem;margin-bottom:1.5rem;">
                HTTP ${pageContext.errorData.statusCode}
                &nbsp;·&nbsp;
                ${pageContext.errorData.requestURI}
            </p>
        </c:if>

        <div style="display:flex;gap:1rem;justify-content:center;">
            <a href="${pageContext.request.contextPath}/" class="btn btn-primary">🏠 Go Home</a>
            <button onclick="history.back()" class="btn btn-ghost">← Go Back</button>
        </div>
    </div>
</main>

</body>
</html>
