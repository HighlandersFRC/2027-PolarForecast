<#import "template.ftl" as layout>

<@layout.registrationLayout displayMessage=false; section>

  <#if section = "header">
    <style>
      :root {
        --pf-background: #070a10;
        --pf-panel: #0d1117;
        --pf-card: #161b22;
        --pf-card-hover: #1c2128;
        --pf-border: #30363d;
        --pf-border-muted: rgba(255, 255, 255, 0.08);
        --pf-text: #f0f6fc;
        --pf-text-muted: #8b949e;
        --pf-blue: #58a6ff;
        --pf-blue-bright: #79c0ff;
        --pf-green: #3fb950;
        --pf-error: #f85149;
        --pf-focus: rgba(88, 166, 255, 0.32);
      }

      * {
        box-sizing: border-box;
      }

      html,
      body {
        width: 100%;
        min-height: 100%;
        margin: 0;
        background: var(--pf-background) !important;
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
      .login-pf-page-header {
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
        border: none !important;
        box-shadow: none !important;
      }

      .pf-page {
        position: fixed;
        inset: 0;
        z-index: 1000;
        display: grid;
        grid-template-columns: minmax(0, 1.15fr) minmax(440px, 0.85fr);
        min-height: 100vh;
        overflow: auto;
        background: var(--pf-background);
      }

      /* ------------------------------------------------------------------ */
      /* LEFT BRAND PANEL                                                    */
      /* ------------------------------------------------------------------ */

      .pf-brand-panel {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        padding: 64px;
        overflow: hidden;
        background:
          radial-gradient(
            circle at 20% 20%,
            rgba(37, 99, 235, 0.25),
            transparent 38%
          ),
          radial-gradient(
            circle at 80% 75%,
            rgba(14, 165, 233, 0.18),
            transparent 42%
          ),
          linear-gradient(145deg, #07101f 0%, #081426 45%, #09101c 100%);
        border-right: 1px solid var(--pf-border-muted);
      }

      .pf-grid {
        position: absolute;
        inset: 0;
        opacity: 0.22;
        background-image:
          linear-gradient(rgba(88, 166, 255, 0.12) 1px, transparent 1px),
          linear-gradient(90deg, rgba(88, 166, 255, 0.12) 1px, transparent 1px);
        background-size: 48px 48px;
        mask-image: linear-gradient(
          to bottom,
          transparent,
          black 20%,
          black 80%,
          transparent
        );
      }

      .pf-glow {
        position: absolute;
        width: 620px;
        height: 620px;
        border-radius: 50%;
        background: rgba(37, 99, 235, 0.12);
        filter: blur(90px);
        animation: pfGlow 7s ease-in-out infinite alternate;
      }

      .pf-snow {
        position: absolute;
        inset: 0;
        pointer-events: none;
        overflow: hidden;
      }

      .pf-snowflake {
        position: absolute;
        top: -30px;
        color: rgba(186, 230, 253, 0.4);
        font-size: 14px;
        animation-name: pfSnowfall;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
      }

      .pf-snowflake:nth-child(1) {
        left: 8%;
        animation-duration: 12s;
        animation-delay: -4s;
      }

      .pf-snowflake:nth-child(2) {
        left: 21%;
        font-size: 9px;
        animation-duration: 17s;
        animation-delay: -10s;
      }

      .pf-snowflake:nth-child(3) {
        left: 37%;
        font-size: 17px;
        animation-duration: 14s;
        animation-delay: -7s;
      }

      .pf-snowflake:nth-child(4) {
        left: 53%;
        font-size: 11px;
        animation-duration: 19s;
        animation-delay: -15s;
      }

      .pf-snowflake:nth-child(5) {
        left: 67%;
        font-size: 15px;
        animation-duration: 13s;
        animation-delay: -2s;
      }

      .pf-snowflake:nth-child(6) {
        left: 81%;
        font-size: 8px;
        animation-duration: 18s;
        animation-delay: -12s;
      }

      .pf-snowflake:nth-child(7) {
        left: 92%;
        font-size: 13px;
        animation-duration: 15s;
        animation-delay: -8s;
      }

      .pf-brand-content {
        position: relative;
        z-index: 2;
        width: 100%;
        max-width: 680px;
      }

      .pf-logo-scene {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 290px;
        height: 290px;
        margin: 0 auto 42px;
      }

      .pf-logo-orbit {
        position: absolute;
        inset: 0;
        border: 1px solid rgba(88, 166, 255, 0.22);
        border-radius: 50%;
        animation: pfRotate 22s linear infinite;
      }

      .pf-logo-orbit::before {
        position: absolute;
        top: 27px;
        left: 32px;
        width: 13px;
        height: 13px;
        content: "";
        border-radius: 50%;
        background: var(--pf-blue-bright);
        box-shadow:
          0 0 12px var(--pf-blue),
          0 0 28px rgba(88, 166, 255, 0.65);
      }

      .pf-logo-orbit-secondary {
        position: absolute;
        inset: 27px;
        border: 1px dashed rgba(125, 211, 252, 0.18);
        border-radius: 50%;
        animation: pfRotateReverse 16s linear infinite;
      }

      .pf-logo-orbit-secondary::before {
        position: absolute;
        right: 8px;
        bottom: 44px;
        width: 9px;
        height: 9px;
        content: "";
        border-radius: 50%;
        background: #bae6fd;
        box-shadow: 0 0 16px rgba(186, 230, 253, 0.8);
      }

      .pf-logo-circle {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 190px;
        height: 190px;
        border: 1px solid rgba(125, 211, 252, 0.32);
        border-radius: 50%;
        background:
          linear-gradient(
            145deg,
            rgba(30, 64, 175, 0.5),
            rgba(8, 47, 73, 0.44)
          );
        box-shadow:
          0 24px 70px rgba(0, 0, 0, 0.45),
          inset 0 1px 0 rgba(255, 255, 255, 0.15),
          0 0 60px rgba(37, 99, 235, 0.22);
        animation: pfFloat 4.5s ease-in-out infinite;
        backdrop-filter: blur(18px);
      }

      .pf-logo-circle::after {
        position: absolute;
        inset: 9px;
        content: "";
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: inherit;
      }

      .pf-logo {
        position: relative;
        z-index: 2;
        width: 132px;
        height: 132px;
        object-fit: contain;
        filter:
          drop-shadow(0 14px 20px rgba(0, 0, 0, 0.35))
          drop-shadow(0 0 18px rgba(125, 211, 252, 0.22));
      }

      .pf-brand-heading {
        margin: 0;
        color: #ffffff;
        font-size: clamp(42px, 5vw, 68px);
        font-weight: 750;
        line-height: 1.02;
        letter-spacing: -2.5px;
        text-align: center;
      }

      .pf-brand-heading span {
        display: block;
        color: transparent;
        background: linear-gradient(
          90deg,
          #ffffff 0%,
          #bae6fd 45%,
          #60a5fa 100%
        );
        background-clip: text;
        -webkit-background-clip: text;
      }

      .pf-brand-description {
        max-width: 560px;
        margin: 22px auto 0;
        color: #a9b8ca;
        font-size: 17px;
        line-height: 1.7;
        text-align: center;
      }

      .pf-feature-row {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        gap: 10px;
        margin-top: 34px;
      }

      .pf-feature {
        display: inline-flex;
        align-items: center;
        gap: 9px;
        padding: 9px 13px;
        color: #c8d9ec;
        font-size: 13px;
        font-weight: 600;
        border: 1px solid rgba(125, 211, 252, 0.16);
        border-radius: 999px;
        background: rgba(8, 47, 73, 0.34);
        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
        backdrop-filter: blur(10px);
      }

      .pf-feature-dot {
        width: 7px;
        height: 7px;
        border-radius: 50%;
        background: #38bdf8;
        box-shadow: 0 0 10px rgba(56, 189, 248, 0.75);
      }

      .pf-brand-footer {
        margin-top: 52px;
        color: rgba(169, 184, 202, 0.56);
        font-size: 12px;
        letter-spacing: 0.08em;
        text-align: center;
        text-transform: uppercase;
      }

      /* ------------------------------------------------------------------ */
      /* RIGHT LOGIN PANEL                                                   */
      /* ------------------------------------------------------------------ */

      .pf-auth-panel {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        padding: 48px;
        background:
          radial-gradient(
            circle at 100% 0%,
            rgba(88, 166, 255, 0.07),
            transparent 35%
          ),
          var(--pf-panel);
      }

      .pf-auth-wrapper {
        width: 100%;
        max-width: 420px;
      }

      .pf-mobile-brand {
        display: none;
        align-items: center;
        gap: 12px;
        margin-bottom: 32px;
      }

      .pf-mobile-logo {
        width: 48px;
        height: 48px;
        padding: 7px;
        object-fit: contain;
        border: 1px solid var(--pf-border);
        border-radius: 14px;
        background: linear-gradient(145deg, #17243b, #0b1220);
      }

      .pf-mobile-name {
        margin: 0;
        color: var(--pf-text);
        font-size: 18px;
        font-weight: 700;
      }

      .pf-mobile-caption {
        margin: 3px 0 0;
        color: var(--pf-text-muted);
        font-size: 12px;
      }

      .pf-auth-heading {
        margin-bottom: 28px;
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
        color: var(--pf-text-muted);
        font-size: 15px;
        line-height: 1.5;
      }

      .pf-message {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        margin-bottom: 18px;
        padding: 12px 14px;
        color: #ffb3ad;
        font-size: 13px;
        line-height: 1.5;
        border: 1px solid rgba(248, 81, 73, 0.45);
        border-radius: 8px;
        background: rgba(248, 81, 73, 0.1);
      }

      .pf-message-icon {
        flex-shrink: 0;
        margin-top: 1px;
      }

      .pf-login-card {
        padding: 24px;
        border: 1px solid var(--pf-border);
        border-radius: 10px;
        background: var(--pf-card);
        box-shadow: 0 16px 42px rgba(0, 0, 0, 0.2);
      }

      .pf-field {
        margin-bottom: 18px;
      }

      .pf-label-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        margin-bottom: 8px;
      }

      .pf-label {
        color: var(--pf-text);
        font-size: 14px;
        font-weight: 600;
      }

      .pf-link {
        color: var(--pf-blue);
        font-size: 13px;
        text-decoration: none;
      }

      .pf-link:hover {
        color: var(--pf-blue-bright);
        text-decoration: underline;
      }

      .pf-input-wrapper {
        position: relative;
      }

      .pf-input-icon {
        position: absolute;
        top: 50%;
        left: 13px;
        width: 18px;
        height: 18px;
        color: var(--pf-text-muted);
        pointer-events: none;
        transform: translateY(-50%);
        transition: color 160ms ease;
      }

      .pf-input {
        width: 100%;
        height: 44px;
        padding: 0 44px 0 42px;
        color: var(--pf-text);
        font-family: inherit;
        font-size: 14px;
        line-height: 20px;
        border: 1px solid var(--pf-border);
        border-radius: 7px;
        outline: none;
        background: #0d1117;
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
        border-color: #484f58;
      }

      .pf-input:focus {
        border-color: var(--pf-blue);
        background: #0b1016;
        box-shadow: 0 0 0 3px var(--pf-focus);
      }

      .pf-input-wrapper:focus-within .pf-input-icon {
        color: var(--pf-blue);
      }

      .pf-password-toggle {
        position: absolute;
        top: 50%;
        right: 8px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 34px;
        height: 34px;
        padding: 0;
        color: var(--pf-text-muted);
        border: 0;
        border-radius: 6px;
        background: transparent;
        cursor: pointer;
        transform: translateY(-50%);
        transition:
          color 150ms ease,
          background 150ms ease;
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

      .pf-checkbox-row {
        display: flex;
        align-items: center;
        gap: 9px;
        margin: 2px 0 20px;
      }

      .pf-checkbox {
        width: 16px;
        height: 16px;
        margin: 0;
        accent-color: var(--pf-blue);
        cursor: pointer;
      }

      .pf-checkbox-label {
        color: var(--pf-text-muted);
        font-size: 13px;
        cursor: pointer;
        user-select: none;
      }

      .pf-button {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 100%;
        min-height: 42px;
        padding: 8px 16px;
        color: #ffffff;
        font-family: inherit;
        font-size: 14px;
        font-weight: 650;
        line-height: 20px;
        border: 1px solid rgba(240, 246, 252, 0.1);
        border-radius: 7px;
        background: #282386;
        box-shadow:
          0 1px 0 rgba(27, 31, 36, 0.1),
          inset 0 1px 0 rgba(255, 255, 255, 0.08);
        cursor: pointer;
        transition:
          background 150ms ease,
          transform 150ms ease,
          box-shadow 150ms ease;
      }

      .pf-button:hover {
        background: #282386;
        box-shadow:
          0 3px 12px rgba(46, 160, 67, 0.18),
          inset 0 1px 0 rgba(255, 255, 255, 0.1);
      }

      .pf-button:active {
        background: #282386;
        transform: translateY(1px);
      }

      .pf-button:focus-visible {
        outline: 2px solid var(--pf-blue);
        outline-offset: 2px;
      }

      .pf-button:disabled {
        opacity: 0.65;
        cursor: wait;
      }

      .pf-create-card {
        margin-top: 16px;
        padding: 17px 20px;
        color: var(--pf-text-muted);
        font-size: 14px;
        line-height: 1.5;
        text-align: center;
        border: 1px solid var(--pf-border);
        border-radius: 10px;
        background: rgba(13, 17, 23, 0.45);
      }

      .pf-create-card .pf-link {
        font-size: 14px;
      }

      .pf-back-link {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        margin-top: 24px;
        color: var(--pf-text-muted);
        font-size: 13px;
        text-decoration: none;
        transition: color 150ms ease;
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

      .pf-security-note {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        margin-top: 18px;
        color: #6e7681;
        font-size: 11px;
        text-align: center;
      }

      .pf-security-note svg {
        width: 13px;
        height: 13px;
      }

      @keyframes pfFloat {
        0%,
        100% {
          transform: translateY(0);
        }

        50% {
          transform: translateY(-12px);
        }
      }

      @keyframes pfRotate {
        to {
          transform: rotate(360deg);
        }
      }

      @keyframes pfRotateReverse {
        to {
          transform: rotate(-360deg);
        }
      }

      @keyframes pfGlow {
        from {
          transform: translate(-80px, -45px) scale(0.9);
        }

        to {
          transform: translate(80px, 45px) scale(1.12);
        }
      }

      @keyframes pfSnowfall {
        from {
          transform: translate3d(0, -30px, 0) rotate(0deg);
          opacity: 0;
        }

        10% {
          opacity: 1;
        }

        90% {
          opacity: 0.8;
        }

        to {
          transform: translate3d(45px, 105vh, 0) rotate(320deg);
          opacity: 0;
        }
      }

      @media (max-width: 1000px) {
        .pf-page {
          grid-template-columns: minmax(0, 1fr) minmax(400px, 0.9fr);
        }

        .pf-brand-panel {
          padding: 40px;
        }

        .pf-logo-scene {
          width: 235px;
          height: 235px;
          margin-bottom: 30px;
        }

        .pf-logo-circle {
          width: 154px;
          height: 154px;
        }

        .pf-logo {
          width: 105px;
          height: 105px;
        }

        .pf-brand-heading {
          font-size: 44px;
        }

        .pf-brand-description {
          font-size: 15px;
        }
      }

      @media (max-width: 780px) {
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
          max-width: 440px;
        }

        .pf-mobile-brand {
          display: flex;
        }
      }

      @media (max-width: 480px) {
        .pf-auth-panel {
          align-items: flex-start;
          padding: 28px 16px;
        }

        .pf-auth-heading h1 {
          font-size: 26px;
        }

        .pf-login-card {
          padding: 20px;
        }
      }

      @media (prefers-reduced-motion: reduce) {
        .pf-logo-circle,
        .pf-logo-orbit,
        .pf-logo-orbit-secondary,
        .pf-glow,
        .pf-snowflake {
          animation: none !important;
        }

        * {
          scroll-behavior: auto !important;
        }
      }
    </style>
  </#if>

  <#if section = "form">
    <main class="pf-page">
      <section class="pf-brand-panel" aria-label="Polar Forecast">
        <div class="pf-grid"></div>
        <div class="pf-glow"></div>

        <div class="pf-snow" aria-hidden="true">
          <span class="pf-snowflake">◆</span>
          <span class="pf-snowflake">✦</span>
          <span class="pf-snowflake">◆</span>
          <span class="pf-snowflake">✦</span>
          <span class="pf-snowflake">◆</span>
          <span class="pf-snowflake">✦</span>
          <span class="pf-snowflake">◆</span>
        </div>

        <div class="pf-brand-content">
          <div class="pf-logo-scene">
            <div class="pf-logo-orbit"></div>
            <div class="pf-logo-orbit-secondary"></div>

            <div class="pf-logo-circle">
              <img
                class="pf-logo"
                src="${url.resourcesPath}/img/PolarBearHead.png"
                alt="Polar Forecast polar bear logo"
              />
            </div>
          </div>

          <h1 class="pf-brand-heading">
            Scout smarter.
            <span>Forecast the match.</span>
          </h1>

          <p class="pf-brand-description">
            Turn scouting data into clear strategy, confident predictions,
            and better decisions throughout every competition.
          </p>

          <div class="pf-feature-row">
            <div class="pf-feature">
              <span class="pf-feature-dot"></span>
              Live scouting data
            </div>

            <div class="pf-feature">
              <span class="pf-feature-dot"></span>
              Match predictions
            </div>

            <div class="pf-feature">
              <span class="pf-feature-dot"></span>
              Alliance insights
            </div>
          </div>

          <div class="pf-brand-footer">
            Built for teams that want an edge
          </div>
        </div>
      </section>

      <section class="pf-auth-panel">
        <div class="pf-auth-wrapper">
          <div class="pf-mobile-brand">
            <img
              class="pf-mobile-logo"
              src="${url.resourcesPath}/img/PolarBearHead.png"
              alt="Polar Forecast logo"
            />

            <div>
              <p class="pf-mobile-name">Polar Forecast</p>
              <p class="pf-mobile-caption">FRC scouting and predictions</p>
            </div>
          </div>

          <div class="pf-auth-heading">
            <h1>Sign in to Polar Forecast</h1>
            <p>
              Enter your account details to access your scouting dashboard.
            </p>
          </div>

          <#if message?has_content>
            <div class="pf-message" role="alert">
              <svg
                class="pf-message-icon"
                width="17"
                height="17"
                viewBox="0 0 24 24"
                fill="none"
                aria-hidden="true"
              >
                <path
                  d="M12 9V13M12 17H12.01M10.29 3.86L1.82 18A2 2 0 0 0 3.53 21H20.47A2 2 0 0 0 22.18 18L13.71 3.86A2 2 0 0 0 10.29 3.86Z"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>

              <span>${kcSanitize(message.summary)?no_esc}</span>
            </div>
          </#if>

          <div class="pf-login-card">
            <form
              id="kc-form-login"
              action="${url.loginAction}"
              method="post"
              onsubmit="return handleLoginSubmit();"
            >
              <div class="pf-field">
                <div class="pf-label-row">
                  <label class="pf-label" for="username">
                    Username
                  </label>
                </div>

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
                      stroke-linejoin="round"
                    />
                  </svg>

                  <input
                    id="username"
                    class="pf-input"
                    name="username"
                    type="text"
                    value="${(login.username!'')}"
                    placeholder="Enter your username"
                    autocomplete="username"
                    autofocus
                    required
                  />
                </div>
              </div>

              <div class="pf-field">
                <div class="pf-label-row">
                  <label class="pf-label" for="password">
                    Password
                  </label>

                  <#if realm.resetPasswordAllowed?? && realm.resetPasswordAllowed>
                    <a
                      class="pf-link"
                      href="${url.loginResetCredentialsUrl}"
                    >
                      Forgot password?
                    </a>
                  </#if>
                </div>

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
                      stroke-linejoin="round"
                    />
                  </svg>

                  <input
                    id="password"
                    class="pf-input"
                    name="password"
                    type="password"
                    placeholder="Enter your password"
                    autocomplete="current-password"
                    required
                  />

                  <button
                    id="password-toggle"
                    class="pf-password-toggle"
                    type="button"
                    onclick="togglePassword()"
                    aria-label="Show password"
                    aria-pressed="false"
                  >
                    <svg
                      id="eye-open"
                      viewBox="0 0 24 24"
                      fill="none"
                      aria-hidden="true"
                    >
                      <path
                        d="M2 12C4.5 7.5 7.8 5.25 12 5.25C16.2 5.25 19.5 7.5 22 12C19.5 16.5 16.2 18.75 12 18.75C7.8 18.75 4.5 16.5 2 12Z"
                        stroke="currentColor"
                        stroke-width="1.8"
                        stroke-linecap="round"
                        stroke-linejoin="round"
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
                      id="eye-closed"
                      viewBox="0 0 24 24"
                      fill="none"
                      aria-hidden="true"
                      style="display:none;"
                    >
                      <path
                        d="M3 3L21 21M10.6 10.7A2 2 0 0 0 13.3 13.4M9.4 5.5C10.23 5.33 11.1 5.25 12 5.25C16.2 5.25 19.5 7.5 22 12C21.23 13.39 20.38 14.57 19.43 15.52M6.05 6.05C4.49 7.27 3.14 9.25 2 12C4.5 16.5 7.8 18.75 12 18.75C13.58 18.75 15.02 18.43 16.32 17.79"
                        stroke="currentColor"
                        stroke-width="1.8"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                    </svg>
                  </button>
                </div>
              </div>

              <#if realm.rememberMe?? && realm.rememberMe>
                <div class="pf-checkbox-row">
                  <input
                    id="rememberMe"
                    class="pf-checkbox"
                    name="rememberMe"
                    type="checkbox"
                    <#if login.rememberMe??>checked</#if>
                  />

                  <label class="pf-checkbox-label" for="rememberMe">
                    Keep me signed in
                  </label>
                </div>
              </#if>

              <button
                id="kc-login"
                class="pf-button"
                name="login"
                type="submit"
              >
                <span id="login-button-text">Sign in</span>
              </button>
            </form>
          </div>

          <#if realm.password && realm.registrationAllowed?? && realm.registrationAllowed>
            <div class="pf-create-card">
              New to Polar Forecast?
              <a class="pf-link" href="${url.registrationUrl}">
                Create an account
              </a>
            </div>
          </#if>

          <a
            class="pf-back-link"
            href="http://localhost:3000"
          >
            <svg
              viewBox="0 0 24 24"
              fill="none"
              aria-hidden="true"
            >
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

          <div class="pf-security-note">
            <svg
              viewBox="0 0 24 24"
              fill="none"
              aria-hidden="true"
            >
              <path
                d="M12 22C12 22 20 18 20 12V5L12 2L4 5V12C4 18 12 22 12 22Z"
                stroke="currentColor"
                stroke-width="1.8"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>

            Secure authentication powered by Keycloak
          </div>
        </div>
      </section>
    </main>

    <script>
      function togglePassword() {
        const passwordField = document.getElementById("password");
        const toggleButton = document.getElementById("password-toggle");
        const openIcon = document.getElementById("eye-open");
        const closedIcon = document.getElementById("eye-closed");

        const passwordIsHidden = passwordField.type === "password";

        passwordField.type = passwordIsHidden ? "text" : "password";
        openIcon.style.display = passwordIsHidden ? "none" : "block";
        closedIcon.style.display = passwordIsHidden ? "block" : "none";

        toggleButton.setAttribute(
          "aria-label",
          passwordIsHidden ? "Hide password" : "Show password"
        );

        toggleButton.setAttribute(
          "aria-pressed",
          passwordIsHidden ? "true" : "false"
        );

        passwordField.focus();
      }

      function handleLoginSubmit() {
        const loginButton = document.getElementById("kc-login");
        const buttonText = document.getElementById("login-button-text");

        loginButton.disabled = true;
        buttonText.textContent = "Signing in...";

        return true;
      }
    </script>
  </#if>

</@layout.registrationLayout>