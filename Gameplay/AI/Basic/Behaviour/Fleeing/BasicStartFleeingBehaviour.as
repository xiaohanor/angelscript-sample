class UBasicStartFleeingBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIFleeingComponent FleeComp;
	UHazeActorRespawnableComponent RespawnComp;
	bool bHasCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FleeComp = UBasicAIFleeingComponent::GetOrCreate(Owner);
		FleeComp.OnStopFleeing.AddUFunction(this, n"OnStopFleeing");
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		bHasCompleted = false;
	}

	UFUNCTION()
	private void OnStopFleeing(AHazeActor Actor)
	{
		bHasCompleted = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bHasCompleted)
			return false;
		return FleeComp.bWantsToFlee;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > BasicSettings.StartFleeingDuration)
			return true;
		return !FleeComp.bWantsToFlee;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(LocomotionFeatureAITags::Flee, SubTagAIFlee::StartFleeing, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (ActiveDuration > BasicSettings.StartFleeingDuration * 0.5)
			bHasCompleted = true;
	}
}

