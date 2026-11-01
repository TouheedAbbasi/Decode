import 'package:flutter/material.dart';

import 'component_item.dart';

/// Design-style sets. Every style ships the same three pieces (card, buttons,
/// login form) so they can be compared side by side; only the CSS differs.
final styleComponents = <ComponentItem>[
  ..._styleSet('neu', 'Neumorphism', Icons.bubble_chart_outlined, _neuCss),
  ..._styleSet('glass', 'Glassmorphism', Icons.blur_on_rounded, _glassCss),
  ..._styleSet('minimal', 'Minimal', Icons.crop_square_rounded, _minimalCss),
  ..._styleSet('gradient', 'Gradient', Icons.gradient_rounded, _gradientCss),
  ..._styleSet('dark', 'Dark UI', Icons.dark_mode_outlined, _darkCss),
  ..._styleSet('brutal', 'Brutalism', Icons.square_rounded, _brutalCss),
];

List<ComponentItem> _styleSet(
  String key,
  String label,
  IconData icon,
  String css,
) =>
    [
      ComponentItem(
        id: '${key}_card',
        name: '$label Card',
        description: 'Card in $label style',
        category: label,
        icon: icon,
        html: _cardHtml,
        css: _stageCss + css,
      ),
      ComponentItem(
        id: '${key}_buttons',
        name: '$label Buttons',
        description: 'Buttons in $label style',
        category: label,
        icon: icon,
        html: _buttonsHtml,
        css: _stageCss + css,
      ),
      ComponentItem(
        id: '${key}_login',
        name: '$label Login',
        description: 'Login form in $label style',
        category: label,
        icon: icon,
        html: _loginHtml,
        css: _stageCss + css,
        js: _loginJs,
      ),
    ];

// ------------------------------------------------------------------ markup

const _cardHtml = r'''<article class="card">
  <div class="card-image"></div>
  <div class="card-body">
    <h3>Card title</h3>
    <p>A short description of what this card is about.</p>
    <button class="btn primary">Read more</button>
  </div>
</article>''';

const _buttonsHtml = r'''<div class="row">
  <button class="btn">Default</button>
  <button class="btn primary">Primary</button>
  <button class="btn" disabled>Disabled</button>
</div>''';

const _loginHtml = r'''<form class="auth-form" id="login-form">
  <h2>Welcome back</h2>
  <input id="email" type="email" placeholder="Email" required>
  <input id="password" type="password" placeholder="Password" required>
  <button class="btn primary" type="submit">Log in</button>
  <p class="hint">Demo only: nothing is sent anywhere.</p>
</form>''';

const _loginJs = r'''const form = document.getElementById('login-form');
const hint = form.querySelector('.hint');

form.addEventListener('submit', (event) => {
  event.preventDefault();
  hint.textContent = 'Signed in (demo).';
});
''';

// ------------------------------------------------------------- shared layout

const _stageCss = r'''* { box-sizing: border-box; }

body {
  margin: 0;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 24px;
  padding: 24px;
  font-family: system-ui, sans-serif;
}

.row { display: flex; flex-wrap: wrap; gap: 16px; justify-content: center; }
.card { width: 100%; max-width: 320px; overflow: hidden; }
.card-image { height: 140px; }
.card-body { padding: 18px; }
.card-body h3 { margin: 0 0 6px; }
.card-body p { margin: 0 0 16px; font-size: 14px; }
.auth-form { width: 100%; max-width: 340px; padding: 26px 22px; display: flex; flex-direction: column; gap: 14px; }
.auth-form h2 { margin: 0; }
.auth-form input { padding: 13px 14px; font-size: 16px; border: 0; outline: 0; }
.hint { margin: 0; font-size: 13px; text-align: center; }
.btn { padding: 12px 22px; font-size: 15px; font-weight: 600; border: 0; cursor: pointer; }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }

''';

// ------------------------------------------------------------------- styles

