# prep_data.R
# 
# This script processes the NCVS Concatenated Incident File (1992-2024)
# from ICPSR 39273-V1 and exports it to a tidy, compressed Parquet file
# for use in the DuckDB WASM / D3.js web dashboard.
#
# Requirements:
#   install.packages("arrow")
#   install.packages("prettyR") # optional, for value labels if needed

if (!requireNamespace("arrow", quietly = TRUE)) {
  stop("The 'arrow' package is required to write Parquet files. Please install it with install.packages('arrow')")
}

# 1. Load the raw ICPSR data
data_path <- "./data/ICPSR_39273-V1/ICPSR_39273/DS0003/39273-0003-Data.rda"
if (!file.exists(data_path)) {
  stop(paste("Could not find the NCVS RDA data file at:", data_path, "\nPlease make sure the file is downloaded and in the correct path."))
}

message("Loading raw NCVS dataset (this may take a minute)...")
load(data_path)
# Get the loaded object dynamically (since load() puts it in the environment)
df_name <- ls()[ls() != "data_path"]
if (length(df_name) == 0) {
  stop("No object was loaded from the RDA file.")
}
ncvs <- get(df_name[1])
message(paste("Successfully loaded dataframe:", df_name[1], "with", nrow(ncvs), "rows."))

# Helper function to extract numeric codes from ICPSR factors/characters
# Example: "(01) YES" -> 1, "(12) Simple assault" -> 12, etc.
get_numeric_code <- function(x) {
  if (is.factor(x) || is.character(x)) {
    char_vals <- as.character(x)
    # Extract digits inside the leading parentheses
    parsed <- sub("^\\(0*([0-9]+)\\).+$", "\\1", char_vals)
    # Fallback to direct numeric coercion if no parentheses matched
    suppressWarnings(numeric_vals <- as.numeric(parsed))
    # If parsing failed, try direct numeric conversion on character
    failed_idx <- is.na(numeric_vals) & !is.na(char_vals)
    if (any(failed_idx)) {
      suppressWarnings(numeric_vals[failed_idx] <- as.numeric(char_vals[failed_idx]))
    }
    return(numeric_vals)
  } else {
    return(as.numeric(x))
  }
}

# Helper function to clean text labels
# Example: "(11) Simple assault" -> "Simple assault"
clean_labels <- function(x) {
  if (is.factor(x) || is.character(x)) {
    return(trimws(sub("^\\([0-9]+\\) +", "", as.character(x))))
  } else {
    return(as.character(x))
  }
}

message("Processing variables...")

# 2. Extract and Recode Variables

# A. Crime Reporting (V4399)
# Standard codes: 1 = Yes (reported), 2 = No (not reported)
# Others (e.g. 3 = Don't know, 8 = Residue, NA) are treated as missing
nV4399 <- get_numeric_code(ncvs$V4399)
reported <- ifelse(nV4399 == 1, 1L, ifelse(nV4399 == 2, 0L, NA_integer_))

# B. Year
year <- as.integer(ncvs$YEAR)

# C. Crime Type (V4529) and Crime Category
crime_type <- clean_labels(ncvs$V4529)
# Broad categories based on typical NCVS groupings
crime_category <- rep("Other", length(crime_type))

# include Theft [include purse snatching, pocket picking]
# Burglary
#MV Theft
crime_category[grepl("completed theft|attempted theft|purse|pocket", crime_type, ignore.case = TRUE)] <- "Theft"
crime_category[grepl("burglary|entry", crime_type, ignore.case = TRUE)] <- "Burglary"
crime_category[grepl("motor vehicle", crime_type, ignore.case = TRUE)] <- "Motor Vehicle Theft"
crime_category[grepl("rape|sexual assault|sexual attack|sexual contact", crime_type, ignore.case = TRUE)] <- "Rape/Sexual Assault"
crime_category[grepl("robbery", crime_type, ignore.case = TRUE)] <- "Robbery"
crime_category[grepl("aggravated assault", crime_type, ignore.case = TRUE)] <- "Aggravated Assault"
crime_category[grepl("simple assault|assault without weapon|threatened assault|verbal threat", crime_type, ignore.case = TRUE)] <- "Simple Assault"

