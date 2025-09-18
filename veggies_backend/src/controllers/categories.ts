import { Request, Response } from 'express';
import { Category } from '../models/Category';
import { logger } from '../utils/logger';

export const getCategories = async (req: Request, res: Response) => {
  try {
    const categories = await Category.find({ isActive: true })
      .sort({ sort: 1, name: 1 })
      .select('name iconUrl');

    res.json({
      success: true,
      data: categories
    });
  } catch (error) {
    logger.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch categories'
    });
  }
};
