const { prisma } = require('../prisma/client');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

exports.loginWithEmail = async (email, password) => {
    try {
        const user = await prisma.user.findUnique({
            where: { email },
        });

        if (!user) return null;

        // compare the password with bcrypt using passwordHash
        const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
        if (!isPasswordValid) {
            return null;
        }

        return user;
    } catch (error) {
        console.error('Login error:', error);
        throw error;
    }
};

exports.loginWithPhone = async (phone, password) => {
    // Phone authentication is disabled because the updated schema has no phone field.
    return null;
};

exports.register = async (data) => {
    try {
        // Hash the password before storing it
        const hashedPassword = await bcrypt.hash(data.password, 10);
        
        // Remove password raw field from input and map to passwordHash
        const { password: _, ...rest } = data;

        const user = await prisma.user.create({
            data: {
                ...rest,
                passwordHash: hashedPassword,
            },
        });
        return user;
    } catch (error) {
        console.error('Registration error:', error);
        throw error;
    }
};

exports.generateToken = (user) => {
    return jwt.sign(
        { 
            id: user.id, 
            role: user.role, 
            name: user.name, 
            tenantId: user.tenantId ?? null 
        }, 
        JWT_SECRET, 
        { expiresIn: '24h' }
    );
};

exports.verifyToken = (token) => {
    const decoded = jwt.verify(token, JWT_SECRET);
    return decoded;
};
