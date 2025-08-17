// Page Reloader Web GUI JavaScript
const API_BASE = '/cgi-bin/page-reloader-api';
let fallbackMode = false;

// API Communication
async function apiCall(action, params = {}) {
    try {
        const queryParams = new URLSearchParams({ action, ...params });
        const response = await fetch(`${API_BASE}?${queryParams}`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const text = await response.text();
        console.log('API Response:', text);
        
        // Try to parse as JSON
        try {
            const jsonData = JSON.parse(text);
            console.log('Parsed JSON:', jsonData);
            return jsonData;
        } catch (e) {
            console.log('Not JSON, treating as text');
            // If not JSON, return as text
            return { success: true, data: text };
        }
    } catch (error) {
        console.error('API call failed:', error);
        showAlert('API call failed. Use Manual Commands tab for SSH commands.', 'warning');
        throw error;
    }
}

// Tab Management
function showTab(tabName) {
    // Hide all tabs
    const tabs = document.querySelectorAll('.tab-content');
    tabs.forEach(tab => tab.classList.remove('active'));
    
    // Hide all nav tabs
    const navTabs = document.querySelectorAll('.nav-tab');
    navTabs.forEach(tab => tab.classList.remove('active'));
    
    // Show selected tab
    const selectedTab = document.getElementById(tabName);
    if (selectedTab) {
        selectedTab.classList.add('active');
    }
    
    // Activate corresponding nav tab
    const selectedNavTab = document.querySelector(`[data-tab="${tabName}"]`);
    if (selectedNavTab) {
        selectedNavTab.classList.add('active');
    }
}

// Service Control Functions
async function startService() {
    try {
        await apiCall('start');
        showAlert('Service started successfully!', 'success');
        updateStatus();
    } catch (error) {
        showAlert('Failed to start service. Use manual command: page-reloader start', 'danger');
    }
}

async function stopService() {
    try {
        await apiCall('stop');
        showAlert('Service stopped successfully!', 'success');
        updateStatus();
    } catch (error) {
        showAlert('Failed to stop service. Use manual command: page-reloader stop', 'danger');
    }
}

async function restartService() {
    try {
        await apiCall('restart');
        showAlert('Service restarted successfully!', 'success');
        updateStatus();
    } catch (error) {
        showAlert('Failed to restart service. Use manual command: page-reloader restart', 'danger');
    }
}

// URL Management Functions
async function quickAddUrl() {
    const urlInput = document.getElementById('quick-url');
    const intervalInput = document.getElementById('quick-interval');
    const url = urlInput.value.trim();
    const interval = intervalInput.value.trim();
    
    if (!url) {
        showAlert('Please enter a valid URL', 'warning');
        return;
    }
    
    try {
        // Add URL first
        await apiCall('add-url', { url });
        
        // Set custom interval if provided
        if (interval && interval > 0) {
            await apiCall('set-url-interval', { url, interval });
            showAlert(`URL added with ${interval}s interval!`, 'success');
        } else {
            showAlert('URL added with default interval!', 'success');
        }
        
        // Clear inputs
        urlInput.value = '';
        intervalInput.value = '600';
        
        updateStatus();
    } catch (error) {
        showAlert(`Failed to add URL. Use manual command: page-reloader add-url "${url}"`, 'danger');
    }
}

// Remove URL function
async function removeUrl(url) {
    if (!confirm(`Remove URL: ${url}?`)) {
        return;
    }
    
    try {
        await apiCall('remove-url', { url });
        showAlert('URL removed successfully!', 'success');
        updateStatus();
    } catch (error) {
        showAlert(`Failed to remove URL. Use manual command: page-reloader remove-url "${url}"`, 'danger');
    }
}

// Update URL interval function
async function updateUrlInterval(url, interval) {
    try {
        await apiCall('set-url-interval', { url, interval });
        showAlert(`Interval updated to ${interval}s for ${url}`, 'success');
        updateStatus();
    } catch (error) {
        showAlert(`Failed to update interval. Use manual command: page-reloader set-url-interval "${url}" ${interval}`, 'danger');
    }
}

// Test specific URL
async function testUrl(url) {
    try {
        const result = await apiCall('test-url', { url });
        if (result.data && result.data.accessible) {
            showAlert(`✅ ${url} is accessible`, 'success');
        } else {
            showAlert(`❌ ${url} is not accessible`, 'warning');
        }
    } catch (error) {
        showAlert(`Failed to test URL: ${url}`, 'danger');
    }
}

// Update status display
async function updateStatus() {
    try {
        const status = await apiCall('status');
        const urls = await apiCall('list-urls');
        
        // Parse service status from JSON response
        let isRunning = false;
        if (status.data && typeof status.data === 'object') {
            isRunning = status.data.running === true;
        } else if (status.data && typeof status.data === 'string') {
            isRunning = status.data.includes('running');
        }
        
        const serviceStatusText = isRunning ? '🟢 Running' : '🔴 Stopped';
        const serviceClass = isRunning ? 'alert-success' : 'alert-danger';
        
        // Parse URLs from JSON response
        let urlCount = 0;
        let urlList = [];
        
        if (urls.data && typeof urls.data === 'object' && urls.data.urls) {
            urlList = urls.data.urls;
            urlCount = urlList.length;
        } else if (urls.data && typeof urls.data === 'string') {
            // Fallback for text response
            const urlLines = urls.data.split('\n').filter(line => line.trim() && line.includes('http'));
            urlCount = urlLines.length;
            urlList = urlLines.map(line => ({ url: line.trim(), status: 'unknown' }));
        }
        
        const statusDisplay = document.getElementById('status-display');
        statusDisplay.innerHTML = `
            <div class="row">
                <div class="col">
                    <div class="alert ${serviceClass}">
                        <h4>🔧 Service Status</h4>
                        <p><strong>${serviceStatusText}</strong></p>
                        <small>${status.data}</small>
                    </div>
                </div>
                <div class="col">
                    <div class="alert alert-info">
                        <h4>📝 Monitored URLs</h4>
                        <p><strong>Total: ${urlCount} URLs</strong></p>
                        ${urlCount > 0 ? '<small>URLs configured and ready for monitoring</small>' : '<small>No URLs configured yet</small>'}
                    </div>
                </div>
            </div>
            
            ${urlCount > 0 ? `
            <div class="alert alert-info">
                <h5>📋 URL Management:</h5>
                <div id="url-list-container"></div>
            </div>
            ` : ''}
        `;
        
        // Generate URL management UI
        if (urlCount > 0) {
            const urlManagementHtml = urlList.map(item => {
                const url = typeof item === 'object' ? item.url : item;
                const status = typeof item === 'object' ? item.status : 'unknown';
                const interval = typeof item === 'object' ? item.interval : '30';
                const statusIcon = status === 'online' ? '🟢' : status === 'offline' ? '🔴' : '⚪';
                const statusText = status === 'online' ? 'Online' : status === 'offline' ? 'Offline' : 'Unknown';
                const urlId = btoa(url).replace(/[^a-zA-Z0-9]/g, '');
                
                return `
                <div style="border: 1px solid #dee2e6; border-radius: 8px; padding: 15px; margin-bottom: 10px; background: #f8f9fa;" data-url-item="${url}">
                    <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap;">
                        <div style="flex: 1; min-width: 200px;">
                            <h6 style="margin-bottom: 5px; color: #495057;">${statusIcon} ${url}</h6>
                            <small style="color: #6c757d;">Status: <strong>${statusText}</strong> | Interval: <strong>${interval}s</strong></small>
                        </div>
                        <div style="display: flex; gap: 5px; flex-wrap: wrap; margin-top: 10px;">
                            <input type="number" class="interval-input" value="${interval}" min="30" max="3600" style="width: 80px; padding: 5px; border: 1px solid #ccc; border-radius: 4px;" placeholder="Interval">
                            <button class="btn btn-secondary url-btn" style="padding: 5px 10px; font-size: 12px;" data-action="update-interval">⏰ Update</button>
                            <button class="btn btn-warning url-btn" style="padding: 5px 10px; font-size: 12px;" data-action="test">🧪 Test</button>
                            <button class="btn btn-danger url-btn" style="padding: 5px 10px; font-size: 12px;" data-action="remove">🗑️ Remove</button>
                        </div>
                    </div>
                </div>
                `;
            }).join('');
            
            const urlListContainer = document.getElementById('url-list-container');
            if (urlListContainer) {
                urlListContainer.innerHTML = urlManagementHtml;
            }
        }
        
    } catch (error) {
        console.error('Failed to load status:', error);
        const statusDisplay = document.getElementById('status-display');
        statusDisplay.innerHTML = `
            <div class="alert alert-warning">
                <h4>⚠️ Status Check Failed</h4>
                <p>Could not connect to API. Use Manual Commands tab for SSH access.</p>
            </div>
        `;
    }
}

// Utility Functions
function showAlert(message, type = 'info') {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type}`;
    alertDiv.innerHTML = message;
    
    const container = document.querySelector('.tab-content.active');
    container.insertBefore(alertDiv, container.firstChild);
    
    setTimeout(() => {
        alertDiv.remove();
    }, 5000);
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    updateStatus();
    
    // Add event listeners for tab navigation
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            showTab(tabName);
        });
    });
    
    // Add event listeners for buttons
    const buttonMap = {
        'quick-add-btn': quickAddUrl,
        'start-service-btn': startService,
        'stop-service-btn': stopService,
        'restart-service-btn': restartService,
        'refresh-status-btn': updateStatus
    };
    
    Object.keys(buttonMap).forEach(buttonId => {
        const btn = document.getElementById(buttonId);
        if (btn) {
            btn.addEventListener('click', buttonMap[buttonId]);
        }
    });
    
    // Event delegation for dynamically created URL management buttons
    document.addEventListener('click', function(event) {
        if (event.target.classList.contains('url-btn')) {
            const action = event.target.getAttribute('data-action');
            const urlItem = event.target.closest('[data-url-item]');
            
            if (urlItem) {
                const url = urlItem.getAttribute('data-url-item');
                const intervalInput = urlItem.querySelector('.interval-input');
                
                switch(action) {
                    case 'update-interval':
                        if (intervalInput) {
                            const interval = intervalInput.value;
                            updateUrlInterval(url, interval);
                        }
                        break;
                    case 'test':
                        testUrl(url);
                        break;
                    case 'remove':
                        removeUrl(url);
                        break;
                }
            }
        }
    });
});
