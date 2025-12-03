class USandSharkTrailCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkTrail);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASandShark SandShark;

	FVector TrailCompRelativeLocation;
	USandSharkAnimationComponent AnimationComp;
	USandSharkChaseComponent ChaseComp;

	bool bIsFinAboveGround;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		TrailCompRelativeLocation = SandShark.TrailComp.RelativeLocation;
		AnimationComp = USandSharkAnimationComponent::Get(Owner);
		ChaseComp = USandSharkChaseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// No need for activation conditions, this capability can be blocked when we don't want a trail.
		auto DorsalFinBotLocation = AnimationComp.FinBotLocation;
		auto DorsalFinTopLocation = AnimationComp.FinTopLocation;

		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != SandShark.LandscapeLevel)
			return false;

		float LandScapeHeight = Desert::GetLandscapeHeight(DorsalFinBotLocation);

		if (!ChaseComp.bIsChasing)
			return false;

		if (DorsalFinTopLocation.Z < LandScapeHeight - 30)
			return false;

		if (DorsalFinBotLocation.Z > LandScapeHeight)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto DorsalFinBotLocation = AnimationComp.FinBotLocation;
		auto DorsalFinTopLocation = AnimationComp.FinTopLocation;

		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return true;

		if (Desert::GetRelevantLandscapeLevel() != SandShark.LandscapeLevel)
			return true;

		float LandScapeHeight = Desert::GetLandscapeHeight(DorsalFinBotLocation);

		if (!ChaseComp.bIsChasing)
			return true;

		if (DorsalFinTopLocation.Z < LandScapeHeight)
			return true;

		if (DorsalFinBotLocation.Z > LandScapeHeight)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto DorsalFinBotLocation = AnimationComp.FinBotLocation;
		auto DorsalFinTopLocation = AnimationComp.FinTopLocation;

		float LandScapeHeight = Desert::GetLandscapeHeight(DorsalFinBotLocation);
		float HeightAlpha = Math::Saturate(Math::NormalizeToRange(LandScapeHeight, DorsalFinBotLocation.Z, DorsalFinTopLocation.Z));

		FVector FinSandLocation = Desert::GetLandscapeLocation(Math::Lerp(DorsalFinBotLocation, DorsalFinTopLocation, HeightAlpha));
		SandShark.TrailComp.SetWorldLocation(FinSandLocation);
		SandShark.TrailComp.Activate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SandShark.TrailComp.Deactivate();
		SandShark.TrailComp.SetWorldLocation(AnimationComp.FinBotLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		FVector Start = SandShark.TrailComp.WorldLocation;
		FVector Delta = SandShark.TrailComp.ForwardVector * 100;
		TemporalLog.DirectionalArrow("TrailLocation", Start, Delta, 100, 100, FLinearColor::Blue);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto DorsalFinBotLocation = AnimationComp.FinBotLocation;
		auto DorsalFinTopLocation = AnimationComp.FinTopLocation;

		float LandScapeHeight = Desert::GetLandscapeHeight(DorsalFinBotLocation);
		float HeightAlpha = Math::Saturate(Math::NormalizeToRange(LandScapeHeight, DorsalFinBotLocation.Z, DorsalFinTopLocation.Z));

		FVector FinSandLocation = Desert::GetLandscapeLocation(Math::Lerp(DorsalFinBotLocation, DorsalFinTopLocation, HeightAlpha));
		SandShark.TrailComp.SetWorldLocation(FinSandLocation);
	}
};