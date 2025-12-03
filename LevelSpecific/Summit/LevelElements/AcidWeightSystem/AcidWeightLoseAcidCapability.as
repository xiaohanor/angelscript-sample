class UAcidWeightLoseAcidCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AAcidWeightActor AcidWeightActor;
	float AcidLossPerSecond = 0.25;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AcidWeightActor = Cast<AAcidWeightActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Time::GameTimeSeconds < AcidWeightActor.LastAcidHitDeactivateTime)
			return false;
		if(AcidWeightActor.AcidAlpha.Value <= 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Time::GameTimeSeconds < AcidWeightActor.LastAcidHitDeactivateTime)
			return true;
		if(AcidWeightActor.AcidAlpha.Value <= 0)
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
		AcidWeightActor.TargetAlpha -= AcidLossPerSecond * DeltaTime;
		AcidWeightActor.TargetAlpha = Math::Clamp(AcidWeightActor.TargetAlpha, 0.0, 1.0);
	}
}