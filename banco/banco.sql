-- Criação do banco de dados
CREATE DATABASE parque_hopiari;
USE parque_hopiari;

-- Tabela de áreas do parque
CREATE TABLE areas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255)
);

-- Tabela de atrações
CREATE TABLE atracoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    area_id INT NOT NULL,
    imagem_url VARCHAR(255),
    capacidade_hora INT,
    tempo_percurso INT, -- em minutos
    FOREIGN KEY (area_id) REFERENCES areas(id)
);

-- Tabela de status possíveis
CREATE TABLE status_tipos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(255),
    classe_css VARCHAR(50) -- para estilização no frontend
);

-- Tabela de tempo de espera das atrações
CREATE TABLE tempos_espera (
    id INT AUTO_INCREMENT PRIMARY KEY,
    atracao_id INT NOT NULL,
    tempo_minutos INT NOT NULL,
    status_id INT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (atracao_id) REFERENCES atracoes(id),
    FOREIGN KEY (status_id) REFERENCES status_tipos(id)
);

-- Tabela de log de atualizações
CREATE TABLE atualizacoes_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario_id INT,
    descricao VARCHAR(255)
);

-- Inserindo dados iniciais

-- Áreas
INSERT INTO areas (nome, descricao) VALUES
('AREA 1', 'Área principal do parque com atrações variadas');

-- Tipos de status
INSERT INTO status_tipos (nome, descricao, classe_css) VALUES
('Normal', 'Fluxo normal de visitantes', 'status-open'),
('Movimentado', 'Fluxo acima do normal', 'status-busy'),
('Muito Movimentado', 'Fluxo muito acima do normal', 'status-busy'),
('Em Manutenção', 'Atração temporariamente fechada para manutenção', 'status-maintenance'),
('Fechado', 'Atração não está operando', 'status-closed');

-- Atrações
INSERT INTO atracoes (nome, area_id, imagem_url, capacidade_hora, tempo_percurso) VALUES
('Montanha Mágica', 1, '/api/placeholder/400/320', 800, 3),
('Carrossel Encantado', 1, '/api/placeholder/400/320', 1200, 2),
('Roda Gigante Celestial', 1, '/api/placeholder/400/320', 600, 5),
('Mansão Assombrada', 1, '/api/placeholder/400/320', 500, 8),
('Splash Aquático', 1, '/api/placeholder/400/320', 400, 4),
('Carrinhos de Choque', 1, '/api/placeholder/400/320', 900, 3),
('Trem Fantástico', 1, '/api/placeholder/400/320', 700, 6),
('Barco Viking', 1, '/api/placeholder/400/320', 500, 4);

-- Tempo de espera atual (com base no código HTML)
INSERT INTO tempos_espera (atracao_id, tempo_minutos, status_id, timestamp) VALUES
(1, 35, 3, '2025-04-25 15:42:00'), -- Montanha Mágica
(2, 15, 1, '2025-04-25 15:42:00'), -- Carrossel Encantado
(3, 20, 1, '2025-04-25 15:42:00'), -- Roda Gigante Celestial
(4, 25, 2, '2025-04-25 15:42:00'), -- Mansão Assombrada
(5, 40, 3, '2025-04-25 15:42:00'), -- Splash Aquático
(6, 10, 1, '2025-04-25 15:42:00'), -- Carrinhos de Choque
(7, 0, 4, '2025-04-25 15:42:00'),  -- Trem Fantástico
(8, 30, 2, '2025-04-25 15:42:00'); -- Barco Viking

-- Log da última atualização
INSERT INTO atualizacoes_log (data_hora, descricao) VALUES
('2025-04-25 15:42:00', 'Atualização automática dos tempos de espera');

-- Criando view para consulta rápida do estado atual
CREATE VIEW view_estado_atual AS
SELECT 
    a.nome AS atracao,
    t.tempo_minutos,
    s.nome AS status,
    s.classe_css,
    a.imagem_url,
    ar.nome AS area,
    t.timestamp AS ultima_atualizacao
FROM 
    tempos_espera t
JOIN 
    atracoes a ON t.atracao_id = a.id
JOIN 
    status_tipos s ON t.status_id = s.id
JOIN 
    areas ar ON a.area_id = ar.id
WHERE 
    t.id IN (
        SELECT MAX(id) FROM tempos_espera GROUP BY atracao_id
    )
ORDER BY 
    ar.nome, a.nome;

-- Procedimento para atualizar o tempo de espera de uma atração
DELIMITER //
CREATE PROCEDURE atualizar_tempo_espera(
    IN p_atracao_id INT,
    IN p_tempo_minutos INT,
    IN p_status_id INT
)
BEGIN
    INSERT INTO tempos_espera (atracao_id, tempo_minutos, status_id)
    VALUES (p_atracao_id, p_tempo_minutos, p_status_id);
    
    INSERT INTO atualizacoes_log (descricao)
    VALUES (CONCAT('Atualização do tempo de espera da atração ID ', p_atracao_id));
END //
DELIMITER ;

-- Procedimento para obter histórico de tempos de espera de uma atração
DELIMITER //
CREATE PROCEDURE obter_historico_atracao(
    IN p_atracao_id INT,
    IN p_dias INT
)
BEGIN
    SELECT 
        a.nome AS atracao,
        t.tempo_minutos,
        s.nome AS status,
        t.timestamp
    FROM 
        tempos_espera t
    JOIN 
        atracoes a ON t.atracao_id = a.id
    JOIN 
        status_tipos s ON t.status_id = s.id
    WHERE 
        t.atracao_id = p_atracao_id
        AND t.timestamp >= DATE_SUB(NOW(), INTERVAL p_dias DAY)
    ORDER BY 
        t.timestamp DESC;
END //
DELIMITER ;