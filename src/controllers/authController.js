// src/controllers/authController.js - Controlador de autenticação
const bcrypt = require('bcrypt');
const db = require('../config/database');

// Registrar um novo usuário
exports.register = async (req, res) => {
    try {
        const { firstName, lastName, email, password, birthDate, phone } = req.body;
        
        // Verificar se o e-mail já está em uso
        const [existingUsers] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
        
        if (existingUsers.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Este e-mail já está cadastrado'
            });
        }
        
        // Hash da senha antes de armazenar no banco
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        
        // Inserir o novo usuário no banco de dados
        const [result] = await db.query(
            'INSERT INTO users (first_name, last_name, email, password, birth_date, phone, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
            [firstName, lastName, email, hashedPassword, birthDate, phone]
        );
        
        res.status(201).json({
            success: true,
            message: 'Usuário cadastrado com sucesso',
            userId: result.insertId
        });
    } catch (error) {
        console.error('Erro no registro:', error);
        res.status(500).json({
            success: false,
            message: 'Erro ao registrar usuário'
        });
    }
};

// Login de usuário
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Buscar usuário pelo e-mail
        const [users] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
        
        if (users.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'E-mail ou senha inválidos'
            });
        }
        
        const user = users[0];
        
        // Verificar a senha
        const isMatch = await bcrypt.compare(password, user.password);
        
        if (!isMatch) {
            return res.status(400).json({
                success: false,
                message: 'E-mail ou senha inválidos'
            });
        }
        
        // Criar dados do usuário para retornar (sem a senha)
        const userData = {
            id: user.id,
            firstName: user.first_name,
            lastName: user.last_name,
            email: user.email
        };
        
        res.status(200).json({
            success: true,
            message: 'Login realizado com sucesso',
            user: userData
        });
    } catch (error) {
        console.error('Erro no login:', error);
        res.status(500).json({
            success: false,
            message: 'Erro ao fazer login'
        });
    }
};