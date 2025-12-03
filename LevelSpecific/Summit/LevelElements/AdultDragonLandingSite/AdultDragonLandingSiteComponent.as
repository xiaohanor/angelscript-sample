// This component holds landing site info and should be on the dragon
class UAdultDragonLandingSiteComponent : UActorComponent
{
	AAdultDragonLandingSite CurrentLandingSite;
	bool bAtLandingSite = false;
	bool bForceExitLandingSite = false;
	bool bBlowingHorn = false;

	void EnterLandingSite(AAdultDragonLandingSite LandingSite)
	{
		CurrentLandingSite = LandingSite;
		CurrentLandingSite.bLandingSiteOccupied = true;
		bAtLandingSite = true;
	}

	void ExitLandingSite()
	{
		CurrentLandingSite.bLandingSiteOccupied = false;
		CurrentLandingSite = nullptr;
		bAtLandingSite = false;
	}
}