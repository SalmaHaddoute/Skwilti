-- Fonction SQL pour incrémenter les points d'un utilisateur
CREATE OR REPLACE FUNCTION increment_points(user_id UUID, points_to_add INT)
RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET points = COALESCE(points, 0) + points_to_add
  WHERE id = user_id;
  
  -- Insérer dans l'historique des points
  INSERT INTO points_history (user_id, points_earned, created_at)
  VALUES (user_id, points_to_add, NOW());
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour les points automatiquement après une session de quiz
CREATE OR REPLACE FUNCTION update_points_after_quiz()
RETURNS trigger AS $$
BEGIN
  -- Ajouter les points seulement si la réponse est correcte
  IF NEW.is_correct = true THEN
    PERFORM increment_points(NEW.user_id, NEW.points_earned);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger
DROP TRIGGER IF EXISTS on_quiz_session_complete ON quiz_sessions;
CREATE TRIGGER on_quiz_session_complete
  AFTER INSERT ON quiz_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_points_after_quiz();
