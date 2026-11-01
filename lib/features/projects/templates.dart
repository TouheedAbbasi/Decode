import 'package:flutter/material.dart';

class ProjectTemplate {
  const ProjectTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.files,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// File name -> initial content.
  final Map<String, String> files;
}

class Templates {
  Templates._();

  static const blank = ProjectTemplate(
    id: 'blank',
    title: 'Blank Project',
    subtitle: 'Start with a clean slate',
    icon: Icons.code_rounded,
    files: {'index.html': _blankHtml},
  );

  static const htmlCssJs = ProjectTemplate(
    id: 'html_css_js',
    title: 'HTML, CSS & JS',
    subtitle: 'Simple static website',
    icon: Icons.language_rounded,
    files: {
      'index.html': _basicHtml,
      'style.css': _basicCss,
      'script.js': _basicJs,
    },
  );

  static const todo = ProjectTemplate(
    id: 'todo',
    title: 'Todo App',
    subtitle: 'Vanilla JS todo application',
    icon: Icons.check_circle_outline_rounded,
    files: {
      'index.html': todoHtml,
      'style.css': todoCss,
      'script.js': todoJs,
    },
  );

  static const portfolio = ProjectTemplate(
    id: 'portfolio',
    title: 'Portfolio',
    subtitle: 'Personal portfolio template',
    icon: Icons.person_outline_rounded,
    files: {
      'index.html': portfolioHtml,
      'style.css': portfolioCss,
      'script.js': portfolioJs,
    },
  );

  static const starters = [htmlCssJs, todo, portfolio];
  static const all = [blank, htmlCssJs, todo, portfolio];

  static ProjectTemplate byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => blank);
}

const _blankHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Untitled</title>
</head>
<body>

</body>
</html>
''';

const _basicHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Website</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main class="container">
    <h1>Hello, Decode!</h1>
    <p>Edit index.html, style.css and script.js to build your site.</p>
    <button id="btn">Click me</button>
  </main>
  <script src="script.js"></script>
</body>
</html>
''';

const _basicCss = r'''* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: system-ui, sans-serif;
  background: #fafaf8;
  color: #1b1c20;
}

.container {
  max-width: 640px;
  margin: 0 auto;
  padding: 48px 20px;
}

button {
  padding: 12px 20px;
  border: 0;
  border-radius: 8px;
  background: #4f46e5;
  color: #fff;
  font-size: 16px;
}
''';

const _basicJs = r'''document.getElementById('btn').addEventListener('click', () => {
  alert('It works!');
});
''';

const todoHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Todo App</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main class="app">
    <h1>Todo</h1>
    <form id="todo-form">
      <input id="todo-input" type="text" placeholder="Add a task..." autocomplete="off">
      <button type="submit">Add</button>
    </form>
    <ul id="todo-list"></ul>
  </main>
  <script src="script.js"></script>
</body>
</html>
''';

const todoCss = r'''* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: system-ui, sans-serif;
  background: #fafaf8;
  color: #1b1c20;
}

.app { max-width: 480px; margin: 0 auto; padding: 32px 20px; }

form { display: flex; gap: 8px; }

input {
  flex: 1;
  padding: 12px;
  border: 1px solid #e6e6e1;
  border-radius: 8px;
  font-size: 16px;
}

button {
  padding: 12px 16px;
  border: 0;
  border-radius: 8px;
  background: #4f46e5;
  color: #fff;
  font-size: 16px;
}

ul { list-style: none; padding: 0; margin-top: 20px; }

li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  margin-bottom: 8px;
  background: #fff;
  border: 1px solid #e6e6e1;
  border-radius: 8px;
}

li.done span { text-decoration: line-through; opacity: 0.5; }
li button { background: transparent; color: #b42318; padding: 0 8px; }
''';

const todoJs = r'''const form = document.getElementById('todo-form');
const input = document.getElementById('todo-input');
const list = document.getElementById('todo-list');

form.addEventListener('submit', (event) => {
  event.preventDefault();
  const text = input.value.trim();
  if (!text) return;

  const item = document.createElement('li');
  const label = document.createElement('span');
  label.textContent = text;
  item.appendChild(label);

  item.addEventListener('click', () => item.classList.toggle('done'));

  const remove = document.createElement('button');
  remove.textContent = '\u00d7';
  remove.addEventListener('click', (e) => {
    e.stopPropagation();
    item.remove();
  });
  item.appendChild(remove);

  list.appendChild(item);
  input.value = '';
});
''';

const portfolioHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Portfolio</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <header class="header">
    <div class="container">
      <h1 class="logo">Your Name</h1>
      <nav>
        <a href="#about">About</a>
        <a href="#projects">Projects</a>
        <a href="#contact">Contact</a>
      </nav>
    </div>
  </header>

  <section class="container hero">
    <h2>Hi, I build things for the web.</h2>
    <p>Student developer learning HTML, CSS and JavaScript.</p>
  </section>

  <section id="about" class="container">
    <h3>About</h3>
    <p>Write a short introduction about yourself here.</p>
  </section>

  <section id="projects" class="container">
    <h3>Projects</h3>
    <div class="grid">
      <article class="card"><h4>Project One</h4><p>Short description.</p></article>
      <article class="card"><h4>Project Two</h4><p>Short description.</p></article>
    </div>
  </section>

  <footer id="contact" class="container footer">
    <p>Contact: you@example.com</p>
  </footer>
  <script src="script.js"></script>
</body>
</html>
''';

const portfolioCss = r'''* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: system-ui, sans-serif;
  background: #fafaf8;
  color: #1b1c20;
  line-height: 1.6;
}

.container { max-width: 720px; margin: 0 auto; padding: 24px 20px; }

.header { border-bottom: 1px solid #e6e6e1; background: #fff; }
.header .container { display: flex; justify-content: space-between; align-items: center; }
.logo { margin: 0; font-size: 18px; }
nav a { margin-left: 14px; color: #4f46e5; text-decoration: none; }

.hero h2 { font-size: 30px; margin-bottom: 8px; }

.grid { display: grid; gap: 12px; }

.card {
  padding: 16px;
  background: #fff;
  border: 1px solid #e6e6e1;
  border-radius: 10px;
}

.footer { color: #6b6f7b; }
''';

const portfolioJs = r'''document.querySelectorAll('nav a').forEach((link) => {
  link.addEventListener('click', (event) => {
    event.preventDefault();
    const target = document.querySelector(link.getAttribute('href'));
    if (target) target.scrollIntoView({ behavior: 'smooth' });
  });
});
''';
