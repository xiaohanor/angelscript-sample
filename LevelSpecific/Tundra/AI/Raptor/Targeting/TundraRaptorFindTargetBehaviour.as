class UTundraRaptorFindTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Use specific aggro target if any
		AHazeActor Target = nullptr;

		// Can we otherwise perceive a target?
		if (Target == nullptr)
	 		Target = TargetComp.FindClosestTarget(BasicSettings.AwarenessRange);

		if (Target != nullptr)
		{
			TargetComp.SetTarget(Target);
			return;
		}
	}
}
