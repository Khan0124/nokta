const express = require('express');
const router = express.Router();

// TODO: Implement inventory management routes
router.get('/', (req, res) => {
  res.json({ message: 'Inventory endpoint - Coming soon' });
});

module.exports = router;
