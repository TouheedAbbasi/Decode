import 'package:flutter/material.dart';

import '../projects/templates.dart';
import 'component_item.dart';
import 'component_styles.dart';

/// Chips shown in the library. 'All' and 'My Components' are virtual.
const componentCategories = [
  'All',
  'My Components',
  'Forms',
  'Navigation',
  'UI',
  'Templates',
  'Neumorphism',
  'Glassmorphism',
  'Minimal',
  'Gradient',
  'Dark UI',
  'Brutalism',
];

/// Categories a user component can be filed under.
final userCategories = componentCategories
    .where((c) => c != 'All' && c != 'My Components')
    .toList();

/// Built-in components: the basics plus the design-style sets.
final componentLibrary = <ComponentItem>[
  ..._basicComponents,
  ...styleComponents,
];

final _basicComponents = <ComponentItem>[
  const ComponentItem(
    id: 'login_form',
    name: 'Login Form',
    description: 'Clean and modern login form',
    category: 'Forms',
    icon: Icons.login_rounded,
    html: _loginHtml,
    css: _baseCss + _formCss,
    js: _loginJs,
  ),
  const ComponentItem(
    id: 'signup_form',
    name: 'Signup Form',
    description: 'Registration form with password check',
    category: 'Forms',
    icon: Icons.person_add_alt_rounded,
    html: _signupHtml,
    css: _baseCss + _formCss,
    js: _signupJs,
  ),
  const ComponentItem(
    id: 'navbar',
    name: 'Navbar',
    description: 'Responsive navigation bar',
    category: 'Navigation',
    icon: Icons.menu_rounded,
    html: _navHtml,
    css: _baseCss + _navCss,
    js: _navJs,
  ),
  const ComponentItem(
    id: 'footer',
    name: 'Footer',
    description: 'Simple footer with links',
    category: 'Navigation',
    icon: Icons.vertical_align_bottom_rounded,
    html: _footerHtml,
    css: _baseCss + _footerCss,
  ),
  const ComponentItem(
    id: 'buttons',
    name: 'Buttons',
    description: 'Button variants and sizes',
    category: 'UI',
    icon: Icons.smart_button_rounded,
    html: _buttonsHtml,
    css: _baseCss + _buttonsCss,
  ),
  const ComponentItem(
    id: 'card',
    name: 'Card',
    description: 'Content card component',
    category: 'UI',
    icon: Icons.crop_portrait_rounded,
    html: _cardHtml,
    css: _baseCss + _cardCss,
  ),
  const ComponentItem(
    id: 'hero',
    name: 'Hero Section',
    description: 'Headline, text and call to action',
    category: 'UI',
    icon: Icons.view_agenda_outlined,
    html: _heroHtml,
    css: _baseCss + _heroCss,
  ),
  ComponentItem(
    id: 'portfolio',
    name: 'Portfolio Template',
    description: 'Personal portfolio page',
    category: 'Templates',
    icon: Icons.person_outline_rounded,
    html: bodyOf(portfolioHtml),
    css: portfolioCss,
    js: portfolioJs,
  ),
  const ComponentItem(
    id: 'landing',
    name: 'Landing Page',
    description: 'Hero, features and call to action',
    category: 'Templates',
    icon: Icons.web_rounded,
    html: _landingHtml,
    css: _baseCss + _landingCss,
  ),
  const ComponentItem(
    id: 'calculator',
    name: 'Calculator',
    description: 'Working calculator app',
    category: 'Templates',
    icon: Icons.calculate_outlined,
    html: _calcHtml,
    css: _baseCss + _calcCss,
    js: _calcJs,
  ),
  ComponentItem(
    id: 'todo',
    name: 'To-Do App',
    description: 'Vanilla JS todo application',
    category: 'Templates',
    icon: Icons.check_circle_outline_rounded,
    html: bodyOf(todoHtml),
    css: todoCss,
    js: todoJs,
  ),
];

// ---------------------------------------------------------------- shared CSS

const _baseCss = r'''* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: system-ui, sans-serif;
  background: #fafaf8;
  color: #1b1c20;
  line-height: 1.5;
}

a { color: #4f46e5; }

''';

