const express = require('express');
const { getTodaysDeals } = require('../controllers/deals');

const router = express.Router();

/**
 * @swagger
 * /deals/today:
 *   get:
 *     summary: Get today's deals
 *     description: Returns products flagged as deals with computed discount percentage and countdown end time.
 *     tags: [Deals]
 *     security: []
 *     responses:
 *       200:
 *         description: List of today's deals
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Product'
 *                 dealEndsAt:
 *                   type: string
 *                   format: date-time
 *                 meta:
 *                   type: object
 *                   properties:
 *                     total:
 *                       type: integer
 *       500:
 *         $ref: '#/components/responses/ValidationError'
 */
router.get('/today', getTodaysDeals);

module.exports = router;
