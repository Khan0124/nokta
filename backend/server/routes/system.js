const express = require('express');
const router = express.Router();

// TODO: Implement system management routes
router.get('/', (req, res) => {
  res.json({ message: 'System endpoint - Coming soon' });
});

module.exports = router;
