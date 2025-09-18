import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { Category } from '../models/Category';
import { Product } from '../models/Product';
import { logger } from '../utils/logger';

dotenv.config();

const seedData = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/veggiefresh');
    logger.info('Connected to MongoDB');

    // Clear existing data
    await Category.deleteMany({});
    await Product.deleteMany({});
    logger.info('Cleared existing data');

    // Create categories
    const categories = await Category.insertMany([
      { name: 'Fruits', iconUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=100', sort: 1 },
      { name: 'Vegetables', iconUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=100', sort: 2 },
      { name: 'Dairy', iconUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=100', sort: 3 },
      { name: 'Herbs & Spices', iconUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=100', sort: 4 },
      { name: 'Organic', iconUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100', sort: 5 }
    ]);
    logger.info('Created categories');

    // Create products
    const products = await Product.insertMany([
      {
        name: 'Fresh Tomatoes',
        slug: 'fresh-tomatoes',
        categoryId: categories[1]._id,
        images: ['https://images.unsplash.com/photo-1546470427-4b4b4b4b4b4b?w=400'],
        description: 'Fresh, juicy tomatoes perfect for salads and cooking',
        unitPrices: [
          { unit: 'kg', step: 0.25, baseQty: 1, price: 40, stock: 50 },
          { unit: 'g', step: 250, baseQty: 1000, price: 40, stock: 50000 }
        ],
        rating: 4.5
      },
      {
        name: 'Organic Bananas',
        slug: 'organic-bananas',
        categoryId: categories[0]._id,
        images: ['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400'],
        description: 'Sweet, organic bananas rich in potassium',
        unitPrices: [
          { unit: 'kg', step: 0.5, baseQty: 1, price: 60, stock: 30 },
          { unit: 'pcs', step: 1, baseQty: 1, price: 3, stock: 200 }
        ],
        rating: 4.3
      },
      {
        name: 'Fresh Carrots',
        slug: 'fresh-carrots',
        categoryId: categories[1]._id,
        images: ['https://images.unsplash.com/photo-1598170845058-87b9d4c0358a?w=400'],
        description: 'Crisp, fresh carrots perfect for snacking',
        unitPrices: [
          { unit: 'kg', step: 0.25, baseQty: 1, price: 35, stock: 40 },
          { unit: 'g', step: 500, baseQty: 1000, price: 35, stock: 40000 }
        ],
        rating: 4.2
      },
      {
        name: 'Fresh Milk',
        slug: 'fresh-milk',
        categoryId: categories[2]._id,
        images: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400'],
        description: 'Fresh, pure milk from local farms',
        unitPrices: [
          { unit: 'pcs', step: 1, baseQty: 1, price: 25, stock: 100 }
        ],
        rating: 4.4
      },
      {
        name: 'Fresh Onions',
        slug: 'fresh-onions',
        categoryId: categories[1]._id,
        images: ['https://images.unsplash.com/photo-1518977956812-cd3dbadaaf31?w=400'],
        description: 'Fresh onions perfect for cooking',
        unitPrices: [
          { unit: 'kg', step: 0.5, baseQty: 1, price: 30, stock: 60 },
          { unit: 'g', step: 500, baseQty: 1000, price: 30, stock: 60000 }
        ],
        rating: 4.1
      },
      {
        name: 'Fresh Potatoes',
        slug: 'fresh-potatoes',
        categoryId: categories[1]._id,
        images: ['https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400'],
        description: 'Fresh potatoes perfect for various dishes',
        unitPrices: [
          { unit: 'kg', step: 0.5, baseQty: 1, price: 25, stock: 80 },
          { unit: 'g', step: 500, baseQty: 1000, price: 25, stock: 80000 }
        ],
        rating: 4.0
      },
      {
        name: 'Fresh Spinach',
        slug: 'fresh-spinach',
        categoryId: categories[1]._id,
        images: ['https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400'],
        description: 'Fresh, leafy spinach rich in iron',
        unitPrices: [
          { unit: 'kg', step: 0.25, baseQty: 1, price: 50, stock: 20 },
          { unit: 'g', step: 250, baseQty: 1000, price: 50, stock: 20000 }
        ],
        rating: 4.6
      },
      {
        name: 'Fresh Apples',
        slug: 'fresh-apples',
        categoryId: categories[0]._id,
        images: ['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400'],
        description: 'Crisp, sweet apples perfect for snacking',
        unitPrices: [
          { unit: 'kg', step: 0.5, baseQty: 1, price: 80, stock: 25 },
          { unit: 'pcs', step: 1, baseQty: 1, price: 8, stock: 150 }
        ],
        rating: 4.4
      }
    ]);
    logger.info('Created products');

    logger.info('Seed data created successfully!');
    logger.info(`Created ${categories.length} categories and ${products.length} products`);

  } catch (error) {
    logger.error('Seed error:', error);
  } finally {
    await mongoose.disconnect();
    logger.info('Disconnected from MongoDB');
  }
};

seedData();
