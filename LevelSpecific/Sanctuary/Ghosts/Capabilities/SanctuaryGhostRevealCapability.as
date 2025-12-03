class USanctuaryGhostRevealCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryGhost");
	default CapabilityTags.Add(n"SanctuaryGhostReveal");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryGhost Ghost;

	FHazeAcceleratedFloat AcceleratedFloat;
	float TargetHeight = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ghost = Cast<ASanctuaryGhost>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Ghost.TargetPlayer == nullptr)
			return false;

		if (Ghost.bIsRevealed)
			return false;

		if (Ghost.GetDistanceTo(Ghost.TargetPlayer) > Ghost.RevealDistance)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Ghost.RevealDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedFloat.SnapTo(Ghost.SurfaceHeight, 0.0);
		Ghost.Reveal();
		TargetHeight = Ghost.TargetPlayer.ActorLocation.Z + Ghost.RevealHeightAbovePlayer;
		Owner.BlockCapabilities(n"SanctuaryGhostSwim", this);
//		Owner.BlockCapabilities(n"SanctuaryGhostChase", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"SanctuaryGhostSwim", this);
//		Owner.UnblockCapabilities(n"SanctuaryGhostChase", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToTarget = Ghost.TargetPlayer.ActorCenterLocation - Ghost.ActorLocation;

		AcceleratedFloat.AccelerateTo(TargetHeight, Ghost.RevealDuration, DeltaTime);

		FVector Location = Ghost.ActorLocation;
		Location.Z = AcceleratedFloat.Value;

		Ghost.ActorLocation = Location;

		Ghost.Pivot.SetWorldRotation(FQuat::Slerp(Ghost.Pivot.ComponentQuat, ToTarget.ToOrientationQuat(), DeltaTime * 5.0));
	}
};