-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
Select npi
	, SUM(total_claim_count) as total_claims
	from prescription
	group by npi
	order by total_claims desc;


-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT nppes_provider_first_name 
	, nppes_provider_last_org_name
	, specialty_description
	, SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING(npi)
	GROUP BY nppes_provider_first_name 
	, nppes_provider_last_org_name
	, specialty_description
	ORDER BY total_claims DESC;

-- "BRUCE"	"PENDLEY"	"Family Practice"	99707


-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description
	, SUM(total_claim_count) AS total_claims
	from prescription
	INNER JOIN prescriber
	USING(npi)
	GROUP BY specialty_description
	ORDER BY total_claims DESC;
-- "Family Practice"	9752347

-- 2b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description
	, SUM(total_claim_count) AS total_claims
	from prescription
	INNER JOIN prescriber
	USING(npi)
	INNER JOIN drug 
	on prescription.drug_name = drug.drug_name
	WHERE opioid_drug_flag = 'Y'
	GROUP BY specialty_description
	ORDER BY total_claims DESC;
-- "Nurse Practitioner"	900845

-- 2c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description
	, SUM(total_claim_count) AS total_claims
	from prescriber
	LEFT JOIN prescription
	USING(npi)
	GROUP BY specialty_description
	HAVING SUM(total_claim_count) IS NULL;
	-- 15

--Kaden:
SELECT 
    specialty_description,
    total_claim_count
FROM prescriber AS p
LEFT JOIN prescription AS r
ON p.npi = r.npi
WHERE total_claim_count IS NULL;

--Avery
SELECT specialty_description, COUNT(prescription.*) AS total_prescriptions
FROM prescriber
FULL JOIN prescription
USING (npi)
GROUP BY specialty_description
HAVING COUNT(prescription.*) = 0;


--Deva
SELECT DISTINCT specialty_description
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE prescription.npi IS NULL;


-- 2d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT specialty_description
	, ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN prescription.total_claim_count END) /
	 SUM(total_claim_count), 3) * 100 AS opioid_percent
	from prescription
	INNER JOIN prescriber
	USING(npi)
	INNER JOIN drug 
	on prescription.drug_name = drug.drug_name
	GROUP BY specialty_description
	ORDER BY opioid_percent DESC NULLS LAST;
-- "Case Manager/Care Coordinator"	72.000



-- 3a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name
 , SUM(total_drug_cost) as drug_money
FROM drug as d
INNER JOIN prescription as rx
ON d.drug_name = rx.drug_name
-- USING(drug_name)
GROUP BY generic_name
ORDER BY drug_money DESC;

-- 3b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT generic_name
 , ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2)::MONEY as drug_cost_per_day
FROM drug as d
INNER JOIN prescription as rx
ON d.drug_name = rx.drug_name
-- USING(drug_name)
GROUP BY generic_name
ORDER BY drug_cost_per_day DESC;
-- "C1 ESTERASE INHIBITOR"	"$3,495.22"

-- Kellen
SELECT 
	generic_name, 
	ROUND(script.total_drug_cost / script.total_day_supply, 2)::MONEY AS cost_per_day
FROM drug
INNER JOIN prescription AS script
USING(drug_name)
ORDER BY cost_per_day DESC;
-- Singular prescription - highest cost per day without taking all numbers into account



-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT drug_name
 , CASE 
 	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	 ELSE 'neither'
	 END as drug_type
	from drug; 
	
-- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT drug_name
	, SUM(total_drug_cost) as total_cost
 , SUM(CASE WHEN opioid_drug_flag = 'Y' THEN prescription.total_claim_count
	 WHEN antibiotic_drug_flag = 'Y' THEN prescription.total_claim_count
	 END) as cost_per_type
	from drug
	INNER JOIN prescription
	USING(drug_name)
	GROUP BY drug_name, opioid_drug_flag, antibiotic_drug_flag
	ORDER BY total_cost DESC; 

-- Kaden
SELECT 
    CASE
    WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
    WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
    END AS drug_type,
SUM(p.total_drug_cost)::MONEY AS total_spent
FROM drug AS d
JOIN prescription AS p
ON d.drug_name = p.drug_name
WHERE d.opioid_drug_flag = 'Y'
OR d.antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY total_spent DESC;

--Justin
select
    case
        when d.opioid_drug_flag = 'Y' THEN 'opioid'
        when d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
    END AS drug_type,
    sum(p.total_drug_cost)::money AS total_spent
FROM drug d
JOIN prescription as p
ON p.drug_name = d.drug_name
WHERE d.opioid_drug_flag = 'Y' OR d.antibiotic_drug_flag = 'Y'
GROUP BY drug_type;

-- Deva
SELECT SUM(total_drug_cost)::MONEY AS total_cost,
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
	END AS drug_type
FROM drug	
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug_type
ORDER BY drug_type DESC;


--Kellen
SELECT
	SUM(CASE WHEN opioid_drug_flag = 'Y' THEN script.total_drug_cost END)::MONEY AS total_opioid_cost,
	SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN script.total_drug_cost END)::MONEY AS total_antibiotic_cost
FROM drug
INNER JOIN prescription AS script
USING(drug_name)

--Michelle 
SELECT 
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type,
	SUM(total_drug_cost)::MONEY AS total_spent
FROM prescription
JOIN drug
		ON prescription.drug_name = drug.drug_name
WHERE total_drug_cost IS NOT NULL 
	-- AND total_drug_cost_ge65 IS NOT NULL
	GROUP BY drug_type
	ORDER BY total_spent;
	
-- 5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
Select COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN';

-- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname 
	, SUM(population) as total_population
	FROM cbsa
	INNER JOIN population
	USING(fipscounty)
	GROUP BY cbsaname
	ORDER BY total_population DESC;
-- Biggest: "Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410
-- Smallest: "Morristown, TN"	116352

-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county
, population
	from fips_county
	INNER JOIN population
	USING(fipscounty)
	WHERE fipscounty NOT IN(SELECT fipscounty FROM cbsa)
	ORDER BY population DESC
-- "SEVIER"	95523


-- Noah
(select	
	county,
	population
from population
inner join fips_county
using(fipscounty))
except
(select	
	county,
	population
from cbsa
inner join fips_county
using(fipscounty)
inner join population
using(fipscounty))
order by population desc
LIMIT 1;



-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
Select drug_name
	, total_claim_count
	from prescription
	WHERE total_claim_count >= 3000;

-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
Select drug_name
	, total_claim_count
	, opioid_drug_flag
	from prescription
	INNER JOIN drug 
	USING(drug_name)
	WHERE total_claim_count >= 3000;
	
-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
Select drug_name
	, total_claim_count
	, opioid_drug_flag
	, nppes_provider_last_org_name
	, nppes_provider_first_name
	from prescription
	INNER JOIN drug 
	USING(drug_name)
	INNER JOIN prescriber
	USING(npi)
	WHERE total_claim_count >= 3000;


-- The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- 7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT *
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

-- 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi
	, drug_name
	, total_claim_count
	FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription
	USING(npi, drug_name)
	WHERE specialty_description = 'Pain Management'
		AND nppes_provider_city = 'NASHVILLE'
		AND opioid_drug_flag = 'Y';

-- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT npi
	, drug_name
	, COALESCE(total_claim_count, 0) as total_claims
	FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription
	USING(npi, drug_name)
	WHERE specialty_description = 'Pain Management'
		AND nppes_provider_city = 'NASHVILLE'
		AND opioid_drug_flag = 'Y'
	ORDER BY total_claims DESC;
