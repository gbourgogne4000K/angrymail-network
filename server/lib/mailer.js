/**
 * Email sending utilities
 * Uses nodemailer for SMTP
 */

const nodemailer = require('nodemailer');
require('dotenv').config();

let transporter = null;

/**
 * Initialize email transporter
 */
function initMailer() {
  if (process.env.ENABLE_EMAIL_NOTIFICATIONS !== 'true') {
    console.log('ℹ Email notifications disabled');
    return null;
  }

  if (!process.env.SMTP_HOST) {
    console.warn('⚠ SMTP not configured, emails will not be sent');
    return null;
  }

  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT) || 587,
    secure: parseInt(process.env.SMTP_PORT) === 465,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });

  console.log('✓ Email transporter initialized');
  return transporter;
}

/**
 * Send email
 */
async function sendEmail({ to, subject, text, html }) {
  if (!transporter) {
    console.log('Email not sent (transporter not initialized):', subject);
    return false;
  }

  try {
    const info = await transporter.sendMail({
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to,
      subject,
      text,
      html
    });

    console.log('✓ Email sent:', info.messageId);
    return true;
  } catch (error) {
    console.error('Error sending email:', error.message);
    return false;
  }
}

/**
 * Send claim verification email
 */
async function sendClaimVerification(email, verificationCode, claimUrl) {
  const subject = 'AngryMail - Verify Your Agent Claim';
  const text = `
Your verification code is: ${verificationCode}

Claim URL: ${claimUrl}

Visit ${process.env.SITE_DOMAIN}/claim to complete verification.
  `.trim();

  const html = `
    <h2>AngryMail - Verify Your Agent Claim</h2>
    <p>Your verification code is:</p>
    <h1 style="color: #e74c3c;">${verificationCode}</h1>
    <p>Claim URL: <a href="${claimUrl}">${claimUrl}</a></p>
    <p><a href="https://${process.env.SITE_DOMAIN}/claim">Click here to complete verification</a></p>
  `;

  return await sendEmail({ to: email, subject, text, html });
}

/**
 * Send webhook notification email
 */
async function sendWebhookNotification(webhookData) {
  const subject = `AngryMail - New Webhook from ${webhookData.source}`;
  const text = `
New webhook received:
Source: ${webhookData.source}
Time: ${new Date().toISOString()}

Payload:
${JSON.stringify(webhookData.payload, null, 2)}
  `.trim();

  const adminEmail = process.env.SMTP_FROM;
  if (!adminEmail) {
    return false;
  }

  return await sendEmail({ to: adminEmail, subject, text });
}

module.exports = {
  initMailer,
  sendEmail,
  sendClaimVerification,
  sendWebhookNotification
};
