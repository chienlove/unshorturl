import { useEffect, useState } from 'react';
import Header from './Header';
import Footer from './Footer';
import styles from '../styles/Home.module.css';

export default function Layout({ children }) {
  const [dark, setDark] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem('theme') === 'dark';
    setDark(saved);
    document.documentElement.setAttribute('data-theme', saved ? 'dark' : 'light');
  }, []);

  const toggleTheme = () => {
    const next = !dark;
    setDark(next);
    document.documentElement.setAttribute('data-theme', next ? 'dark' : 'light');
    localStorage.setItem('theme', next ? 'dark' : 'light');
  };

  return (
    <>
      <button onClick={toggleTheme} className={styles.darkToggle}>
        {dark ? '🌞 Sáng' : '🌙 Tối'}
      </button>
      <Header />
      <main>{children}</main>
      <Footer />
    </>
  );
}