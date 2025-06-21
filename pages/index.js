import { useState } from 'react';
import styles from '../styles/Home.module.css';

export default function Home() {
  const [url, setUrl] = useState('');
  const [result, setResult] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setResult('');
    setLoading(true);

    try {
      const res = await fetch('/api/unshorten', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url })
      });

      const data = await res.json();
      if (data.originalUrl) {
        setResult(`✅ Link gốc: ${data.originalUrl}`);
      } else {
        setResult(`❌ Lỗi: ${data.error}`);
      }
    } catch (error) {
      setResult('❌ Có lỗi xảy ra khi gửi yêu cầu.');
    }

    setLoading(false);
  };

  return (
    <div className={styles.container}>
      <h1>🔗 Unshorten Link</h1>
      <form onSubmit={handleSubmit} className={styles.form}>
        <input
          type="url"
          placeholder="Dán link rút gọn vào đây..."
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          required
        />
        <button type="submit">Xem link gốc</button>
      </form>
      <div className={styles.result}>
        {loading ? '⏳ Đang kiểm tra...' : result}
      </div>
    </div>
  );
}