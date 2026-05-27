const authService = require('../services/auth');

// Login with email/phone (we only receive one) and password
exports.login = async (req, res) => {
  const { any, password } = req.body;

  try {
    //we check if the input is an email or a phone number
    const isEmail = any.includes('@');
    const user = isEmail
      ? await authService.loginWithEmail(any, password)
      : await authService.loginWithPhone(any, password);

    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate a JWT token for the authenticated user
    const token = authService.generateToken(user);

    res.json({ token });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

exports.register = async (req, res) => {
  const data = req.body;

  try {
    const user = await authService.register(data);

    if (!user) {
      return res.status(400).json({ message: 'Registration failed' });
    }

    // Generate a JWT token for the newly registered user
    const token = authService.generateToken(user);

    res.json({ token });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

exports.authorize = (roles = []) => {
  // roles param can be a single role string (e.g. 'admin') or an array of roles (e.g. ['admin', 'user'])
  if (typeof roles === 'string') {
    roles = [roles];
  }

  return (req, res, next) => {
    const user = req.user;

    if (!user) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (roles.length && !roles.includes(user.role)) {
      return res.status(403).json({ message: 'Forbidden' });
    }

    next();
  };
};

// Middleware to authenticate JWT token and attach user to request
exports.authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'No token provided' });
  }

  try {
    const user = authService.verifyToken(token);
    if (!user || !user.id) {
      return res.status(401).json({ message: 'Invalid token' });
    }
    req.user = user;
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(401).json({ message: 'Invalid token' });
  }
};