class UCoastWaterskiToWingsuitTransitionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UCoastWaterskiPlayerComponent WaterskiComp;
	UWingSuitPlayerComponent WingsuitComp;

	const float AnimationTransitionDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		WingsuitComp = UWingSuitPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(WaterskiComp == nullptr)
			WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WingsuitComp.bWingsuitActive)
			return false;

		if(WaterskiComp == nullptr)
			return false;

		if(WaterskiComp.IsWaterskiing())
			return false;

		// This means the waterski's has never been destroyed
		if(WaterskiComp.FrameOfDestroyWaterski == 0)
			return false;

		uint FrameDifference = Time::FrameNumber - WaterskiComp.FrameOfDestroyWaterski;
		if(FrameDifference > 1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WingsuitComp.bWingsuitActive)
			return true;

		if(ActiveDuration > AnimationTransitionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WaterskiComp.AnimData.bTransitioningToWingsuit = true;
		WingsuitComp.bTransitioningFromWaterski = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WaterskiComp.AnimData.bTransitioningToWingsuit = false;
		WingsuitComp.bTransitioningFromWaterski = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"Waterski", this);
		}
	}
}