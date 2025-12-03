class USpaceLiftRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SpaceLiftRotationCapability");
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	ASolarFlareSpaceLiftMain SpaceLift;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpaceLift = Cast<ASolarFlareSpaceLiftMain>(Owner);
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
		FQuat MeshRelRot = SpaceLift.MeshRoot.RelativeRotation.Quaternion();
		SpaceLift.MeshRoot.RelativeRotation = Math::QInterpConstantTo(MeshRelRot, SpaceLift.TargetRot.Quaternion(), DeltaTime, 1.4).Rotator();
		FQuat PoleRelRot = SpaceLift.PoleAnchor.RelativeRotation.Quaternion();
		SpaceLift.PoleAnchor.RelativeRotation = Math::QInterpConstantTo(PoleRelRot, SpaceLift.TargetRotPoleAnchor.Quaternion(), DeltaTime, 1.8).Rotator();
	}
}