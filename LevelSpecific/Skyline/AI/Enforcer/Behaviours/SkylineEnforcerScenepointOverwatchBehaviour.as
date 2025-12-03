// After reaching an entry scenepoint, keep still and fire.
class USkylineEnforcerScenepointOverwatchBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	UScenepointUserComponent ScenepointUserComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIEntranceComponent EntranceComp;
	UScenepointComponent ScenepointComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		EntranceComp = UBasicAIEntranceComponent::GetOrCreate(Owner);
		ScenepointUserComp = UScenepointUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!EntranceComp.bHasStartedEntry)
			return false;
		if (!EntranceComp.bHasCompletedEntry)
			return false;
        UScenepointComponent Scenepoint = Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp);
		if (Scenepoint == nullptr)
		 	return false;
        if (!Scenepoint.CanUse(Owner))
            return false;
        if (!Scenepoint.IsAt(Owner))
            return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ScenepointComp = Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp);
        ScenepointComp.Use(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;        
		return false;
	}

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Super::OnDeactivated();
        ScenepointComp = Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp);
        ScenepointComp.Release(Owner);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}
