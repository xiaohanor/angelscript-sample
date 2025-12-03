class UCoastWingsuitToWaterskiTransitionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UCoastWaterskiPlayerComponent WaterskiComp;
	UWingSuitPlayerComponent WingsuitComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;

	const float AnimationTransitionDuration = 1.73;
	const float AnimationFastTransitionDuration = 0.9;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		WingsuitComp = UWingSuitPlayerComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastWingsuitToWaterskiTransitionActivatedParams& Params) const
	{
		if(WingsuitComp == nullptr)
			return false;

		if(WaterskiComp.IsWaterskiing())
			return false;

		if(!WingsuitComp.bWingsuitActive)
			return false;

		if (!WasActionStarted(ActionNames::Grapple))
			return false;

		auto Targetable = PlayerTargetablesComponent.GetPrimaryTarget(UCoastWaterskiAttachPointComponent);

		if (Targetable == nullptr)
			return false;

		Params.AttachPoint = Targetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return true;

		if(!WingsuitComp.AnimData.bCloseToWaterSurface && ActiveDuration > AnimationTransitionDuration)
			return true;

		if(WingsuitComp.AnimData.bCloseToWaterSurface && ActiveDuration > AnimationFastTransitionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCoastWingsuitToWaterskiTransitionActivatedParams Params)
	{
		WingsuitComp.AnimData.bIsTransitioningToWaterski = true;

		float HeightDiff = Player.ActorLocation.Z - OceanWaves::GetOceanWavePaint().TargetLandscape.ActorLocation.Z;
		if(HeightDiff < 2000.0)
			WingsuitComp.AnimData.bCloseToWaterSurface = true;

		DeactivateWingSuit(Player);
		WaterskiComp.WaterskiManager.StartWaterskiing(Player, Params.AttachPoint, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WingsuitComp.AnimData.bIsTransitioningToWaterski = false;
		WingsuitComp.AnimData.bCloseToWaterSurface = false;
		WaterskiComp.FrameOfStopTransitionFromWingsuit.Set(Time::FrameNumber);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"WingSuit", this);
		}
	}
}

struct FCoastWingsuitToWaterskiTransitionActivatedParams
{
	UCoastWaterskiAttachPointComponent AttachPoint;
}