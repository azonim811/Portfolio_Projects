DROP TABLE IF EXISTS nashville_housing;
CREATE TABLE nashville_housing (
	UniqueID INT,
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
	HalfBath FLOAT
);

LOAD DATA INFILE 'C:/ProgramData/MYSQL/MYSQL Server 8.0/Uploads/cleaned_nashville.csv'
INTO TABLE nashville_housing
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT *
FROM nashville_housing;

/*
Cleaning Data
*/

# Standardize date format
ALTER TABLE nashville_housing
ADD DateSale DATE;	-- adding a new column for the modified column's data type 

UPDATE nashville_housing
SET DateSale = STR_TO_DATE(SaleDate, '%M %d, %Y');

ALTER TABLE nashville_housing
DROP COLUMN SaleDate;	-- dropping the old column format

# Populate 'PropertyAddress'
SELECT *
FROM nashville_housing
WHERE PropertyAddress IS NULL;	-- there is NULL values on the property adress which should not because it is an address of the property; ParcelID is the same as the PropertyAddress
	
    --	we will use the ParcelID to populate the NULL values of the PropertyAddress
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

# Breaking out addresses into individual columns (Address, City, and State)
-- for the PropertyAddress
SELECT 	SUBSTR(PropertyAddress, 1, POSITION(',' IN PropertyAddress) - 1) AS Address,
		SUBSTR(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, LENGTH(PropertyAddress)) AS City
FROM nashville_housing;	-- so far the Address and the City are now separated

	-- we need to create two columns for the newly separated PropertyAddress 
	ALTER TABLE nashville_housing
	ADD Property_Address VARCHAR(255);	

	UPDATE nashville_housing
	SET Property_Address = SUBSTR(PropertyAddress, 1, POSITION(',' IN PropertyAddress) - 1);
    
	ALTER TABLE nashville_housing
	ADD Property_City VARCHAR(255);	

	UPDATE nashville_housing
	SET Property_City = SUBSTR(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, LENGTH(PropertyAddress));
 
-- for the OwnerAddress
SELECT 	SUBSTR(OwnerAddress, 1, POSITION(',' IN OwnerAddress) - 1) AS Address,
		SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS CityTown,
		SUBSTRING_INDEX(OwnerAddress, ' ', -1) AS State
FROM nashville_housing;	

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




ALTER TABLE nashville_housing
DROP COLUMN SaleDate;	-- dropping the old column format

# Change Y and N to (Yes and No) in column 'SoldAsVacant'
# Remove duplicates
# Delete unused columns


SELECT OwnerAddress
FROM nashville_housing;



