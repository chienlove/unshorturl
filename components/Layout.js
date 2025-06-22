import { useEffect, useState } from 'react';
import Header from './Header';
import Footer from './Footer';

export default function Layout({ children }) {
  const [dark, setDark] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem('theme') === 'dark';
    document.documentElement.setAttribute('data-theme', saved ? 'dark' : 'light');
    setDark(saved);
  }, []);

  const toggleTheme = () => {
    const next = !dark;
    setDark(next);
    document.documentElement.setAttribute('data-theme', next ? 'dark' : 'light');
    localStorage.setItem('theme', next ? 'dark' : 'light');
  };

  return (
    <>
      <Header />
      <div style={{ textAlign: 'center', paddingBottom: '10px' }}>
        <button onClick={toggleTheme}>
          {dark ? '🌞 Chế độ sáng' : '🌙 Chế độ tối'}
        </button>
      </div>
      <main>{children}</main>
      <Footer />
    </>
  );
}