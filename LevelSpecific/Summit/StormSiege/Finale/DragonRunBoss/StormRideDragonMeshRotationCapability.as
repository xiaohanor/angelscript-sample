class UStormRideDragonMeshRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormRideDragonMeshRotationCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormRideDragon StormDragon;

	float Speed = 1500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormRideDragon>(Owner);
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
		FQuat CurrentQuat = StormDragon.MeshOffsetComponent.RelativeRotation.Quaternion();
		StormDragon.MeshOffsetComponent.RelativeRotation = Math::QInterpTo(CurrentQuat, StormDragon.RelativeMeshRotTarget.Quaternion(), DeltaTime, StormDragon.QInterp).Rotator();
	}
}