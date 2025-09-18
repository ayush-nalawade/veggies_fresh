import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth';
export declare const getOrders: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getOrderById: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
//# sourceMappingURL=orders.d.ts.map