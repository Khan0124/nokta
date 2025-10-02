const express = require('express');
const router = express.Router();

// TODO: Implement product management routes
router.get('/', (req, res) => {
  res.json({ message: 'Products endpoint - Coming soon' });
});

module.exports = router;
