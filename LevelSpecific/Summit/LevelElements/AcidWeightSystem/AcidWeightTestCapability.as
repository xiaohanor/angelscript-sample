class UAcidWeightTestCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AAcidWeightActor WeightActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeightActor = Cast<AAcidWeightActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeightActor.bTestActivate == false)
			return false;	

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeightActor.bTestActivate == false)
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
		
	}
}
