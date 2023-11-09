/*
Cleaning Data of a Housing Dataset
Skills used: Converting Data Types, JOIN, COALESCE, SUBSTRING, CASE Statement, CTE, Temporary Tables, Window Functions
*/

USE projects;

# Preparing table for the datasets 
DROP TABLE IF EXISTS nashville_housing;
CREATE TABLE nashville_housing 
	(	UniqueID INT,
		ParcelID VARCHAR(255),
		LandUse VARCHAR(255),
		PropertyAddress VARCHAR(255),
		SaleDate VARCHAR(255),
		SalePrice VARCHAR(255),
		LegalReference VARCHAR(255),
		SoldAsVacant VARCHAR(255),
		OwnerName VARCHAR(255),
		OwnerAddress VARCHAR(255),
		Acreage FLOAT,
		TaxDistrict VARCHAR(255),
		LandValue FLOAT,
		BuildingValue FLOAT,
		TotalValue FLOAT,
		YearBuilt FLOAT,
		Bedrooms FLOAT,
		FullBath FLOAT,
		HalfBath FLOAT	);

-- importing the datasets
LOAD DATA INFILE 'C:/ProgramData/MYSQL/MYSQL Server 8.0/Uploads/cleaned_nashville.csv'
INTO TABLE nashville_housing
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- checking the imported datasets
SELECT *
FROM nashville_housing;


# Standardize date format
ALTER TABLE nashville_housing
ADD DateSale DATE;	-- adding a new column for the modified column's data type 

UPDATE nashville_housing
SET DateSale = STR_TO_DATE(SaleDate, '%M %d, %Y');	-- update the new column with the new data type

ALTER TABLE nashville_housing
DROP COLUMN SaleDate;	-- drop the old column format


# Populate 'PropertyAddress'
SELECT *
FROM nashville_housing
WHERE PropertyAddress IS NULL;	-- to see if there are NULL values on the property adress which should not be because it is an address of the property
	
--	we will use the 'ParcelID' to populate the NULL values of the 'PropertyAddress'
SELECT x.ParcelID, x.PropertyAddress, y.ParcelID, y.PropertyAddress,
	COALESCE(x.PropertyAddress, y.PropertyAddress) 
FROM nashville_housing x
JOIN nashville_housing y
	ON x.ParcelID = y.ParcelID AND x.UniqueID <> y.UniqueID
WHERE x.PropertyAddress IS NULL;
    
-- update the table after the COALESCE     
UPDATE nashville_housing x
JOIN nashville_housing y
	ON x.ParcelID = y.ParcelID AND x.UniqueID <> y.UniqueID
SET x.PropertyAddress = COALESCE(x.PropertyAddress, y.PropertyAddress)
WHERE x.PropertyAddress IS NULL;  


# Breaking out 'PropertyAddress' into individual columns (Address and City)
SELECT 	SUBSTR(PropertyAddress, 1, POSITION(',' IN PropertyAddress) - 1) AS Address,
		SUBSTR(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, LENGTH(PropertyAddress)) AS City
FROM nashville_housing;	-- so far the Address and the City are now separated

-- we need to create two columns for the newly separated 'PropertyAddress' 
ALTER TABLE nashville_housing
ADD Property_Address VARCHAR(255);	

UPDATE nashville_housing
SET Property_Address = SUBSTR(PropertyAddress, 1, POSITION(',' IN PropertyAddress) - 1);
    
ALTER TABLE nashville_housing
ADD Property_City VARCHAR(255);	

UPDATE nashville_housing
SET Property_City = SUBSTR(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, LENGTH(PropertyAddress));
 
 
# Breaking out 'OwnerAddress' into individual columns (Address, City, and State)
SELECT 	SUBSTR(OwnerAddress, 1, POSITION(',' IN OwnerAddress) - 1) AS Address,
		SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City,
		SUBSTRING_INDEX(OwnerAddress, ' ', -1) AS State
FROM nashville_housing;	-- so far the Address, City, and State are now separated

-- again we need to create the columns 
ALTER TABLE nashville_housing
ADD Owner_Address VARCHAR(255);	

UPDATE nashville_housing
SET Owner_Address = SUBSTR(OwnerAddress, 1, POSITION(',' IN OwnerAddress) - 1);
    
ALTER TABLE nashville_housing
ADD Owner_City VARCHAR(255);	

UPDATE nashville_housing
SET Owner_City = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE nashville_housing
ADD Owner_State VARCHAR(255);	

UPDATE nashville_housing
SET Owner_State = SUBSTRING_INDEX(OwnerAddress, ' ', -1);


# Change Y and N to (Yes and No) in column 'SoldAsVacant'
SELECT SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'YES'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
	END  
FROM nashville_housing;

-- now update the column
UPDATE nashville_housing
SET SoldAsVacant = 	CASE
						WHEN SoldAsVacant = 'Y' THEN 'YES'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
					END;


# Remove duplicates
WITH rownumCTE AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY	ParcelID, 
										PropertyAddress,
										SaleDate,
										SalePrice,
										LegalReference ORDER BY UniqueID) AS row_num
	FROM nashville_housing	)
SELECT *					
FROM rownumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- after seeing the results of all duplicates, DELETE the duplicate values
WITH rownumCTE AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY 	ParcelID, 
										PropertyAddress,
										SaleDate,
										SalePrice,
										LegalReference ORDER BY UniqueID) AS row_num
	FROM nashville_housing	)
DELETE 
FROM nashville_housing
WHERE UniqueID IN (	SELECT UniqueID
					FROM rownumCTE
					WHERE row_num > 1	);


# Delete unwanted and unused columns
ALTER TABLE nashville_housing
DROP COLUMN PropertyAddress;	

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress;

ALTER TABLE nashville_housing
DROP COLUMN Taxdistrict;


# Check the cleaner table
SELECT *
FROM nashville_housing;



