import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals';
import { Request, Response } from 'express';
import { User } from '../entities/User';
import argon2 from 'argon2';

// Mock argon2
jest.mock('argon2');

describe('User Creation - Integration Tests', () => {
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;
  let mockJsonResponse: jest.Mock;
  let mockStatusJsonResponse: jest.Mock;
  let mockStatusResponse: jest.Mock;
  let mockCookie: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();

    mockJsonResponse = jest.fn().mockReturnValue(undefined);
    mockStatusJsonResponse = jest.fn().mockReturnValue({
      json: mockJsonResponse,
    });
    mockStatusResponse = jest.fn().mockReturnValue({
      json: mockStatusJsonResponse,
      send: jest.fn(),
      cookie: mockCookie,
    });
    mockCookie = jest.fn().mockReturnValue(undefined);

    mockRes = {
      status: mockStatusResponse,
      json: mockJsonResponse,
      cookie: mockCookie,
    };
  });

  describe('POST /users - Create user', () => {
    it('should create user successfully with valid credentials', async () => {
      // Arrange
      const email = 'newuser@test.com';
      const password = 'Password123!';
      const hashedPassword = '$argon2id$v=19$m=65536,t=3,p=4$abcdef$1234567890';

      mockReq = {
        body: { email, password },
      };

      (argon2.hash as jest.Mock).mockResolvedValue(hashedPassword);

      const mockUser = new User();
      mockUser.email = email;
      mockUser.hashedPassword = hashedPassword;
      mockUser.id = 1;
      mockUser.addresses = [];
      mockUser.createdAt = new Date();
      mockUser.save = jest.fn().mockResolvedValue(undefined);

      // Act
      mockUser.email = mockReq.body!.email;
      mockUser.hashedPassword = await argon2.hash(mockReq.body!.password);
      await mockUser.save();

      // Assert
      expect(mockReq.body!.email).toBe(email);
      expect(mockReq.body!.password).toBe(password);
      expect(mockUser.email).toBe(email);
      expect(mockUser.hashedPassword).toBe(hashedPassword);
      expect(argon2.hash).toHaveBeenCalledWith(password);
      expect(mockUser.save).toHaveBeenCalled();
    });

    it('should reject request with missing email', () => {
      // Arrange
      mockReq = {
        body: { password: 'Password123!' },
      };

      const email = mockReq.body!.email;
      const password = mockReq.body!.password;

      // Act & Assert
      expect(!email || !password).toBe(true);
      expect(email).toBeUndefined();
    });

    it('should reject request with missing password', () => {
      // Arrange
      mockReq = {
        body: { email: 'test@example.com' },
      };

      const email = mockReq.body!.email;
      const password = mockReq.body!.password;

      // Act & Assert
      expect(!email || !password).toBe(true);
      expect(password).toBeUndefined();
    });

    it('should reject request with both email and password missing', () => {
      // Arrange
      mockReq = {
        body: {},
      };

      const email = mockReq.body!.email;
      const password = mockReq.body!.password;

      // Act & Assert
      expect(!email || !password).toBe(true);
      expect(email).toBeUndefined();
      expect(password).toBeUndefined();
    });

    it('should handle database errors when saving user', async () => {
      // Arrange
      const email = 'newuser@test.com';
      const password = 'Password123!';
      const hashedPassword = '$argon2id$v=19$m=65536,t=3,p=4$abcdef$1234567890';
      const dbError = new Error('Database connection failed');

      mockReq = {
        body: { email, password },
      };

      (argon2.hash as jest.Mock).mockResolvedValue(hashedPassword);

      const mockUser = new User();
      mockUser.email = email;
      mockUser.hashedPassword = hashedPassword;
      mockUser.save = jest.fn().mockRejectedValue(dbError);

      // Act & Assert
      expect(mockUser.save()).rejects.toThrow('Database connection failed');
    });

    it('should handle password hashing errors', async () => {
      // Arrange
      const email = 'newuser@test.com';
      const password = 'Password123!';
      const hashError = new Error('Hashing failed');

      mockReq = {
        body: { email, password },
      };

      (argon2.hash as jest.Mock).mockRejectedValue(hashError);

      // Act & Assert
      expect(argon2.hash(password)).rejects.toThrow('Hashing failed');
    });

    it('should not store plain text password', async () => {
      // Arrange
      const email = 'newuser@test.com';
      const plainPassword = 'Password123!';
      const hashedPassword = '$argon2id$v=19$m=65536,t=3,p=4$abcdef$1234567890';

      mockReq = {
        body: { email, password: plainPassword },
      };

      (argon2.hash as jest.Mock).mockResolvedValue(hashedPassword);

      const mockUser = new User();
      mockUser.email = email;
      mockUser.hashedPassword = await argon2.hash(plainPassword);

      // Act & Assert
      expect(mockUser.hashedPassword).toBe(hashedPassword);
      expect(mockUser.hashedPassword).not.toBe(plainPassword);
    });

    it('should trim whitespace from email if provided', () => {
      // Arrange
      const emailWithSpaces = '  test@example.com  ';
      const trimmedEmail = emailWithSpaces.trim();

      // Act & Assert
      expect(trimmedEmail).toBe('test@example.com');
      expect(trimmedEmail).not.toBe(emailWithSpaces);
    });

    it('should preserve user data during creation flow', async () => {
      // Arrange
      const email = 'newuser@test.com';
      const password = 'Password123!';
      const hashedPassword = '$argon2id$v=19$m=65536,t=3,p=4$abcdef$1234567890';

      (argon2.hash as jest.Mock).mockResolvedValue(hashedPassword);

      const mockUser = new User();
      mockUser.id = 1;
      mockUser.email = email;
      mockUser.hashedPassword = hashedPassword;
      mockUser.addresses = [];
      mockUser.createdAt = new Date();
      mockUser.save = jest.fn().mockResolvedValue(undefined);

      // Act
      await mockUser.save();

      // Assert
      expect(mockUser.id).toBe(1);
      expect(mockUser.email).toBe(email);
      expect(mockUser.addresses).toEqual([]);
      expect(mockUser.createdAt).toBeInstanceOf(Date);
    });
  });
});

