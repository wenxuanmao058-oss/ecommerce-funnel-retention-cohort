USE project2;
SHOW TABLES;
#漏斗分析
SELECT * FROM  interactions;
DESC interactions;
#字段转化
ALTER TABLE interactions MODIFY COLUMN interaction_id VARCHAR(64),
MODIFY COLUMN user_id VARCHAR(64),
MODIFY COLUMN product_id VARCHAR(64),
MODIFY COLUMN session_id VARCHAR(64),
MODIFY COLUMN interaction_type VARCHAR(32),
MODIFY COLUMN dwell_time_ms DECIMAL(10,2);

#索引
CREATE INDEX idx_user_id ON interactions(user_id);
CREATE INDEX idx_interaction_type ON interactions(interaction_type);
CREATE INDEX idx_timestamp ON interactions(timestamp);

SELECT interaction_type,
COUNT(DISTINCT(user_id)) users_count
FROM interactions
GROUP BY interaction_type
ORDER BY users_count;#漏斗主干

SELECT COUNT(DISTINCT user_id) AS purchase_users
FROM purchases;

CREATE VIEW v_funnel_summary AS
SELECT 'view' AS stage, COUNT(DISTINCT user_id) AS users FROM interactions WHERE interaction_type='view'
UNION ALL
SELECT 'click', COUNT(DISTINCT user_id) FROM interactions WHERE interaction_type='click'
UNION ALL
SELECT 'add_to_cart', COUNT(DISTINCT user_id) FROM interactions WHERE interaction_type='add_to_cart'
UNION ALL
SELECT 'purchase', COUNT(DISTINCT user_id) FROM purchases;

SELECT * FROM v_funnel_summary;

#留存分析
DESC users;
SELECT * FROM users;
ALTER TABLE users MODIFY COLUMN user_id VARCHAR(64);
CREATE INDEX idx_user_id ON users(user_id);

SELECT 
    u.user_id,
    u.signup_date,
    i.timestamp AS activity_time,
    i.interaction_type
FROM users u
JOIN interactions i ON u.user_id = i.user_id
ORDER BY u.user_id, i.timestamp;
