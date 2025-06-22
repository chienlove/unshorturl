import { useEffect, useState } from 'react';
import Layout from '../components/Layout';
import styles from '../styles/Home.module.css';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faLink, faClipboard } from '@fortawesome/free-solid-svg-icons';

export default function Home() {
  const [url, setUrl] = useState('');
  const [result, setResult] = useState('');
  const [safe, setSafe] = useState(true);
  const [error, setError] = useState('');
  const [copied, setCopied] = useState(false);
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(false); // ✅ loading state

  useEffect(() => {
    const saved = JSON.parse(localStorage.getItem('history') || '[]');
    setHistory(saved);
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!url) return;

    setResult('');
    setError('');
    setCopied(false);
    setLoading(true); // ✅ bắt đầu loading

    try {
      const res = await fetch('/api/unshorten', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url })
      });

      const data = await res.json();
      if (data.originalUrl) {
        setResult(data.originalUrl);
        setSafe(data.safe);
        const newItem = {
          short: url,
          original: data.originalUrl,
          safe: data.safe,
          timestamp: new Date().toISOString()
        };
        const updated = [newItem, ...history].slice(0, 10);
        setHistory(updated);
        localStorage.setItem('history', JSON.stringify(updated));
      } else {
        setError(data.error);
      }
    } catch {
      setError('❌ Có lỗi xảy ra khi gửi yêu cầu.');
    }

    setLoading(false); // ✅ kết thúc loading
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(result);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <Layout>
      <div className={styles.container}>
        <h1><FontAwesomeIcon icon={faLink} /> Unshorten Link</h1>

        <div className={styles.intro}>
          <p><strong>Giới thiệu:</strong> Công cụ kiểm tra <strong>link gốc</strong> từ các liên kết rút gọn như <code>bit.ly</code>, <code>tinyurl</code>, <code>is.gd</code>,... miễn phí.</p>
          <p><strong>Hỗ trợ:</strong> HTTP/S link rút gọn. Không hỗ trợ:
            <ul>
              <li>Link có token riêng (Google Drive, Dropbox…)</li>
              <li>Link yêu cầu đăng nhập</li>
            </ul>
          </p>
        </div>

        <form onSubmit={handleSubmit} className={styles.form}>
          <input
            type="url"
            className={styles.input}
            placeholder="Dán link rút gọn vào đây..."
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            required
          />
          <button type="submit" className={styles.button} disabled={loading}>
            {loading ? '⏳ Đang kiểm tra...' : (result || error ? '🔁 Kiểm tra lại' : '🔍 Xem link gốc')}
          </button>
        </form>

        {loading && <div className={styles.loading}>Đang xử lý link...</div>}

        {error && (
          <div className={`${styles.resultBox} ${styles.error}`}>
            ❌ {error}
          </div>
        )}

        {result && (
          <div className={`${styles.resultBox} ${!safe ? styles.warning : ''}`}>
            <div className={styles.resultLink}>
              <FontAwesomeIcon icon={faLink} /> <a href={result} target="_blank" rel="noreferrer">{result}</a>
            </div>
            <button className={styles.copyBtn} onClick={handleCopy}>
              <FontAwesomeIcon icon={faClipboard} /> Sao chép
            </button>
            {copied && <div className={styles.copyFeedback}>✅ Đã sao chép!</div>}
            {!safe && <div style={{ color: 'orange' }}>⚠️ Link có thể không an toàn.</div>}
          </div>
        )}

        <div className={styles.history}>
          <h3>Lịch sử</h3>
          <ul>
            {history.map((item, idx) => {
              const time = new Date(item.timestamp).toLocaleString('vi-VN', {
                hour12: false,
                dateStyle: 'short',
                timeStyle: 'short'
              });
              return (
                <li key={idx} className={styles.historyItem}>
                  <div><strong>{time}</strong></div>
                  <div className={styles.linkPair}>
                    <span className={styles.short}>{item.short}</span>
                    <span className={styles.arrow}>➝</span>
                    <a href={item.original} target="_blank" rel="noreferrer">{item.original}</a>
                  </div>
                </li>
              );
            })}
          </ul>
        </div>
      </div>
    </Layout>
  );
}