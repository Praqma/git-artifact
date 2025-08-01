// DOM Elements
const hamburger = document.querySelector('.hamburger');
const navMenu = document.querySelector('.nav-menu');
const navLinks = document.querySelectorAll('.nav-link');
const tabBtns = document.querySelectorAll('.tab-btn');
const tabPanels = document.querySelectorAll('.tab-panel');
const copyBtns = document.querySelectorAll('.copy-btn');

// Mobile Navigation Toggle
hamburger?.addEventListener('click', () => {
    hamburger.classList.toggle('active');
    navMenu.classList.toggle('active');
});

// Close mobile menu when clicking on a link
navLinks.forEach(link => {
    link.addEventListener('click', () => {
        hamburger?.classList.remove('active');
        navMenu?.classList.remove('active');
    });
});

// Smooth scrolling for navigation links
navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = link.getAttribute('href');
        const targetSection = document.querySelector(targetId);
        
        if (targetSection) {
            const navHeight = document.querySelector('.navbar').offsetHeight;
            const targetPosition = targetSection.offsetTop - navHeight;
            
            window.scrollTo({
                top: targetPosition,
                behavior: 'smooth'
            });
        }
    });
});

// Tab functionality for demo section
tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        const targetTab = btn.dataset.tab;
        
        // Remove active class from all tabs and panels
        tabBtns.forEach(tab => tab.classList.remove('active'));
        tabPanels.forEach(panel => panel.classList.remove('active'));
        
        // Add active class to clicked tab and corresponding panel
        btn.classList.add('active');
        document.getElementById(`${targetTab}-tab`).classList.add('active');
    });
});

// Copy to clipboard functionality
copyBtns.forEach(btn => {
    btn.addEventListener('click', async () => {
        const textToCopy = btn.dataset.copy;
        
        try {
            await navigator.clipboard.writeText(textToCopy);
            
            // Visual feedback
            const originalText = btn.textContent;
            btn.textContent = 'Copied!';
            btn.classList.add('copy-success');
            
            setTimeout(() => {
                btn.textContent = originalText;
                btn.classList.remove('copy-success');
            }, 1000);
        } catch (err) {
            // Fallback for older browsers
            const textArea = document.createElement('textarea');
            textArea.value = textToCopy;
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
            
            // Visual feedback
            const originalText = btn.textContent;
            btn.textContent = 'Copied!';
            btn.classList.add('copy-success');
            
            setTimeout(() => {
                btn.textContent = originalText;
                btn.classList.remove('copy-success');
            }, 1000);
        }
    });
});

// Navbar scroll effect
let lastScrollTop = 0;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    
    // Add background blur when scrolling
    if (scrollTop > 100) {
        navbar.style.background = 'rgba(255, 255, 255, 0.95)';
        navbar.style.backdropFilter = 'blur(10px)';
    } else {
        navbar.style.background = '#fff';
        navbar.style.backdropFilter = 'none';
    }
    
    lastScrollTop = scrollTop;
});

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in-up');
        }
    });
}, observerOptions);

// Observe sections for animation
document.querySelectorAll('.section').forEach(section => {
    observer.observe(section);
});

// Observe cards and other elements
document.querySelectorAll('.feature-card, .use-case-card, .command-group, .install-step').forEach(element => {
    observer.observe(element);
});

// Active navigation highlighting based on scroll position
const sections = document.querySelectorAll('.section');
const navItems = document.querySelectorAll('.nav-link');

window.addEventListener('scroll', () => {
    let current = '';
    const scrollPos = window.pageYOffset + 200;
    
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        
        if (scrollPos >= sectionTop && scrollPos < sectionTop + sectionHeight) {
            current = section.getAttribute('id');
        }
    });
    
    navItems.forEach(item => {
        item.classList.remove('active');
        if (item.getAttribute('href') === `#${current}`) {
            item.classList.add('active');
        }
    });
});

// Enhanced git graph animation
document.addEventListener('DOMContentLoaded', () => {
    const commits = document.querySelectorAll('.commit');
    
    commits.forEach((commit, index) => {
        commit.style.animationDelay = `${index * 0.1}s`;
        commit.classList.add('fade-in-up');
    });
});

// Interactive command builder (future enhancement)
class CommandBuilder {
    constructor() {
        this.commands = {
            init: {
                base: 'git artifact init',
                options: ['--url', '--path', '--branch']
            },
            clone: {
                base: 'git artifact clone',
                options: ['--url', '--path']
            },
            'add-n-push': {
                base: 'git artifact add-n-push',
                options: ['-t', '-b']
            },
            'fetch-co': {
                base: 'git artifact fetch-co',
                options: ['-t']
            },
            'fetch-co-latest': {
                base: 'git artifact fetch-co-latest',
                options: ['--regex']
            },
            'find-latest': {
                base: 'git artifact find-latest',
                options: ['-r']
            }
        };
    }
    
    buildCommand(command, options = {}) {
        if (!this.commands[command]) {
            return null;
        }
        
        let cmd = this.commands[command].base;
        
        Object.entries(options).forEach(([key, value]) => {
            if (value && this.commands[command].options.includes(key)) {
                cmd += ` ${key}=${value}`;
            }
        });
        
        return cmd;
    }
}

// Initialize command builder
const commandBuilder = new CommandBuilder();

// Performance optimization: Debounce scroll events
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Apply debouncing to scroll events
const debouncedScrollHandler = debounce(() => {
    // Scroll handling code here if needed
}, 16); // ~60fps

// Keyboard navigation support
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        // Close mobile menu on Escape
        hamburger?.classList.remove('active');
        navMenu?.classList.remove('active');
    }
});

// Focus management for accessibility
const focusableElements = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';

function trapFocus(element) {
    const focusableContent = element.querySelectorAll(focusableElements);
    const firstFocusableElement = focusableContent[0];
    const lastFocusableElement = focusableContent[focusableContent.length - 1];

    document.addEventListener('keydown', function(e) {
        if (e.key === 'Tab') {
            if (e.shiftKey) {
                if (document.activeElement === firstFocusableElement) {
                    lastFocusableElement.focus();
                    e.preventDefault();
                }
            } else {
                if (document.activeElement === lastFocusableElement) {
                    firstFocusableElement.focus();
                    e.preventDefault();
                }
            }
        }
    });
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Add loading animation to page elements
    document.body.classList.add('loaded');
    
    // Initialize syntax highlighting if Prism is available
    if (typeof Prism !== 'undefined') {
        Prism.highlightAll();
    }
    
    console.log('git-artifact showcase loaded successfully!');
});