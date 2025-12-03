class UBasicOptimizeFitnessStrafingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFitnessStrafingComponent FitnessStrafingComp;
	UFitnessUserComponent FitnessComp;
	UBasicAITargetingComponent TargetComp;
	UFitnessSettings FitnessSettings;
	float Cooldown = 0.0;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);
		TargetComp = UBasicAITargetingComponent::Get(Owner);
		FitnessSettings = UFitnessSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Time::GameTimeSeconds < Cooldown)
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		
		auto Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		float Score = FitnessComp.GetFitnessScore(Player);
		if(Player == nullptr || Score >= FitnessSettings.OptimalThresholdMax || Score <= FitnessSettings.OptimalThresholdMin)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!TargetComp.HasValidTarget())
			return true;

		auto Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		float Score = FitnessComp.GetFitnessScore(Player);
		if(Player == nullptr || Score >= FitnessSettings.OptimalThresholdMax || Score <= FitnessSettings.OptimalThresholdMin)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Never any need to do this frequently
		Cooldown = Time::GameTimeSeconds + Math::RandRange(0.7, 1.2);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FitnessStrafingComp.OptimizeStrafeDirection();
	}
}