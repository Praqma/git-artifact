# Git Artifact Manager Web Application

A modern, responsive web interface for managing git artifacts and visualizing tag relationships.

## Quick Start

From the repository root directory:

```bash
./git-artifact-app
```

Then open http://localhost:8080 in your browser.

## Application Overview

This web application provides three main interfaces:

### 1. Commands Tab
Execute git-artifact commands through an intuitive form-based interface:

- **Repository Operations**
  - Initialize new git artifact repositories
  - Clone existing repositories
  
- **Artifact Operations** 
  - Add and push artifacts with tags
  - Fetch and checkout specific versions
  
- **Discovery Operations**
  - List tags with pattern matching
  - Find latest versions
  - Generate tag summaries

### 2. Tag Browser Tab
Visualize tag relationships in git artifact repositories:

- Interactive graph showing horizontal tag structure
- Click tags to view detailed information (commit, author, date, artifacts)
- Search and filter functionality
- Multiple visualization modes

### 3. Help Tab
Comprehensive documentation including:

- Git-artifact concepts and benefits
- Command reference
- Getting started guide
- Best practices

## Technical Details

### Architecture
- **Frontend**: Pure HTML5, CSS3, and JavaScript (ES6+)
- **Backend**: Python HTTP server for development
- **Styling**: Modern CSS with flexbox and grid layouts
- **Icons**: Font Awesome for consistent iconography

### Browser Compatibility
- Chrome/Chromium 70+
- Firefox 65+
- Safari 12+
- Edge 79+

### Files Structure
```
app/
├── index.html      # Main application page
├── styles.css      # Application styles and responsive design
├── script.js       # Interactive functionality and UI logic
└── README.md       # This file
```

## Features

### Command Interface
- Form validation and error handling
- Real-time command output display
- Automatic command string generation
- Copy-to-clipboard functionality (planned)

### Tag Visualization
- Interactive node-based graph
- Hover effects and click handlers
- Dynamic tag detail display
- Search and filtering capabilities

### Responsive Design
- Mobile-friendly layout
- Tablet and desktop optimized
- Touch-friendly controls
- Accessible keyboard navigation

## Development Mode

The application currently runs in demonstration mode, simulating git-artifact command execution. For production deployment:

1. Implement backend API endpoints
2. Add actual git-artifact command execution
3. Include file system integration
4. Add authentication if needed

## Customization

### Adding New Commands
1. Add form fields to the appropriate section in `index.html`
2. Implement command handling in the `executeCommand()` function in `script.js`
3. Add validation logic in `validateCommand()`
4. Update help documentation

### Modifying Visualization
- Edit the `.demo-graph` section in `index.html` for static elements
- Modify graph generation in `script.js` for dynamic content
- Customize styling in `styles.css` for appearance

### Extending API Integration
- Implement `apiCall()` function in `script.js`
- Add error handling for network requests
- Include progress indicators for long-running operations

## Security Considerations

When deploying to production:

- Validate all user inputs on the server side
- Sanitize command parameters to prevent injection attacks
- Implement proper authentication and authorization
- Use HTTPS for all communications
- Consider rate limiting for command execution

## Performance Optimization

For large repositories:

- Implement pagination for tag lists
- Add lazy loading for tag details
- Use virtual scrolling for large graphs
- Cache frequently accessed data

## Contributing

To contribute to this application:

1. Follow the existing code style and structure
2. Test in multiple browsers
3. Ensure responsive design works on various screen sizes
4. Update documentation for new features
5. Include appropriate error handling