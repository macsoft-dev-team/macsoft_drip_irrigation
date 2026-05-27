const { prisma } = require('../prisma/client');
const bcrypt = require('bcrypt');

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

exports.loginWithEmail = async (email, password) => {
    try {
        const user = await prisma.user.findUnique({
            where: { email },
        });

        //compare the password with bcrypt
        const isPasswordValid = await bcrypt.compare(password, user.password);

        if (!user || !isPasswordValid) {
            return null;
        }

        return user;
    } catch (error) {
        console.error('Login error:', error);
        throw error;
    }
};

exports.loginWithPhone = async (phone, password) => {
    try {
        const user = await prisma.user.findUnique({
            where: { phone },
        });

        //compare the password with bcrypt
        const isPasswordValid = await bcrypt.compare(password, user.password);

        if (!user || !isPasswordValid) {
            return null;
        }

        return user;
    } catch (error) {
        console.error('Login error:', error);
        throw error;
    }
};

exports.register = async (data) => {
    try {
        // Hash the password before storing it
        const hashedPassword = await bcrypt.hash(data.password, 10);
        const user = await prisma.user.create({
            data: {
                ...data,
                password: hashedPassword,
            },
        });
        return user;
    } catch (error) {
        console.error('Registration error:', error);
        throw error;
    }
};

exports.generateToken = (user) => {
    return jwt.sign({ id: user.id, role: user.role, name: user.name, customerId: user.customerId ?? null }, JWT_SECRET, { expiresIn: '24h' });
};

exports.verifyToken = (token) => {
    const decoded = jwt.verify(token, JWT_SECRET);
    return decoded;
};
