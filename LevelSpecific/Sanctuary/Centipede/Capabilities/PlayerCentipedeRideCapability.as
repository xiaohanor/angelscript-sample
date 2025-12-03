class UPlayerCentipedeRideCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastDemotable;

	UPlayerCentipedeComponent CentipedeComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		return false;
	}

	// Snap player mesh to mount bone
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform MountTransform = CentipedeComponent.GetMountBoneTransform();

		// Flip tail player 180
		if (CentipedeComponent.IsTailPlayer())
		{
			FQuat YawFlip = FQuat(MountTransform.Rotation.UpVector, PI);
			MountTransform.SetRotation(YawFlip * MountTransform.Rotation);
		}

		Player.Mesh.SetWorldTransform(MountTransform);
	}
}