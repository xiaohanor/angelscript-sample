
class UIslandWalkerSuspendedSpawnBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandWalkerSettings WalkerSettings;
	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerSpawnerComponent SpawnerComp;
	UHazeActorSpawnerComponent MinionSpawnerComp;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerSpawnPattern SpawnPattern;
	UIslandWalkerSettings Settings;

	FBasicAIAnimationActionDurations Durations;

	// Spawn points are always used in this order by this behaviour
	TArray<UWalkerSpawnPointComponent> OrderedSpawnPoints;
	int NumSpawned = 0;
	int NumToSpawn = 0;
	TArray<float32> SpawnTimes;
	TArray<UWalkerSpawnPointComponent> SpawnOrder;
	float StartSpawningTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		WalkerSettings = UIslandWalkerSettings::GetSettings(Owner);
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);
		SpawnerComp = UIslandWalkerSpawnerComponent::GetOrCreate(Owner);
		SpawnPattern = UIslandWalkerSpawnPattern::Get(Owner);
		MinionSpawnerComp = UHazeActorSpawnerComponent::Get(Owner);
		
		TArray<UWalkerSpawnPointComponent> AllSpawnPoints; 
		Owner.GetComponentsByClass(UWalkerSpawnPointComponent, AllSpawnPoints);

		OrderedSpawnPoints.SetNumZeroed(AllSpawnPoints.Num());
		for (int i = 0; i < AllSpawnPoints.Num(); i++)
		{
			OrderedSpawnPoints[MapSpawnPointOrder(AllSpawnPoints[i].Index)] = AllSpawnPoints[i];
		}
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
		if (WalkerComp.NumSuspendedSprayGasWithNoSpawn < Settings.SuspendedSpawnSprayGasCount)
			return false;
		if (Time::GameTimeSeconds < SpawnerComp.SpawnCooldown)
			return false;
		if (Time::GetGameTimeSince(WalkerComp.SuspendIntroCompleteTime) < 8.0)
		 	return false;
		UHazeTeam MinionTeam = MinionSpawnerComp.GetSpawnedActorsTeam();
		if ((MinionTeam != nullptr) && (MinionTeam.GetMembers().Num() > Settings.RespawnMaxActiveMinions))
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.SuspendedSpawnPrePauseDuration + Durations.GetTotal() + Settings.SuspendedSpawnPostPauseDuration)
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
		WalkerComp.NumSuspendedSprayGasWithNoSpawn = 0;

		Durations.Telegraph = Settings.StandingSpawnTelegraphDuration;
		Durations.Anticipation = Settings.StandingSpawnAnticipationDuration;
		Durations.Action = Settings.StandingSpawnActionDuration;
		Durations.Recovery = Settings.StandingSpawnRecoveryDuration;
		WalkerAnimComp.FinalizeDurations(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Spawning, Durations);

		// Short pause before we let slip the buzzers of war
		AnimComp.RequestAction(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Idle, EBasicBehaviourPriority::Medium, this, Durations);
		StartSpawningTime = Settings.SuspendedSpawnPrePauseDuration;

		SpawnPattern.ActivatePattern(this);

		// Check when and from where we should spawn minions during action duration (when mh spawn anim is being played)
		NumSpawned = 0;
		NumToSpawn = Settings.SuspendedMaxSpawnCount;
		UAnimSequence SpawnAnim = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Spawning);
		SpawnAnim.GetAnimNotifyTriggerTimes(UWalkerSpawnAnimNotify, SpawnTimes);
		int NumAnimSpawn = SpawnTimes.Num();

		SpawnOrder = OrderedSpawnPoints; 
		SpawnTimes.SetNum(NumToSpawn);
		for (int i = NumAnimSpawn; i < NumToSpawn; i++)
		{
			// Any additional spawn will occur as an aditional wave at last spawn opportunity
			SpawnTimes[i] = SpawnTimes[i - 1]; 
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		SpawnPattern.ClearPatternActivation(this);
		SpawnerComp.SpawnCooldown = Time::GameTimeSeconds + Settings.SuspendedSpawnCooldown;
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
		if (ActiveDuration > StartSpawningTime)
		{
			AnimComp.RequestAction(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Spawning, EBasicBehaviourPriority::Medium, this, Durations);
			StartSpawningTime = BIG_NUMBER;
		}

		// Spawn when appropriate
		float LapsedSpawnTime = ActiveDuration - Settings.SuspendedSpawnPrePauseDuration;
		if ((NumSpawned < NumToSpawn) && (SpawnTimes[NumSpawned] < LapsedSpawnTime))
		{
			SpawnerComp.PendingSpawnPoints.Add(SpawnOrder[NumSpawned % SpawnOrder.Num()]);
			NumSpawned++;	
		}			
	}
}