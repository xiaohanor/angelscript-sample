class USanctuaryGhostSwimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryGhost");
	default CapabilityTags.Add(n"SanctuaryGhostSwim");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryGhost Ghost;

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

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Ghost.TargetPlayer == nullptr)
			return true;

		if (Ghost.bIsRevealed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Ghost.ActorLocation = FVector(Ghost.ActorLocation.X, Ghost.ActorLocation.Y, Ghost.SurfaceHeight);
		Ghost.LightBirdTargetComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Ghost.LightBirdTargetComp.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToTarget = Ghost.TargetPlayer.ActorCenterLocation - Ghost.ActorLocation;
		ToTarget = ToTarget.VectorPlaneProject(FVector::UpVector);
		FVector Direction = ToTarget.SafeNormal;
		float Distance = Math::Min(ToTarget.Size(), Ghost.SwimSpeed * DeltaTime);

		FVector DeltaMove = Direction * Distance;

		Ghost.ActorLocation += DeltaMove;

		Ghost.Pivot.SetWorldRotation(FQuat::Slerp(Ghost.Pivot.ComponentQuat, ToTarget.ToOrientationQuat(), DeltaTime * 5.0));
	}
};