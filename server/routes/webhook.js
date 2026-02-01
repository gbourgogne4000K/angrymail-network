/**
 * Webhook routes
 * Handles incoming webhooks from Moltbook and other services
 */

const express = require('express');
const router = express.Router();
const db = require('../lib/db');
const { sendWebhookNotification } = require('../lib/mailer');

/**
 * POST /webhook/moltbook
 * Receive Moltbook webhooks
 */
router.post('/moltbook', async (req, res) => {
  try {
    const payload = req.body;

    // Log webhook
    const result = await db.query(
      `INSERT INTO webhook_logs (source, payload, status)
       VALUES ('moltbook', ?, 'received')`,
      [JSON.stringify(payload)]
    );

    const logId = result.insertId;

    // Process webhook (add your business logic here)
    try {
      // Example: Extract data from webhook
      const { event, data } = payload;

      console.log('Moltbook webhook received:', event);

      // Send email notification if enabled
      if (process.env.ENABLE_EMAIL_NOTIFICATIONS === 'true') {
        await sendWebhookNotification({ source: 'moltbook', payload });
      }

      // Mark as processed
      await db.query(
        'UPDATE webhook_logs SET status = ?, processed_at = NOW() WHERE id = ?',
        ['processed', logId]
      );

      res.json({ success: true, message: 'Webhook received and processed' });
    } catch (processError) {
      // Mark as failed
      await db.query(
        'UPDATE webhook_logs SET status = ?, error_message = ? WHERE id = ?',
        ['failed', processError.message, logId]
      );

      console.error('Error processing webhook:', processError);
      res.status(500).json({ error: 'Failed to process webhook' });
    }
  } catch (error) {
    console.error('Error receiving webhook:', error);
    res.status(500).json({ error: 'Failed to receive webhook' });
  }
});

/**
 * POST /webhook/generic
 * Generic webhook endpoint for other services
 */
router.post('/generic', async (req, res) => {
  try {
    const source = req.query.source || 'unknown';
    const payload = req.body;

    await db.query(
      `INSERT INTO webhook_logs (source, payload, status, processed_at)
       VALUES (?, ?, 'processed', NOW())`,
      [source, JSON.stringify(payload)]
    );

    console.log(`Webhook received from ${source}`);

    res.json({ success: true });
  } catch (error) {
    console.error('Error receiving generic webhook:', error);
    res.status(500).json({ error: 'Failed to receive webhook' });
  }
});

module.exports = router;
