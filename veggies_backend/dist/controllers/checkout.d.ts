import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth';
export declare const saveAddress: (req: AuthRequest, res: Response) => Promise<void>;
export declare const createOrder: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const getTimeSlots: (req: AuthRequest, res: Response) => Promise<void>;
export declare const verifyPayment: (req: AuthRequest, res: Response) => Promise<Response<any, Record<string, any>> | undefined>;
//# sourceMappingURL=checkout.d.ts.map