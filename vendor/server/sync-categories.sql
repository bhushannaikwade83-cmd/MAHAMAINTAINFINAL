-- Sync service categories from MahaMaintain Pro app
-- Ensures all 23 service categories are in the database with is_active = 1

INSERT IGNORE INTO service_categories (name, is_active, created_at) VALUES
('Insta Help', 1, NOW()),
('Women\'s Salon & Spa', 1, NOW()),
('Men\'s Salon & Massage', 1, NOW()),
('Cleaning', 1, NOW()),
('Home Painting', 1, NOW()),
('AC & Appliance Repair', 1, NOW()),
('Electrician, Plumber & Carpenter', 1, NOW()),
('Vehicle Care', 1, NOW()),
('Food & Catering', 1, NOW()),
('Health & Care', 1, NOW()),
('Pooja Services', 1, NOW()),
('Festival Services', 1, NOW()),
('Pest Control', 1, NOW()),
('Smart Society Management', 1, NOW()),
('Real Estate', 1, NOW()),
('Interior Designer', 1, NOW()),
('Hologram Services', 1, NOW()),
('Fire Safety', 1, NOW()),
('Water Proofing', 1, NOW()),
('Water Testing', 1, NOW()),
('Blood Testing', 1, NOW()),
('Weekly Bazar', 1, NOW()),
('Tours & Travels', 1, NOW());

-- Update any existing categories to be active
UPDATE service_categories SET is_active = 1 WHERE name IN (
  'Insta Help', 'Women\'s Salon & Spa', 'Men\'s Salon & Massage', 'Cleaning', 'Home Painting',
  'AC & Appliance Repair', 'Electrician, Plumber & Carpenter', 'Vehicle Care', 'Food & Catering',
  'Health & Care', 'Pooja Services', 'Festival Services', 'Pest Control', 'Smart Society Management',
  'Real Estate', 'Interior Designer', 'Hologram Services', 'Fire Safety', 'Water Proofing',
  'Water Testing', 'Blood Testing', 'Weekly Bazar', 'Tours & Travels'
);
