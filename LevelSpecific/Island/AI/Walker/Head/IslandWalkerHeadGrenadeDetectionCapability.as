class UIslandWalkerHeadGrenadeDetectionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GrenadeDetection");

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandWalkerHeadComponent HeadComp;
	UWalkerHeadBackDividerComponent BackDivider;
	TPerPlayer<UIslandRedBlueStickyGrenadeUserComponent> Grenadiers;
	TPerPlayer<AIslandRedBlueStickyGrenade> DetectedGrenades;
	UIslandWalkerSettings Settings; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		BackDivider = UWalkerHeadBackDividerComponent::Get(Owner);

		Settings = UIslandWalkerSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HeadComp.State != EIslandWalkerHeadState::Detached)
			return false;

		// TODO: Should activate to allow us to catch grenades in mouth
		//return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HeadComp.State != EIslandWalkerHeadState::Detached)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Grenadiers[Player] = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (DetectedGrenades[Player] != nullptr)
				UndetectGrenade(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			if (HasNewlyDetectedGrenade(Player))
				CrumbDetectGrenade(Player);
			else if (HasLostDetectedGrenade(Player))
				CrumbUndetectGrenade(Player);
			else if (HasBadlyPlacedGrenade(Player))
				RemoveBadlyPlacedGrenade(Player);
		}
	}

	bool HasNewlyDetectedGrenade(AHazePlayerCharacter Player)
	{
		AIslandRedBlueStickyGrenade Grenade = Grenadiers[Player].Grenade;
		if (Grenade == nullptr)
			return false; 
		if (DetectedGrenades[Player] == Grenade)
			return false; // Already detected
		if (!Grenade.IsGrenadeAttached())
			return false;
		if (!IsAttachedToUs(Grenade))
			return false;
		if (BackDivider.ForwardVector.DotProduct(Grenade.ActorLocation - BackDivider.WorldLocation) > 0.0)
			return false; // Ignore grenades on front part of head
		return true;
	}

	bool IsAttachedToUs(AIslandRedBlueStickyGrenade Grenade) const
	{
		if (Grenade == nullptr)
			return false;
		AActor AttachParent = Grenade.AttachParentActor;
		while (AttachParent != nullptr) 
		{
			if (AttachParent == Owner)
				return true;
			AttachParent = AttachParent.AttachParentActor;
		} 
		return false;
	}

	bool HasLostDetectedGrenade(AHazePlayerCharacter Player)
	{	
		AIslandRedBlueStickyGrenade Grenade = DetectedGrenades[Player];
		if (Grenade == nullptr)
			return false; // No detected grenade
		if (Grenade.IsGrenadeAttached())
			return false; 
		return true;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbDetectGrenade(AHazePlayerCharacter Player)
	{
		DetectGrenade(Player);
	}
	void DetectGrenade(AHazePlayerCharacter Player)
	{
		DetectedGrenades[Player] = Grenadiers[Player].Grenade;

		//UIslandWalkerHeadEffectHandler::Trigger_OnGrenadeHitLock(Owner, FIslandWalkerGrenadeLockParams(RootComp.GrenadeLock));
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbUndetectGrenade(AHazePlayerCharacter Player)
	{
		UndetectGrenade(Player);
	}
	void UndetectGrenade(AHazePlayerCharacter Player)
	{
		DetectedGrenades[Player] = nullptr;
		//UIslandWalkerHeadEffectHandler::Trigger_OnGrenadeRemovedFromLock(Owner, FIslandWalkerGrenadeLockParams(RootComps[Player].GrenadeLock));
	}

	bool HasBadlyPlacedGrenade(AHazePlayerCharacter Player)
	{
		AIslandRedBlueStickyGrenade Grenade = Grenadiers[Player].Grenade;
		if (Grenade == nullptr)
			return false; 
		if (DetectedGrenades[Player] == Grenade)
			return false; // This one is correctly placed
		if (!Grenade.IsGrenadeAttached())
			return false;
		if (!IsAttachedToUs(Grenade))
			return false;
		// Grenade has attached to us but not close enough to affect it's grenade lock
		return true;
	}

	void RemoveBadlyPlacedGrenade(AHazePlayerCharacter Player)
	{
		// Just nuke it for now
		Grenadiers[Player].Grenade.DetonateGrenade();
	}
};