-- Replace TEAM_07_PUDL with your assigned team database before executing.
-- This counts reference codes by fuel unit, not generation or consumption.
SELECT fuel_units, COUNT(*) AS code_count
FROM TEAM_07_PUDL.pudl_eia_energy_sources
GROUP BY fuel_units
ORDER BY code_count DESC;
