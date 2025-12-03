class USummitDecimatorTopdownSpawnerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USummitDecimatorTopdownSettings Settings;
	UHazeActorSpawnerComponent SpawnComp;
	UHazeActorSpawnPatternInterval SpawnPattern;
	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	USummitDecimatorTopdownPhaseComponent PhaseComp;

	float MinActiveDuration = 5.0; // let animation finish
	
	int NumSpawnedSpikeBombs = 0;
	bool bHasStartedSpawning = false;
	bool bIsBlockingMovement = false;

	AAISummitDecimatorTopdown Decimator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
		
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);

		SpawnComp = UHazeActorSpawnerComponent::Get(Owner);
		SpawnComp.OnPostSpawn.AddUFunction(this, n"OnPostSpawn");
		SpawnComp.OnPostUnspawn.AddUFunction(this, n"OnPostUnspawn");

		SpawnPattern = Decimator.SpikeBombSpawnPattern;		
		SpawnPattern.Interval = Settings.SpikeBombSpawnInterval;
		SpawnPattern.bInfiniteSpawn = true;
		SpawnPattern.MaxActiveSpawnedActors = Settings.SpikeBombMaxSpawnCount;
		
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnPostSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (SpawningPattern != SpawnPattern)
			return;
		FVector HeadLocation;
		FRotator SomeRotation;

		// Set reference to Decimator
		Cast<AAISummitDecimatorSpikeBomb>(SpawnedActor).DecimatorOwner = Decimator;

		Decimator.Mesh.TransformFromBoneSpace(n"Head", FVector::ZeroVector, FRotator::ZeroRotator, HeadLocation, SomeRotation);
		SpawnedActor.SetActorLocation(HeadLocation);		
		FVector AimDir = SomeRotation.UpVector;		
		UHazeMovementComponentBase MoveComp = UHazeMovementComponentBase::Get(SpawnedActor);
		MoveComp.Reset();		 
		
		// Stop spawning when max count is hit. PhaseComp will switch AttackState when count reaches 0 later.
		PhaseComp.NumActiveSpikeBombs++;
		NumSpawnedSpikeBombs++;
		if (NumSpawnedSpikeBombs >= Settings.SpikeBombMaxSpawnCount)
		{
			SpawnPattern.DeactivatePattern(this);
		}

		if (PhaseComp.NumActiveSpikeBombs == 1)
			SpawnedActor.AddMovementImpulse( AimDir * Settings.SpikeBombSpawnImpulse1 );
		else if (PhaseComp.NumActiveSpikeBombs == 2)
			SpawnedActor.AddMovementImpulse( AimDir.RotateTowards(Owner.ActorForwardVector,5) * Settings.SpikeBombSpawnImpulse2 );
		else if (PhaseComp.NumActiveSpikeBombs == 3)
			SpawnedActor.AddMovementImpulse( AimDir * Settings.SpikeBombSpawnImpulse3 );

		UBasicAIDestinationComponent DestinationComp = UBasicAIDestinationComponent::Get(SpawnedActor);
		DestinationComp.Update();  // HACK. This will later be properly bound to the respawn event and handled automatically internally in the DestinationComp.

		USummitDecimatorSpikeBombEffectsHandler::Trigger_OnSpawned(SpawnedActor, FSummitDecimatorSpikeBombLaunchParams(SpawnedActor.ActorCenterLocation, AimDir));
	}

	
	UFUNCTION()
	private void OnPostUnspawn(AHazeActor UnspawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (SpawningPattern != SpawnPattern)
			return;

		PhaseComp.NumActiveSpikeBombs--;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;
		if(!SpawnComp.IsSpawnerActive())
			return false;
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return false;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::SpawningSpikeBombs)
			return false;
		if (PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::TurningInwards)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HealthComp.IsDead())
			return true;
		if(!SpawnComp.IsSpawnerActive())
			return true;
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return true;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::SpawningSpikeBombs)
			return true;
		if (NumSpawnedSpikeBombs >= Settings.SpikeBombMaxSpawnCount && ActiveDuration > MinActiveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DecimatorTopdown::Animation::RequestFeatureSpikeBombSpawning(AnimComp, this);

		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		bIsBlockingMovement = true;
		
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Activated Substate: Spawn Spikebombs", 5.0, Color=FLinearColor::Yellow);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		SpawnPattern.DeactivatePattern(this);
		AnimComp.ClearFeature(this);
		bHasStartedSpawning = false;
		NumSpawnedSpikeBombs = 0;

		// Not good, this can deadlock if not called in the correct order. Depending on use case, should add a movement substate and break out from attack sequence substates.
		if (PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::SpawningSpikeBombs) // Could have advanced substate already in OnActivated
			PhaseComp.TryActivateNextAttackState();

		UnblockMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PhaseComp.RemainingActionDuration = MinActiveDuration - ActiveDuration;
		if (Settings.SpikeBombSpawnInitialDelay < ActiveDuration && !bHasStartedSpawning)
		{
			// Start spawner
			bHasStartedSpawning = true;
			SpawnPattern.ActivatePattern(this);
		}
	}


	private void UnblockMovement()
	{
		if (bIsBlockingMovement)
		{
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
			bIsBlockingMovement = false;
		}
	}
}