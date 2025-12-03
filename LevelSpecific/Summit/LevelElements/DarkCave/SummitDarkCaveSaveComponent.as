event void FOnSummitDarkCaveActivateSave();

class USummitDarkCaveSaveComponent : UActorComponent
{
	FOnSummitDarkCaveActivateSave OnSummitDarkCaveActivateSave; 

	void ActivateSaveState()
	{
		OnSummitDarkCaveActivateSave.Broadcast();
	}
};