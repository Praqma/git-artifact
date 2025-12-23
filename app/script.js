// Git Artifact Manager JavaScript
document.addEventListener('DOMContentLoaded', function() {
    // Initialize the application
    initializeApp();
    // Set up event listeners
    setupEventListeners();
    // Fetch and display real git tags
    fetchGitTags();
});
// Fetch git tags from backend and display them, with optional repo path
async function fetchGitTags() {
    const pathInput = document.getElementById('repo-path-input');
    const repoPath = pathInput ? pathInput.value.trim() : '';
    let url = 'http://localhost:8000/tags?';
    if (repoPath) {
        url += `path=${encodeURIComponent(repoPath)}`;
    }
    try {
        const response = await fetch(url);
        const data = await response.json();
        if (response.ok) {
            window._fullTagTree = data.tree;
            displayTagTree(data.tree);
        } else {
            displayTags([], data.error || 'Unknown error');
        }
    } catch (e) {
        displayTags([], e.message);
        console.error('Error fetching tags:', e);
    }
}


// UI filter for tag tree
function filterTagTree() {
    const searchInput = document.getElementById('tag-search');
    const modeInput = document.getElementById('tag-search-mode');
    const filterRaw = searchInput && searchInput.value.trim();
    const mode = modeInput ? modeInput.value : 'plain';
    const tree = window._fullTagTree || {};
    if (!filterRaw) {
        displayTagTree(tree);
        return;
    }
    const filter = filterRaw.toLowerCase();

    // Helper for glob to regex (always case-insensitive)
    function globToRegex(glob) {
        return new RegExp('^' + glob.replace(/[.+^${}()|[\\]\\]/g, '\\$&').replace(/\\*/g, '.*').replace(/\\?/g, '.') + '$', 'i');
    }

    // Recursively filter tree by matching the full path
    function filterTree(node, pathSoFar) {
        const filtered = {};
        for (const key in node) {
            const currentPath = pathSoFar ? pathSoFar + '/' + key : key;
            let match = false;
            let pathToTest = currentPath.toLowerCase();
            if (mode === 'plain') {
                match = pathToTest.includes(filter);
            } else if (mode === 'glob') {
                try {
                    match = globToRegex(filterRaw).test(currentPath);
                } catch {}
            } else if (mode === 'regex') {
                try {
                    const re = new RegExp(filterRaw, 'i');
                    match = re.test(currentPath);
                } catch {}
            }
            if (match) {
                filtered[key] = node[key];
            } else {
                const child = filterTree(node[key], currentPath);
                if (Object.keys(child).length > 0) {
                    filtered[key] = child;
                }
            }
        }
        return filtered;
    }
    // Auto-expand all folders when showing a filtered view
    displayTagTree(filterTree(tree, ''), true);
}