# Lets add in flags for Weapon, Verbal, Attempted, Injury
weapon <- rep("No Weapon", length(crime_type))
weapon[grepl("with weapon", crime_type, ignore.case = TRUE)] <- "Weapon"

attempted <- rep("Completed", length(crime_type))
attempted[grepl("Attempted", crime_type, ignore.case = TRUE)] <- "Attempted"
attempted[grepl("Verbal", crime_type, ignore.case = TRUE)] <- "Verbal"

injury <- rep("Other", length(crime_type))
injury[grepl("With Injury", crime_type, ignore.case = TRUE)] <- "With Injury"
injury[grepl("Without Injury", crime_type, ignore.case = TRUE)] <- "Without Injury"

# D. Victim-Offender Relationship, Domestic Violence Flag, & Generic Relationship Category
# Derived from nV4245 (single offender relationship), nV4265, nV4266, nV4271 (multiple offenders relationship)
# and nV4241 (single offender stranger), nV4262 (multiple offenders stranger)
nV4245 <- get_numeric_code(ncvs$V4245)
nV4265 <- get_numeric_code(ncvs$V4265)
nV4266 <- get_numeric_code(ncvs$V4266)
nV4271 <- get_numeric_code(ncvs$V4271)
nV4241 <- get_numeric_code(ncvs$V4241)
nV4262 <- get_numeric_code(ncvs$V4262)

lbl_4245 <- tolower(clean_labels(ncvs$V4245))
lbl_4241 <- tolower(clean_labels(ncvs$V4241))
lbl_4262 <- tolower(clean_labels(ncvs$V4262))
lbl_4265 <- tolower(clean_labels(ncvs$V4265))
lbl_4266 <- tolower(clean_labels(ncvs$V4266))
lbl_4271 <- tolower(clean_labels(ncvs$V4271))

# Domestic violence flag logic from pred_model.R (spouses, ex-spouses, boyfriends/girlfriends)
one_off <- (nV4245 == 1) | (nV4245 == 2) | (nV4245 == 7)
mult_off <- (nV4265 == 1) | (nV4266 == 1) | (nV4271 == 1)

one_off[is.na(one_off)] <- FALSE
mult_off[is.na(mult_off)] <- FALSE

domestic_violence <- as.integer(one_off | mult_off)

# Generic Victim-Offender Relationship Category: Intimate Partner, Other Relative, Acquaintance, Stranger, Unknown
victim_offender_relationship <- rep("Unknown", nrow(ncvs))

# Single Offender cases
single_intimate <- (nV4245 %in% c(1, 2, 7)) | grepl("spouse|husband|wife|boyfriend|girlfriend", lbl_4245)
single_relative <- !single_intimate & ((nV4245 %in% c(3, 4, 5, 6)) | grepl("parent|child|sibling|brother|sister|relative|grand", lbl_4245))
single_acquaintance <- !single_intimate & !single_relative & ((nV4245 %in% c(8, 9, 10, 11, 12, 13, 14)) | grepl("friend|neighbor|acquaintance|schoolmate|roommate|co-worker|work|school|known", lbl_4245))
single_stranger <- !single_intimate & !single_relative & !single_acquaintance & (nV4241 == 1 | grepl("stranger", lbl_4241) | grepl("stranger", lbl_4245))

