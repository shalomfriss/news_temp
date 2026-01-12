INSERT INTO categories (name) VALUES
  ('top'),
  ('business'),
  ('entertainment'),
  ('health'),
  ('science'),
  ('sports'),
  ('technology');

INSERT INTO feeds (category, blocks_json, total_count) VALUES
  (
    'top',
    '[{"type":"__section_header__","title":"Top Stories","action":{"type":"__navigate_to_feed_category__","category":"top"}},'
    '{"type":"__post_large__","id":"art_tech_001","category":"technology","author":"Jane Doe","published_at":"2024-06-01T10:00:00Z","image_url":"https://example.com/img/ai.jpg","title":"AI chips are back","description":"Chip supply rebounds as demand surges.","is_premium":false,"is_content_overlaid":false,"action":{"type":"__navigate_to_article__","article_id":"art_tech_001"}}]'
    ,
    2
  ),
  (
    'technology',
    '[{"type":"__section_header__","title":"Technology","action":{"type":"__navigate_to_feed_category__","category":"technology"}},'
    '{"type":"__post_small__","id":"art_tech_002","category":"technology","author":"Sam Lee","published_at":"2024-06-02T09:30:00Z","image_url":"https://example.com/img/robot.jpg","title":"Warehouse robots get smarter","description":"New vision systems improve safety.","is_premium":true,"action":{"type":"__navigate_to_article__","article_id":"art_tech_002"}}]'
    ,
    2
  );

INSERT INTO articles (
  id, title, url, is_premium, total_count, content_json, content_preview_json, post_json
) VALUES
  (
    'art_tech_001',
    'AI chips are back',
    'https://example.com/articles/ai-chips',
    false,
    3,
    '[{"type":"__article_introduction__","category":"technology","author":"Jane Doe","published_at":"2024-06-01T10:00:00Z","image_url":"https://example.com/img/ai.jpg","title":"AI chips are back","is_premium":false},'
    '{"type":"__text_paragraph__","text":"After months of shortages, chip inventories are finally stabilizing."},'
    '{"type":"__text_paragraph__","text":"Manufacturers report improved yields and faster deliveries."}]',
    '[{"type":"__article_introduction__","category":"technology","author":"Jane Doe","published_at":"2024-06-01T10:00:00Z","image_url":"https://example.com/img/ai.jpg","title":"AI chips are back","is_premium":false},'
    '{"type":"__text_paragraph__","text":"After months of shortages, chip inventories are finally stabilizing."}]',
    '{"type":"__post_large__","id":"art_tech_001","category":"technology","author":"Jane Doe","published_at":"2024-06-01T10:00:00Z","image_url":"https://example.com/img/ai.jpg","title":"AI chips are back","description":"Chip supply rebounds as demand surges.","is_premium":false,"is_content_overlaid":false,"action":{"type":"__navigate_to_article__","article_id":"art_tech_001"}}'
  ),
  (
    'art_tech_002',
    'Warehouse robots get smarter',
    'https://example.com/articles/robots',
    true,
    2,
    '[{"type":"__article_introduction__","category":"technology","author":"Sam Lee","published_at":"2024-06-02T09:30:00Z","image_url":"https://example.com/img/robot.jpg","title":"Warehouse robots get smarter","is_premium":true},'
    '{"type":"__text_paragraph__","text":"Vision systems now recognize gestures and dynamic obstacles."}]',
    '[{"type":"__article_introduction__","category":"technology","author":"Sam Lee","published_at":"2024-06-02T09:30:00Z","image_url":"https://example.com/img/robot.jpg","title":"Warehouse robots get smarter","is_premium":true}]',
    NULL
  );

INSERT INTO related_articles (article_id, blocks_json, total_count) VALUES
  (
    'art_tech_001',
    '[{"type":"__post_small__","id":"art_tech_002","category":"technology","author":"Sam Lee","published_at":"2024-06-02T09:30:00Z","image_url":"https://example.com/img/robot.jpg","title":"Warehouse robots get smarter","description":"New vision systems improve safety.","is_premium":true,"action":{"type":"__navigate_to_article__","article_id":"art_tech_002"}}]',
    1
  );

INSERT INTO popular_search (id, topics_json, articles_json) VALUES
  (
    'current',
    '["AI","Chips","Robotics"]',
    '[{"type":"__post_small__","id":"art_tech_001","category":"technology","author":"Jane Doe","published_at":"2024-06-01T10:00:00Z","image_url":"https://example.com/img/ai.jpg","title":"AI chips are back","description":"Chip supply rebounds as demand surges.","is_premium":false,"action":{"type":"__navigate_to_article__","article_id":"art_tech_001"}}]'
  );

INSERT INTO relevant_search (term, topics_json, articles_json) VALUES
  (
    'china',
    '["Supply chain","Manufacturing"]',
    '[{"type":"__post_small__","id":"art_tech_001","category":"technology","author":"Jane Doe","published_at":"2024-06-01T10:00:00Z","image_url":"https://example.com/img/ai.jpg","title":"AI chips are back","description":"Chip supply rebounds as demand surges.","is_premium":false,"action":{"type":"__navigate_to_article__","article_id":"art_tech_001"}}]'
  );

INSERT INTO subscriptions (id, name, monthly, annual, benefits_json) VALUES
  (
    'dd339fda-33e9-49d0-9eb5-0ccb77eb760f',
    'premium',
    1499,
    16200,
    '["Ad-free reading","Full article access","Premium newsletters"]'
  ),
  (
    '34809bc1-28e5-4967-b029-2432638b0dc7',
    'basic',
    499,
    5400,
    '["Limited premium articles"]'
  );

INSERT INTO users (id, subscription) VALUES
  ('user_123', 'basic');
