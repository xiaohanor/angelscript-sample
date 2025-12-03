class USkylineTorIntroWaitBehaviour : UBasicBehaviour
{
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorHoldHammerComponent HoldHammerComp;

	// TArray<AHazeActor> SpawnedActors;
	bool bCompleted;
	// bool bDepleted;
	// int Counter = 0;
	float EndTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);

		// ASkylineEnforcerSentencedManager SentencedManager = TListedActors<ASkylineEnforcerSentencedManager>().Single;
		// SentencedManager.OnPassiveSentenced.AddUFunction(this, n"PassiveSentenced");
		
		// AHazeActorSpawnerBase Spawner = SentencedManager.Spawners[0];
		// Spawner.OnPostSpawn.AddUFunction(this, n"Spawned");
		// Spawner.OnDepleted.AddUFunction(this, n"Depleted");
	}

	// UFUNCTION()
	// private void Depleted(AHazeActor LastActor)
	// {
	// 	bDepleted = true;
	// }

	// UFUNCTION()
	// private void Spawned(AHazeActor SpawnedActor)
	// {
	// 	Counter++;
	// 	SpawnedActors.Add(SpawnedActor);
	// }

	// UFUNCTION()
	// private void PassiveSentenced(AHazeActorSpawnerBase Spawner, int Index)
	// {
	// 	Counter--;
	// 	if(Counter == 0)
	// 	{
	// 		EndTime = Time::GameTimeSeconds;
	// 		DeactivateBehaviour();
	// 	}
	// }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(bCompleted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 2)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
		AHazeActor TargetActor = TListedActors<ASkylineTorReferenceManager>().Single.HammerIntroLocation;
		UBasicAITargetingComponent::GetOrCreate(Owner).SetTarget(TargetActor);
		PhaseComp.SetSubPhase(ESkylineTorSubPhase::EntryAttack);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(EndTime == 0)
		// 	return;
		// if(Time::GetGameTimeSince(EndTime) > 2)
		// 	DeactivateBehaviour();
	}
}
