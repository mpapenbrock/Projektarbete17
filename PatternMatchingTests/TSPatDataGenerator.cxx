/*
 * TSPatDataGenerator.cxx
 *
 *  Created on: Nov 2017
 *      Author: Adam Hedkvist & Arvi Jonnarth
 */

#include "TSPatDataGenerator.h"

#include <FairMultiLinkedData.h>
#include <FairRunAna.h>
#include <FairRuntimeDb.h>
#include <PndSttMapCreator.h>
#include <PndSttTube.h>
#include <PndTrackCand.h>
#include <PndFtsHit.h>
#include <PndSttHit.h>
#include <boost/range/adaptor/reversed.hpp>
#include <TArc.h>
#include <TArrow.h>
#include <TLine.h>
#include <TText.h>
#include <TMath.h>

#include <iostream>
#include <fstream>


ClassImp(TSPatDataGenerator)

TSPatDataGenerator::TSPatDataGenerator() {
  fSttParameters = NULL;
  fEventHeader = NULL;
  fTubeArray = NULL;
  fSTTHitArray = NULL;
  fFTSHitArray = NULL;
  fMCTrackArray = NULL;
  trackCands = NULL;
  idealTracks = NULL;
  genTracks = NULL;
  sttBranchID = -1;
  mcTrackID = -1;
  dataFileName = "./dataTSPat.csv";
}

TSPatDataGenerator::~TSPatDataGenerator() {
  // TODO Auto-generated destructor stub
}

void TSPatDataGenerator::SetParContainers() {
  FairRuntimeDb *rtdb = FairRunAna::Instance()->GetRuntimeDb();
  fSttParameters = (PndGeoSttPar*) rtdb->getContainer("PndGeoSttPar");
}

InitStatus TSPatDataGenerator::Init() {
  
  // Create file
  csvFile.open(dataFileName);
  
  // Get the running instance of the FairRootManager to access tree branches
  FairRootManager *ioman = FairRootManager::Instance();
  if(!ioman) {
    std::cout << "-E- PatternDBGenerator::Init: FairRootManager not instantiated!" << std::endl;
    return kFATAL;
  }
  
  // Access the STTHit branch
  fSTTHitArray = (TClonesArray*) ioman->GetObject("STTHit");
  // Access MCTrack pointers
  fMCTrackArray = (TClonesArray*) ioman->GetObject("MCTrack");
  // Get the ID of the STTHit branch for accessing the FairLinks later
  sttBranchID = ioman->GetBranchId("STTHit");
  if (sttBranchID == -1) {
    std::cout << "-E- PatternDBGenerator:Init: STTHit branch not found!" << std::endl;
  }
  
  // Get the ID of the MCTrack branch for accessing through FairLinks later
  mcTrackID = ioman->GetBranchId("MCTrack");
  if (mcTrackID == -1) {
    std::cout << "-E- PatternDBGenerator:Init: MCTrack branch not found!" << std::endl;
  }
  
  // Get the track candidates from the ideal track finder
  trackCands = (TClonesArray*) ioman->GetObject("SttMvdGemIdealTrackCand");
  if (!trackCands) {
    std::cout << "-E- PatternDBGenerator:Init: SttMvdGemIdealTrackCand not fount!" << std::endl;
  }
  
  // Initialization successful
  std::cout << "-I- PatternDBGenerator: Initialisation successful" << std::endl;
  return kSUCCESS;
}


void TSPatDataGenerator::Exec(Option_t* opt) {
  PndMCTrack *mcTrack;
  PndSttHit *sttHit;
  PndFtsHit *ftsHit;
  PndTrackCand *cand;
  FairMultiLinkedData sttLinks;
  
  // Get FairRootManager instance to access objects through FairLinks
  FairRootManager *ioman = FairRootManager::Instance();
  
  // Get the number of track candidates
  int nTrackCands = trackCands->GetEntriesFast();
  
  // Print the number of tube hits
  int nTubesSTT = fSTTHitArray->GetEntriesFast();
  csvFile << nTubesSTT;
  
  
  // Print the number of tube hits created by the final state proton
  int nTubes = 0;
  for (int iTrack = 0; iTrack < nTrackCands; ++iTrack) {
    cand = (PndTrackCand*) (trackCands->At(iTrack));
    FairMultiLinkedData mcTrackLinks = cand->GetLinksWithType(mcTrackID);
    FairLink mcTrackLink = mcTrackLinks.GetLink(0);
    mcTrack = (PndMCTrack*) (ioman->GetCloneOfLinkData(mcTrackLink));

    if (mcTrack->GetPdgCode() == 2212 && mcTrack->GetMotherID() == -1) {
      sttLinks = cand->GetLinksWithType(sttBranchID);
      nTubes += sttLinks.GetNLinks();
    }
  }
  csvFile << "," << nTubes;
  
  // Print all the STT tube IDs
  for (int iTube = 0; iTube < nTubesSTT; ++iTube) {
    sttHit = (PndSttHit*) (fSTTHitArray->At(iTube));
    csvFile << "," << sttHit->GetTubeID() << "," << sttHit->GetTimeStamp()/100.;
  }
  
  // Loop over all track candidates and write the tube IDs associated with the final state proton
  for (int iTrack = 0; iTrack < nTrackCands; ++iTrack) {
    
    // Get the next track candidate
    cand = (PndTrackCand*) (trackCands->At(iTrack));
    
    // Get the MC track
    FairMultiLinkedData mcTrackLinks = cand->GetLinksWithType(mcTrackID);
    FairLink mcTrackLink = mcTrackLinks.GetLink(0);
    mcTrack = (PndMCTrack*) (ioman->GetCloneOfLinkData(mcTrackLink));
    
    // Get the FairLinks from the candidate pointing at STTHit branch
    sttLinks = cand->GetLinksWithType(sttBranchID);
    
    // Write the tube IDs to the csv file
    if (mcTrack->GetPdgCode() == 2212 && mcTrack->GetMotherID() == -1) {
      for (int iLink = 0; iLink < sttLinks.GetNLinks(); ++iLink) {
        FairLink sttLink = sttLinks.GetLink(iLink);
        sttHit = (PndSttHit*) (ioman->GetCloneOfLinkData(sttLink));
        csvFile << "," << sttHit->GetTubeID();
      }
    }
  }
  
  csvFile << "\n";
}


void TSPatDataGenerator::FinishTask() {
  // close csv
  csvFile.close();
}


void TSPatDataGenerator::SetFileName(TString name) {
  dataFileName = name;
}







