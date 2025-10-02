const express = require('express');
const router = express.Router();

// TODO: Implement branch management routes
router.get('/', (req, res) => {
  res.json({ message: 'Branches endpoint - Coming soon' });
});

module.exports = router;
