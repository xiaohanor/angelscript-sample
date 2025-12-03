struct FIslandWalkerFallParams
{
	EIslandWalkerUnbalancedDirection FallDirection;
}

class UIslandWalkerFallBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerNeckRoot NeckRoot;
	UIslandWalkerSpawnerComponent SpawnerComp;
	UIslandWalkerSwivelComponent Swivel;
	UIslandWalkerSettings Settings;
	AIslandWalkerArenaLimits Arena;
	bool bFell;
	UHazeTeam SpawnTeam;
	float DestroySpawnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);
		NeckRoot = UIslandWalkerNeckRoot::Get(Owner);
		SpawnerComp = UIslandWalkerSpawnerComponent::GetOrCreate(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
		Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandWalkerFallParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!LegsComp.bIsUnbalanced)
			return false;
		if(bFell)
			return false;
		OutParams.FallDirection = LegsComp.UnbalancedDirection;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.WalkingFallDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandWalkerFallParams Params)
	{
		Super::OnActivated();

		// Net sync fall direction
		LegsComp.UnbalancedDirection = Params.FallDirection;
		
		RequestAnims();

		LegsComp.PowerDownLegs();

		SpawnerComp.bAllowSpawning = false;
		SpawnTeam = HazeTeam::GetTeam(IslandBuzzerTags::IslandBuzzerTeam);
		DestroySpawnTime = (SpawnTeam == nullptr) ? BIG_NUMBER : Settings.WalkingFallDuration * 0.5;

		Arena.OnPhaseChange.Broadcast(EIslandWalkerPhase::WalkingCollapse);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bFell = true;

		// Destroy any remaining spawn
		if (SpawnTeam != nullptr)
		{
			for (AHazeActor Spawn : SpawnTeam.GetMembers())
			{
				if (Spawn == nullptr)
					continue;
				UBasicAIHealthComponent::Get(Spawn).TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
			}
		}

		// Time to get hoisted up
		PhaseComp.Phase = EIslandWalkerPhase::Suspended;
		AnimComp.SetBaseAnimationTag(FeatureTagWalker::Suspended, this);
	}

	private void RequestAnims()
	{
		if (LegsComp.UnbalancedDirection == EIslandWalkerUnbalancedDirection::Left)
			AnimComp.RequestFeature(FeatureTagWalker::Fall, SubTagWalkerFall::Left, EBasicBehaviourPriority::High, this);
		else if (LegsComp.UnbalancedDirection == EIslandWalkerUnbalancedDirection::Right)
			AnimComp.RequestFeature(FeatureTagWalker::Fall, SubTagWalkerFall::Right, EBasicBehaviourPriority::High, this);
		else 
			AnimComp.RequestFeature(FeatureTagWalker::Fall, SubTagWalkerFall::Forward, EBasicBehaviourPriority::High, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestroySpawn();
		Swivel.Realign(Settings.WalkingFallDuration * 0.25, DeltaTime);	

		if (NeckRoot.Head.bIsPoweredUp && (ActiveDuration > Settings.WalkingFallDuration - 3.0))
			NeckRoot.Head.PowerDown();	
	}

	void DestroySpawn()
	{
		if (ActiveDuration < DestroySpawnTime) 
			return;
		if (SpawnTeam == nullptr)
			return;	
		DestroySpawnTime = BIG_NUMBER; // Set to valid time below if there are more than one member left
		TArray<AHazeActor> Members = SpawnTeam.GetMembers();
		if (Members.Num() == 0)
			return;

		// Time to kill another of our spawn
		if (Members.Num() > 1)
			DestroySpawnTime = ActiveDuration + ((Settings.WalkingFallDuration - ActiveDuration - 0.5) / (Members.Num() - 1));
		for (AHazeActor Spawn : SpawnTeam.GetMembers())
		{
			if (Spawn == nullptr)
				continue;
			auto HealthComp = UBasicAIHealthComponent::Get(Spawn);
			if (HealthComp.IsDead())
				continue;
			HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
			break;
		}
	}
}