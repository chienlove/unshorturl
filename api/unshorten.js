export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Only POST allowed' });
  }

  const { url } = req.body;

  if (!url || !url.startsWith('http')) {
    return res.status(400).json({ error: 'Invalid URL' });
  }

  try {
    const response = await fetch(url, {
      method: 'HEAD',
      redirect: 'manual'
    });

    const location = response.headers.get('location');

    if (location) {
      res.status(200).json({ originalUrl: location });
    } else {
      res.status(404).json({ error: 'Redirect location not found' });
    }
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch', detail: err.message });
  }
}