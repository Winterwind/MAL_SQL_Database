/*Created by Arian Djahed & Anish Guntreddi*/

.shell echo "Running first query..."
.www

/*Returns the studios with the top 50 highest-rated average scores of all the anime they made
(omitting studios with a negligible amount of anime made)*/
SELECT
  s.StudioName             AS Studio,
  ROUND(AVG(a.Score), 2)   AS MeanAnimeScore,
  COUNT(a.AnimeID)         AS AnimeCount,
  -- highest‑rated anime for each studio
  (
    SELECT a2.Name
    FROM Anime a2
    JOIN Anime_Studio ast2 ON a2.AnimeID = ast2.AnimeID
    WHERE ast2.StudioID = s.StudioID
    ORDER BY a2.Score DESC, a2.AnimeID ASC
    LIMIT 1
  )                         AS HighestRatedAnime,
  -- earliest premiered year (extracting year from TEXT)
  (
    SELECT MIN(CAST(substr(a3.Premiered,-4,4) AS INTEGER))
    FROM Anime a3
    JOIN Anime_Studio ast3 ON a3.AnimeID = ast3.AnimeID
    WHERE ast3.StudioID = s.StudioID
      AND a3.Premiered IS NOT NULL
  )                         AS EarliestPremierYear
FROM Studios s
JOIN Anime_Studio ast   ON s.StudioID    = ast.StudioID
JOIN Anime         a    ON ast.AnimeID   = a.AnimeID
GROUP BY s.StudioID
HAVING COUNT(a.AnimeID) >= 4
ORDER BY MeanAnimeScore DESC
LIMIT 50;

.shell echo "First query complete."
.shell echo "Running second query..."
.www

/*Returns the top 50 producers by popularity & favorites*/
SELECT
  p.ProducerName          AS Producer,
  COUNT(a.AnimeID)        AS AnimeCount,
  ROUND(AVG(a.Popularity),2) AS AvgPopularity,
  SUM(a.Favorites)        AS TotalFavorites
FROM Producers p
JOIN Anime_Producer ap ON p.ProducerID = ap.ProducerID
JOIN Anime          a  ON ap.AnimeID   = a.AnimeID
GROUP BY p.ProducerID
HAVING COUNT(a.AnimeID) >= 10
ORDER BY AvgPopularity DESC
LIMIT 50;

.shell echo "Second query complete."
.shell echo "Running third query..."
.www

/*Returns the longest-running anime per type*/
SELECT DISTINCT
  a1.Type,
  -- name of the single longest show of that type
  (
    SELECT a2.Name
    FROM Anime a2
    WHERE a2.Type = a1.Type
      AND a2.Episodes IS NOT NULL
    ORDER BY a2.Episodes DESC
    LIMIT 1
  )                        AS LongestAnime,
  -- the max episode count
  (
    SELECT MAX(a3.Episodes)
    FROM Anime a3
    WHERE a3.Type = a1.Type
  )                        AS MaxEpisodes,
  -- Aired field for that same longest show
  (
    SELECT a4.Aired
    FROM Anime a4
    WHERE a4.Type = a1.Type
    ORDER BY a4.Episodes DESC
    LIMIT 1
  )                        AS Aired
FROM Anime a1
WHERE a1.Type IS NOT NULL
ORDER BY a1.Type;

.shell echo "Third query complete."
.shell echo "Running fourth query..."
.www

/*Returns the top 35 most popular genres based on total favorites*/
SELECT
  g.GenreName             AS Genre,
  SUM(a.Favorites)        AS total_favorites
FROM Genres g
JOIN Anime_Genre ag    ON g.GenreID = ag.GenreID
JOIN Anime       a     ON ag.AnimeID = a.AnimeID
GROUP BY g.GenreID
ORDER BY total_favorites DESC
LIMIT 35;

.shell echo "Fourth query complete."
.shell echo "Running fifth query..."
.www

/*Returns the anime with the top 50 highest planning-to-completed ratio*/
SELECT
  a.AnimeID,
  a.Name,
  a.Watching             AS PlanToWatch,
  a.Completed,
  ROUND(
    CAST(a.Watching AS REAL)
    / NULLIF(CAST(a.Completed AS REAL),0)
  ,2)                     AS ptw_to_completed_ratio
