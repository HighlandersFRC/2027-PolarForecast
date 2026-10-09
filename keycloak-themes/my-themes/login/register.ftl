<#import "template.ftl" as layout>

<@layout.registrationLayout; section>

  <#if section = "header">
    <style>
      :root {
        --pf-bg: #080b11;
        --pf-panel: #0d1117;
        --pf-card: #161b22;
        --pf-input: #0d1117;
        --pf-border: #30363d;
        --pf-border-hover: #484f58;
        --pf-text: #f0f6fc;
        --pf-muted: #8b949e;
        --pf-blue: #4f7cff;
        --pf-blue-hover: #638cff;
        --pf-blue-soft: rgba(79, 124, 255, 0.18);
        --pf-focus: rgba(79, 124, 255, 0.3);
        --pf-error: #f85149;
      }

      * {
        box-sizing: border-box;
      }

      html,
      body {
        width: 100%;
        min-height: 100%;
        margin: 0;
        background: var(--pf-bg) !important;
        color: var(--pf-text);
        font-family:
          -apple-system,
          BlinkMacSystemFont,
          "Segoe UI",
          Helvetica,
          Arial,
          sans-serif;
      }

      body {
        overflow-x: hidden;
      }

      #kc-header,
      #kc-header-wrapper,
      .login-pf-page-header,
      .pf-hidden-header {
        display: none !important;
      }

      #kc-content,
      #kc-content-wrapper,
      .login-pf-page,
      .login-pf body,
      .card-pf {
        width: 100% !important;
        max-width: none !important;
        min-height: 100vh !important;
        margin: 0 !important;
        padding: 0 !important;
        background: transparent !important;
        border: 0 !important;
        box-shadow: none !important;
      }

      .pf-page {
        position: fixed;
        inset: 0;
        z-index: 1000;
        display: grid;
        grid-template-columns: minmax(0, 1.05fr) minmax(460px, 0.95fr);
        min-height: 100vh;
        overflow-y: auto;
        background: var(--pf-bg);
      }

      /* ================================================================ */
      /* LEFT SIDE                                                         */
      /* ================================================================ */

      .pf-brand-panel {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        padding: 58px;
        overflow: hidden;
        border-right: 1px solid rgba(255, 255, 255, 0.08);
        background:
          radial-gradient(
            circle at 20% 15%,
            rgba(79, 124, 255, 0.25),
            transparent 35%
          ),
          radial-gradient(
            circle at 80% 80%,
            rgba(14, 165, 233, 0.12),
            transparent 40%
          ),
          linear-gradient(145deg, #07101f, #081426 55%, #08101b);
      }

      .pf-grid-background {
        position: absolute;
        inset: 0;
        opacity: 0.23;
        background-image:
          linear-gradient(rgba(121, 166, 255, 0.1) 1px, transparent 1px),
          linear-gradient(90deg, rgba(121, 166, 255, 0.1) 1px, transparent 1px);
        background-size: 44px 44px;
        mask-image: radial-gradient(
          ellipse at center,
          black 25%,
          transparent 82%
        );
      }

      .pf-background-glow {
        position: absolute;
        width: 600px;
        height: 600px;
        border-radius: 50%;
        background: rgba(37, 99, 235, 0.12);
        filter: blur(100px);
        animation: pfGlow 8s ease-in-out infinite alternate;
      }

      .pf-brand-content {
        position: relative;
        z-index: 2;
        width: 100%;
        max-width: 680px;
      }

      .pf-brand-header {
        display: flex;
        align-items: center;
        gap: 14px;
        margin-bottom: 48px;
      }

      .pf-logo-box {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 64px;
        height: 64px;
        flex-shrink: 0;
        border: 1px solid rgba(121, 166, 255, 0.3);
        border-radius: 19px;
        background:
          linear-gradient(
            145deg,
            rgba(30, 64, 175, 0.5),
            rgba(8, 47, 73, 0.45)
          );
        box-shadow:
          0 18px 40px rgba(0, 0, 0, 0.3),
          inset 0 1px 0 rgba(255, 255, 255, 0.12);
        backdrop-filter: blur(12px);
      }

      .pf-logo {
        width: 49px;
        height: 49px;
        object-fit: contain;
        filter: drop-shadow(0 7px 8px rgba(0, 0, 0, 0.3));
      }

      .pf-brand-name {
        margin: 0;
        color: white;
        font-size: 23px;
        font-weight: 750;
        letter-spacing: -0.5px;
      }

      .pf-brand-tagline {
        margin: 4px 0 0;
        color: #8294aa;
        font-size: 13px;
      }

      .pf-brand-heading {
        max-width: 610px;
        margin: 0;
        color: white;
        font-size: clamp(42px, 5vw, 68px);
        font-weight: 760;
        line-height: 1.03;
        letter-spacing: -2.7px;
      }

      .pf-brand-heading span {
        display: block;
        color: transparent;
        background: linear-gradient(
          90deg,
          #ffffff 0%,
          #bcd5ff 48%,
          #6f9cff 100%
        );
        background-clip: text;
        -webkit-background-clip: text;
      }

      .pf-brand-description {
        max-width: 570px;
        margin: 22px 0 36px;
        color: #a6b4c6;
        font-size: 16px;
        line-height: 1.7;
      }

      /* Match strategy display */

      .pf-match-board {
        position: relative;
        width: 100%;
        padding: 20px;
        overflow: hidden;
        border: 1px solid rgba(121, 166, 255, 0.18);
        border-radius: 18px;
        background:
          linear-gradient(
            135deg,
            rgba(15, 35, 64, 0.78),
            rgba(7, 19, 37, 0.72)
          );
        box-shadow:
          0 26px 60px rgba(0, 0, 0, 0.3),
          inset 0 1px 0 rgba(255, 255, 255, 0.05);
        backdrop-filter: blur(16px);
      }

      .pf-match-board::after {
        position: absolute;
        top: 0;
        left: -80%;
        width: 45%;
        height: 100%;
        content: "";
        background: linear-gradient(
          90deg,
          transparent,
          rgba(121, 166, 255, 0.07),
          transparent
        );
        animation: pfBoardScan 6s ease-in-out infinite;
      }

      .pf-match-header {
        position: relative;
        z-index: 2;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 14px;
        margin-bottom: 18px;
      }

      .pf-match-label {
        display: flex;
        align-items: center;
        gap: 9px;
        color: #e7efff;
        font-size: 13px;
        font-weight: 650;
      }

      .pf-live-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: #3fb950;
        box-shadow: 0 0 11px rgba(63, 185, 80, 0.8);
        animation: pfPulse 1.8s ease-in-out infinite;
      }

      .pf-match-number {
        color: #71849a;
        font-size: 11px;
        font-weight: 650;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }

      .pf-alliance-grid {
        position: relative;
        z-index: 2;
        display: grid;
        grid-template-columns: 1fr auto 1fr;
        align-items: stretch;
        gap: 12px;
      }

      .pf-alliance-card {
        padding: 15px;
        border: 1px solid rgba(255, 255, 255, 0.07);
        border-radius: 12px;
        background: rgba(4, 12, 24, 0.42);
      }

      .pf-alliance-card-red {
        border-top: 2px solid #f85149;
      }

      .pf-alliance-card-blue {
        border-top: 2px solid #4f7cff;
      }

      .pf-alliance-title {
        margin-bottom: 11px;
        color: #8b9aad;
        font-size: 10px;
        font-weight: 700;
        letter-spacing: 0.1em;
        text-transform: uppercase;
      }

      .pf-team-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
        margin-top: 7px;
      }

      .pf-team-number {
        color: #edf3ff;
        font-size: 14px;
        font-weight: 650;
      }

      .pf-team-rating {
        color: #71849a;
        font-size: 10px;
      }

      .pf-versus {
        display: flex;
        align-items: center;
        justify-content: center;
        color: #62758d;
        font-size: 11px;
        font-weight: 750;
      }

      .pf-prediction {
        position: relative;
        z-index: 2;
        display: flex;
        align-items: center;
        gap: 14px;
        margin-top: 14px;
        padding: 13px;
        border-radius: 11px;
        background: rgba(4, 12, 24, 0.4);
      }

      .pf-prediction-icon {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 37px;
        height: 37px;
        flex-shrink: 0;
        color: #9abbff;
        border: 1px solid rgba(121, 166, 255, 0.22);
        border-radius: 10px;
        background: rgba(79, 124, 255, 0.13);
      }

      .pf-prediction-icon svg {
        width: 19px;
        height: 19px;
      }

      .pf-prediction-main {
        flex: 1;
        min-width: 0;
      }

      .pf-prediction-title {
        display: block;
        color: #e7efff;
        font-size: 12px;
        font-weight: 650;
      }

      .pf-prediction-subtitle {
        display: block;
        margin-top: 3px;
        color: #71849a;
        font-size: 10px;
      }

      .pf-confidence {
        color: #89adff;
        font-size: 18px;
        font-weight: 750;
      }

      .pf-feature-row {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        margin-top: 27px;
      }

      .pf-feature {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 8px 12px;
        color: #b8c7d9;
        font-size: 12px;
        font-weight: 600;
        border: 1px solid rgba(121, 166, 255, 0.15);
        border-radius: 999px;
        background: rgba(8, 31, 57, 0.45);
      }

      .pf-feature-dot {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        background: #5f8fff;
        box-shadow: 0 0 8px rgba(95, 143, 255, 0.75);
      }

      /* ================================================================ */
      /* RIGHT SIDE                                                        */
      /* ================================================================ */

      .pf-auth-panel {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        padding: 44px;
        background:
          radial-gradient(
            circle at 100% 0%,
            rgba(79, 124, 255, 0.07),
            transparent 35%
          ),
          var(--pf-panel);
      }

      .pf-auth-wrapper {
        width: 100%;
        max-width: 450px;
      }

      .pf-mobile-brand {
        display: none;
        align-items: center;
        gap: 12px;
        margin-bottom: 27px;
      }

      .pf-mobile-logo-box {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 48px;
        height: 48px;
        border: 1px solid var(--pf-border);
        border-radius: 14px;
        background: linear-gradient(145deg, #17243b, #0b1220);
      }

      .pf-mobile-logo {
        width: 37px;
        height: 37px;
        object-fit: contain;
      }

      .pf-mobile-name {
        margin: 0;
        color: var(--pf-text);
        font-size: 17px;
        font-weight: 700;
      }

      .pf-mobile-caption {
        margin: 3px 0 0;
        color: var(--pf-muted);
        font-size: 12px;
      }

      .pf-auth-heading {
        margin-bottom: 24px;
      }

      .pf-auth-heading h1 {
        margin: 0;
        color: var(--pf-text);
        font-size: 30px;
        font-weight: 650;
        letter-spacing: -0.8px;
      }

      .pf-auth-heading p {
        margin: 9px 0 0;
        color: var(--pf-muted);
        font-size: 14px;
        line-height: 1.55;
      }

      .pf-message,
      .pf-local-error {
        display: flex;
        align-items: flex-start;
        gap: 9px;
        margin-bottom: 16px;
        padding: 11px 13px;
        color: #ffb3ad;
        font-size: 13px;
        line-height: 1.45;
        border: 1px solid rgba(248, 81, 73, 0.45);
        border-radius: 8px;
        background: rgba(248, 81, 73, 0.1);
      }

      .pf-local-error[hidden] {
        display: none;
      }

      .pf-register-card {
        padding: 24px;
        border: 1px solid var(--pf-border);
        border-radius: 10px;
        background: var(--pf-card);
        box-shadow: 0 16px 42px rgba(0, 0, 0, 0.2);
      }

      .pf-form-row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 14px;
      }

      .pf-field {
        margin-bottom: 17px;
      }

      .pf-label {
        display: block;
        margin-bottom: 7px;
        color: var(--pf-text);
        font-size: 13px;
        font-weight: 600;
      }

      .pf-required {
        color: #79a6ff;
      }

      .pf-input-wrapper {
        position: relative;
      }

      .pf-input-icon {
        position: absolute;
        top: 50%;
        left: 13px;
        width: 17px;
        height: 17px;
        color: var(--pf-muted);
        pointer-events: none;
        transform: translateY(-50%);
        transition: color 150ms ease;
      }

      .pf-input {
        width: 100%;
        height: 43px;
        padding: 0 42px 0 40px;
        color: var(--pf-text);
        font-family: inherit;
        font-size: 14px;
        border: 1px solid var(--pf-border);
        border-radius: 7px;
        outline: none;
        background: var(--pf-input);
        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.03);
        transition:
          border-color 150ms ease,
          box-shadow 150ms ease,
          background 150ms ease;
      }

      .pf-input::placeholder {
        color: #6e7681;
      }

      .pf-input:hover {
        border-color: var(--pf-border-hover);
      }

      .pf-input:focus {
        border-color: var(--pf-blue);
        background: #0b1016;
        box-shadow: 0 0 0 3px var(--pf-focus);
      }

      .pf-input-wrapper:focus-within .pf-input-icon {
        color: #79a6ff;
      }

      .pf-input[type="number"] {
        appearance: textfield;
        -moz-appearance: textfield;
      }

      .pf-input[type="number"]::-webkit-inner-spin-button,
      .pf-input[type="number"]::-webkit-outer-spin-button {
        margin: 0;
        appearance: none;
        -webkit-appearance: none;
      }

      .pf-password-toggle {
        position: absolute;
        top: 50%;
        right: 7px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 33px;
        height: 33px;
        padding: 0;
        color: var(--pf-muted);
        border: 0;
        border-radius: 6px;
        background: transparent;
        cursor: pointer;
        transform: translateY(-50%);
      }

      .pf-password-toggle:hover {
        color: var(--pf-text);
        background: rgba(177, 186, 196, 0.12);
      }

      .pf-password-toggle:focus-visible {
        outline: 2px solid var(--pf-blue);
        outline-offset: 1px;
      }

      .pf-password-toggle svg {
        width: 18px;
        height: 18px;
      }

      .pf-button {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 100%;
        min-height: 43px;
        margin-top: 3px;
        padding: 9px 16px;
        color: white;
        font-family: inherit;
        font-size: 14px;
        font-weight: 650;
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 7px;
        background: var(--pf-blue);
        box-shadow:
          0 1px 0 rgba(0, 0, 0, 0.16),
          inset 0 1px 0 rgba(255, 255, 255, 0.13);
        cursor: pointer;
        transition:
          background 150ms ease,
          transform 150ms ease,
          box-shadow 150ms ease;
      }

      .pf-button:hover {
        background: var(--pf-blue-hover);
        box-shadow:
          0 5px 18px rgba(79, 124, 255, 0.24),
          inset 0 1px 0 rgba(255, 255, 255, 0.13);
      }

      .pf-button:active {
        background: #466fe7;
        transform: translateY(1px);
      }

      .pf-button:focus-visible {
        outline: 2px solid #92b2ff;
        outline-offset: 2px;
      }

      .pf-button:disabled {
        opacity: 0.65;
        cursor: wait;
      }

      .pf-login-card {
        margin-top: 15px;
        padding: 16px 18px;
        color: var(--pf-muted);
        font-size: 13px;
        text-align: center;
        border: 1px solid var(--pf-border);
        border-radius: 10px;
        background: rgba(13, 17, 23, 0.45);
      }

      .pf-link {
        color: #79a6ff;
        text-decoration: none;
      }

      .pf-link:hover {
        color: #a8c4ff;
        text-decoration: underline;
      }

      .pf-back-link {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        margin-top: 22px;
        color: var(--pf-muted);
        font-size: 13px;
        text-decoration: none;
      }

      .pf-back-link:hover {
        color: var(--pf-text);
      }

      .pf-back-link svg {
        width: 15px;
        height: 15px;
        transition: transform 150ms ease;
      }

      .pf-back-link:hover svg {
        transform: translateX(-3px);
      }

      @keyframes pfGlow {
        from {
          transform: translate(-70px, -40px) scale(0.9);
        }

        to {
          transform: translate(80px, 50px) scale(1.12);
        }
      }

      @keyframes pfBoardScan {
        0% {
          left: -80%;
        }

        45%,
        100% {
          left: 150%;
        }
      }

      @keyframes pfPulse {
        0%,
        100% {
          opacity: 0.45;
        }

        50% {
          opacity: 1;
        }
      }

      @media (max-width: 900px) {
        .pf-page {
          display: block;
          position: fixed;
          overflow-y: auto;
        }

        .pf-brand-panel {
          display: none;
        }

        .pf-auth-panel {
          min-height: 100vh;
          padding: 34px 22px;
        }

        .pf-auth-wrapper {
          max-width: 470px;
        }

        .pf-mobile-brand {
          display: flex;
        }
      }

      @media (max-width: 520px) {
        .pf-auth-panel {
          align-items: flex-start;
          padding: 26px 15px;
        }

        .pf-auth-heading h1 {
          font-size: 26px;
        }

        .pf-register-card {
          padding: 20px;
        }

        .pf-form-row {
          grid-template-columns: 1fr;
          gap: 0;
        }
      }

      @media (prefers-reduced-motion: reduce) {
        .pf-background-glow,
        .pf-match-board::after,
        .pf-live-dot {
          animation: none !important;
        }
      }
    </style>

    <span class="pf-hidden-header">Create account</span>
  </#if>

  <#if section = "form">
    <main class="pf-page">
      <section class="pf-brand-panel" aria-label="Polar Forecast">
        <div class="pf-grid-background"></div>
        <div class="pf-background-glow"></div>

        <div class="pf-brand-content">
          <div class="pf-brand-header">
            <div class="pf-logo-box">
              <img
                class="pf-logo"
                src="${url.resourcesPath}/img/PolarBearHead.png"
                alt="Polar Forecast logo"
              />
            </div>

            <div>
              <p class="pf-brand-name">Polar Forecast</p>
              <p class="pf-brand-tagline">
                FRC scouting and match predictions
              </p>
            </div>
          </div>

          <h1 class="pf-brand-heading">
            Build your strategy.
            <span>Before the match starts.</span>
          </h1>

          <p class="pf-brand-description">
            Join your scouting team, collect match data, compare robot
            performance, and turn every observation into a better decision.
          </p>

          <div class="pf-match-board">
            <div class="pf-match-header">
              <div class="pf-match-label">
                <span class="pf-live-dot"></span>
                Match forecast
              </div>

              <span class="pf-match-number">Qualification 42</span>
            </div>

            <div class="pf-alliance-grid">
              <div class="pf-alliance-card pf-alliance-card-red">
                <div class="pf-alliance-title">Red alliance</div>

                <div class="pf-team-row">
                  <span class="pf-team-number">118</span>
                  <span class="pf-team-rating">217 OPR</span>
                </div>

                <div class="pf-team-row">
                  <span class="pf-team-number">4499</span>
                  <span class="pf-team-rating">204 OPR</span>
                </div>

                <div class="pf-team-row">
                  <span class="pf-team-number">6328</span>
                  <span class="pf-team-rating">191 OPR</span>
                </div>
              </div>

              <div class="pf-versus">VS</div>

              <div class="pf-alliance-card pf-alliance-card-blue">
                <div class="pf-alliance-title">Blue alliance</div>

                <div class="pf-team-row">
                  <span class="pf-team-number">2996</span>
                  <span class="pf-team-rating">188 OPR</span>
                </div>

                <div class="pf-team-row">
                  <span class="pf-team-number">9068</span>
                  <span class="pf-team-rating">181 OPR</span>
                </div>

                <div class="pf-team-row">
                  <span class="pf-team-number">8044</span>
                  <span class="pf-team-rating">174 OPR</span>
                </div>
              </div>
            </div>

            <div class="pf-prediction">
              <div class="pf-prediction-icon">
                <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
                  <path
                    d="M4 18L9 13L13 16L20 8"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />

                  <path
                    d="M15 8H20V13"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                </svg>
              </div>

              <div class="pf-prediction-main">
                <span class="pf-prediction-title">
                  Red alliance predicted to win
                </span>

                <span class="pf-prediction-subtitle">
                  Based on scouting data and event performance
                </span>
              </div>

              <span class="pf-confidence">86%</span>
            </div>
          </div>

          <div class="pf-feature-row">
            <div class="pf-feature">
              <span class="pf-feature-dot"></span>
              Live scouting
            </div>

            <div class="pf-feature">
              <span class="pf-feature-dot"></span>
              Team analytics
            </div>

            <div class="pf-feature">
              <span class="pf-feature-dot"></span>
              Match forecasts
            </div>
          </div>
        </div>
      </section>

      <section class="pf-auth-panel">
        <div class="pf-auth-wrapper">
          <div class="pf-mobile-brand">
            <div class="pf-mobile-logo-box">
              <img
                class="pf-mobile-logo"
                src="${url.resourcesPath}/img/PolarBearHead.png"
                alt="Polar Forecast logo"
              />
            </div>

            <div>
              <p class="pf-mobile-name">Polar Forecast</p>
              <p class="pf-mobile-caption">
                FRC scouting and predictions
              </p>
            </div>
          </div>

          <div class="pf-auth-heading">
            <h1>Create your account</h1>

            <p>
              Enter your details to get started with Polar Forecast.
            </p>
          </div>

          <#if message?? && message.summary??>
            <div class="pf-message" role="alert">
              ${message.summary}
            </div>
          </#if>

          <div
            id="password-match-error"
            class="pf-local-error"
            role="alert"
            hidden
          >
            The passwords do not match. Please enter them again.
          </div>

          <div class="pf-register-card">
            <form
              id="kc-register-form"
              action="${url.registrationAction}"
              method="post"
              onsubmit="return prepareRegistration();"
            >
              <div class="pf-form-row">
                <div class="pf-field">
                  <label class="pf-label" for="username">
                    Username (e.g. Woody Flowers)<span class="pf-required">*</span>
                  </label>

                  <div class="pf-input-wrapper">
                    <svg
                      class="pf-input-icon"
                      viewBox="0 0 24 24"
                      fill="none"
                      aria-hidden="true"
                    >
                      <path
                        d="M20 21A8 8 0 0 0 4 21M12 13A5 5 0 1 0 12 3A5 5 0 0 0 12 13Z"
                        stroke="currentColor"
                        stroke-width="1.8"
                        stroke-linecap="round"
                      />
                    </svg>

                    <input
                      id="username"
                      class="pf-input"
                      name="username"
                      type="text"
                      placeholder="Username"
                      autocomplete="username"
                      autofocus
                      required
                    />
                  </div>
                </div>

                <div class="pf-field">
                  <label class="pf-label" for="firstName">
                    First name (e.g. Woody)<span class="pf-required">*</span>
                  </label>

                  <div class="pf-input-wrapper">
                    <svg
                      class="pf-input-icon"
                      viewBox="0 0 24 24"
                      fill="none"
                      aria-hidden="true"
                    >
                      <path
                        d="M20 21A8 8 0 0 0 4 21M12 13A5 5 0 1 0 12 3A5 5 0 0 0 12 13Z"
                        stroke="currentColor"
                        stroke-width="1.8"
                        stroke-linecap="round"
                      />
                    </svg>

                    <input
                      id="firstName"
                      class="pf-input"
                      name="firstName"
                      type="text"
                      placeholder="First name"
                      autocomplete="given-name"
                      required
                    />
                  </div>
                </div>
              </div>

              <div class="pf-field">
                <label class="pf-label" for="teamNumber">
                  FRC team number <span class="pf-required">*</span>
                </label>

                <div class="pf-input-wrapper">
                  <svg
                    class="pf-input-icon"
                    viewBox="0 0 24 24"
                    fill="none"
                    aria-hidden="true"
                  >
                    <path
                      d="M4 4H10V10H4V4ZM14 4H20V10H14V4ZM4 14H10V20H4V14ZM14 14H20V20H14V14Z"
                      stroke="currentColor"
                      stroke-width="1.8"
                      stroke-linejoin="round"
                    />
                  </svg>

                  <input
                    id="teamNumber"
                    class="pf-input"
                    name="user.attributes.teamNumber"
                    type="number"
                    min="1"
                    step="1"
                    inputmode="numeric"
                    placeholder="Example: 4499"
                    required
                  />
                </div>
              </div>

              <div class="pf-field">
                <label class="pf-label" for="password">
                  Password <span class="pf-required">*</span>
                </label>

                <div class="pf-input-wrapper">
                  <svg
                    class="pf-input-icon"
                    viewBox="0 0 24 24"
                    fill="none"
                    aria-hidden="true"
                  >
                    <path
                      d="M7 10V7A5 5 0 0 1 17 7V10M6 10H18A2 2 0 0 1 20 12V20A2 2 0 0 1 18 22H6A2 2 0 0 1 4 20V12A2 2 0 0 1 6 10Z"
                      stroke="currentColor"
                      stroke-width="1.8"
                      stroke-linecap="round"
                    />
                  </svg>

                  <input
                    id="password"
                    class="pf-input"
                    name="password"
                    type="password"
                    placeholder="Create a password"
                    autocomplete="new-password"
                    required
                  />

                  <button
                    class="pf-password-toggle"
                    type="button"
                    onclick="togglePassword('password', this)"
                    aria-label="Show password"
                  >
                    <svg
                      class="pf-eye-open"
                      viewBox="0 0 24 24"
                      fill="none"
                      aria-hidden="true"
                    >
                      <path
                        d="M2 12C4.5 7.5 7.8 5.25 12 5.25C16.2 5.25 19.5 7.5 22 12C19.5 16.5 16.2 18.75 12 18.75C7.8 18.75 4.5 16.5 2 12Z"
                        stroke="currentColor"
                        stroke-width="1.8"
                      />

                      <circle
                        cx="12"
                        cy="12"
                        r="3"
                        stroke="currentColor"
                        stroke-width="1.8"
                      />
                    </svg>

                    <svg
                      class="pf-eye-closed"
                      viewBox="0 0 24 24"
                      fill="none"
                      aria-hidden="true"
                      style="display:none;"
                    >
                      <path
                        d="M3 3L21 21M9.5 5.5C10.3 5.3 11.1 5.25 12 5.25C16.2 5.25 19.5 7.5 22 12C21.3 13.3 20.4 14.5 19.4 15.5M6.1 6.1C4.5 7.3 3.1 9.3 2 12C4.5 16.5 7.8 18.75 12 18.75C13.6 18.75 15 18.4 16.3 17.8"
                        stroke="currentColor"
                        stroke-width="1.8"
                        stroke-linecap="round"
                      />
                    </svg>
                  </button>
                </div>
              </div>

              <div class="pf-field">
                <label class="pf-label" for="password-confirm">
                  Confirm password <span class="pf-required">*</span>
                </label>

                <div class="pf-input-wrapper">
                  <svg
                    class="pf-input-icon"
                    viewBox="0 0 24 24"
                    fill="none"
                    aria-hidden="true"
                  >
                    <path
                      d="M7 10V7A5 5 0 0 1 17 7V10M6 10H18A2 2 0 0 1 20 12V20A2 2 0 0 1 18 22H6A2 2 0 0 1 4 20V12A2 2 0 0 1 6 10Z"
                      stroke="currentColor"
                      stroke-width="1.8"
                      stroke-linecap="round"
                    />
                  </svg>

                  <input
                    id="password-confirm"
                    class="pf-input"
                    name="password-confirm"
                    type="password"
                    placeholder="Enter your password again"
                    autocomplete="new-password"
                    required
                  />

                  <button
                    class="pf-password-toggle"
                    type="button"
                    onclick="togglePassword('password-confirm', this)"
                    aria-label="Show password"
                  >
                    <svg
                      class="pf-eye-open"
                      viewBox="0 0 24 24"
                      fill="none"
                      aria-hidden="true"
                    >
                      <path
                        d="M2 12C4.5 7.5 7.8 5.25 12 5.25C16.2 5.25 19.5 7.5 22 12C19.5 16.5 16.2 18.75 12 18.75C7.8 18.75 4.5 16.5 2 12Z"
                        stroke="currentColor"
                        stroke-width="1.8"
                      />

                      <circle
                        cx="12"
                        cy="12"
                        r="3"
                        stroke="currentColor"
                        stroke-width="1.8"
                      />
                    </svg>

                    <svg
                      class="pf-eye-closed"
                      viewBox="0 0 24 24"
                      fill="none"
                      aria-hidden="true"
                      style="display:none;"
                    >
                      <path
                        d="M3 3L21 21M9.5 5.5C10.3 5.3 11.1 5.25 12 5.25C16.2 5.25 19.5 7.5 22 12C21.3 13.3 20.4 14.5 19.4 15.5M6.1 6.1C4.5 7.3 3.1 9.3 2 12C4.5 16.5 7.8 18.75 12 18.75C13.6 18.75 15 18.4 16.3 17.8"
                        stroke="currentColor"
                        stroke-width="1.8"
                        stroke-linecap="round"
                      />
                    </svg>
                  </button>
                </div>
              </div>

              <button
                id="kc-register"
                class="pf-button"
                type="submit"
              >
                <span id="register-button-text">Create account</span>
              </button>
            </form>
          </div>

          <div class="pf-login-card">
            Already have an account?
            <a class="pf-link" href="${url.loginUrl}">
              Sign in
            </a>
          </div>

          <a
            class="pf-back-link"
            href="http://localhost:3000"
          >
            <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path
                d="M19 12H5M11 18L5 12L11 6"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>

            Back to Polar Forecast
          </a>
        </div>
      </section>
    </main>

    <script>
      function togglePassword(fieldId, button) {
        const field = document.getElementById(fieldId);
        const openIcon = button.querySelector(".pf-eye-open");
        const closedIcon = button.querySelector(".pf-eye-closed");
        const showingPassword = field.type === "text";

        field.type = showingPassword ? "password" : "text";
        openIcon.style.display = showingPassword ? "block" : "none";
        closedIcon.style.display = showingPassword ? "none" : "block";

        button.setAttribute(
          "aria-label",
          showingPassword ? "Show password" : "Hide password"
        );

        field.focus();
      }

      function prepareRegistration() {
        const password = document.getElementById("password");
        const confirmation = document.getElementById("password-confirm");
        const error = document.getElementById("password-match-error");
        const button = document.getElementById("kc-register");
        const buttonText = document.getElementById(
          "register-button-text"
        );

        if (password.value !== confirmation.value) {
          error.hidden = false;
          confirmation.focus();
          return false;
        }

        error.hidden = true;
        button.disabled = true;
        buttonText.textContent = "Creating account...";

        return true;
      }
    </script>
  </#if>

</@layout.registrationLayout>