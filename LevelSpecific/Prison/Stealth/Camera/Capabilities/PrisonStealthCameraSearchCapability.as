/**
 * Look towards where the player was last seen after the player has been spotted.
 */
class UPrisonStealthCameraSearchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthCamera);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileStunned);

	APrisonStealthCamera StealthCamera;
    UPrisonStealthVisionComponent VisionComp;
	UPrisonStealthStunnedComponent StunnedComp;
	UPrisonStealthDetectionComponent DetectionComp;

	TPerPlayer<bool> bHasSpottedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StealthCamera = Cast<APrisonStealthCamera>(Owner);
        VisionComp = UPrisonStealthVisionComponent::Get(Owner);
		StunnedComp = UPrisonStealthStunnedComponent::Get(Owner);
		DetectionComp = UPrisonStealthDetectionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Never search while stunned
		if(StunnedComp.IsStunned())
			return false;

		// If we have already detected (killed) the player, don't search
		if(StealthCamera.HasDetectedAnyPlayer())
			return false;

		// If we haven't actually seen the player, no need to search
		if(!StealthCamera.HasSpottedAnyPlayer())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// If we get stunned, immediately stop searching
		if(StunnedComp.IsStunned())
			return true;

		// If we detected the player while searching, stop
		if(StealthCamera.HasDetectedAnyPlayer())
			return true;

		float MaxLastSeenTime = 0;
		for(auto Player : Game::Players)
		{
			FPrisonStealthPlayerLastSeen LastSeenData = StealthCamera.GetLastSeenData(Player);
			MaxLastSeenTime = Math::Max(MaxLastSeenTime, LastSeenData.Time);
		}

		// If we have not seen any player for some time, or our detection alpha has been reset, deactivate
		if(Time::GetGameTimeSeconds() > MaxLastSeenTime + StealthCamera.SearchTime && StealthCamera.GetMaxDetectionAlpha() < KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StealthCamera.BlockCapabilities(PrisonStealthTags::BlockedWhileSearching, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StealthCamera.UnblockCapabilities(PrisonStealthTags::BlockedWhileSearching, this);

		for(auto Player : Game::Players)
		{
			bHasSpottedPlayer[Player] = false;

		 	if(StealthCamera.HasDetectedPlayer(Player))
				continue;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto Player : Game::Players)
		{
			if(!StealthCamera.IsDetectionEnabledForPlayer(Player))
				continue;

			if(StealthCamera.HasDetectedPlayer(Player))
			{
				bHasSpottedPlayer[Player] = false;
			}
			else
			{
				bHasSpottedPlayer[Player] = StealthCamera.HasSpottedPlayer(Player);
			}
		}
	}
}	