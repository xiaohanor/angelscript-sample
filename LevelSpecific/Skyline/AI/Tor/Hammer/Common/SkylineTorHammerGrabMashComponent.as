class USkylineTorHammerGrabMashComponent : UActorComponent
{
	USkylineTorHammerWhipComponent WhipComp;
	private bool bInternalActive;

	bool GetbActive() property
	{
		return bInternalActive;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipComp = USkylineTorHammerWhipComponent::GetOrCreate(Owner);
	}

	void StartMash(UGravityWhipResponseComponent ResponseComp)
	{
		bInternalActive = true;
		// FHazePointOfInterestFocusTargetInfo Info;
		// Info.SetFocusToActor(ResponseComp.Owner);
		// FApplyPointOfInterestSettings Settings;
		// Game::Zoe.ApplyPointOfInterest(this, Info, Settings, 1, EHazeCameraPriority::High);
		// Game::Zoe.ApplyCameraSettings(WhipComp.GrabMashCameraSettings, 0.5, this, EHazeCameraPriority::High);
	}

	void StopMash(UGravityWhipResponseComponent ResponseComp)
	{
		bInternalActive = false;
		// Game::Zoe.ClearPointOfInterestByInstigator(this);
		// Game::Zoe.ClearCameraSettingsByInstigator(this);
	}
}