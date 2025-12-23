# git-artifact SPA Showcase

This directory contains the Single Page Application (SPA) showcase for git-artifact, designed to be hosted on GitHub Pages.

## 🎯 Purpose

The SPA provides an interactive demonstration of git-artifact's capabilities, making it easier for users to:
- Understand the library's functionality
- See real command examples
- Learn about use cases
- Get installation guidance
- Access complete API documentation

## 🏗️ Structure

```
docs/
├── index.html          # Main SPA file with all content
├── styles.css          # Responsive CSS styling
├── script.js           # Interactive JavaScript functionality
├── _config.yml         # Jekyll configuration for GitHub Pages
└── README.md           # This file
```

## 🚀 Features

### Interactive Demo
- Tabbed interface for different git-artifact commands
- Copy-to-clipboard functionality
- Real command examples with explanations

### Responsive Design
- Mobile-first approach
- Touch-friendly navigation
- Adaptive layouts for all screen sizes

### Content Sections
1. **Landing Page** - Overview and quick start
2. **Interactive Demo** - Try git-artifact commands
3. **Use Cases** - Real-world scenarios
4. **API Reference** - Complete command documentation
5. **Installation Guide** - Step-by-step setup

## 🛠️ Development

The SPA is built with vanilla HTML, CSS, and JavaScript for:
- ✅ No build dependencies
- ✅ Fast loading times
- ✅ Easy maintenance
- ✅ Direct GitHub Pages compatibility

### Local Development

```bash
# Serve locally for testing
cd docs/
python3 -m http.server 8000
# Visit http://localhost:8000
```

## 🌐 Deployment

The SPA automatically deploys to GitHub Pages via the workflow in `.github/workflows/deploy-pages.yml`.

### Manual GitHub Pages Setup
1. Go to repository Settings > Pages
2. Set Source to "GitHub Actions"
3. The site will be available at: `https://praqma.github.io/git-artifact/`

## 🎨 Design Principles

- **Accessibility**: Semantic HTML, keyboard navigation, focus management
- **Performance**: Optimized images, minimal dependencies, efficient CSS
- **Mobile-First**: Responsive design tested on various screen sizes
- **User Experience**: Smooth animations, clear navigation, helpful feedback

## 🔧 Customization

The SPA can be easily customized by modifying:
- `index.html`: Content structure and sections
- `styles.css`: Visual styling and responsive breakpoints
- `script.js`: Interactive functionality and animations
- `_config.yml`: Jekyll and GitHub Pages settings

## 📦 Dependencies

- **Prism.js** (CDN): Syntax highlighting for code blocks
- **Modern Browser**: ES6+ features, CSS Grid, Flexbox

## 🤝 Contributing

When making changes to the showcase:
1. Test locally using the development server
2. Verify responsive design on multiple screen sizes
3. Check all interactive features work correctly
4. Ensure fast loading times and accessibility

## 📄 License

This showcase follows the same license as the git-artifact project.