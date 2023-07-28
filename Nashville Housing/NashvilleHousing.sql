/* -----------------------------------------------------------------------
Clean and Transform Nashville Housing Data for Analysis
------------------------------------------------------------------------*/

-- Inspect data 
SELECT *
FROM PortfolioProject..NashvilleHousing

/* -----------------------------------------------------------------------
Standardize Date Format
- Sale date is stored as varchar, convert to consistent date format
- Add new column for standardized date  
------------------------------------------------------------------------*/

SELECT SaleDate, CONVERT(date, SaleDate) 
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)  

ALTER TABLE PortfolioProject..NashvilleHousing   
ADD SaleDateConverted Date

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate) 

-- Verify update
SELECT SaleDateConverted, CONVERT(date, SaleDate)
FROM PortfolioProject..NashvilleHousing


/* ----------------------------------------------------------------------- 
Populate Missing Property Address Data
- Join table to find matching ParcelIDs with address info
- Update joined columns where address is missing
------------------------------------------------------------------------*/

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,  
       ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
     ON a.ParcelID = b.ParcelID
	 AND a.[UniqueID] <> b.[UniqueID] 
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
     ON a.ParcelID = b.ParcelID
	 AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL


/* -----------------------------------------------------------------------
Split Address into Individual Columns 
- Parse address into separate columns for analysis
------------------------------------------------------------------------*/

SELECT PropertyAddress  
FROM PortfolioProject..NashvilleHousing

SELECT
 SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address, 
 SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing  

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) 

SELECT *
FROM PortfolioProject..NashvilleHousing

/* -----------------------------------------------------------------------
Split Owner Address into Columns  
- Parse owner address into separate columns
------------------------------------------------------------------------*/

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
       PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),  
       PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM PortfolioProject..NashvilleHousing  

ALTER TABLE PortfolioProject..NashvilleHousing 
ADD OwnerSplitAddress Nvarchar(255)  

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) 

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing 
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

/* -----------------------------------------------------------------------
Update Sold As Vacant Field  
- Change Y/N to clearer labels
------------------------------------------------------------------------*/

SELECT DISTINCT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing  

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'  
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

/* -----------------------------------------------------------------------
Remove Duplicates
- Use ROW_NUMBER() to identify duplicates
- Delete duplicates
------------------------------------------------------------------------*/

WITH RowNumCTE AS(
SELECT *,  
    ROW_NUMBER() OVER (PARTITION BY ParcelID,
									 PropertyAddress,
									 SalePrice,
									 SaleDate,
									 LegalReference 
							 ORDER BY UniqueID) row_num
FROM PortfolioProject..NashvilleHousing
) 
DELETE
FROM RowNumCTE 
WHERE row_num > 1

/* -----------------------------------------------------------------------
Remove Unused Columns
------------------------------------------------------------------------*/

ALTER TABLE PortfolioProject..NashvilleHousing  
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate