# test_records.R
# Author: Emmanuel Blondel <emmanuel.blondel1@gmail.com>
#
# Description: Unit tests for Zenodo record operations
#=======================
require(zen4R, quietly = TRUE)
require(testthat)

context("records")

test_that("create empty record - with pre-reserved DOI",{
  newRec <- ZENODO$createEmptyRecord()
  expect_is(newRec, "ZenodoRecord")
  expect_is(newRec$metadata$prereserve_doi, "list")
  expect_true(nchar(newRec$metadata$prereserve_doi$doi)>0)
  expect_true(newRec$metadata$prereserve_doi$recid>0)
})

test_that("create and deposit record",{
  myrec <- ZenodoRecord$new()
  myrec$setTitle("My publication title")
  myrec$setDescription("A description of my publication")
  myrec$setUploadType("publication")
  myrec$setPublicationType("article")
  myrec$addCreator(firstname = "John", lastname = "Doe", affiliation = "Independent")
  myrec$setLicense("mit")
  myrec$addCommunity("ecfunded")
  myrec$setKeywords(c("R","package","software"))
  myrec$addReference("Author et al., 2019. Title")
  myrec$addReference("Fulano et al., 2018. Título")
  myrec$addGrant("675680")
  myrec$setJournalTitle("Journal title")
  myrec$setJournalVolume("1")
  myrec$setJournalIssue("Issue 1")
  myrec$setJournalPages("19")
  myrec$setConferenceTitle("Roots Rock Reggae International Conference")
  myrec$setConferenceAcronym("RRR-IC-VIBES")
  myrec$setConferenceDates("June 2019")
  myrec$setConferencePlace("Kingston, Jamaica")
  myrec$setConferenceSession("I")
  myrec$setConferenceSessionPart("1")
  myrec$setConferenceUrl("http://www.google.com")
  myrec$setImprintPublisher("The Publisher")
  myrec$setImprintISBN("isbn")
  myrec$setImprintPlace("location")
  myrec$setPartofTitle("Book title")
  myrec$setPartofPages("1-30")
  myrec$addContributor(firstname = "Peter", lastname = "Lead", type = "WorkPackageLeader")
  myrec$addContributor(firstname = "Frank", "Super", type = "Supervisor")
  
  expect_equal(myrec$metadata$title, "My publication title")
  expect_equal(myrec$metadata$description, "A description of my publication")
  expect_equal(myrec$metadata$upload_type, "publication")
  expect_equal(myrec$metadata$publication_type, "article")
  expect_is(myrec$metadata$creator, "list")
  expect_equal(length(myrec$metadata$creator), 1L)
  expect_equal(myrec$metadata$creator[[1]]$name, "Doe, John")
  expect_equal(myrec$metadata$creator[[1]]$affiliation, "Independent")
  expect_true(myrec$metadata$prereserve_doi)
  
  #deposit
  deposit = ZENODO$depositRecord(myrec)
  expect_is(deposit, "ZenodoRecord")
  
  #add files
  ZENODO$uploadFile("README.md", deposit$id)
  
  #delete record
  deleted <- ZENODO$deleteRecord(deposit$id)
  expect_true(deleted)
})

test_that("create, deposit and publish record",{
  myrec <- ZenodoRecord$new()
  myrec$setTitle(paste("My publication title -", Sys.time()))
  myrec$setDescription("A description of my publication")
  myrec$setUploadType("publication")
  myrec$setPublicationType("article")
  myrec$addCreator(firstname = "John", lastname = "Doe", affiliation = "Independent")
  myrec$setLicense("mit")
  myrec$addCommunity("ecfunded")
  myrec$setKeywords(c("R","package","software"))
  myrec$addReference("Author et al., 2019. Title")
  myrec$addReference("Fulano et al., 2018. Título")
  
  expect_true(startsWith(myrec$metadata$title, "My publication title"))
  expect_equal(myrec$metadata$description, "A description of my publication")
  expect_equal(myrec$metadata$upload_type, "publication")
  expect_equal(myrec$metadata$publication_type, "article")
  expect_is(myrec$metadata$creator, "list")
  expect_equal(length(myrec$metadata$creator), 1L)
  expect_equal(myrec$metadata$creator[[1]]$name, "Doe, John")
  expect_equal(myrec$metadata$creator[[1]]$affiliation, "Independent")
  expect_true(myrec$metadata$prereserve_doi)
  
  #deposit
  deposit = ZENODO$depositRecord(myrec)
  expect_is(deposit, "ZenodoRecord")
  
  #add files
  ZENODO$uploadFile("README.md", deposit$id)
  
  #publish record
  deposit <- ZENODO$publishRecord(deposit$id)
  
  #delete record
  deleted <- ZENODO$deleteRecord(deposit$id)
  expect_false(deleted)
})

test_that("get by concept DOI",{
  rec <- ZENODO$getDepositionByConceptDOI("10.5072/zenodo.349738")
  expect_is(rec, "ZenodoRecord")
  expect_equal(rec$conceptdoi, "10.5072/zenodo.349738")
  expect_equal(rec$metadata$title, "My publication title - 2019-07-24")
})

test_that("get by record DOI",{
  rec <- ZENODO$getDepositionByDOI("10.5072/zenodo.349739")
  expect_is(rec, "ZenodoRecord")
  expect_equal(rec$conceptdoi, "10.5072/zenodo.349738")
  expect_equal(rec$metadata$title, "My publication title - 2019-07-24")
})

test_that("versioning",{
  rec <- ZENODO$getDepositionByConceptDOI("10.5072/zenodo.349738")
  rec$setTitle(paste("My publication title -", Sys.time()))
  rec$setPublicationDate(Sys.Date())
  write.csv(data.frame(title = rec$metadata$title, stringsAsFactors = FALSE), row.names = FALSE, "publication.csv")
  rec_version <- ZENODO$depositRecordVersion(rec, files = "publication.csv", publish = TRUE)
  unlink("publication.csv")
})

test_that("versions & DOIs",{
  rec <- ZENODO$getDepositionByConceptDOI("10.5072/zenodo.349738")
  expect_equal(rec$getConceptDOI(), "10.5072/zenodo.349738")
  expect_equal(rec$getFirstDOI(), "10.5072/zenodo.349739")
  expect_equal(rec$getLastDOI(), "10.5072/zenodo.349743")
  versions <- rec$getVersions()
  expect_is(versions, "data.frame")
  
  rec <- ZENODO$getDepositionByDOI("10.5072/zenodo.349743")
  expect_equal(rec$getFirstDOI(), "10.5072/zenodo.349739")
  expect_equal(rec$getLastDOI(), "10.5072/zenodo.349743")
  expect_equal(rec$getConceptDOI(), "10.5072/zenodo.349738")
  versions <- rec$getVersions()
  expect_is(versions, "data.frame")
  
  rec <- ZENODO$getDepositionByDOI("10.5072/zenodo.349741")
  expect_is(rec, "ZenodoRecord")
})