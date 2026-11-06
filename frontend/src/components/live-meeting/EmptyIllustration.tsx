/** Moon-window empty-state illustration shared by the home dashboard and the today panel. */
export default function EmptyIllustration() {
  return (
    <svg width="132" height="96" viewBox="0 0 132 96" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <g opacity="0.85">
        <rect x="14" y="10" width="104" height="70" rx="10" fill="rgba(255,255,255,0.03)" stroke="rgba(255,255,255,0.08)" />
        <circle cx="66" cy="40" r="13" stroke="#3B82F6" strokeWidth="2.5" />
        <path d="M70 33a9 9 0 1 0 5 12 11 11 0 0 1-5-12Z" fill="#3B82F6" opacity="0.85" />
        <circle cx="34" cy="30" r="2" fill="#22D3EE" opacity="0.7" />
        <circle cx="98" cy="26" r="1.6" fill="#818CF8" opacity="0.7" />
        <circle cx="104" cy="52" r="2" fill="#3B82F6" opacity="0.5" />
        <rect x="46" y="86" width="40" height="4" rx="2" fill="rgba(255,255,255,0.08)" />
      </g>
    </svg>
  );
}