const _neuCss = r'''body { background: #e0e5ec; color: #3d4852; }

.card, .auth-form {
  background: #e0e5ec;
  border-radius: 22px;
  box-shadow: 9px 9px 18px #a3b1c6, -9px -9px 18px #ffffff;
}

.card-image {
  margin: 16px 16px 0;
  border-radius: 16px;
  background: #e0e5ec;
  box-shadow: inset 6px 6px 12px #a3b1c6, inset -6px -6px 12px #ffffff;
}

.btn {
  border-radius: 14px;
  background: #e0e5ec;
  color: #3d4852;
  box-shadow: 6px 6px 12px #a3b1c6, -6px -6px 12px #ffffff;
}

.btn:active { box-shadow: inset 4px 4px 8px #a3b1c6, inset -4px -4px 8px #ffffff; }
.btn.primary { color: #4f46e5; }

.auth-form input {
  border-radius: 12px;
  background: #e0e5ec;
  color: #3d4852;
  box-shadow: inset 5px 5px 10px #a3b1c6, inset -5px -5px 10px #ffffff;
}

.hint, .card-body p { color: #6b7785; }
''';

const _glassCss = r'''body { background: linear-gradient(135deg, #6d63f5, #ec4899 55%, #f59e0b); color: #fff; }

.card, .auth-form {
  background: rgba(255, 255, 255, 0.18);
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 20px;
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  box-shadow: 0 8px 32px rgba(31, 38, 135, 0.25);
}

.card-image { background: rgba(255, 255, 255, 0.25); }

.btn {
  border: 1px solid rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}

.btn.primary { background: rgba(255, 255, 255, 0.85); color: #4f46e5; }

.auth-form input {
  border: 1px solid rgba(255, 255, 255, 0.45);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
}

.auth-form input::placeholder { color: rgba(255, 255, 255, 0.8); }
.hint, .card-body p { color: rgba(255, 255, 255, 0.9); }
''';

const _minimalCss = r'''body { background: #ffffff; color: #111111; }

.card, .auth-form { background: #fff; border: 1px solid #e5e5e5; border-radius: 6px; }
.card-image { background: #f2f2f2; }

.btn {
  border: 1px solid #111;
  border-radius: 6px;
  background: #fff;
  color: #111;
}

.btn.primary { background: #111; color: #fff; }

.auth-form input {
  border: 0;
  border-bottom: 1px solid #cfcfcf;
  border-radius: 0;
  padding-left: 0;
  background: transparent;
  color: #111;
}

.auth-form input:focus { border-bottom-color: #111; }
.hint, .card-body p { color: #777; }
''';

const _gradientCss = r'''body { background: #0f172a; color: #f8fafc; }

.card, .auth-form { background: #1e293b; border-radius: 18px; overflow: hidden; }
.card-image { background: linear-gradient(135deg, #6366f1, #ec4899); }

.btn {
  border-radius: 999px;
  background: #334155;
  color: #f8fafc;
}

.btn.primary { background: linear-gradient(90deg, #6366f1, #ec4899); }

.auth-form h2 {
  background: linear-gradient(90deg, #818cf8, #f472b6);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.auth-form input { border-radius: 12px; background: #0f172a; color: #f8fafc; }
.hint, .card-body p { color: #94a3b8; }
''';

const _darkCss = r'''body { background: #0e1015; color: #e9eaef; }

.card, .auth-form { background: #161922; border: 1px solid #262a36; border-radius: 12px; }
.card-image { background: #1d2130; }

.btn {
  border: 1px solid #262a36;
  border-radius: 8px;
  background: #1d2130;
  color: #e9eaef;
}

.btn.primary { border-color: transparent; background: #7168f7; color: #fff; }

.auth-form input {
  border: 1px solid #262a36;
  border-radius: 8px;
  background: #0e1015;
  color: #e9eaef;
}

.auth-form input:focus { border-color: #7168f7; }
.hint, .card-body p { color: #8d93a5; }
''';

const _brutalCss = r'''body { background: #fff4d6; color: #000; }

.card, .auth-form {
  background: #fff;
  border: 3px solid #000;
  border-radius: 0;
  box-shadow: 6px 6px 0 #000;
}

.card-image { border-bottom: 3px solid #000; background: #ffde59; }
.card-body h3, .auth-form h2 { text-transform: uppercase; }

.btn {
  border: 3px solid #000;
  border-radius: 0;
  background: #fff;
  color: #000;
  text-transform: uppercase;
  box-shadow: 4px 4px 0 #000;
}

.btn:active { transform: translate(4px, 4px); box-shadow: none; }
.btn.primary { background: #ff6b6b; }

.auth-form input { border: 3px solid #000; border-radius: 0; background: #fff; color: #000; }
.hint, .card-body p { color: #222; }
''';
