class USummitDecimatorTopdownSpinSpikebombSpawnerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USummitDecimatorTopdownSettings Settings;
	UHazeActorSpawnerComponent SpawnComp;
	UHazeActorSpawnPatternInterval SpawnPattern;
	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	USummitDecimatorTopdownPhaseComponent PhaseComp;

	float InitialDelay;
	float MinActiveDuration = 7.0;

	int NumCurrentSpikeBombs = 0;
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

		SpawnPattern = Decimator.SpinSpikeBombSpawnPattern;		
		SpawnPattern.Interval = Settings.SpikeBombSpawnInterval;
		SpawnPattern.bInfiniteSpawn = true;
		SpawnPattern.MaxActiveSpawnedActors = Settings.SpikeBombMaxSpawnCount;
		
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		
		InitialDelay = 2.0;
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
		FVector AimDir = SomeRotation.UpVector * -1.0;
		UHazeMovementComponentBase MoveComp = UHazeMovementComponentBase::Get(SpawnedActor);
		MoveComp.Reset();		 
		
		// Stop spawning when max count is hit. PhaseComp will switch AttackState when count reaches 0 later.
		NumCurrentSpikeBombs++;
		NumSpawnedSpikeBombs++;
		if (NumSpawnedSpikeBombs >= Settings.SpikeBombMaxSpawnCount)
		{
			SpawnPattern.DeactivatePattern(this);			
		}

		if (NumCurrentSpikeBombs == 1)
			SpawnedActor.AddMovementImpulse( AimDir * Settings.SpikeBombSpawnImpulsePhaseThree1 );
		else if (NumCurrentSpikeBombs == 2)
			SpawnedActor.AddMovementImpulse( AimDir * Settings.SpikeBombSpawnImpulsePhaseThree2 );
		else if (NumCurrentSpikeBombs == 3)
			SpawnedActor.AddMovementImpulse( AimDir * Settings.SpikeBombSpawnImpulsePhaseThree3 );

		USummitDecimatorSpikeBombEffectsHandler::Trigger_OnSpawned(SpawnedActor, FSummitDecimatorSpikeBombLaunchParams(SpawnedActor.ActorCenterLocation, AimDir));
	}

	
	UFUNCTION()
	private void OnPostUnspawn(AHazeActor UnspawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (SpawningPattern != SpawnPattern)
			return;

		NumCurrentSpikeBombs--;
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
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::ChargingAndSpawningSpikeBombs) // temp
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
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::ChargingAndSpawningSpikeBombs)
			return true;
		if (NumSpawnedSpikeBombs >= Settings.SpikeBombMaxSpawnCount && ActiveDuration > MinActiveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
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
		bHasStartedSpawning = false;
		NumSpawnedSpikeBombs = 0;		

		if (PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::SpawningSpikeBombs) // Could have advanced substate already in OnActivated
			PhaseComp.TryActivateNextAttackState();

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (InitialDelay < ActiveDuration && !bHasStartedSpawning)
		{
			// Start spawner
			bHasStartedSpawning = true;
			SpawnComp.SetComponentTickEnabled(true);
			SpawnPattern.ActivatePattern(this);
		}
	}
	
}