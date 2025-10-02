const express = require('express');
const router = express.Router();

// TODO: Implement order management routes
router.get('/', (req, res) => {
  res.json({ message: 'Orders endpoint - Coming soon' });
});

module.exports = router;
