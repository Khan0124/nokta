const express = require('express');
const router = express.Router();

// TODO: Implement payment management routes
router.get('/', (req, res) => {
  res.json({ message: 'Payments endpoint - Coming soon' });
});

module.exports = router;
