import { Html, Head, Main, NextScript } from 'next/document';

export default function Document() {
  return (
    <Html lang="vi">
      <Head>
        <meta charSet="UTF-8" />
        <meta name="description" content="Công cụ xem link gốc từ liên kết rút gọn - Unshorten Link Việt Nam." />
        <meta property="og:title" content="Unshorten Link - Xem link gốc" />
        <meta property="og:image" content="/banner.png" />
        <meta name="robots" content="index, follow" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}