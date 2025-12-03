class UAcidWeightContainerMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AAcidWeightActor AcidWeightActor;
	FHazeAcceleratedVector AccelVectorTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AcidWeightActor = Cast<AAcidWeightActor>(Owner);
		
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
		AccelVectorTarget.SnapTo(AcidWeightActor.MeshRoot.RelativeLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccelVectorTarget.AccelerateTo(AcidWeightActor.GetTargetLocation(), 1.5, DeltaTime);
		AcidWeightActor.MeshRoot.RelativeLocation = AccelVectorTarget.Value;
	}
}