# Multiple Offenders cases
multiple_stranger <- (nV4262 == 1) | grepl("all strangers|yes", lbl_4262)
multiple_intimate <- !multiple_stranger & (
  (nV4265 %in% c(1, 2, 7) | nV4266 %in% c(1, 2, 7) | nV4271 %in% c(1, 2, 7)) | 
  (grepl("spouse|husband|wife|boyfriend|girlfriend", lbl_4265) | grepl("spouse|husband|wife|boyfriend|girlfriend", lbl_4266) | grepl("spouse|husband|wife|boyfriend|girlfriend", lbl_4271))
)
multiple_relative <- !multiple_stranger & !multiple_intimate & (
  (nV4265 %in% c(3, 4, 5, 6) | nV4266 %in% c(3, 4, 5, 6) | nV4271 %in% c(3, 4, 5, 6)) | 
  (grepl("parent|child|sibling|brother|sister|relative|grand", lbl_4265) | grepl("parent|child|sibling|brother|sister|relative|grand", lbl_4266) | grepl("parent|child|sibling|brother|sister|relative|grand", lbl_4271))
)
multiple_acquaintance <- !multiple_stranger & !multiple_intimate & !multiple_relative & (
  (nV4265 %in% c(8, 9, 10, 11, 12, 13, 14) | nV4266 %in% c(8, 9, 10, 11, 12, 13, 14) | nV4271 %in% c(8, 9, 10, 11, 12, 13, 14)) | 
  (grepl("friend|neighbor|acquaintance|schoolmate|roommate|co-worker|work|school|known", lbl_4265) | grepl("friend|neighbor|acquaintance|schoolmate|roommate|co-worker|work|school|known", lbl_4266) | grepl("friend|neighbor|acquaintance|schoolmate|roommate|co-worker|work|school|known", lbl_4271))
)

victim_offender_relationship[single_intimate | multiple_intimate] <- "Intimate Partner"
victim_offender_relationship[single_relative | multiple_relative] <- "Other Relative"
victim_offender_relationship[single_acquaintance | multiple_acquaintance] <- "Acquaintance"
victim_offender_relationship[single_stranger | multiple_stranger] <- "Stranger"

# Text-matching fallbacks for any remaining unresolved rows
unresolved <- (victim_offender_relationship == "Unknown")
victim_offender_relationship[unresolved & (grepl("stranger", lbl_4245) | grepl("stranger", lbl_4241) | grepl("all strangers", lbl_4262))] <- "Stranger"
victim_offender_relationship[unresolved & (grepl("friend|acquaint", lbl_4245) | grepl("friend|acquaint", lbl_4265) | grepl("friend|acquaint", lbl_4266) | grepl("friend|acquaint", lbl_4271))] <- "Acquaintance"

# E. Victim Gender (V3018)
# Codes: 1 = Male, 2 = Female
nV3018 <- get_numeric_code(ncvs$V3018)
victim_gender <- ifelse(nV3018 == 1, "Male", ifelse(nV3018 == 2, "Female", "Unknown/Other"))

# F. Victim Race & Hispanic Origin
# V3023 & nV3023A (Race), V3024 & nV3024A (Hispanic Origin)
# Matches pred_model.R logic
nV3023 <- get_numeric_code(ncvs$V3023)
nV3023A <- get_numeric_code(ncvs$V3023A)
nV3024 <- get_numeric_code(ncvs$V3024)
nV3024A <- get_numeric_code(ncvs$V3024A)

nV3023[is.na(nV3023)] <- 99
nV3023A[is.na(nV3023A)] <- -1
nV3024[is.na(nV3024)] <- -1
nV3024A[is.na(nV3024A)] <- -1

white <- (nV3023 == 1) | (nV3023A == 1)
black <- (nV3023 == 2) | (nV3023A == 2)
nat <- (nV3023 == 3) | (nV3023A == 3)
asa_isl <- (nV3023 == 4) | (nV3023A == 4) | (nV3023A == 5)
mult <- (nV3023A > 5)
hisp <- (nV3024 == 1) | (nV3024A == 1)

# Combined Race/Ethnicity (Mutually Exclusive)
victim_race_ethnicity <- rep("Unknown/Other", length(white))
victim_race_ethnicity[white] <- "White"
victim_race_ethnicity[black] <- "Black"
victim_race_ethnicity[nat] <- "Native American"
victim_race_ethnicity[asa_isl] <- "Asian/Pacific Islander"
victim_race_ethnicity[mult] <- "Multiple"
# Hispanic origin takes precedence in demographic reporting
victim_race_ethnicity[hisp] <- "Hispanic"

