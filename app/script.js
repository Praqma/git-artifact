// Git Artifact Manager JavaScript
document.addEventListener('DOMContentLoaded', function() {
    // Initialize the application
    initializeApp();
    
    // Set up event listeners
    setupEventListeners();
    
    // Initialize sample data for demo
    initializeSampleData();
});

function initializeApp() {
    // Show the commands tab by default
    showTab('commands');
    
    // Add some welcome text to the output
    updateOutput('Git Artifact Manager initialized successfully!\nReady to execute commands...\n');
}

function setupEventListeners() {
    // Tab switching
    const tabButtons = document.querySelectorAll('.tab-btn');
    tabButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const tabName = this.dataset.tab;
            showTab(tabName);
        });
    });
    
    // Form submissions (prevent default behavior)
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
        });
    });
}

function showTab(tabName) {
    // Hide all tab contents
    const tabContents = document.querySelectorAll('.tab-content');
    tabContents.forEach(content => {
        content.classList.remove('active');
    });
    
    // Remove active class from all tab buttons
    const tabButtons = document.querySelectorAll('.tab-btn');
    tabButtons.forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show the selected tab content
    const selectedContent = document.getElementById(tabName);
    if (selectedContent) {
        selectedContent.classList.add('active');
    }
    
    // Add active class to the selected tab button
    const selectedButton = document.querySelector(`[data-tab="${tabName}"]`);
    if (selectedButton) {
        selectedButton.classList.add('active');
    }
}

function executeCommand(command) {
    const timestamp = new Date().toLocaleTimeString();
    let commandText = '';
    let parameters = {};
    
    // Build command based on the action
    switch(command) {
        case 'init':
            parameters.url = document.getElementById('init-url').value;
            parameters.path = document.getElementById('init-path').value;
            parameters.branch = document.getElementById('init-branch').value;
            commandText = buildCommandString('git artifact init', parameters);
            break;
            
        case 'clone':
            parameters.url = document.getElementById('clone-url').value;
            parameters.path = document.getElementById('clone-path').value;
            commandText = buildCommandString('git artifact clone', parameters);
            break;
            
        case 'add-n-push':
            parameters.tag = document.getElementById('artifact-tag').value;
            parameters.branch = document.getElementById('artifact-branch').value;
            commandText = buildCommandString('git artifact add-n-push', parameters);
            break;
            
        case 'fetch-co':
            parameters.tag = document.getElementById('fetch-tag').value;
            commandText = buildCommandString('git artifact fetch-co', parameters);
            break;
            
        case 'list':
            parameters.glob = document.getElementById('list-glob').value;
            commandText = buildCommandString('git artifact list', parameters);
            break;
            
        case 'find-latest':
            parameters.glob = document.getElementById('latest-glob').value;
            commandText = buildCommandString('git artifact find-latest', parameters);
            break;
            
        case 'summary':
            parameters.delimiter = document.getElementById('summary-delimiter').value;
            commandText = buildCommandString('git artifact summary', parameters);
            break;
            
        default:
            commandText = `git artifact ${command}`;
    }
    
    // Validate required parameters
    if (!validateCommand(command, parameters)) {
        return;
    }
    
    // Update output with command execution
    const output = `[${timestamp}] Executing: ${commandText}\n`;
    updateOutput(output);
    
    // Simulate command execution
    setTimeout(() => {
        simulateCommandExecution(command, parameters);
    }, 500);
}

function buildCommandString(baseCommand, parameters) {
    let command = baseCommand;
    
    if (parameters.url) command += ` --url="${parameters.url}"`;
    if (parameters.path) command += ` --path="${parameters.path}"`;
    if (parameters.branch) command += ` --branch="${parameters.branch}"`;
    if (parameters.tag) command += ` --tag="${parameters.tag}"`;
    if (parameters.glob) command += ` --glob="${parameters.glob}"`;
    if (parameters.delimiter && parameters.delimiter !== '/') command += ` --delimiter="${parameters.delimiter}"`;
    
    return command;
}

function validateCommand(command, parameters) {
    const errors = [];
    
    switch(command) {
        case 'init':
        case 'clone':
            if (!parameters.url) {
                errors.push('Remote URL is required');
            }
            break;
            
        case 'add-n-push':
            if (!parameters.tag) {
                errors.push('Tag is required');
            }
            break;
            
        case 'fetch-co':
            if (!parameters.tag) {
                errors.push('Tag is required');
            }
            break;
    }
    
    if (errors.length > 0) {
        const timestamp = new Date().toLocaleTimeString();
        const errorOutput = `[${timestamp}] Error: ${errors.join(', ')}\n`;
        updateOutput(errorOutput);
        return false;
    }
    
    return true;
}

function simulateCommandExecution(command, parameters) {
    const timestamp = new Date().toLocaleTimeString();
    let output = '';
    
    // Simulate different command outputs
    switch(command) {
        case 'init':
            output = `[${timestamp}] Repository initialized successfully!\n`;
            output += `Directory: ${parameters.path || 'my-artifact-repo'}\n`;
            output += `Remote: ${parameters.url}\n`;
            output += `Branch: ${parameters.branch || 'main'}\n`;
            output += `Ready to receive artifacts...\n\n`;
            break;
            
        case 'clone':
            output = `[${timestamp}] Cloning repository...\n`;
            output += `Cloning into '${parameters.path || 'repository'}'...\n`;
            output += `Repository cloned successfully!\n`;
            output += `Ready to receive artifacts...\n\n`;
            break;
            
        case 'add-n-push':
            output = `[${timestamp}] Adding artifacts...\n`;
            output += `Committing artifacts...\n`;
            output += `Tagging with: ${parameters.tag}\n`;
            output += `Pushing tag to remote...\n`;
            output += `All good.. get back to clear state for next artifact...\n\n`;
            break;
            
        case 'fetch-co':
            output = `[${timestamp}] Fetching tag: ${parameters.tag}\n`;
            output += `Checking out tag in detached HEAD...\n`;
            output += `* ${parameters.tag} (tag: ${parameters.tag})\n\n`;
            break;
            
        case 'list':
            output = `[${timestamp}] Tags matching pattern '${parameters.glob}':\n`;
            output += generateSampleTags();
            output += `\nTags found: ${parameters.glob} : 8\n\n`;
            break;
            
        case 'find-latest':
            output = `[${timestamp}] Finding latest tag matching '${parameters.glob}':\n`;
            output += `v2.1.3\n\n`;
            break;
            
        case 'summary':
            output = `[${timestamp}] Summary using delimiter: ${parameters.delimiter}\n`;
            output += `------------------------\n`;
            output += `v1 : 3\n`;
            output += `v2 : 5\n`;
            output += `dev : 2\n\n`;
            break;
            
        default:
            output = `[${timestamp}] Command '${command}' executed successfully!\n\n`;
    }
    
    updateOutput(output);
}

function generateSampleTags() {
    const tags = [
        'v1.0',
        'v1.0/src',
        'v1.1',
        'v2.0',
        'v2.0/src',
        'v2.0/test',
        'v2.1.0',
        'v2.1.3'
    ];
    
    return tags.map(tag => `${tag}`).join('\n') + '\n';
}

function updateOutput(text) {
    const outputElement = document.getElementById('command-output');
    if (outputElement) {
        outputElement.textContent += text;
        outputElement.scrollTop = outputElement.scrollHeight;
    }
}

function clearOutput() {
    const outputElement = document.getElementById('command-output');
    if (outputElement) {
        outputElement.textContent = 'Command output cleared.\n';
    }
}

// Tag Browser Functions
function loadRepository() {
    const timestamp = new Date().toLocaleTimeString();
    updateOutput(`[${timestamp}] Loading repository tags...\n`);
    
    setTimeout(() => {
        updateOutput(`[${timestamp}] Repository loaded successfully!\n`);
        updateOutput(`Found 12 tags in repository.\n`);
        updateTagVisualization();
    }, 1000);
}