// Display tag tree in the visualization area with collapsible nodes
function displayTagTree(tree, parentOrExpand) {
    // Support optional boolean to expand all in filtered mode, or an explicit parent element
    let expandAll = false;
    let viz = document.getElementById('tag-visualization');
    if (typeof parentOrExpand === 'boolean') {
        expandAll = parentOrExpand;
    } else if (parentOrExpand && typeof parentOrExpand.appendChild === 'function') {
        viz = parentOrExpand;
    }
    if (!viz) return;
    if (!parentOrExpand || typeof parentOrExpand === 'boolean') {
        viz.innerHTML = '<h4>Repository Tags (Tree View)</h4>';
    }
    if (!tree || Object.keys(tree).length === 0) {
        viz.innerHTML += '<p>No tags found.</p>';
        return;
    }
    const ul = document.createElement('ul');
    ul.className = 'tag-tree';
    // Helper to get the full path for each node
    function renderTree(node, parentUl, pathSoFar) {
        for (const key in node) {
            const li = document.createElement('li');
            const hasChildren = Object.keys(node[key]).length > 0;
            const currentPath = pathSoFar ? pathSoFar + '/' + key : key;
            let spanTag = `<span>${key}</span>`;
            if (hasChildren) {
                li.innerHTML = `<span class=\"tree-toggle\" style=\"cursor:pointer;user-select:none;\">▶</span> <i class=\"fas fa-folder\"></i> ${spanTag}`;
                const childUl = document.createElement('ul');
                childUl.style.display = 'none';
                childUl.style.marginLeft = '24px'; // Indent child nodes
                renderTree(node[key], childUl, currentPath);
                li.appendChild(childUl);
                li.querySelector('.tree-toggle').addEventListener('click', function(e) {
                    e.stopPropagation();
                    if (childUl.style.display === 'none') {
                        childUl.style.display = 'block';
                        this.textContent = '▼';
                    } else {
                        childUl.style.display = 'none';
                        this.textContent = '▶';
                    }
                });
                // Auto-expand when in filtered mode
                if (expandAll) {
                    childUl.style.display = 'block';
                    const toggle = li.querySelector('.tree-toggle');
                    if (toggle) toggle.textContent = '▼';
                }
            } else {
                li.innerHTML = `<i class=\"fas fa-tag\"></i> ${spanTag}`;
            }
            // Add selection handler to all tag/folder spans
            const tagSpan = li.querySelector('span:last-of-type');
            if (tagSpan) {
                tagSpan.style.cursor = 'pointer';
                tagSpan.addEventListener('click', async function(e) {
                    e.stopPropagation();
                    // Remove highlight from all previously selected tags
                    document.querySelectorAll('.tag-selected').forEach(el => el.classList.remove('tag-selected'));
                    // Highlight the whole path (all parent <li>s)
                    let current = tagSpan.parentElement;
                    while (current && current !== viz) {
                        if (current.tagName === 'LI') {
                            const span = current.querySelector('span:last-of-type');
                            if (span) span.classList.add('tag-selected');
                        }
                        current = current.parentElement;
                    }
                    // If this is a leaf (no children), fetch tag info
                    if (!hasChildren) {
                        const repoPathInput = document.getElementById('repo-path-input');
                        const repoPath = repoPathInput ? repoPathInput.value.trim() : '';
                        let url = `http://localhost:8000/tag_info?tag=${encodeURIComponent(currentPath)}`;
                        if (repoPath) {
                            url += `&path=${encodeURIComponent(repoPath)}`;
                        }
                        const tagInfoDiv = document.getElementById('tag-info');
                        if (tagInfoDiv) tagInfoDiv.innerHTML = '<em>Loading tag info...</em>';
                        try {
                            const resp = await fetch(url);
                            const data = await resp.json();
                            if (resp.ok && data.info) {
                                tagInfoDiv.innerHTML = `<b>Tag:</b> ${data.tag}<br>` +
                                    `<b>Commit:</b> ${data.info.commit}<br>` +
                                    `<b>Tagger:</b> ${data.info.tagger}<br>` +
                                    `<b>Date:</b> ${data.info.date}<br>` +
                                    `<b>Subject:</b> ${data.info.subject}`;
                            } else if (resp.status === 404) {
                                // Show fetch button if tag not found
                                tagInfoDiv.innerHTML = `<span style='color:red'>${data.error || 'Tag not found.'}</span><br>` +
                                    `<button id='fetch-tag-btn' class='btn btn-primary'>Fetch Tag from Remote</button>`;
                                const fetchBtn = document.getElementById('fetch-tag-btn');
                                if (fetchBtn) {
                                    fetchBtn.onclick = async function() {
                                        tagInfoDiv.innerHTML = '<em>Fetching tag from remote...</em>';
                                        try {
                                            const resp2 = await fetch('http://localhost:8000/fetch_tag', {
                                                method: 'POST',
                                                headers: { 'Content-Type': 'application/json' },
                                                body: JSON.stringify({ tag: currentPath, path: repoPath })
                                            });
                                            const data2 = await resp2.json();
                                            if (resp2.ok && data2.fetched) {
                                                // Immediately call tag_info again and display info
                                                tagInfoDiv.innerHTML = '<em>Fetching tag info...</em>';
                                                try {
                                                    let url2 = `http://localhost:8000/tag_info?tag=${encodeURIComponent(currentPath)}`;
                                                    if (repoPath) {
                                                        url2 += `&path=${encodeURIComponent(repoPath)}`;
                                                    }
                                                    const resp3 = await fetch(url2);
                                                    const data3 = await resp3.json();
                                                    if (resp3.ok && data3.info) {
                                                        tagInfoDiv.innerHTML = `<b>Tag:</b> ${data3.tag}<br>` +
                                                            `<b>Commit:</b> ${data3.info.commit}<br>` +
                                                            `<b>Tagger:</b> ${data3.info.tagger}<br>` +
                                                            `<b>Date:</b> ${data3.info.date}<br>` +
                                                            `<b>Subject:</b> ${data3.info.subject}`;
                                                    } else {
                                                        tagInfoDiv.innerHTML = `<span style='color:red'>${data3.error || 'No info found for tag.'}</span>`;
                                                    }
                                                } catch (err3) {
                                                    tagInfoDiv.innerHTML = `<span style='color:red'>Error loading tag info after fetch</span>`;
                                                }
                                            } else {
                                                tagInfoDiv.innerHTML = `<span style='color:red'>${data2.error || 'Failed to fetch tag.'}</span>`;
                                            }
                                        } catch (err2) {
                                            tagInfoDiv.innerHTML = `<span style='color:red'>Error fetching tag from remote</span>`;
                                        }
                                    };
                                }
                            } else {
                                tagInfoDiv.innerHTML = `<span style='color:red'>${data.error || 'No info found for tag.'}</span>`;
                            }
                        } catch (err) {
                            if (tagInfoDiv) tagInfoDiv.innerHTML = `<span style='color:red'>Error loading tag info</span>`;
                        }
                    }
                });
            }
            parentUl.appendChild(li);
        }
    }
    renderTree(tree, ul, '');
    viz.appendChild(ul);
}

function initializeApp() {
    // Show the Tag Browser tab by default
    showTab('browser');
    
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

    // Tag filter: update on input/change for all relevant controls
    const tagSearch = document.getElementById('tag-search');
    if (tagSearch) {
        tagSearch.addEventListener('input', filterTagTree);
    }
    const tagSearchMode = document.getElementById('tag-search-mode');
    if (tagSearchMode) {
        tagSearchMode.addEventListener('change', filterTagTree);
    }
    // Remove case sensitivity event listener (option removed)
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
    fetchGitTags();
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