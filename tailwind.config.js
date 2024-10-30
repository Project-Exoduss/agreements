module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#e4e0e1',
          secondary: '#ef9fbc',
          accent: '#eeaf3a',
          neutral: '#291334',
          'base-100': '#faf7f5',
          'base-200': '#efeae6',
          'base-300': '#e7e2df',
          'base-content': '#291334',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        },
        pex: {
          'color-scheme': 'light',
          primary: '#1E88E5',       // Clear blue for primary actions (slightly muted)
          secondary: '#6B7280',     // Medium gray for secondary elements
          accent: '#94A3B8',        // Light gray-blue for subtle accents
          neutral: '#334155',       // Slate gray for text
          'base-100': '#FFFFFF',    // Pure white background
          'base-200': '#F8FAFC',    // Very subtle off-white
          'base-300': '#F1F5F9',    // Light gray for borders
          'base-content': '#000000',// Slate gray for main text
          '--rounded-btn': '0.5rem',
          '--tab-border': '1px',
          '--tab-radius': '.25rem'
        }
      }
    ]
  }
}
