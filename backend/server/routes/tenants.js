const express = require('express');
const router = express.Router();

// TODO: Implement tenant management routes
router.get('/', (req, res) => {
  res.json({ message: 'Tenants endpoint - Coming soon' });
});

module.exports = router;
