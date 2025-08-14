# Git Artifact Manager - Standalone Application

This standalone web application provides a user-friendly interface for managing git artifacts and visualizing tag relationships.

## Features

### 1. Command Interface
The application provides a graphical interface for executing git-artifact commands:

- **Repository Operations**: Initialize and clone git artifact repositories
- **Artifact Management**: Add, push, fetch, and checkout artifacts 
- **Discovery Operations**: List tags, find latest versions, and generate summaries
- **Real-time Output**: Command execution results displayed in a terminal-style interface

### 2. Tag Browser
Visual representation of tag relationships in git artifact repositories:

- **Interactive Graph**: Shows the horizontal tag structure used by git-artifact
- **Tag Details**: Click any tag to view commit information, author, date, and artifacts
- **Filtering**: Search tags and filter by type (release, development)
- **Multiple Views**: Tree view, graph view, and timeline visualization modes

### 3. Comprehensive Help
Built-in documentation covering:

- Git-artifact concepts and benefits
- Command reference with descriptions
- Getting started guide
- Best practices for artifact management

## Installation and Usage

### Prerequisites
- Python 3.x (for the web server)
- Git (for git-artifact functionality)

### Starting the Application

1. Make the application launcher executable:
   ```bash
   chmod +x git-artifact-app
   ```

2. Start the application:
   ```bash
   ./git-artifact-app
   ```

3. Open your browser to: http://localhost:8080

### Application Structure

```
app/
├── index.html      # Main application interface
├── styles.css      # Application styling
└── script.js       # Interactive functionality
```

## Key Components

### Command Interface
- **Form-based inputs**: Easy-to-use forms for each git-artifact command
- **Validation**: Input validation ensures required fields are provided
- **Command building**: Automatically constructs proper git-artifact command syntax
- **Output display**: Real-time command output with timestamps

### Tag Browser
- **Visual graph**: Interactive representation of tag relationships
- **Horizontal structure**: Demonstrates git-artifact's unique horizontal commit model
- **Tag interaction**: Click tags to view detailed information
- **Search and filter**: Find specific tags or filter by patterns

### Demo Mode
The current implementation runs in demo mode, simulating git-artifact command execution. In a production environment, this would be extended with:

- Backend API integration
- Real git-artifact command execution
- File system access for repository management
- Authentication and authorization

## Extending the Application

### Adding New Commands
1. Add form elements to `index.html`
2. Implement command handling in `script.js`
3. Add validation logic
4. Update help documentation

### Customizing Visualization
The tag browser can be extended with:
- Different graph layouts
- Custom styling for tag types
- Export functionality for graphs
- Integration with git log information

### Backend Integration
For production use, implement:
- RESTful API endpoints
- Command execution service
- Repository file management
- User session management

## Benefits

1. **User-Friendly**: Eliminates need to remember complex command-line syntax
2. **Visual**: Provides clear visualization of tag relationships
3. **Educational**: Built-in help teaches git-artifact concepts
4. **Extensible**: Web-based architecture allows easy customization
5. **Portable**: Runs on any system with Python and a web browser

## Screenshots

The application includes three main tabs:

1. **Commands Tab**: Form-based interface for executing git-artifact commands
2. **Tag Browser Tab**: Visual representation of tag relationships
3. **Help Tab**: Comprehensive documentation and getting started guide

This standalone application makes git-artifact more accessible to users who prefer graphical interfaces while maintaining all the power and flexibility of the command-line tool.