const _formCss = r'''body {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.auth-form {
  width: 100%;
  max-width: 380px;
  padding: 28px 24px;
  background: #fff;
  border: 1px solid #e6e6e1;
  border-radius: 12px;
}

.auth-form h2 { margin: 0 0 16px; }

.auth-form label {
  display: block;
  margin: 12px 0 6px;
  font-size: 14px;
  font-weight: 600;
}

.auth-form input {
  width: 100%;
  padding: 12px;
  border: 1px solid #e6e6e1;
  border-radius: 8px;
  font-size: 16px;
}

.auth-form input:focus { outline: 2px solid #4f46e5; border-color: transparent; }

.auth-form button {
  width: 100%;
  margin-top: 20px;
  padding: 12px;
  border: 0;
  border-radius: 8px;
  background: #4f46e5;
  color: #fff;
  font-size: 16px;
  font-weight: 600;
}

.hint { margin: 16px 0 0; font-size: 14px; color: #6b6f7b; text-align: center; }
''';

// ---------------------------------------------------------------------- forms

const _loginHtml = r'''<form class="auth-form" id="login-form">
  <h2>Welcome back</h2>
  <label for="email">Email</label>
  <input id="email" type="email" placeholder="you@example.com" required>
  <label for="password">Password</label>
  <input id="password" type="password" placeholder="Your password" required>
  <button type="submit">Log in</button>
  <p class="hint">No account? <a href="#">Sign up</a></p>
</form>''';

const _loginJs = r'''const form = document.getElementById('login-form');
const hint = form.querySelector('.hint');

form.addEventListener('submit', (event) => {
  event.preventDefault();
  hint.textContent = 'Demo only: nothing was sent anywhere.';
});
''';

const _signupHtml = r'''<form class="auth-form" id="signup-form">
  <h2>Create account</h2>
  <label for="name">Name</label>
  <input id="name" type="text" placeholder="Your name" required>
  <label for="email">Email</label>
  <input id="email" type="email" placeholder="you@example.com" required>
  <label for="password">Password</label>
  <input id="password" type="password" minlength="6" placeholder="At least 6 characters" required>
  <label for="confirm">Confirm password</label>
  <input id="confirm" type="password" placeholder="Repeat password" required>
  <button type="submit">Sign up</button>
  <p class="hint" id="message">Already have an account? <a href="#">Log in</a></p>
</form>''';

const _signupJs = r'''const form = document.getElementById('signup-form');
const message = document.getElementById('message');

form.addEventListener('submit', (event) => {
  event.preventDefault();
  const password = document.getElementById('password').value;
  const confirm = document.getElementById('confirm').value;

  if (password !== confirm) {
    message.textContent = 'Passwords do not match.';
    return;
  }
  message.textContent = 'Demo only: nothing was sent anywhere.';
});
''';

// ----------------------------------------------------------------- navigation

const _navCss = r'''.navbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  background: #fff;
  border-bottom: 1px solid #e6e6e1;
}

.brand { font-weight: 700; font-size: 18px; color: #1b1c20; text-decoration: none; }

.menu-btn {
  display: none;
  border: 1px solid #e6e6e1;
  background: #fff;
  border-radius: 8px;
  padding: 6px 10px;
  font-size: 18px;
}

.nav-links { display: flex; gap: 18px; }
.nav-links a { text-decoration: none; color: #1b1c20; }
.nav-links a:hover { color: #4f46e5; }

@media (max-width: 600px) {
  .menu-btn { display: block; }
  .nav-links { display: none; width: 100%; flex-direction: column; gap: 12px; padding-top: 14px; }
  .nav-links.open { display: flex; }
}
''';

const _navHtml = r'''<nav class="navbar">
  <a class="brand" href="#">Brand</a>
  <button class="menu-btn" id="menu-btn" aria-label="Toggle menu">&#9776;</button>
  <div class="nav-links" id="nav-links">
    <a href="#">Home</a>
    <a href="#">About</a>
    <a href="#">Projects</a>
    <a href="#">Contact</a>
  </div>
</nav>''';

const _navJs = r'''const menuBtn = document.getElementById('menu-btn');
const links = document.getElementById('nav-links');

menuBtn.addEventListener('click', () => {
  links.classList.toggle('open');
});
''';

const _footerCss = r'''body { min-height: 100vh; display: flex; flex-direction: column; }
main { flex: 1; padding: 24px 20px; }

.footer {
  padding: 24px 20px;
  background: #fff;
  border-top: 1px solid #e6e6e1;
  text-align: center;
  color: #6b6f7b;
  font-size: 14px;
}

.footer nav { display: flex; justify-content: center; gap: 16px; margin-bottom: 10px; }
.footer a { color: #1b1c20; text-decoration: none; }
''';

