const express = require('express');
const router = express.Router();

// TODO: Implement category management routes
router.get('/', (req, res) => {
  res.json({ message: 'Categories endpoint - Coming soon' });
});

module.exports = router;
