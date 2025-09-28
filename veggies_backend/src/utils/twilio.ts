import twilio from 'twilio';
import { logger } from './logger';

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

export const sendOTP = async (phoneNumber: string, otp: string): Promise<boolean> => {
  try {
    // const message = await client.messages.create({
    //   body: `Your VeggieFresh verification code is: ${otp}. This code will expire in 5 minutes.`,
    //   from: process.env.TWILIO_PHONE_NUMBER,
    //   to: `+91${phoneNumber}` // Assuming Indian phone numbers
    // });

    // logger.info(`OTP sent to ${phoneNumber}, Message SID: ${message.sid}`);
    console.log("otp sent ::::::::",otp);
    return true;
  } catch (error) {
    logger.error('Failed to send OTP:', error);
    return false;
  }
};

export const generateOTP = (): string => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};
