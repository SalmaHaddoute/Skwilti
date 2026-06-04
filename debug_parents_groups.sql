-- ══════════════════════════════════════════════════════════════
-- DEBUG SCRIPT - Groupes de Parents
-- ══════════════════════════════════════════════════════════════
-- Exécutez ces requêtes une par une pour diagnostiquer le problème
-- ══════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 1: Vérifier l'utilisateur connecté
-- ══════════════════════════════════════════════════════════════
SELECT 
  auth.uid() as current_user_id,
  auth.email() as current_user_email;

-- Résultat attendu: Votre ID utilisateur et email
-- Si NULL, vous n'êtes pas connecté

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 2: Vérifier le profil de l'enseignant
-- ══════════════════════════════════════════════════════════════
SELECT 
  id,
  first_name,
  last_name,
  role,
  email
FROM profiles 
WHERE id = auth.uid();

-- Résultat attendu: Votre profil avec role = 'teacher'

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 3: Vérifier les classes de l'enseignant
-- ══════════════════════════════════════════════════════════════
SELECT 
  cp.classe_id,
  cp.professeur_id,
  c.nom as classe_name
FROM classe_professeurs cp
LEFT JOIN classes c ON c.id = cp.classe_id
WHERE cp.professeur_id = auth.uid();

-- Résultat attendu: Liste des classes assignées à l'enseignant
-- Si vide, l'enseignant n'a pas de classes assignées

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 4: Vérifier les élèves dans ces classes
-- ══════════════════════════════════════════════════════════════
SELECT 
  p.id,
  p.first_name,
  p.last_name,
  p.classe_id,
  p.role
FROM profiles p
WHERE p.role = 'student'
  AND p.classe_id IN (
    SELECT classe_id 
    FROM classe_professeurs 
    WHERE professeur_id = auth.uid()
  );

-- Résultat attendu: Liste des élèves dans vos classes
-- Si vide, pas d'élèves dans vos classes

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 5: Vérifier les relations parent-enfant
-- ══════════════════════════════════════════════════════════════
SELECT 
  pe.parent_id,
  pe.enfant_id,
  p_parent.first_name as parent_first_name,
  p_parent.last_name as parent_last_name,
  p_enfant.first_name as enfant_first_name,
  p_enfant.last_name as enfant_last_name
FROM parent_enfants pe
LEFT JOIN profiles p_parent ON p_parent.id = pe.parent_id
LEFT JOIN profiles p_enfant ON p_enfant.id = pe.enfant_id
WHERE pe.enfant_id IN (
  SELECT p.id
  FROM profiles p
  WHERE p.role = 'student'
    AND p.classe_id IN (
      SELECT classe_id 
      FROM classe_professeurs 
      WHERE professeur_id = auth.uid()
    )
);

-- Résultat attendu: Relations parent-enfant pour vos élèves
-- Si vide, pas de parents liés aux élèves

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 6: Vérifier tous les parents dans la base
-- ══════════════════════════════════════════════════════════════
SELECT 
  id,
  first_name,
  last_name,
  email,
  role,
  created_at
FROM profiles 
WHERE role = 'parent'
ORDER BY created_at DESC;

-- Résultat attendu: Tous les parents dans la base
-- Vérifiez qu'il y a bien des parents

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 7: Vérifier les politiques RLS sur profiles
-- ══════════════════════════════════════════════════════════════
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Résultat attendu: Politiques RLS sur la table profiles
-- Vérifiez qu'il y a une politique SELECT

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 8: Test direct de la requête Flutter
-- ══════════════════════════════════════════════════════════════

-- 8a. Récupérer les classes de l'enseignant (comme dans Flutter)
SELECT classe_id 
FROM classe_professeurs 
WHERE professeur_id = auth.uid();

-- 8b. Récupérer les élèves (remplacez <CLASSE_IDS> par les IDs de l'étape 8a)
/*
SELECT id, first_name, last_name, avatar_url, classe_id
FROM profiles
WHERE role = 'student'
  AND classe_id IN (<CLASSE_IDS>);
*/

-- 8c. Récupérer les parents d'un élève (remplacez <STUDENT_ID>)
/*
SELECT parent_id 
FROM parent_enfants 
WHERE enfant_id = '<STUDENT_ID>';
*/

-- 8d. Récupérer le profil des parents (remplacez <PARENT_IDS>)
/*
SELECT id, first_name, last_name, avatar_url
FROM profiles
WHERE id IN (<PARENT_IDS>);
*/

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 9: Solutions possibles
-- ══════════════════════════════════════════════════════════════

-- Si ÉTAPE 3 est vide: Assigner l'enseignant à une classe
/*
INSERT INTO classe_professeurs (classe_id, professeur_id)
VALUES ('<CLASSE_ID>', auth.uid());
*/

-- Si ÉTAPE 4 est vide: Créer des élèves ou les assigner à une classe
/*
UPDATE profiles 
SET classe_id = '<CLASSE_ID>'
WHERE role = 'student' AND id = '<STUDENT_ID>';
*/

-- Si ÉTAPE 5 est vide: Créer des relations parent-enfant
/*
INSERT INTO parent_enfants (parent_id, enfant_id)
VALUES ('<PARENT_ID>', '<STUDENT_ID>');
*/

-- Si ÉTAPE 6 est vide: Créer un parent de test
/*
INSERT INTO profiles (first_name, last_name, email, role)
VALUES ('Test', 'Parent', 'parent@test.com', 'parent');
*/

-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 10: Requête complète pour déboguer
-- ══════════════════════════════════════════════════════════════
SELECT 
  'Enseignant' as type,
  auth.uid() as id,
  p.first_name,
  p.last_name
FROM profiles p
WHERE p.id = auth.uid()

UNION ALL

SELECT 
  'Classe' as type,
  cp.classe_id::text as id,
  c.nom as first_name,
  '' as last_name
FROM classe_professeurs cp
LEFT JOIN classes c ON c.id = cp.classe_id
WHERE cp.professeur_id = auth.uid()

UNION ALL

SELECT 
  'Élève' as type,
  p.id as id,
  p.first_name,
  p.last_name
FROM profiles p
WHERE p.role = 'student'
  AND p.classe_id IN (
    SELECT classe_id 
    FROM classe_professeurs 
    WHERE professeur_id = auth.uid()
  )

UNION ALL

SELECT 
  'Parent' as type,
  p_parent.id as id,
  p_parent.first_name,
  p_parent.last_name
FROM parent_enfants pe
JOIN profiles p_parent ON p_parent.id = pe.parent_id
WHERE pe.enfant_id IN (
  SELECT p.id
  FROM profiles p
  WHERE p.role = 'student'
    AND p.classe_id IN (
      SELECT classe_id 
      FROM classe_professeurs 
      WHERE professeur_id = auth.uid()
    )
);

-- ══════════════════════════════════════════════════════════════
-- FIN DU SCRIPT DE DEBUG
-- ══════════════════════════════════════════════════════════════