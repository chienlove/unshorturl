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
          <p><strong>Giới thiệu:</strong> Đây là công cụ giúp bạn kiểm tra <strong>link gốc</strong> của các liên kết rút gọn như <code>bit.ly</code>, <code>tinyurl</code>, <code>is.gd</code>,... hoàn toàn miễn phí.</p>
          <p><strong>Hỗ trợ:</strong> Liên kết dạng rút gọn HTTP/S đơn thuần. Không hỗ trợ:
            <ul>
              <li>Liên kết có mã token (Google Drive, Dropbox…)</li>
              <li>Liên kết cần xác thực đăng nhập</li>
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
          <button type="submit" className={styles.button}>
            {result || error ? '🔁 Kiểm tra lại' : '🔍 Xem link gốc'}
          </button>
        </form>

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