class UIslandWalkerDefensiveSpawnBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UIslandWalkerSettings WalkerSettings;
	AAIIslandWalker Walker;
	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerSpawnerComponent SpawnerComp;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerSwivelComponent Swivel;
	UIslandWalkerSpawnPattern SpawnPattern;
	UIslandWalkerSettings Settings;

	FBasicAIAnimationActionDurations Durations;
	bool bShouldProtectLegs = false;

	// Spawn points are always used in this order by this behaviour
	TArray<UWalkerSpawnPointComponent> OrderedSpawnPoints;
	int NumSpawned = 0;
	int NumToSpawn = 0;
	TArray<float32> SpawnTimes;
	TArray<UWalkerSpawnPointComponent> SpawnOrder;

	bool bHasTurned = false;
	float CompletedTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		WalkerSettings = UIslandWalkerSettings::GetSettings(Owner);
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Walker = Cast<AAIIslandWalker>(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);
		SpawnerComp = UIslandWalkerSpawnerComponent::GetOrCreate(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		SpawnPattern = UIslandWalkerSpawnPattern::Get(Owner);
		LegsComp.OnLegDestroyed.AddUFunction(this, n"OnLegDestroyed");

		TArray<UWalkerSpawnPointComponent> AllSpawnPoints; 
		Owner.GetComponentsByClass(UWalkerSpawnPointComponent, AllSpawnPoints);

		OrderedSpawnPoints.SetNumZeroed(AllSpawnPoints.Num());
		for (int i = 0; i < AllSpawnPoints.Num(); i++)
		{
			OrderedSpawnPoints[MapSpawnPointOrder(AllSpawnPoints[i].Index)] = AllSpawnPoints[i];
		}
	}

	UFUNCTION()
	private void OnLegDestroyed(AIslandWalkerLegTarget Leg)
	{
		if (LegsComp.NumDestroyedLegs() == 1)
			SpawnerComp.bAllowSpawning = true;
		bShouldProtectLegs = true;
	}

	int MapSpawnPointOrder(int Index)
	{
		// Hard code order to 5,2,4,1,3,0 (which is current order in animation)
		switch (Index)
		{
			case 0: return 5;
			case 1: return 3;
			case 2: return 1;
			case 3: return 4;
			case 4: return 2;
			case 5: return 0;
		}
		return -1;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!bShouldProtectLegs)
			return false;
		if (!SpawnerComp.bAllowSpawning)
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > CompletedTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		WalkerComp.LastAttack = EISlandWalkerAttackType::Spawn;
		SpawnerComp.OnStart.Broadcast();
		LegsComp.HideLegs();
		bHasTurned = false;

		Durations.Telegraph = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::Spawner, SubTagWalkerSpawner::ProtectingLegs, Settings.DefensiveSpawnTelegraphDuration);
		Durations.Anticipation = 0.0; // Not used
		Durations.Action = Settings.DefensiveSpawnDuration;
		Durations.Recovery = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::Spawner, SubTagWalkerSpawner::ProtectingLegsEnd, Settings.DefensiveSpawnRecoveryDuration);
		AnimComp.RequestFeature(FeatureTagWalker::Spawner, SubTagWalkerSpawner::ProtectingLegs, EBasicBehaviourPriority::Medium, this, Durations.Telegraph);
		CompletedTime = Durations.GetTotal(); // This will be increased if/when we decide to end with a turn

		SpawnPattern.ActivatePattern(this);

		// Check when and from where we should spawn minions during action duration (when mh spawn anim is being played)
		NumSpawned = 0;
		NumToSpawn = Settings.SpawningMaxSpawnCount;
		if (LegsComp.NumDestroyedLegs() > 1)
			NumToSpawn += Settings.SpawningAdditionalMaxSpawnCount;
		UAnimSequence SpawnAnim = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::Spawner, SubTagWalkerSpawner::ProtectingLegsSpawning);
		int FullLoops = Math::TruncToInt(Durations.Action / SpawnAnim.PlayLength); 
		SpawnAnim.GetAnimNotifyTriggerTimes(UWalkerSpawnAnimNotify, SpawnTimes);
		int NumSpawnTimesPerLoop = SpawnTimes.Num();
		int NumAnimSpawn = NumSpawnTimesPerLoop * FullLoops;
		float RemainderTime = Durations.Action - (FullLoops * SpawnAnim.PlayLength);
		for (int i = 0; i < NumSpawnTimesPerLoop; i++)
		{
			if (SpawnTimes[i] > RemainderTime)
				break; // No furher spawn time will be reached
			NumAnimSpawn++;
		}

		// Spawn at every opportunity 
		SpawnOrder = OrderedSpawnPoints; 
		SpawnTimes.SetNumZeroed(NumToSpawn);
		if (ensure(NumSpawnTimesPerLoop > 0, "Spawn anim does not have any Spawn anim notifies."))
		{
			SpawnTimes.SetNum(NumToSpawn);
			for (int i = NumSpawnTimesPerLoop; i < NumToSpawn; i++)
			{
				int iMod = i % NumSpawnTimesPerLoop;
				int iLoop = Math::IntegerDivisionTrunc(i, NumSpawnTimesPerLoop); 
				SpawnTimes[i] = iLoop * SpawnAnim.PlayLength + SpawnTimes[iMod]; 
			}
		}
		check(NumAnimSpawn >= NumToSpawn, "Walker has too few spawn opportunities in anim, some fake ones will occur during recovery or even as a batch on deactivation");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bShouldProtectLegs = false;
		SpawnPattern.ClearPatternActivation(this);
		SpawnerComp.SpawnCooldown = Time::GameTimeSeconds + Settings.SpawningCooldown;
		SpawnerComp.OnStop.Broadcast();

		// Spawn any stragglers
		for (int i = NumSpawned; i < NumToSpawn; i++)
		{
			SpawnerComp.PendingSpawnPoints.Add(SpawnOrder[i % SpawnOrder.Num()]);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Swivel.Realign(Durations.Telegraph, DeltaTime);	

		float SpawningDuration = ActiveDuration - Durations.GetPreActionDuration();
		if (Durations.IsInActionRange(ActiveDuration) && (SpawnTimes.Num() > 0))
		{
			if (SpawningDuration < SpawnTimes.Last() + 0.5)
				AnimComp.RequestFeature(FeatureTagWalker::Spawner, SubTagWalkerSpawner::ProtectingLegsSpawning, EBasicBehaviourPriority::Medium, this);
			else
				AnimComp.RequestFeature(FeatureTagWalker::Spawner, SubTagWalkerSpawner::ProtectingLegsMH, EBasicBehaviourPriority::Medium, this);
		}
		if (Durations.IsInRecoveryRange(ActiveDuration) && !bHasTurned)
			AnimComp.RequestFeature(FeatureTagWalker::Spawner, SubTagWalkerSpawner::ProtectingLegsEnd, EBasicBehaviourPriority::Medium, this, Durations.Recovery);

		// Spawn when appropriate
		if ((NumSpawned < NumToSpawn) && (SpawnTimes[NumSpawned] < SpawningDuration))
		{
			SpawnerComp.PendingSpawnPoints.Add(SpawnOrder[NumSpawned % SpawnOrder.Num()]);
			NumSpawned++;	
		}		

		if ((ActiveDuration > Durations.GetTotal() - 0.8) && !bHasTurned && HasControl())
		{
			// Turn to make players have to reposition
			CrumbTurn(Math::RandBool());
		}	
	}

	UFUNCTION(CrumbFunction)
	void CrumbTurn(bool bLeft)
	{
		bHasTurned = true;

		FName TurnTag = bLeft ? SubTagWalkerTurn::Left90 : SubTagWalkerTurn::Right90;
		AnimComp.RequestFeature(FeatureTagWalker::Turn, TurnTag, EBasicBehaviourPriority::Medium, this);
		WalkerAnimComp.HeadAnim.RequestFeature(FeatureTagWalker::Turn, TurnTag, EBasicBehaviourPriority::Medium, this);
	
		float TurnDuration = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::Turn, TurnTag, 0.0);
		CompletedTime = ActiveDuration + TurnDuration;
	}
}