FROM Anime a
WHERE a.Completed  >  0
  AND a.Watching  IS NOT NULL
ORDER BY ptw_to_completed_ratio DESC
LIMIT 50;

.shell echo "Fifth query complete."
.shell echo "Running sixth query..."
.www

/*Returns the top 50 users who have completed the most anime*/
SELECT
  al.UserID,
  COUNT(*)              AS completed_anime_count
FROM Anime_List al
WHERE al.WatchStatus = 2    -- 2 = “Completed” in Watching_Status
GROUP BY al.UserID
ORDER BY completed_anime_count DESC
LIMIT 50;

.shell echo "Sixth query complete."
.shell echo "Running seventh query..."
.www

/*Returns the top 50 "harshest critics", i.e. the 50 users with the most scores below 4*/
SELECT
  al.UserID,
  SUM(CASE WHEN al.UserScore <= 3 THEN 1 ELSE 0 END) 
                        AS harsh_ratings
FROM Anime_List al
WHERE al.WatchStatus = 2
GROUP BY al.UserID
ORDER BY harsh_ratings DESC
LIMIT 50;

.shell echo "Seventh query complete."
.shell echo "Running eighth query..."
.www

/*Returns the top 50 most "controversial" anime, i.e. the ones with the highest score variance*/
WITH Agg AS (
  SELECT
    al.AnimeID,
    COUNT(*)             AS rating_count,
    AVG(al.UserScore)    AS avg_score,
    SUM(al.UserScore*al.UserScore) AS sum_sq
  FROM Anime_List al INDEXED BY idx_animelist_partial_status2
  WHERE al.WatchStatus = 2
  GROUP BY al.AnimeID
  HAVING rating_count > 100
)
SELECT
  a.AnimeID,
  a.Name,
  Agg.rating_count,
  ROUND(
    SQRT(
      (Agg.sum_sq * 1.0 / Agg.rating_count)
      - (Agg.avg_score * Agg.avg_score)
    )
  ,2)                   AS rating_stddev
FROM Agg
JOIN Anime a USING(AnimeID)
ORDER BY rating_stddev DESC
LIMIT 50;

.shell echo "Eighth query complete."
.shell echo "Running ninth query..."
.www

/*Returns the top 50 'most-watched' anime by users, i.e. the total number of episodes watched for that anime by any user*/
WITH totals AS (
  SELECT
    al.AnimeID,
    SUM(al.WatchedEpisodes) AS total_episodes_viewed
  FROM Anime_List al
  GROUP BY al.AnimeID
)
SELECT
  t.AnimeID,
  a.Name,
  t.total_episodes_viewed
FROM totals t
JOIN Anime a USING(AnimeID)
ORDER BY t.total_episodes_viewed DESC
LIMIT 50;

.shell echo "Ninth query complete."
.shell echo "Running tenth query..."
.www

/*Returns the users with the top 50 highest deviations from the average scores of all the anime they've watched*/
WITH Deviation AS (
  SELECT
    al.UserID,
    ABS(al.UserScore - a.Score) AS ScoreDeviation
  FROM Anime_List al
  JOIN Anime       a USING(AnimeID)
  WHERE al.UserScore > 0
)
SELECT
  d.UserID,
  AVG(d.ScoreDeviation) AS AvgDeviation,
  COUNT(*)              AS RatedCount
FROM Deviation d
GROUP BY d.UserID
HAVING RatedCount >= 20
ORDER BY AvgDeviation DESC
LIMIT 50;

.shell echo "Tenth query complete."
.she. echo "Running eleventh query..."
.www

/*Returns the top 50 anime with the longest synopses along with their synopsis lengths, rating, rankings and popularity*/
SELECT Name,
       LENGTH(Synopsis) AS SynopsisLength,
       Score,
       Ranked,
       Popularity
  FROM Anime
 WHERE Synopsis IS NOT NULL
 ORDER BY SynopsisLength DESC
 LIMIT 50;
.shell echo "Eleventh query complete."

/*END OF FILE*/