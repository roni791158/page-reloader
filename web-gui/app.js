// Page Reloader Web Interface JavaScript
// Lightweight and efficient for router use

class PageReloaderGUI {
    constructor() {
        this.apiUrl = '/cgi-bin/page-reloader-api';
        this.refreshInterval = null;
        this.init();
    }

    init() {
        // Auto-refresh dashboard every 30 seconds
        this.startAutoRefresh();
        
        // Load initial data
        this.loadDashboard();
        this.loadUrls();
        this.loadTimingInfo();
        this.loadLogs();
        this.loadSystemInfo();
    }

    startAutoRefresh() {
        this.refreshInterval = setInterval(() => {
            if (document.getElementById('dashboard').classList.contains('active')) {
                this.loadDashboard();
            }
        }, 30000);
    }

    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }

    // API Communication
    async apiCall(endpoint, method = 'GET', data = null) {
        try {
            const options = {
                method: method,
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                }
            };

            if (data && method !== 'GET') {
                options.body = new URLSearchParams(data).toString();
            }

            const response = await fetch(`${this.apiUrl}?action=${endpoint}`, options);
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const text = await response.text();
            
            try {
                return JSON.parse(text);
            } catch (e) {
                // If response is not JSON, return as text
                return { success: true, message: text };
            }
        } catch (error) {
            console.error('API Error:', error);
            this.showAlert('Error: ' + error.message, 'danger');
            return { success: false, error: error.message };
        }
    }

    // Dashboard Functions
    async loadDashboard() {
        try {
            const [statusResult, urlsResult] = await Promise.all([
                this.apiCall('status'),
                this.apiCall('list-urls')
            ]);

            // Update service status
            const statusElement = document.getElementById('service-status');
            if (statusResult.success) {
                statusElement.textContent = statusResult.data.running ? '🟢 Running' : '🔴 Stopped';
                statusElement.style.color = statusResult.data.running ? '#28a745' : '#dc3545';
            }

            // Update URL counts
            if (urlsResult.success && urlsResult.data.urls) {
                const urls = urlsResult.data.urls;
                document.getElementById('total-urls').textContent = urls.length;
                
                const onlineCount = urls.filter(url => url.status === 'online').length;
                document.getElementById('online-urls').textContent = onlineCount;
                document.getElementById('online-urls').style.color = onlineCount === urls.length ? '#28a745' : '#ffc107';
            }

            // Update last check time
            document.getElementById('last-check').textContent = new Date().toLocaleTimeString();

        } catch (error) {
            console.error('Dashboard load error:', error);
        }
    }

    // URL Management Functions
    async loadUrls() {
        const container = document.getElementById('url-list');
        
        try {
            const result = await this.apiCall('list-urls');
            
            if (result.success && result.data.urls) {
                this.renderUrls(result.data.urls);
            } else {
                container.innerHTML = '<div class="alert alert-warning">No URLs configured</div>';
            }
        } catch (error) {
            container.innerHTML = '<div class="alert alert-danger">Failed to load URLs</div>';
        }
    }

    renderUrls(urls) {
        const container = document.getElementById('url-list');
        
        if (urls.length === 0) {
            container.innerHTML = '<div class="alert alert-warning">No URLs configured</div>';
            return;
        }

        const urlsHtml = urls.map(url => `
            <div class="url-item">
                <div class="url-status ${this.getStatusClass(url.status)}">
                    ${this.getStatusIcon(url.status)}
                </div>
                <div class="url-info">
                    <div class="url-address">${url.url}</div>
                    <div class="url-interval">
                        Check every ${this.formatInterval(url.interval)} 
                        ${url.interval === url.defaultInterval ? '(default)' : '(custom)'}
                    </div>
                </div>
                <div class="url-actions">
                    <button class="btn btn-primary btn-sm" onclick="gui.testUrl('${url.url}')">🧪 Test</button>
                    <button class="btn btn-warning btn-sm" onclick="gui.editUrlInterval('${url.url}', ${url.interval})">⏰ Timing</button>
                    <button class="btn btn-danger btn-sm" onclick="gui.removeUrl('${url.url}')">🗑️ Remove</button>
                </div>
            </div>
        `).join('');

        container.innerHTML = urlsHtml;
    }

    getStatusClass(status) {
        switch (status) {
            case 'online': return 'status-online';
            case 'offline': return 'status-offline';
            default: return 'status-unknown';
        }
    }

    getStatusIcon(status) {
        switch (status) {
            case 'online': return '✅';
            case 'offline': return '❌';
            default: return '❓';
        }
    }

    formatInterval(seconds) {
        if (seconds < 60) return `${seconds}s`;
        if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
        return `${Math.floor(seconds / 3600)}h`;
    }

    async addUrl() {
        const url = document.getElementById('new-url').value.trim();
        const interval = document.getElementById('new-url-interval').value;

        if (!url) {
            this.showAlert('Please enter a URL', 'warning');
            return;
        }

        try {
            const result = await this.apiCall('add-url', 'POST', { url });
            
            if (result.success) {
                // Set custom interval if provided
                if (interval && interval !== '') {
                    await this.apiCall('set-url-interval', 'POST', { url, interval });
                }
                
                this.showAlert('URL added successfully', 'success');
                document.getElementById('new-url').value = '';
                document.getElementById('new-url-interval').value = '';
                this.loadUrls();
                this.loadDashboard();
            } else {
                this.showAlert('Failed to add URL: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error adding URL', 'danger');
        }
    }

    async quickAddUrl() {
        const url = document.getElementById('quick-url').value.trim();
        
        if (!url) {
            this.showAlert('Please enter a URL', 'warning');
            return;
        }

        try {
            const result = await this.apiCall('add-url', 'POST', { url });
            
            if (result.success) {
                this.showAlert('URL added successfully', 'success');
                document.getElementById('quick-url').value = '';
                this.loadUrls();
                this.loadDashboard();
            } else {
                this.showAlert('Failed to add URL: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error adding URL', 'danger');
        }
    }

    async removeUrl(url) {
        if (!confirm(`Are you sure you want to remove: ${url}?`)) {
            return;
        }

        try {
            const result = await this.apiCall('remove-url', 'POST', { url });
            
            if (result.success) {
                this.showAlert('URL removed successfully', 'success');
                this.loadUrls();
                this.loadDashboard();
            } else {
                this.showAlert('Failed to remove URL: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error removing URL', 'danger');
        }
    }

    async testUrl(url) {
        try {
            this.showAlert('Testing URL...', 'info');
            const result = await this.apiCall('test-url', 'POST', { url });
            
            if (result.success) {
                const status = result.data.accessible ? 'accessible ✅' : 'not accessible ❌';
                this.showAlert(`${url} is ${status}`, result.data.accessible ? 'success' : 'warning');
            } else {
                this.showAlert('Test failed: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error testing URL', 'danger');
        }
    }

    editUrlInterval(url, currentInterval) {
        const newInterval = prompt(`Set check interval for ${url} (seconds):`, currentInterval);
        
        if (newInterval === null) return; // Cancelled
        
        const interval = parseInt(newInterval);
        if (isNaN(interval) || interval < 5) {
            this.showAlert('Invalid interval. Must be 5 seconds or more.', 'warning');
            return;
        }

        this.setUrlInterval(url, interval);
    }

    async setUrlInterval(url, interval) {
        try {
            const result = await this.apiCall('set-url-interval', 'POST', { url, interval });
            
            if (result.success) {
                this.showAlert(`Interval updated for ${url}`, 'success');
                this.loadUrls();
            } else {
                this.showAlert('Failed to update interval: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error updating interval', 'danger');
        }
    }

    // Service Control Functions
    async startService() {
        try {
            const result = await this.apiCall('start', 'POST');
            this.showAlert(result.success ? 'Service started' : 'Failed to start service', result.success ? 'success' : 'danger');
            this.loadDashboard();
        } catch (error) {
            this.showAlert('Error starting service', 'danger');
        }
    }

    async stopService() {
        try {
            const result = await this.apiCall('stop', 'POST');
            this.showAlert(result.success ? 'Service stopped' : 'Failed to stop service', result.success ? 'success' : 'danger');
            this.loadDashboard();
        } catch (error) {
            this.showAlert('Error stopping service', 'danger');
        }
    }

    async restartService() {
        try {
            const result = await this.apiCall('restart', 'POST');
            this.showAlert(result.success ? 'Service restarted' : 'Failed to restart service', result.success ? 'success' : 'danger');
            this.loadDashboard();
        } catch (error) {
            this.showAlert('Error restarting service', 'danger');
        }
    }

    async testAllUrls() {
        try {
            this.showAlert('Testing all URLs...', 'info');
            const result = await this.apiCall('test-all', 'POST');
            
            if (result.success) {
                this.showAlert('All URLs tested. Check logs for details.', 'success');
                this.loadUrls();
                this.loadLogs();
            } else {
                this.showAlert('Test failed: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error testing URLs', 'danger');
        }
    }

    // Timing Functions
    async loadTimingInfo() {
        try {
            const result = await this.apiCall('show-timing');
            
            if (result.success) {
                document.getElementById('timing-info').innerHTML = result.data.info || 'No timing information available';
                
                // Update form fields
                if (result.data.interval) {
                    document.getElementById('default-interval').value = result.data.interval;
                }
                if (result.data.timeout) {
                    document.getElementById('timeout').value = result.data.timeout;
                }
            }
        } catch (error) {
            document.getElementById('timing-info').innerHTML = 'Failed to load timing information';
        }
    }

    async setDefaultInterval() {
        const interval = document.getElementById('default-interval').value;
        
        if (!interval || interval < 5) {
            this.showAlert('Invalid interval. Must be 5 seconds or more.', 'warning');
            return;
        }

        try {
            const result = await this.apiCall('set-interval', 'POST', { interval });
            
            if (result.success) {
                this.showAlert('Default interval updated', 'success');
                this.loadTimingInfo();
            } else {
                this.showAlert('Failed to update interval: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error updating interval', 'danger');
        }
    }

    async setTimeout() {
        const timeout = document.getElementById('timeout').value;
        
        if (!timeout || timeout < 1) {
            this.showAlert('Invalid timeout. Must be 1 second or more.', 'warning');
            return;
        }

        try {
            const result = await this.apiCall('set-timeout', 'POST', { timeout });
            
            if (result.success) {
                this.showAlert('Timeout updated', 'success');
                this.loadTimingInfo();
            } else {
                this.showAlert('Failed to update timeout: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error updating timeout', 'danger');
        }
    }

    async setPreset(preset) {
        try {
            const result = await this.apiCall('set-preset', 'POST', { preset });
            
            if (result.success) {
                this.showAlert(`Applied ${preset} preset`, 'success');
                this.loadTimingInfo();
            } else {
                this.showAlert('Failed to apply preset: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error applying preset', 'danger');
        }
    }

    // Logs Functions
    async loadLogs() {
        try {
            const result = await this.apiCall('logs');
            const container = document.getElementById('logs-container');
            
            if (result.success && result.data.logs) {
                const logsHtml = result.data.logs.map(log => 
                    `<div class="log-entry">${this.escapeHtml(log)}</div>`
                ).join('');
                container.innerHTML = logsHtml;
                container.scrollTop = container.scrollHeight;
            } else {
                container.innerHTML = '<div class="log-entry">No logs available</div>';
            }
        } catch (error) {
            document.getElementById('logs-container').innerHTML = '<div class="log-entry">Failed to load logs</div>';
        }
    }

    refreshLogs() {
        this.loadLogs();
    }

    clearLogs() {
        document.getElementById('logs-container').innerHTML = '<div class="log-entry">Logs cleared from display</div>';
    }

    // Settings Functions
    async loadSystemInfo() {
        try {
            const result = await this.apiCall('system-info');
            
            if (result.success) {
                document.getElementById('system-info').innerHTML = result.data.info || 'No system information available';
            }
        } catch (error) {
            document.getElementById('system-info').innerHTML = 'Failed to load system information';
        }
    }

    async enableAutoStart() {
        try {
            const result = await this.apiCall('enable-autostart', 'POST');
            this.showAlert(result.success ? 'Auto-start enabled' : 'Failed to enable auto-start', result.success ? 'success' : 'danger');
        } catch (error) {
            this.showAlert('Error enabling auto-start', 'danger');
        }
    }

    async disableAutoStart() {
        try {
            const result = await this.apiCall('disable-autostart', 'POST');
            this.showAlert(result.success ? 'Auto-start disabled' : 'Failed to disable auto-start', result.success ? 'success' : 'danger');
        } catch (error) {
            this.showAlert('Error disabling auto-start', 'danger');
        }
    }

    exportConfig() {
        this.apiCall('export-config').then(result => {
            if (result.success) {
                const blob = new Blob([result.data.config], { type: 'text/plain' });
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'page-reloader-config.txt';
                a.click();
                window.URL.revokeObjectURL(url);
            } else {
                this.showAlert('Failed to export config', 'danger');
            }
        });
    }

    importConfig() {
        document.getElementById('config-file').click();
    }

    handleConfigImport() {
        const file = document.getElementById('config-file').files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = async (e) => {
            try {
                const result = await this.apiCall('import-config', 'POST', { config: e.target.result });
                
                if (result.success) {
                    this.showAlert('Configuration imported successfully', 'success');
                    this.loadUrls();
                    this.loadTimingInfo();
                    this.loadDashboard();
                } else {
                    this.showAlert('Failed to import config: ' + result.error, 'danger');
                }
            } catch (error) {
                this.showAlert('Error importing config', 'danger');
            }
        };
        reader.readAsText(file);
    }

    async clearAllUrls() {
        if (!confirm('Are you sure you want to remove ALL URLs? This cannot be undone!')) {
            return;
        }

        try {
            const result = await this.apiCall('clear-urls', 'POST');
            
            if (result.success) {
                this.showAlert('All URLs cleared', 'success');
                this.loadUrls();
                this.loadDashboard();
            } else {
                this.showAlert('Failed to clear URLs: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error clearing URLs', 'danger');
        }
    }

    async uninstallService() {
        if (!confirm('Are you sure you want to uninstall the Page Reloader service? This will remove all configuration!')) {
            return;
        }

        if (!confirm('This action cannot be undone! Are you absolutely sure?')) {
            return;
        }

        try {
            const result = await this.apiCall('uninstall', 'POST');
            
            if (result.success) {
                this.showAlert('Service uninstalled successfully', 'success');
                setTimeout(() => {
                    window.location.href = '/';
                }, 3000);
            } else {
                this.showAlert('Failed to uninstall: ' + result.error, 'danger');
            }
        } catch (error) {
            this.showAlert('Error during uninstall', 'danger');
        }
    }

    // Utility Functions
    showAlert(message, type = 'info') {
        // Remove existing alerts
        const existingAlerts = document.querySelectorAll('.alert-temporary');
        existingAlerts.forEach(alert => alert.remove());

        const alert = document.createElement('div');
        alert.className = `alert alert-${type} alert-temporary`;
        alert.innerHTML = message;
        alert.style.position = 'fixed';
        alert.style.top = '20px';
        alert.style.right = '20px';
        alert.style.zIndex = '9999';
        alert.style.maxWidth = '400px';
        alert.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';

        document.body.appendChild(alert);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (alert.parentNode) {
                alert.remove();
            }
        }, 5000);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Tab Management Functions
function showTab(tabId) {
    // Hide all tabs
    const tabs = document.querySelectorAll('.tab-content');
    tabs.forEach(tab => tab.classList.remove('active'));

    // Remove active class from all nav tabs
    const navTabs = document.querySelectorAll('.nav-tab');
    navTabs.forEach(tab => tab.classList.remove('active'));

    // Show selected tab
    document.getElementById(tabId).classList.add('active');
    event.target.classList.add('active');

    // Load data for specific tabs
    if (tabId === 'urls') {
        gui.loadUrls();
    } else if (tabId === 'logs') {
        gui.loadLogs();
    } else if (tabId === 'timing') {
        gui.loadTimingInfo();
    } else if (tabId === 'dashboard') {
        gui.loadDashboard();
    }
}

// Initialize GUI when page loads
let gui;
document.addEventListener('DOMContentLoaded', function() {
    gui = new PageReloaderGUI();
});

// Handle page visibility changes
document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
        gui.stopAutoRefresh();
    } else {
        gui.startAutoRefresh();
    }
});

// Handle window beforeunload
window.addEventListener('beforeunload', function() {
    gui.stopAutoRefresh();
});
