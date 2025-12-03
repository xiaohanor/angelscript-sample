struct FWalkerSuspendedFallDownBehaviourParams
{
	FName Reaction;
}

class UIslandWalkerSuspendedFallDownBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerNeckRoot NeckRoot;
	TArray<UIslandWalkerCablesTargetRoot> CablesTargetRoots;
	UIslandWalkerSettings Settings;

	UHazeTeam SpawnTeam;
	float DestroySpawnTime;
	
	bool bFalling = false;
	float StartFallingTime;
	TArray<AHazeActor> AttackBlockedActors;

	float AnimDuration = 2.0;
	float BreakCableTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		NeckRoot = UIslandWalkerNeckRoot::Get(Owner);
		Owner.GetComponentsByClass(CablesTargetRoots);
		UIslandWalkerPhaseComponent::Get(Owner).OnSkipIntro.AddUFunction(this, n"OnSkipIntro");
		check(CablesTargetRoots.Num() > 0); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWalkerSuspendedFallDownBehaviourParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		for (UIslandWalkerCablesTargetRoot Root : CablesTargetRoots)
		{
			if ((Root.Target == nullptr) || !Root.Target.bCablesTargetDestroyed)
				return false;
		}
		if (WalkerComp.bFrontCableCut)
			OutParams.Reaction = SubTagWalkerSuspended::FallDownFrontFirst;
		else 
			OutParams.Reaction = SubTagWalkerSuspended::FallDownRearFirst;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > AnimDuration - Settings.SuspendedEndingDurationReduction)
			return true;
		return false; 
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWalkerSuspendedFallDownBehaviourParams Params)
	{
		Super::OnActivated();

		AnimDuration = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::Suspended, Params.Reaction).PlayLength;

		// Request animation with SuspendedInstigator so we won't clear request on deactivation
		AnimComp.RequestFeature(FeatureTagWalker::Suspended, Params.Reaction, EBasicBehaviourPriority::High, IslandWalker::SuspendedInstigator);

		NeckRoot.Head.HeadComp.bSubmerged = false;

		// Spawn should stop attacking and will be autodestroyed when walker falls	
		SpawnTeam = UHazeActorSpawnerComponent::Get(Owner).SpawnedActorsTeam;
		if (SpawnTeam != nullptr)
		{
			DestroySpawnTime = Math::Min(3.0, AnimDuration * 0.5);
			AttackBlockedActors = SpawnTeam.GetMembers();
			for (AHazeActor Spawn : AttackBlockedActors)
			{
				if (!IsValid(Spawn))
					continue;
				Spawn.BlockCapabilities(BasicAITags::Attack, this);
			}
		}

		bFalling = false;
		StartFallingTime = 0.5;
		BreakCableTime = 0.4;

		WalkerComp.ArenaLimits.OnPhaseChange.Broadcast(EIslandWalkerPhase::SuspendedFall);	
		WalkerComp.ArenaLimits.OnSuspendedFallStart.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		// Allow any spawn to attack again. Then kill them! Muahahahaha!
		for (AHazeActor Spawn : AttackBlockedActors)
		{
			if (!IsValid(Spawn))
				continue;
			if (Spawn.IsCapabilityTagBlocked(BasicAITags::Attack))
				Spawn.UnblockCapabilities(BasicAITags::Attack, this);
			UBasicAIHealthComponent::Get(Spawn).TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
		}

		CompleteFall();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bFalling && (ActiveDuration > StartFallingTime))
			bFalling = true;

		FVector SuspendLocation = WalkerComp.GetSuspendLocation();
		SuspendLocation.Z -= Settings.SuspendHeight * (ActiveDuration / AnimDuration);
		FVector ClampedLoc = WalkerComp.ArenaLimits.ClampToInnerArena(SuspendLocation);
		ClampedLoc.Z = SuspendLocation.Z;	
		DestinationComp.MoveTowardsIgnorePathfinding(ClampedLoc, Settings.SuspendAcceleration);

		if (!NeckRoot.Head.HeadComp.bSubmerged && NeckRoot.Head.ActorLocation.Z < WalkerComp.ArenaLimits.PoolSurfaceHeight)
		{
			// Head has just fallen into pool
			NeckRoot.Head.HeadComp.bSubmerged = true;
			FIslandWalkerPoolSurfaceParams Params;
			Params.SurfaceLocation = NeckRoot.Head.ActorLocation;
			Params.SurfaceLocation.Z = WalkerComp.ArenaLimits.PoolSurfaceHeight;
			UIslandWalkerHeadEffectHandler::Trigger_OnIntroFallIntoPool(NeckRoot.Head, Params);				
		}

		if (ActiveDuration > DestroySpawnTime)
		{
			DestroySpawnTime = BIG_NUMBER;
			if (SpawnTeam != nullptr)
			{
				for (AHazeActor Spawn : SpawnTeam.GetMembers())
				{
					if (!IsValid(Spawn))
						continue;
					UBasicAIHealthComponent::Get(Spawn).TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
					DestroySpawnTime = ActiveDuration + Math::RandRange(0.3, 0.8);
					break;
				}
			}
		}

		if (ActiveDuration > BreakCableTime)
			BreakCable();
	}

	void BreakCable()
	{
		for (AIslandWalkerSuspensionCable Cable : WalkerComp.DeployedCables)
		{
			if (!Cable.bBroken)
			{
				Cable.Break();
				BreakCableTime += Math::RandRange(0.4, 0.8);
				return;
			}
		}

		// All cables are broken
		BreakCableTime = BIG_NUMBER;
	}

	void CompleteFall()
	{
		// Off with their head!
		NeckRoot.SwapHead();
		NeckRoot.DetachHead();
	}

	UFUNCTION()
	private void OnSkipIntro(EIslandWalkerPhase NewPhase)
	{
		if ((NewPhase != EIslandWalkerPhase::Decapitated) && (NewPhase != EIslandWalkerPhase::Swimming))
			return;

		for (AIslandWalkerSuspensionCable Cable : WalkerComp.DeployedCables)
		{
			Cable.Break();
			Cable.Update(100.0);
		}
		Owner.TeleportActor(WalkerComp.ArenaLimits.PoolSurface.WorldLocation, Owner.ActorRotation, this);
		AnimComp.RequestFeature(FeatureTagWalker::AtBottomOfPool, EBasicBehaviourPriority::High, IslandWalker::SuspendedInstigator);
		UIslandWalkerLegsComponent::Get(Owner).PowerDownLegs();
		for (UIslandWalkerCablesTargetRoot Root : CablesTargetRoots)
		{
			Root.Target.PowerDown();
		}
		CompleteFall();
		NeckRoot.Head.TeleportActor(WalkerComp.ArenaLimits.PoolSurface.WorldLocation - FVector(0.0, 0.0, 1000.0), Owner.ActorRotation, this);
	}
}