function refreshTags() {
    const timestamp = new Date().toLocaleTimeString();
    updateOutput(`[${timestamp}] Refreshing tag information...\n`);
    
    setTimeout(() => {
        updateOutput(`[${timestamp}] Tags refreshed successfully!\n\n`);
        updateTagVisualization();
    }, 800);
}

function filterTags() {
    const searchTerm = document.getElementById('tag-search').value.toLowerCase();
    const tagNodes = document.querySelectorAll('.tag-node');
    
    tagNodes.forEach(node => {
        const tagName = node.querySelector('span').textContent.toLowerCase();
        if (tagName.includes(searchTerm)) {
            node.style.display = 'inline-flex';
        } else {
            node.style.display = 'none';
        }
    });
}

function updateFilter() {
    // This would implement tag filtering based on checkboxes
    console.log('Updating tag filters...');
}

function changeViewMode() {
    const selectedMode = document.querySelector('input[name="view-mode"]:checked').value;
    const timestamp = new Date().toLocaleTimeString();
    updateOutput(`[${timestamp}] Switching to ${selectedMode} view...\n`);
    
    // Here you would implement different visualization modes
    setTimeout(() => {
        updateOutput(`[${timestamp}] View mode changed to ${selectedMode}.\n\n`);
    }, 500);
}

function updateTagVisualization() {
    // Add click handlers to tag nodes for showing details
    const tagNodes = document.querySelectorAll('.tag-node');
    tagNodes.forEach(node => {
        node.addEventListener('click', function() {
            const tagName = this.querySelector('span').textContent;
            showTagDetails(tagName);
        });
    });
}

function showTagDetails(tagName) {
    const tagInfo = document.getElementById('tag-info');
    const sampleData = {
        'v1.0': {
            commit: '1a2b3c4d',
            date: '2024-01-15',
            author: 'John Doe',
            message: 'Release version 1.0',
            artifacts: ['binary', 'documentation']
        },
        'v1.0/src': {
            commit: '2b3c4d5e',
            date: '2024-01-15',
            author: 'John Doe',
            message: 'Source code for v1.0',
            artifacts: ['source files', 'build scripts']
        },
        'v2.0': {
            commit: '3c4d5e6f',
            date: '2024-02-20',
            author: 'Jane Smith',
            message: 'Major release 2.0',
            artifacts: ['binary', 'documentation', 'tests']
        }
    };
    
    const details = sampleData[tagName] || {
        commit: 'abc123',
        date: '2024-01-01',
        author: 'Developer',
        message: `Tag ${tagName}`,
        artifacts: ['unknown']
    };
    
    const detailsHtml = `
        <div class="tag-detail-card">
            <h5><i class="fas fa-tag"></i> ${tagName}</h5>
            <p><strong>Commit:</strong> ${details.commit}</p>
            <p><strong>Date:</strong> ${details.date}</p>
            <p><strong>Author:</strong> ${details.author}</p>
            <p><strong>Message:</strong> ${details.message}</p>
            <p><strong>Artifacts:</strong> ${details.artifacts.join(', ')}</p>
        </div>
    `;
    
    if (tagInfo) {
        tagInfo.innerHTML = detailsHtml;
    }
}

function initializeSampleData() {
    // Initialize the tag visualization with sample data
    updateTagVisualization();
}

// Utility function to simulate API calls in a real implementation
function apiCall(endpoint, data) {
    return new Promise((resolve, reject) => {
        // Simulate network delay
        setTimeout(() => {
            // In a real implementation, this would make actual HTTP requests
            // to a backend API that interfaces with the git-artifact script
            resolve({
                success: true,
                data: data,
                message: 'Command executed successfully'
            });
        }, Math.random() * 1000 + 500);
    });
}

// Export functions for potential use in other modules
window.GitArtifactManager = {
    executeCommand,
    showTab,
    loadRepository,
    refreshTags,
    filterTags,
    updateFilter,
    changeViewMode,
    clearOutput
};