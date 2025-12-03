class UBigHogDefaultCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	ABigHog BigHog;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BigHog = Cast<ABigHog>(Owner);
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
		if (BigHog.Mesh.CanRequestLocomotion())
			BigHog.Mesh.RequestLocomotion(n"BigHog", this);

		if (!BigHog.IsFarting())
		{
			FVector BoneScale = BigHog.Mesh.GetSocketTransform(n"Spine1").Scale3D;
			BigHog.BellyCollision.SetRelativeScale3D(BoneScale * 1.5);
		}
	}
}