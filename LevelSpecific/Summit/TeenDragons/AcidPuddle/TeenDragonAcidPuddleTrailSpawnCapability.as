class UTeenDragonAcidPuddleTrailSpawnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	//ATeenDragon TeenDragon;
	UTeenDragonAcidPuddleContainerComponent PuddleComponent;
	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;
	FVector LastDroppedLocation;
	float NextDropTime = 0;
	float NextDropDistance = 0;
	ATeenDragonAcidPuddleTrail PreviousHead;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//TeenDragon = Cast<ATeenDragon>(Owner);
		PuddleComponent = UTeenDragonAcidPuddleContainerComponent::GetOrCreate(Player);
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PuddleComponent.CollectedAcidAlpha <= 0)
			return false;

		if(!RollComp.IsRolling())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PuddleComponent.CollectedAcidAlpha <= 0)
			return true;
		
		if(!RollComp.IsRolling())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		LastDroppedLocation = Player.ActorLocation;	

		// Initial delay so we have time to enter the roll
		NextDropTime = Time::GameTimeSeconds + 2;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(PreviousHead != nullptr)
		{
			PreviousHead.bIsHeadOfTrail = false;
			PreviousHead = nullptr;
		}

		// For now, we reset the collected amount when we stop rolling
		PuddleComponent.CollectedAcidAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GameTimeSeconds > NextDropTime
			|| LastDroppedLocation.DistSquared(Player.ActorLocation) > Math::Square(NextDropDistance))
		{
			CrumbSpawnNewTrailDrop(Player.ActorLocation, Player.ActorRotation);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnNewTrailDrop(FVector Location, FRotator Rotation)
	{
		auto Drop = SpawnActor(PuddleComponent.TrailClass, Location, Rotation);
		Drop.Container = PuddleComponent;
		Drop.LifeTimeLeft = Drop.LifeTime;
		Drop.bIsHeadOfTrail = true;
	
		// Link the drops
		if(PreviousHead != nullptr)
		{
			PreviousHead.bIsHeadOfTrail = false;
			Drop.Prev = PreviousHead;
			PreviousHead.Next = Drop;	
		}

		PreviousHead = Drop;
		NextDropDistance = Drop.SpawnDistance;
		LastDroppedLocation = Player.ActorLocation;
		NextDropTime = Time::GameTimeSeconds + (Drop.LifeTime * 0.5);
	}
};