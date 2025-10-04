import { Request, Response } from 'express';
import { Product } from '../models/Product';
import { logger } from '../utils/logger';

export const getProducts = async (req: Request, res: Response) => {
  try {
    const { category, q, limit = '20', page = '1' } = req.query;
    
    const query: any = { isActive: true };
    
    if (category) {
      query.categoryId = category;
    }
    
    if (q) {
      // Use regex for partial/substring matching (case-insensitive)
      const searchRegex = new RegExp(q as string, 'i');
      query.$or = [
        { name: searchRegex },
        { description: searchRegex }
      ];
    }

    const limitNum = parseInt(limit as string);
    const pageNum = parseInt(page as string);
    const skip = (pageNum - 1) * limitNum;

    const products = await Product.find(query)
      .populate('categoryId', 'name')
      .select('name slug images unitPrices rating description')
      .sort({ createdAt: -1 })
      .limit(limitNum)
      .skip(skip);

    const total = await Product.countDocuments(query);

    res.json({
      success: true,
      data: products,
      meta: {
        total,
        page: pageNum,
        limit: limitNum,
        pages: Math.ceil(total / limitNum)
      }
    });
  } catch (error) {
    logger.error('Get products error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch products'
    });
  }
};

export const getProductById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    const product = await Product.findOne({ _id: id, isActive: true })
      .populate('categoryId', 'name');

    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    logger.error('Get product by ID error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch product'
    });
  }
};
