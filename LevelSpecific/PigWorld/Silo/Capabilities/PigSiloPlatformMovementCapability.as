class UPigSiloPlatformMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	APigSiloPlatform SiloPlatformOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SiloPlatformOwner = Cast<APigSiloPlatform>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// FQuat RotationDelta = FQuat(FVector::UpVector, 40.0 * DeltaTime * DeltaTime);
		// SiloPlatformOwner.SetActorRotation(RotationDelta * SiloPlatformOwner.ActorQuat);
	}
}