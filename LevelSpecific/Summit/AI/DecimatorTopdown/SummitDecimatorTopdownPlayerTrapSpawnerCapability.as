class USummitDecimatorTopdownPlayerTrapSpawnerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USummitDecimatorTopdownSettings Settings;
	UBasicAIHealthComponent HealthComp;
	USummitDecimatorTopdownPhaseComponent PhaseComp;
	USummitDecimatorTopdownPlayerTargetComponent TargetComp;
	UBasicAIAnimationComponent AnimComp;

	AAISummitDecimatorTopdown Decimator;
	ASummitDecimatorTopdownPlayerTrap PlayerTrap;
	float InitialDelay;
	bool bIsBlockingMovement = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		TargetComp = USummitDecimatorTopdownPlayerTargetComponent::Get(Owner);
		TargetComp.Init();
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);		

		InitialDelay = 2.0;

		PlayerTrap = SpawnActor(Decimator.PlayerTrapClass, bDeferredSpawn = true);
		PlayerTrap.MakeNetworked(this, n"PlayerTrap");
		PlayerTrap.SetTarget(TargetComp.Target);
		// Set reference for easy access in BPs and sounddef
		PlayerTrap.Decimator = Decimator;
		FinishSpawningActor(PlayerTrap);
		PlayerTrap.DecimatorPhaseComp = PhaseComp;		
		PlayerTrap.RespawnComp.OnUnspawn.AddUFunction(this, n"OnTrapUnspawned");
		PlayerTrap.SetActorControlSide(TargetComp.Target);
		PlayerTrap.AddActorDisable(this);

		// Set reference for easy access in BPs. and sounddef
		Decimator.PlayerTrap = PlayerTrap;
	}

	// Crumbed from invoker
	UFUNCTION()
	private void OnTrapUnspawned(AHazeActor RespawnableActor)
	{
		// Change target and controlside
		TargetComp.SwitchTarget();
		PlayerTrap.SetActorHiddenInGame(true); // Hack: make sure that crystal mesh is not flashing by for one frame.
		PlayerTrap.SetTarget(TargetComp.Target);		
		PhaseComp.bHasActivePlayerTrap = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return false;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::TrappingPlayer)
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
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return true;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::TrappingPlayer)
			return true;
		if (PhaseComp.bHasActivePlayerTrap)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// temp
		DecimatorTopdown::Animation::RequestFeatureSpikeBombSpawning(AnimComp, this);

		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		bIsBlockingMovement = true;
		
		PlayerTrap.SetActorControlSide(TargetComp.Target); // Update control side to match current target.
		
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Activated Substate: Player Trap", 5.0, Color=FLinearColor::Yellow);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnimComp.ClearFeature(this);

		if (PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::SpawningSpikeBombs)
			PhaseComp.TryActivateNextAttackState();

		PhaseComp.TryActivateNextAttackState();

		UnblockMovement();
	}

	const float AttackDuration = 1.1;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		PhaseComp.RemainingActionDuration = AttackDuration - ActiveDuration;

		if (HasControl() && AttackDuration < ActiveDuration && !PhaseComp.bHasActivePlayerTrap)
		{
			CrumbActivateTrap();	
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

	UFUNCTION(CrumbFunction)
	private void CrumbActivateTrap()
	{
		PhaseComp.bHasActivePlayerTrap = true;
		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Spawner = this;
		PlayerTrap.RespawnComp.OnSpawned(Owner, SpawnParams);
		PlayerTrap.SetTarget(TargetComp.Target);
		
		PlayerTrap.LaunchLocation = Decimator.HeadCapsuleComponent.WorldLocation;
		PlayerTrap.LaunchVelocity = Decimator.ActorForwardVector * 1000;
		PlayerTrap.RemoveActorDisable(this);
	}
}