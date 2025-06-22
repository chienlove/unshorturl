import { useEffect, useState } from 'react';
import styles from '../styles/Home.module.css';
import Layout from '../components/Layout';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faClipboard } from '@fortawesome/free-solid-svg-icons';

export default function Home() {
  const [url, setUrl] = useState('');
  const [result, setResult] = useState('');
  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState([]);

  useEffect(() => {
    const saved = JSON.parse(localStorage.getItem('history') || '[]');
    setHistory(saved);
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!url) return;

    setLoading(true);
    setResult('');

    try {
      const res = await fetch('/api/unshorten', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url })
      });

      const data = await res.json();
      if (data.originalUrl) {
        setResult(data.originalUrl);
        const newItem = { short: url, original: data.originalUrl };
        const updated = [newItem, ...history].slice(0, 10);
        setHistory(updated);
        localStorage.setItem('history', JSON.stringify(updated));
      } else {
        setResult(`❌ ${data.error}`);
      }
    } catch {
      setResult('❌ Có lỗi xảy ra.');
    }

    setLoading(false);
  };

  return (
    <Layout>
      <div className={styles.container}>
        <h1><FontAwesomeIcon icon={faLink} /> Unshorten Link</h1>
        <form onSubmit={handleSubmit} className={styles.form}>
          <input
            type="url"
            className={styles.input}  
            placeholder="Dán link rút gọn vào đây..."
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            required
          />
          <button
            type="submit"
            className={styles.button} 
            disabled={loading}
          >
            {loading ? '⏳ Đang kiểm tra...' : 'Xem link gốc'}
          </button>
        </form>

        {result && (
          <div className={styles.result}>
            ✅ Link gốc: <a href={result} target="_blank" rel="noopener noreferrer">{result}</a>
            <button className={styles.copyBtn} onClick={() => navigator.clipboard.writeText(result)}>
  <FontAwesomeIcon icon={faClipboard} /> Sao chép
</button>
          </div>
        )}

        <div className={styles.history}>
          <h3>Lịch sử</h3>
          <ul>
            {history.map((item, idx) => (
              <li key={idx}>
                <span>{item.short}</span> ➝ <a href={item.original} target="_blank" rel="noreferrer">{item.original}</a>
              </li>
            ))}
          </ul>
        </div>

        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "WebApplication",
              "name": "Unshorten Link",
              "url": "https://yourdomain.com",
              "applicationCategory": "Utility",
              "operatingSystem": "All",
              "description": "Công cụ mở rộng link rút gọn miễn phí",
              "creator": {
                "@type": "Person",
                "name": "Tên của bạn"
              }
            })
          }}
        />
      </div>
    </Layout>
  );
}