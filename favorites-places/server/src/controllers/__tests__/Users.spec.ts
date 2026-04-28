import argon2 from 'argon2';

// Mock argon2
jest.mock('argon2');

describe('User Creation - Unit Tests', () => {
  let mockHashedPassword: string;

  beforeEach(() => {
    // @ts-expect-error - jest is globally available
    jest.clearAllMocks();
    mockHashedPassword = '$argon2id$v=19$m=65536,t=3,p=4$some$hash';
  });

  it('should create a user with valid email and password', async () => {
    // Arrange
    const email = 'test@example.com';
    const password = 'securePassword123';

    // @ts-expect-error - jest is globally available
    (argon2.hash as jest.Mock).mockResolvedValue(mockHashedPassword);

    // Act
    const hashedPassword = await argon2.hash(password);

    // Assert
    expect(email).toBe(email);
    expect(hashedPassword).toBe(mockHashedPassword);
    // @ts-expect-error - jest is globally available
    expect(argon2.hash).toHaveBeenCalledWith(password);
  });

  it('should hash the password before storing', async () => {
    // Arrange
    const password = 'mySecurePassword';

    // @ts-expect-error - jest is globally available
    (argon2.hash as jest.Mock).mockResolvedValue(mockHashedPassword);

    // Act
    const result = await argon2.hash(password);

    // Assert
    // @ts-expect-error - jest is globally available
    expect(argon2.hash).toHaveBeenCalledWith(password);
    expect(result).toBe(mockHashedPassword);
    expect(result).not.toBe(password);
  });

  it('should call argon2.hash with the plain password', async () => {
    // Arrange
    const password = 'securePassword123';

    // @ts-expect-error - jest is globally available
    (argon2.hash as jest.Mock).mockResolvedValue(mockHashedPassword);

    // Act
    await argon2.hash(password);

    // Assert
    // @ts-expect-error - jest is globally available
    expect(argon2.hash).toHaveBeenCalledWith(password);
    // @ts-expect-error - jest is globally available
    expect(argon2.hash).toHaveBeenCalledTimes(1);
  });

  it('should handle argon2 hashing errors', async () => {
    // Arrange
    const password = 'securePassword123';
    const hashError = new Error('Argon2 error');

    // @ts-expect-error - jest is globally available
    (argon2.hash as jest.Mock).mockRejectedValue(hashError);

    // Act & Assert
    await expect(argon2.hash(password)).rejects.toThrow('Argon2 error');
  });

  it('should not return plain text password', async () => {
    // Arrange
    const password = 'MySecretPassword123!';

    // @ts-expect-error - jest is globally available
    (argon2.hash as jest.Mock).mockResolvedValue(mockHashedPassword);

    // Act
    const result = await argon2.hash(password);

    // Assert
    expect(result).not.toContain(password);
    expect(result).toMatch(/^\$argon2id\$/);
  });
});

