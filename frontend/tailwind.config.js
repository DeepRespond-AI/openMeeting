/** @type {import('tailwindcss').Config} */
module.exports = {
    darkMode: ['class'],
    content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
  	extend: {
  		fontFamily: {
  			sans: [
  				'var(--font-source-sans-3)',
  				'PingFang SC',
  				'Hiragino Sans GB',
  				'Microsoft YaHei',
  				'system-ui',
  				'sans-serif'
  			]
  		},
  		colors: {
  			background: 'hsl(var(--background))',
  			foreground: 'hsl(var(--foreground))',
  			border: 'hsl(var(--border))',
  			input: 'hsl(var(--input))',
  			ring: 'hsl(var(--ring))',
  			primary: {
  				DEFAULT: 'hsl(var(--primary))',
  				foreground: 'hsl(var(--primary-foreground))'
  			},
  			secondary: {
  				DEFAULT: 'hsl(var(--secondary))',
  				foreground: 'hsl(var(--secondary-foreground))'
  			},
  			tertiary: '#64748b',
  			/* V2 Aurora Dark brand palette (现代亮蓝) */
  			brand: {
  				'50': '#eef4ff',
  				'100': '#dce8ff',
  				'200': '#b6ccff',
  				'300': '#85a9ff',
  				'400': '#5b85f7',
  				'500': '#3b82f6',
  				'600': '#2f6ae8',
  				'700': '#2653c4',
  				'800': '#1f4099',
  				'900': '#1a3173',
  				cyan: '#4cc3ff'
  			},
  			success: 'hsl(var(--success))',
  			warning: 'hsl(var(--warning))',
  			sidebar: {
  				DEFAULT: 'hsl(var(--sidebar))',
  				foreground: 'hsl(var(--sidebar-foreground))'
  			},
  			card: {
  				DEFAULT: 'hsl(var(--card))',
  				foreground: 'hsl(var(--card-foreground))'
  			},
  			popover: {
  				DEFAULT: 'hsl(var(--popover))',
  				foreground: 'hsl(var(--popover-foreground))'
  			},
  			muted: {
  				DEFAULT: 'hsl(var(--muted))',
  				foreground: 'hsl(var(--muted-foreground))'
  			},
  			accent: {
  				DEFAULT: 'hsl(var(--accent))',
  				foreground: 'hsl(var(--accent-foreground))'
  			},
  			destructive: {
  				DEFAULT: 'hsl(var(--destructive))',
  				foreground: 'hsl(var(--destructive-foreground))'
  			},
  			chart: {
  				'1': 'hsl(var(--chart-1))',
  				'2': 'hsl(var(--chart-2))',
  				'3': 'hsl(var(--chart-3))',
  				'4': 'hsl(var(--chart-4))',
  				'5': 'hsl(var(--chart-5))'
  			}
  		},
  		backgroundImage: {
  			'brand-gradient': 'linear-gradient(135deg, #6366f1 0%, #3b82f6 52%, #22d3ee 100%)'
  		},
  		boxShadow: {
  			card: '0 1px 2px rgba(0, 0, 0, 0.30), 0 6px 20px rgba(0, 0, 0, 0.22)',
  			elevated: '0 16px 48px rgba(0, 0, 0, 0.50), 0 4px 12px rgba(0, 0, 0, 0.32)',
  			glow: '0 8px 28px rgba(59, 130, 246, 0.38), 0 2px 8px rgba(59, 130, 246, 0.22)'
  		},
  		borderRadius: {
  			xl: 'calc(var(--radius) + 4px)',
  			lg: 'var(--radius)',
  			md: 'calc(var(--radius) - 2px)',
  			sm: 'calc(var(--radius) - 4px)'
  		},
  		keyframes: {
  			'accordion-down': {
  				from: {
  					height: '0'
  				},
  				to: {
  					height: 'var(--radix-accordion-content-height)'
  				}
  			},
  			'accordion-up': {
  				from: {
  					height: 'var(--radix-accordion-content-height)'
  				},
  				to: {
  					height: '0'
  				}
  			},
  			'rise-in': {
  				from: {
  					opacity: '0',
  					transform: 'translateY(14px)'
  				},
  				to: {
  					opacity: '1',
  					transform: 'translateY(0)'
  				}
  			},
  			'pulse-ring': {
  				'0%': {
  					transform: 'scale(1)',
  					opacity: '0.6'
  				},
  				'100%': {
  					transform: 'scale(1.6)',
  					opacity: '0'
  				}
  			}
  		},
  		animation: {
  			'accordion-down': 'accordion-down 0.2s ease-out',
  			'accordion-up': 'accordion-up 0.2s ease-out',
  			'rise-in': 'rise-in 0.55s cubic-bezier(0.22, 0.8, 0.3, 1) forwards',
  			'pulse-ring': 'pulse-ring 1.6s ease-out infinite'
  		}
  	}
  },
  plugins: [
    require("tailwindcss-animate"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
}