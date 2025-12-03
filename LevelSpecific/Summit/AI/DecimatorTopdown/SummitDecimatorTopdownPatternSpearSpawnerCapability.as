class USummitDecimatorTopdownPatternSpearSpawnerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USummitDecimatorTopdownSettings Settings;
	USummitDecimatorTopdownSpearLauncherComponent SpearLauncherComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	USummitDecimatorTopdownPhaseComponent PhaseComp;

	ASummitDecimatorTopdownSpearManager SpearManager;
	AAISummitDecimatorTopdown Self;

	float NextSpawnTime;
	float AnimationDuration = 0.9;
	bool bIsBatchSpawning;
	bool bHasFinished = false;
	bool bHasSpawnedFirstSpear = false;
	int CurrentPhase;
	float TurnDuration = 0;
	bool bIsBlockingMovement = false;
	float Interval;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Self = Cast<AAISummitDecimatorTopdown>(Owner);		
		SpearManager = Self.SpearManager;
		SpearManager.OnSpawnParamsUpdated.AddUFunction(this, n"UpdateInterval");

		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);

		SpearLauncherComp = USummitDecimatorTopdownSpearLauncherComponent::Get(Owner);	
		
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
	}

	UFUNCTION()
	private void Spawn()
	{
		if (!SpearManager.HasNextSpawnLocation())
		{
			bHasFinished = true;
		}
		else
		{
			FVector SpawnLocation = SpearManager.GetNextSpawnLocation() + FVector::UpVector * -(350*5*.5 + 70);
			ASummitDecimatorTopdownSpear SpearProjectile = Cast<ASummitDecimatorTopdownSpear>(SpearLauncherComp.SpawnProjectile(SpawnLocation));
			SpearProjectile.SpawnLocation = SpawnLocation;
			
			if(!bHasSpawnedFirstSpear)
			{

				USummitDecimatorTopdownEffectsHandler::Trigger_OnTelegraphNewSpearShower(Owner);
				SpearProjectile.bFirstSpearInWave = true;
			}
		}

		bHasSpawnedFirstSpear = true;
	}

	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return false;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::SpawningSpearShower)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HealthComp.IsDead())
			return true;
		if (CurrentPhase != PhaseComp.CurrentPhase)
			return true;
		if (PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return true;
		if (bHasFinished)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		bIsBlockingMovement = true;
		bHasSpawnedFirstSpear = false;
		SpearManager.bIsSpawningSpears = true;
		
		Interval = SpearManager.CurrentSpawnDelayInterval;
		
		TurnDuration = 0; // reset
		if (PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::Running)
			TurnDuration = 90 / Settings.DecimatorTurnRate;

		PhaseComp.TryActivateNextAttackState(); // this attack should be able to run simultaneously as other attacks
		CurrentPhase = PhaseComp.CurrentPhase; // there is an edge case when activated just before begin hit by spikebomb

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Activated Substate: Spear Shower", 5.0, Color=FLinearColor::Yellow);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		bHasFinished = false;
		AnimComp.ClearFeature(this);
		SpearManager.NextPattern(); // Next PatternGroup set active
		SpearManager.bIsSpawningSpears = false;
		UnblockMovement();

		USummitDecimatorTopdownEffectsHandler::Trigger_OnSpearShowerFinished(Owner);
	}


	UFUNCTION(NotBlueprintCallable)
	void UpdateInterval(float SpawnInterval)
	{
		Interval = SpawnInterval;
	}
	
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > AnimationDuration + TurnDuration)
		{
			// Animation finished
			AnimComp.ClearFeature(this);
			UnblockMovement();
		}
		else if (ActiveDuration > TurnDuration)
		{
			// Run animation
			DecimatorTopdown::Animation::RequestFeatureSpearSpawning(AnimComp, this);
		}
		else
		{
			// Prevent spawning until animation has run
			return;
		}

		// Batch Spawn
		if (SpearManager.bIsBatchSpawning)
		{
			while (!bHasFinished) // temp
			{
				Spawn();
			}

		}
		// Interval Spawn
		else if (NextSpawnTime < Time::GetGameTimeSeconds())
		{
			Spawn();
			NextSpawnTime = Time::GetGameTimeSeconds() + Interval;
		}
		
		// temp, skip to next state if trying to activate this already active state. Might need to crumb this, such as HasControl() -> CrumbTryActivateNextAttackState().
		if (PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::SpawningSpearShower)
			PhaseComp.TryActivateNextAttackState(); 
	}

	void UnblockMovement()
	{
		if (bIsBlockingMovement)
		{
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
			bIsBlockingMovement = false;
		}
	}
}