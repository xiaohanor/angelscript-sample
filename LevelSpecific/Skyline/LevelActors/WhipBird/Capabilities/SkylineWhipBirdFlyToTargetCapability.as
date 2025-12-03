class USkylineWhipBirdFlyToTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineWhipBirdMovement");
	default CapabilityTags.Add(n"SkylineWhipBirdFlyToTarget");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineWhipBird WhipBird;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipBird = Cast<ASkylineWhipBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WhipBird.HasValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WhipBird.HasValidTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToTarget = WhipBird.CurrentTarget.WorldLocation - WhipBird.ActorLocation;
		WhipBird.Force += ToTarget.SafeNormal * Math::Min(ToTarget.Size(), WhipBird.FlySpeed) * (WhipBird.bIsThrown ? 0.0 : 1.0);
	}
};