# G. Victim Age (V3014)
victim_age <- as.integer(ncvs$V3014)
# Clean up missing or invalid ages (NCVS contains ages 12 to 88, 88 means 88+)
victim_age[victim_age < 0 | victim_age > 120] <- NA_integer_

# Age categories
victim_age_cat <- rep("Unknown", length(victim_age))
victim_age_cat[!is.na(victim_age) & victim_age >= 12 & victim_age <= 17] <- "12-17"
victim_age_cat[!is.na(victim_age) & victim_age >= 18 & victim_age <= 24] <- "18-24"
victim_age_cat[!is.na(victim_age) & victim_age >= 25 & victim_age <= 34] <- "25-34"
victim_age_cat[!is.na(victim_age) & victim_age >= 35 & victim_age <= 49] <- "35-49"
victim_age_cat[!is.na(victim_age) & victim_age >= 50 & victim_age <= 64] <- "50-64"
victim_age_cat[!is.na(victim_age) & victim_age >= 65] <- "65+"

# H. Area Population (recode from pred_model.R)
# Derived from V2126A and V2126B
nV2126A <- get_numeric_code(ncvs$V2126A)
nV2126B <- get_numeric_code(ncvs$V2126B)

pop_under50 <- (nV2126A %in% c(0,3,8,10,11)) | (nV2126B %in% c(0,13,16))
pop_50_250 <- (nV2126A %in% c(12,13)) | (nV2126B %in% c(17,18))
pop_over250 <- (nV2126A %in% c(14,15)) | (nV2126B %in% c(19,20))
pop_over1mill <- (nV2126A %in% c(16)) | (nV2126B %in% c(21,22,23))

pop_under50[is.na(pop_under50)] <- FALSE
pop_50_250[is.na(pop_50_250)] <- FALSE
pop_over250[is.na(pop_over250)] <- FALSE
pop_over1mill[is.na(pop_over1mill)] <- FALSE

area_population <- rep("Unknown", length(pop_under50))
area_population[pop_under50] <- "Under 50k"
area_population[pop_50_250] <- "50k to 250k"
area_population[pop_over250] <- "250k to 1 million"
area_population[pop_over1mill] <- "Over 1 million"

# I. US Region (nV2127B)
nV2127B <- get_numeric_code(ncvs$V2127B)
region <- rep("Unknown", length(nV2127B))
region[nV2127B == 1] <- "Northeast"
region[nV2127B == 2] <- "Midwest"
region[nV2127B == 3] <- "South"
region[nV2127B == 4] <- "West"
region[is.na(nV2127B)] <- "Unknown"

# J. Person Weight (V3080)
person_weight <- as.numeric(ncvs$V3080)
person_weight[is.na(person_weight)] <- 1.0 # Default fallback if weight is missing

# 3. Assemble Cleaned Dataframe
tidy_df <- data.frame(
  year = year,
  reported = reported,
  crime_type = crime_type,
  crime_category = crime_category,
  domestic_violence = domestic_violence,
  weapon = weapon,
  attempted = attempted,
  injury = injury,
  victim_offender_relationship = victim_offender_relationship,
  victim_gender = victim_gender,
  victim_race_ethnicity = victim_race_ethnicity,
  victim_age = victim_age,
  victim_age_cat = victim_age_cat,
  area_population = area_population,
  region = region,
  person_weight = person_weight,
  stringsAsFactors = FALSE
)

# 4. Filter to cases with valid reporting status
original_count <- nrow(tidy_df)
tidy_df <- tidy_df[!is.na(tidy_df$reported), ]
filtered_count <- nrow(tidy_df)
message(paste("Filtered out", original_count - filtered_count, "rows with missing reporting status. Keeping", filtered_count, "rows."))

# 5. Write to Parquet
output_file <- "./dashboard/ncvs_victimizations_1992_2024.parquet"
message(paste("Writing tidy Parquet file to:", output_file))
arrow::write_parquet(tidy_df, output_file, compression = "snappy")
message("Parquet conversion completed successfully!")