const _footerHtml = r'''<main>
  <h1>Page content</h1>
</main>

<footer class="footer">
  <nav>
    <a href="#">Privacy</a>
    <a href="#">Terms</a>
    <a href="#">Contact</a>
  </nav>
  <p>&copy; 2026 Your Name. All rights reserved.</p>
</footer>''';

// ------------------------------------------------------------------------- UI

const _buttonsCss = r'''body { padding: 24px 20px; }

.row { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin-bottom: 20px; }

.btn {
  padding: 10px 18px;
  border: 1px solid transparent;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 600;
}

.btn-primary { background: #4f46e5; color: #fff; }
.btn-secondary { background: #ececf1; color: #1b1c20; }
.btn-outline { background: transparent; border-color: #4f46e5; color: #4f46e5; }
.btn-danger { background: #d92d20; color: #fff; }
.btn-sm { padding: 6px 12px; font-size: 13px; }
.btn-lg { padding: 14px 26px; font-size: 17px; }
.btn:disabled { opacity: 0.5; }
''';

const _buttonsHtml = r'''<div class="row">
  <button class="btn btn-primary">Primary</button>
  <button class="btn btn-secondary">Secondary</button>
  <button class="btn btn-outline">Outline</button>
  <button class="btn btn-danger">Danger</button>
</div>

<div class="row">
  <button class="btn btn-primary btn-sm">Small</button>
  <button class="btn btn-primary">Medium</button>
  <button class="btn btn-primary btn-lg">Large</button>
  <button class="btn btn-primary" disabled>Disabled</button>
</div>''';

const _cardCss = r'''body { padding: 24px 20px; }

.card {
  max-width: 340px;
  overflow: hidden;
  background: #fff;
  border: 1px solid #e6e6e1;
  border-radius: 12px;
}

.card-image { height: 160px; background: linear-gradient(135deg, #c7c3fb, #e9e8fd); }
.card-body { padding: 16px; }
.card-title { margin: 0 0 6px; font-size: 18px; }
.card-text { margin: 0 0 14px; color: #6b6f7b; font-size: 14px; }

.card-btn {
  padding: 9px 16px;
  border: 0;
  border-radius: 8px;
  background: #4f46e5;
  color: #fff;
  font-weight: 600;
}
''';

const _cardHtml = r'''<article class="card">
  <div class="card-image"></div>
  <div class="card-body">
    <h3 class="card-title">Card title</h3>
    <p class="card-text">A short description of what this card is about.</p>
    <button class="card-btn">Read more</button>
  </div>
</article>''';

const _heroCss = r'''.hero {
  max-width: 720px;
  margin: 0 auto;
  padding: 72px 20px;
  text-align: center;
}

.hero h1 { margin: 0 0 12px; font-size: 38px; line-height: 1.15; }
.hero p { margin: 0 0 24px; color: #6b6f7b; font-size: 17px; }

.hero-actions { display: flex; justify-content: center; flex-wrap: wrap; gap: 12px; }

.hero-actions a {
  padding: 12px 22px;
  border-radius: 8px;
  font-weight: 600;
  text-decoration: none;
}

.primary { background: #4f46e5; color: #fff; }
.secondary { border: 1px solid #e6e6e1; background: #fff; color: #1b1c20; }
''';

const _heroHtml = r'''<section class="hero">
  <h1>Build something great</h1>
  <p>Code, create and ship from your phone.</p>
  <div class="hero-actions">
    <a class="primary" href="#">Get started</a>
    <a class="secondary" href="#">Learn more</a>
  </div>
</section>''';

// ------------------------------------------------------------------ templates

const _landingCss = r'''.hero { padding: 64px 20px; text-align: center; background: #fff; border-bottom: 1px solid #e6e6e1; }
.hero h1 { margin: 0 0 10px; font-size: 34px; }
.hero p { margin: 0 auto 22px; max-width: 460px; color: #6b6f7b; }

.btn {
  display: inline-block;
  padding: 12px 22px;
  border-radius: 8px;
  background: #4f46e5;
  color: #fff;
  font-weight: 600;
  text-decoration: none;
}

.features {
  max-width: 900px;
  margin: 0 auto;
  padding: 40px 20px;
  display: grid;
  gap: 14px;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}

.feature { padding: 18px; background: #fff; border: 1px solid #e6e6e1; border-radius: 10px; }
.feature h3 { margin: 0 0 6px; }
.feature p { margin: 0; color: #6b6f7b; font-size: 14px; }

.cta { padding: 48px 20px; text-align: center; }
.footer { padding: 20px; text-align: center; color: #6b6f7b; font-size: 14px; }
''';

const _landingHtml = r'''<header class="hero">
  <h1>Your product, simply explained</h1>
  <p>One clear sentence about what you offer and who it is for.</p>
  <a class="btn" href="#cta">Get started</a>
</header>

<section class="features">
  <div class="feature"><h3>Fast</h3><p>Loads quickly on any device.</p></div>
  <div class="feature"><h3>Simple</h3><p>Easy to understand and use.</p></div>
  <div class="feature"><h3>Free</h3><p>No ads and no sign-up needed.</p></div>
</section>

<section class="cta" id="cta">
  <h2>Ready to begin?</h2>
  <a class="btn" href="#">Join now</a>
</section>

<footer class="footer">&copy; 2026 Your Name</footer>''';

const _calcCss = r'''body {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.calculator {
  width: 100%;
  max-width: 320px;
  padding: 16px;
  background: #fff;
  border: 1px solid #e6e6e1;
  border-radius: 14px;
}

#display {
  margin-bottom: 12px;
  padding: 16px 12px;
  background: #f3f3f0;
  border-radius: 8px;
  text-align: right;
  font-size: 32px;
  overflow: hidden;
}

.keys { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }

.keys button {
  padding: 16px 0;
  border: 1px solid #e6e6e1;
  border-radius: 8px;
  background: #fff;
  font-size: 20px;
}

.keys .op { background: #eeedfc; color: #4f46e5; }
.keys .equals { background: #4f46e5; color: #fff; }
.keys .wide { grid-column: span 4; }
''';

const _calcHtml = r'''<div class="calculator">
  <div id="display">0</div>
  <div class="keys">
    <button data-key="7">7</button>
    <button data-key="8">8</button>
    <button data-key="9">9</button>
    <button class="op" data-key="/">&divide;</button>

    <button data-key="4">4</button>
    <button data-key="5">5</button>
    <button data-key="6">6</button>
    <button class="op" data-key="*">&times;</button>

    <button data-key="1">1</button>
    <button data-key="2">2</button>
    <button data-key="3">3</button>
    <button class="op" data-key="-">&minus;</button>

    <button data-key="0">0</button>
    <button data-key=".">.</button>
    <button class="equals" data-key="=">=</button>
    <button class="op" data-key="+">+</button>

    <button class="wide" data-key="C">Clear</button>
  </div>
</div>''';

const _calcJs = r'''const display = document.getElementById('display');
let current = '0';
let previous = null;
let operator = null;
let fresh = true;

function render() {
  display.textContent = current;
}

function compute(a, b, op) {
  switch (op) {
    case '+': return a + b;
    case '-': return a - b;
    case '*': return a * b;
    case '/': return b === 0 ? NaN : a / b;
    default: return b;
  }
}

function format(value) {
  return Number.isFinite(value) ? String(parseFloat(value.toFixed(10))) : 'Error';
}

document.querySelectorAll('.keys button').forEach((btn) => {
  btn.addEventListener('click', () => {
    const key = btn.dataset.key;

    if (/^[0-9]$/.test(key)) {
      current = fresh || current === '0' ? key : current + key;
      fresh = false;
    } else if (key === '.') {
      if (fresh) {
        current = '0.';
        fresh = false;
      } else if (!current.includes('.')) {
        current += '.';
      }
    } else if (key === 'C') {
      current = '0';
      previous = null;
      operator = null;
      fresh = true;
    } else if (key === '=') {
      if (operator !== null && previous !== null) {
        current = format(compute(previous, parseFloat(current), operator));
        previous = null;
        operator = null;
        fresh = true;
      }
    } else {
      if (operator !== null && previous !== null && !fresh) {
        current = format(compute(previous, parseFloat(current), operator));
      }
      previous = parseFloat(current);
      if (Number.isNaN(previous)) {
        previous = null;
        operator = null;
        current = '0';
      } else {
        operator = key;
      }
      fresh = true;
    }
    render();
  });
});

render();
''';
