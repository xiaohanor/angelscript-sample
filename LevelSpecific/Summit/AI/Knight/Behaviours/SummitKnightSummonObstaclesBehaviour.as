class USummitKnightSummonObstaclesBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USummitKnightSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	USummitKnightAnimationComponent KnightAnimComp;
	
	int NumSpawnedObstacles;
	FAreaDenialZoneObstacleSpawnParameters ObstacleParams;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);

		// Randomize starting obstacle variants. This is replicated along with other obstacle spawn params.
		ObstacleParams.MetalVariant = Math::RandRange(0, 5);
		ObstacleParams.CrystalVariant = Math::RandRange(0, 5);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAreaDenialZoneObstacleSpawnParameters& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		SetupObstacleSpawnParameters(OutParams);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAreaDenialZoneObstacleSpawnParameters Params)
	{
		Super::OnActivated();
		ObstacleParams = Params;
		NumSpawnedObstacles = 0;

		Durations.Telegraph = Settings.SummonObstaclesTelegraphDuration;
		Durations.Anticipation = Settings.SummonObstaclesAnticipationDuration;
		Durations.Action = Settings.SummonObstaclesActionDuration;
		Durations.Recovery = Settings.SummonObstaclesRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SummonObstacles, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::SummonObstacles, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		// Spawn any remaining obstacles (unlikely but might happen on remote or due to interrupting behaviour)
		for (int i = NumSpawnedObstacles; i < ObstacleParams.Zones.Num(); i++)
		{
			SpawnObstacle();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > ObstacleParams.SpawnTime)
			SpawnObstacle();
	}

	void SetupObstacleSpawnParameters(FAreaDenialZoneObstacleSpawnParameters& OutParams) const
	{
		OutParams.Zones.Reset(Settings.SummonObstaclesNumber);		

		// Random selection of zones for now
		TArray<ASummitKnightAreaDenialZone> Zones = TListedActors<ASummitKnightAreaDenialZone>().Array;
		Zones.Shuffle();
		for (ASummitKnightAreaDenialZone Zone : Zones)
		{
			if (Zone.HasActiveObstacle())
				continue; // Already in use

			OutParams.Zones.Add(Zone);
			if (OutParams.Zones.Num() >= Settings.SummonObstaclesNumber)
				break; // We've got enough zones
		}

		if (OutParams.Zones.Num() == 0)
		{
			// Nothing to spawn
			OutParams.SpawnTime = BIG_NUMBER;
			OutParams.Reset(Settings.SummonObstaclesNumber);
		}
		else
		{	
			OutParams.SpawnTime = 0.0; 
			float SpawnDuration = 1.0;
			UAnimSequence SummonAnim = KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::SummonObstacles, NAME_None);
			TArray<FHazeAnimNotifyStateGatherInfo> ActionInfo;
			if (ensure(SummonAnim != nullptr) && SummonAnim.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, ActionInfo) && (ActionInfo.Num() > 0))
			{
				OutParams.SpawnTime = ActionInfo[0].TriggerTime;
				SpawnDuration = ActionInfo[0].Duration;
			}

			OutParams.SpawnInterval = SpawnDuration / Math::Max(1.0, float(OutParams.Zones.Num() - 1));

			// Variants are randomized on setup and then incremented. This ensures they get replicated to remote.
			OutParams.MetalVariant = ObstacleParams.MetalVariant;
			OutParams.CrystalVariant = ObstacleParams.CrystalVariant;
		}
	}	

	void SpawnObstacle()
	{
		if (ensure(ObstacleParams.Zones.IsValidIndex(NumSpawnedObstacles)))
		{
			// Start with metal obstacles as they hinder tail dragon, then alternate
			if (NumSpawnedObstacles % 2 == 0)
			{
				ObstacleParams.Zones[NumSpawnedObstacles].MetalObstacle.SpawnObstacle(ObstacleParams.MetalVariant, Owner);
				ObstacleParams.MetalVariant++;
			}
			else
			{
				ObstacleParams.Zones[NumSpawnedObstacles].CrystalObstacle.SpawnObstacle(ObstacleParams.CrystalVariant);
				ObstacleParams.CrystalVariant++;
			}
		}

		NumSpawnedObstacles++;
		if (ObstacleParams.Zones.IsValidIndex(NumSpawnedObstacles))
			ObstacleParams.SpawnTime += ObstacleParams.SpawnInterval;
		else
			ObstacleParams.SpawnTime = BIG_NUMBER;
	}
}

