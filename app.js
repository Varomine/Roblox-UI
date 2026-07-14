document.addEventListener('DOMContentLoaded', () => {
  // Initialize Highlight.js
  hljs.highlightAll();

  // Elements
  const navLinks = document.querySelectorAll('.nav-link');
  const sections = document.querySelectorAll('.doc-section');
  const pageTitle = document.getElementById('page-title');
  const searchInput = document.getElementById('docs-search');
  const searchResults = document.getElementById('search-results');
  
  // Theme Switch Buttons
  const goldThemeBtn = document.getElementById('theme-gold-btn');
  const indigoThemeBtn = document.getElementById('theme-indigo-btn');
  const simFrame = document.getElementById('sim-main-frame');

  // Simulator Toggle Panel Button
  const toggleSimBtn = document.getElementById('toggle-simulator-btn');
  const simPanel = document.getElementById('simulator-panel');

  /* ===== INTERACTIVE ROUTER ===== */
  function navigateTo(targetId) {
    // Update active nav links
    navLinks.forEach(link => {
      if (link.getAttribute('data-target') === targetId) {
        link.classList.add('active');
        // Update top bar title
        pageTitle.innerText = link.textContent.trim();
      } else {
        link.classList.remove('active');
      }
    });

    // Update visible section
    sections.forEach(sec => {
      if (sec.id === `sec-${targetId}`) {
        sec.classList.add('active');
      } else {
        sec.classList.remove('active');
      }
    });

    // Scroll to top of main content
    document.querySelector('.main-content').scrollTop = 0;
  }

  // Handle Hash Navigation
  function handleHash() {
    const hash = window.location.hash.substring(1) || 'intro';
    navigateTo(hash);
  }

  window.addEventListener('hashchange', handleHash);
  // Trigger initial routing
  handleHash();

  // Navigation Clicks
  navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const target = link.getAttribute('data-target');
      window.location.hash = target;
    });
  });

  /* ===== THEME TOGGLE ENGINE ===== */
  function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    if (theme === 'gold') {
      goldThemeBtn.classList.add('active');
      indigoThemeBtn.classList.remove('active');
      simFrame.classList.remove('theme-indigo');
      simFrame.classList.add('theme-gold');
    } else {
      indigoThemeBtn.classList.add('active');
      goldThemeBtn.classList.remove('active');
      simFrame.classList.remove('theme-gold');
      simFrame.classList.add('theme-indigo');
    }
  }

  goldThemeBtn.addEventListener('click', () => setTheme('gold'));
  indigoThemeBtn.addEventListener('click', () => setTheme('indigo'));
  
  // Set default theme state on simulator
  simFrame.classList.add('theme-gold');

  /* ===== SIMULATOR TOGGLE PANEL ===== */
  toggleSimBtn.addEventListener('click', () => {
    simPanel.classList.toggle('collapsed');
    if (simPanel.classList.contains('collapsed')) {
      toggleSimBtn.innerHTML = '<i class="fa-solid fa-laptop"></i> Show Preview';
    } else {
      toggleSimBtn.innerHTML = '<i class="fa-solid fa-laptop"></i> Hide Preview';
    }
  });

  /* ===== COPY TO CLIPBOARD SYSTEM ===== */
  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const targetSelector = btn.getAttribute('data-clipboard-target');
      const codeElement = document.querySelector(targetSelector);
      if (codeElement) {
        navigator.clipboard.writeText(codeElement.textContent).then(() => {
          btn.innerHTML = '<i class="fa-solid fa-check"></i> Copied!';
          btn.classList.add('copied');
          setTimeout(() => {
            btn.innerHTML = '<i class="fa-regular fa-copy"></i> Copy';
            btn.classList.remove('copied');
          }, 2000);
        });
      }
    });
  });

  /* ===== SEARCH ENGINE ===== */
  const searchIndex = [
    { name: 'Introduction', hash: 'intro', tags: 'home startup features overview' },
    { name: 'Installation', hash: 'install', tags: 'download loadstring bootstrapper studio local storage module' },
    { name: 'Themes & Styling', hash: 'themes', tags: 'colors palettes configuration custom design variables' },
    { name: 'CreateWindow', hash: 'window', tags: 'library window create settings name config primary' },
    { name: 'CreateTab', hash: 'tab', tags: 'window tab page navigation category icons list' },
    { name: 'CreateSection', hash: 'section', tags: 'tab section category partition headings divider' },
    { name: 'CreateLabel', hash: 'label', tags: 'tab label text static stats info dynamic set' },
    { name: 'CreateButton', hash: 'button', tags: 'tab button click trigger execution callback' },
    { name: 'CreateToggle', hash: 'toggle', tags: 'tab toggle state switch on off state boolean callback' },
    { name: 'CreateSlider', hash: 'slider', tags: 'tab slider drag numbers ranges minimum maximum value' },
    { name: 'CreateDropdown', hash: 'dropdown', tags: 'tab dropdown select lists choices options optionsList' },
    { name: 'CreateTextBox', hash: 'textbox', tags: 'tab textbox text input box keyboard placeholders' },
    { name: 'CreateKeybind', hash: 'keybind', tags: 'tab keybind bind keyboard hotkeys listening' },
    { name: 'CreateColorpicker', hash: 'colorpicker', tags: 'tab colorpicker select presets box colors' },
    { name: 'Notify', hash: 'notification', tags: 'library notify toasts banner popups timer duration' }
  ];

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();
    if (!query) {
      searchResults.style.display = 'none';
      return;
    }

    const matches = searchIndex.filter(item => 
      item.name.toLowerCase().includes(query) || item.tags.includes(query)
    );

    if (matches.length > 0) {
      searchResults.innerHTML = matches.map(item => `
        <div class="search-result-item" data-hash="${item.hash}">
          <strong>${item.name}</strong> <small style="color: var(--text-muted);">#${item.hash}</small>
        </div>
      `).join('');
      searchResults.style.display = 'block';

      // Setup click handlers
      document.querySelectorAll('.search-result-item').forEach(item => {
        item.addEventListener('click', () => {
          const hash = item.getAttribute('data-hash');
          window.location.hash = hash;
          searchInput.value = '';
          searchResults.style.display = 'none';
        });
      });
    } else {
      searchResults.innerHTML = `<div class="search-result-item" style="cursor: default; color: var(--text-muted);">No results found</div>`;
      searchResults.style.display = 'block';
    }
  });

  // Hide search when clicking outside
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.search-box')) {
      searchResults.style.display = 'none';
    }
  });


  /* ========================================================
     ROBLOX INTERACTIVE SIMULATOR CLIENT LOGIC
     ======================================================== */

  const simTabBtns = document.querySelectorAll('.sim-tab-btn');
  const simPages = document.querySelectorAll('.sim-page');
  const simCurrentTabName = document.getElementById('sim-current-tab-name');
  
  // Close / Min Window controls
  const simBtnMin = document.getElementById('sim-btn-minimize');
  const simBtnClose = document.getElementById('sim-btn-close');
  const simMinimizedAlert = document.getElementById('sim-minimized-alert');
  const gameView = document.getElementById('game-view');

  // Page tab switches
  function switchSimTab(tabName) {
    simTabBtns.forEach(btn => {
      if (btn.getAttribute('data-tab') === tabName) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    simPages.forEach(page => {
      if (page.getAttribute('data-page') === tabName) {
        page.classList.add('active');
      } else {
        page.classList.remove('active');
      }
    });

    simCurrentTabName.innerText = tabName;
  }

  simTabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.getAttribute('data-tab');
      switchSimTab(tab);
    });
  });

  // Minimize logic
  simBtnMin.addEventListener('click', (e) => {
    e.stopPropagation();
    simFrame.classList.add('minimized');
    simMinimizedAlert.style.display = 'flex';
  });

  // Re-maximize logic
  simMinimizedAlert.addEventListener('click', () => {
    simFrame.classList.remove('minimized');
    simMinimizedAlert.style.display = 'none';
  });

  // Close logic
  simBtnClose.addEventListener('click', (e) => {
    e.stopPropagation();
    simFrame.classList.add('hidden');
    simMinimizedAlert.style.display = 'flex';
    simMinimizedAlert.querySelector('span').innerHTML = 'Luxury UI Closed.<br><small>Click here to execute script again.</small>';
  });

  simMinimizedAlert.addEventListener('click', () => {
    if (simFrame.classList.contains('hidden')) {
      simFrame.classList.remove('hidden');
      simFrame.classList.remove('minimized');
      simMinimizedAlert.style.display = 'none';
      simMinimizedAlert.querySelector('span').innerHTML = 'Luxury UI Minimized.<br><small>Click anywhere in Roblox or press LeftCtrl to open.</small>';
      pushSimNotification('Luxury UI', 'Script executed successfully!');
    }
  });

  // Keyboard Control keybind simulation toggle
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Control') {
      if (simFrame.classList.contains('minimized') || simFrame.classList.contains('hidden')) {
        simFrame.classList.remove('hidden');
        simFrame.classList.remove('minimized');
        simMinimizedAlert.style.display = 'none';
      } else {
        simFrame.classList.add('minimized');
        simMinimizedAlert.style.display = 'flex';
      }
    }
  });

  // Draggability inside Simulator Viewport
  let isDragging = false;
  let dragX = 0;
  let dragY = 0;
  const dragHandle = document.getElementById('sim-drag-handle');

  dragHandle.addEventListener('mousedown', (e) => {
    isDragging = true;
    dragX = e.clientX - simFrame.offsetLeft;
    dragY = e.clientY - simFrame.offsetTop;
    simFrame.style.transition = 'none';
  });

  document.addEventListener('mousemove', (e) => {
    if (isDragging) {
      const rect = gameView.getBoundingClientRect();
      const parentWidth = gameView.clientWidth;
      const parentHeight = gameView.clientHeight;
      const frameWidth = simFrame.clientWidth;
      const frameHeight = simFrame.clientHeight;

      // Mouse position relative to game-view viewport
      let localX = e.clientX - rect.left;
      let localY = e.clientY - rect.top;

      // Calculate new left and top coordinates relative to game-view
      let newLeft = localX - (dragX - rect.left);
      let newTop = localY - (dragY - rect.top);

      // Clamp coordinates to keep the frame completely inside the game-view boundaries
      newLeft = Math.max(0, Math.min(parentWidth - frameWidth, newLeft));
      newTop = Math.max(0, Math.min(parentHeight - frameHeight, newTop));

      simFrame.style.left = `${newLeft}px`;
      simFrame.style.top = `${newTop}px`;
      simFrame.style.position = 'absolute';
    }
  });

  document.addEventListener('mouseup', () => {
    isDragging = false;
    simFrame.style.transition = 'height 0.25s cubic-bezier(0.4, 0, 0.2, 1)';
  });

  /* ===== SIMULATOR COMPONENTS INTERACTIVITY ===== */
  
  // Button Click
  const simKillBtn = document.getElementById('sim-element-kill-all');
  simKillBtn.addEventListener('click', () => {
    flashSimElement(simKillBtn);
    pushSimNotification('Combat Module', 'Killed all players successfully!');
  });

  // Toggle switch
  const simAimToggle = document.getElementById('sim-element-aimbot-toggle');
  const simAimPill = simAimToggle.querySelector('.sim-toggle-pill');
  simAimPill.addEventListener('click', () => {
    simAimPill.classList.toggle('active');
    const state = simAimPill.classList.contains('active');
    pushSimNotification('Aimbot Settings', `Aimbot state set to: ${state ? 'ON' : 'OFF'}`);
  });

  // Visuals Tab Toggle
  const simEspToggle = document.getElementById('sim-element-esp-toggle');
  const simEspPill = simEspToggle.querySelector('.sim-toggle-pill');
  simEspPill.addEventListener('click', () => {
    simEspPill.classList.toggle('active');
    const state = simEspPill.classList.contains('active');
    pushSimNotification('ESP Visuals', `Player ESP set to: ${state ? 'ON' : 'OFF'}`);
  });

  // Slider Drag Simulation (Simplistic click-based fill setting)
  const simFovSlider = document.getElementById('sim-element-fov-slider');
  const sliderTrack = simFovSlider.querySelector('.sim-slider-track');
  const sliderFill = simFovSlider.querySelector('.sim-slider-fill');
  const sliderHandle = simFovSlider.querySelector('.sim-slider-handle');
  const fovValText = document.getElementById('sim-fov-val');

  function setSliderValue(val) {
    const min = 0;
    const max = 180;
    const percentage = ((val - min) / (max - min)) * 100;
    sliderFill.style.width = `${percentage}%`;
    sliderHandle.style.left = `${percentage}%`;
    fovValText.innerText = val;
  }

  sliderTrack.addEventListener('click', (e) => {
    const rect = sliderTrack.getBoundingClientRect();
    const percent = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
    const val = Math.floor(percent * 180);
    setSliderValue(val);
  });

  // Dropdown list switch
  const simDropdown = document.getElementById('sim-element-dropdown');
  const dropBtn = simDropdown.querySelector('.sim-dropdown-header');
  const dropValText = document.getElementById('sim-drop-val');
  const dropList = document.getElementById('sim-dropdown-options');
  const dropOptions = dropList.querySelectorAll('.sim-dropdown-option');

  dropBtn.addEventListener('click', () => {
    simDropdown.classList.toggle('expanded');
  });

  dropOptions.forEach(opt => {
    opt.addEventListener('click', () => {
      dropOptions.forEach(o => o.classList.remove('active'));
      opt.classList.add('active');
      const val = opt.textContent.trim();
      dropValText.innerText = val;
      simDropdown.classList.remove('expanded');
      pushSimNotification('Aimbot Settings', `Aim target changed to: ${val}`);
    });
  });

  // TextBox Input key loss focus
  const simInput = document.querySelector('.sim-textbox-input');
  simInput.addEventListener('change', (e) => {
    const text = e.target.value.trim();
    if (text) {
      pushSimNotification('WalkSpeed Controller', `Walkspeed overridden to: ${text}`);
    }
  });

  // Keybind bind listener
  const simKeybindBtn = document.querySelector('.sim-keybind-trigger');
  let listeningKey = false;
  simKeybindBtn.addEventListener('click', () => {
    if (!listeningKey) {
      listeningKey = true;
      simKeybindBtn.innerText = '...';
      simKeybindBtn.style.borderColor = 'var(--accent-color)';
    }
  });

  document.addEventListener('keydown', (e) => {
    if (listeningKey) {
      listeningKey = false;
      const key = e.key;
      simKeybindBtn.innerText = key;
      simKeybindBtn.style.borderColor = '#222';
      pushSimNotification('Keybind Module', `Self Destruct key bound to: ${key}`);
    }
  });

  // Colorpicker preset selection
  const simColorpicker = document.getElementById('sim-element-colorpicker');
  const colorHeader = simColorpicker.querySelector('.sim-colorpicker-header');
  const colorBox = document.getElementById('sim-color-picker-box');
  const colorPanel = document.getElementById('sim-colorpicker-panel');
  const colorPresets = colorPanel.querySelectorAll('.sim-color-preset');

  colorHeader.addEventListener('click', () => {
    simColorpicker.classList.toggle('expanded');
  });

  colorPresets.forEach(preset => {
    preset.addEventListener('click', () => {
      const color = preset.style.backgroundColor;
      colorBox.style.backgroundColor = color;
      simColorpicker.classList.remove('expanded');
      pushSimNotification('ESP Visuals', `Glow color set to: ${color}`);
    });
  });

  /* ===== SIMULATOR UTILITIES ===== */
  
  function flashSimElement(element) {
    element.style.borderColor = 'var(--accent-color)';
    setTimeout(() => {
      element.style.borderColor = '#1c1c1c';
    }, 300);
  }

  function pushSimNotification(title, content) {
    const container = document.getElementById('sim-toast-container');
    
    const toast = document.createElement('div');
    toast.className = 'sim-toast';
    
    // Determine toast indicator color based on active HTML theme
    const activeTheme = document.documentElement.getAttribute('data-theme');
    const accentColor = activeTheme === 'gold' ? '#d4af37' : '#7c4dff';

    toast.innerHTML = `
      <i class="fa-regular fa-bell" style="color: ${accentColor}"></i>
      <div class="sim-toast-body">
        <span class="sim-toast-title">${title}</span>
        <span class="sim-toast-content">${content}</span>
      </div>
    `;

    container.appendChild(toast);

    // Stay for 3.5 seconds, then animate fade out
    setTimeout(() => {
      toast.style.transition = 'opacity 0.3s, transform 0.3s';
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      setTimeout(() => {
        toast.remove();
      }, 300);
    }, 3500);
  }

  // Set default color preview box background
  colorBox.style.backgroundColor = '#d4af37';


  /* ========================================================
     EXTERNAL DIRECT INTERACTIONS FROM DOCUMENTATION BODY
     ======================================================== */

  window.simulatorSwitchTab = (tabName) => {
    switchSimTab(tabName);
    const targetEl = document.querySelector(`.sim-tab-btn[data-tab="${tabName}"]`);
    if (targetEl) flashSimElement(targetEl);
  };

  window.simulatorTriggerButton = () => {
    switchSimTab('Combat');
    simKillBtn.click();
  };

  window.simulatorSetToggle = (val) => {
    switchSimTab('Combat');
    if (val && !simAimPill.classList.contains('active')) {
      simAimPill.click();
    } else if (!val && simAimPill.classList.contains('active')) {
      simAimPill.click();
    }
    flashSimElement(simAimToggle);
  };

  window.simulatorSetSlider = (val) => {
    switchSimTab('Combat');
    setSliderValue(val);
    flashSimElement(simFovSlider);
    pushSimNotification('Aimbot Settings', `Slider FOV adjusted to: ${val}`);
  };

  window.simulatorSetDropdown = (val) => {
    switchSimTab('Combat');
    
    // Find matching option button
    const options = dropList.querySelectorAll('.sim-dropdown-option');
    let matched = null;
    options.forEach(o => {
      if (o.textContent.trim() === val) matched = o;
    });

    if (matched) {
      matched.click();
    }
    flashSimElement(simDropdown);
  };

  window.simulatorSetColor = (colorHex) => {
    switchSimTab('Visuals');
    colorBox.style.backgroundColor = colorHex;
    flashSimElement(simColorpicker);
    pushSimNotification('ESP Visuals', `Glow color set to: ${colorHex}`);
  };

  window.simulatorSendNotification = () => {
    pushSimNotification('Luxury UI Loader', 'Successfully executed loadstring in 0.14 seconds.');
  };

});
