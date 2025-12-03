struct FPrisonStealthGuardSearchDeactivateParams
{
	bool bHasDetectedPlayer = false;
};

class UPrisonStealthGuardSearchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthGuard);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileStunned);

	APrisonStealthGuard StealthGuard;
    UPrisonStealthVisionComponent VisionComponent;
	UPrisonStealthStunnedComponent StunnedComp;
	UPrisonStealthDetectionComponent DetectionComp;

	TPerPlayer<bool> bHasSpottedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StealthGuard = Cast<APrisonStealthGuard>(Owner);
        VisionComponent = UPrisonStealthVisionComponent::Get(Owner);
		StunnedComp = UPrisonStealthStunnedComponent::Get(Owner);
		DetectionComp = UPrisonStealthDetectionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!StealthGuard.HasSpottedAnyPlayer())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		float MaxLastSeenTime = StealthGuard.GetMaxLastSeenTime();

		// If we have not seen any player for some time, or our detection alpha has been reset -> deactivate
		float MaxDetectionAlpha = StealthGuard.GetMaxDetectionAlpha();
		float Time = Time::GetGameTimeSeconds();
		if(Time > MaxLastSeenTime + StealthGuard.SearchTime && MaxDetectionAlpha < KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StealthGuard.BlockCapabilities(PrisonStealthTags::BlockedWhileSearching, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StealthGuard.UnblockCapabilities(PrisonStealthTags::BlockedWhileSearching, this);

		for(auto Player : Game::Players)
		{
			bHasSpottedPlayer[Player] = false;
		}

		if(StealthGuard.PatrolComponent.Sections.IsEmpty())
		{
			StealthGuard.TargetYaw = StealthGuard.InitialYaw;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);

		const bool bHadSpottedAnyPlayer = bHasSpottedPlayer[0] || bHasSpottedPlayer[1];

		for(auto Player : Game::Players)
		{
			if(!StealthGuard.IsDetectionEnabledForPlayer(Player))
				continue;

			bHasSpottedPlayer[Player] = StealthGuard.HasSpottedPlayer(Player);
		}
	}

	void TickControl(float DeltaTime)
	{
		FPrisonStealthPlayerLastSeen LastSpottedData;

		for(auto Player : Game::Players)
		{
			if(!StealthGuard.HasSpottedPlayer(Player))
				continue;

			FPrisonStealthPlayerLastSeen LastSeenData = StealthGuard.GetLastSeenData(Player);

			if(!LastSeenData.IsValid())
				continue;

			if(LastSeenData.Time > LastSpottedData.Time)
				LastSpottedData = LastSeenData;
		}

		if(LastSpottedData.IsValid())
		{
			// Rotate towards the last seen location
			const FVector ToSpottedLocation = LastSpottedData.Location - Owner.ActorLocation;

			const FRotator TargetRotation = FRotator::MakeFromZX(FVector::UpVector, ToSpottedLocation);

			StealthGuard.TargetYaw = TargetRotation.Yaw;
		}
	}
	
	void TickRemote(float DeltaTime)
	{

	}
};