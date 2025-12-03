
class UBasicScenepointEntranceBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	UScenepointUserComponent ScenepointUserComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIEntranceComponent EntranceComp;
	UScenepointComponent Scenepoint;

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
		if (EntranceComp.bHasStartedEntry)
			return false;
		if (EntranceComp.bHasCompletedEntry)
			return false;
		if (Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp) == nullptr)
		 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Scenepoint = Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp);
		EntranceComp.bHasStartedEntry = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (EntranceComp.bHasCompletedEntry)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Go to scene point!
		DestinationComp.MoveTowards(Scenepoint.WorldLocation, BasicSettings.ScenepointEntryMoveSpeed);

		// Continue until we're there
		if (DestinationComp.MoveSuccess() || Scenepoint.IsAt(Owner))
		{
			// We're done!
			EntranceComp.bHasCompletedEntry = true;
		}			
		else if (BasicSettings.bScenepointEntryAbortOnDamage && (HealthComp.LastDamage > 0.0))
		{
			// Abort!
			EntranceComp.bHasCompletedEntry = true;
		}
		else if (DestinationComp.MoveFailed())
		{
			// Wait a while then try again
			Cooldown.Set(2.0); 
			EntranceComp.bHasCompletedEntry = false;
		}
	}
}
