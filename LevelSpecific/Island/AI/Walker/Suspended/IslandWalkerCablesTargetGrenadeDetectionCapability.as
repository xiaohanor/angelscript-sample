class UIslandWalkerCablesTargetGrenadeDetectionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GrenadeDetection");

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandWalkerForceFieldComponent ForceField;
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;	
	TPerPlayer<UIslandRedBlueStickyGrenadeUserComponent> Grenadiers;
	TPerPlayer<AIslandRedBlueStickyGrenade> DetectedGrenades; 
	UIslandWalkerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForceField = UIslandWalkerForceFieldComponent::Get(Owner);
		GrenadeResponseComp = UIslandRedBlueStickyGrenadeResponseComponent::Get(Owner);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			DetectedGrenades[Player] = nullptr;
			
			// Force field will only react to detonations from detected grenades
			GrenadeResponseComp.BlockImpactForPlayer(Player, this);
		}
		Settings = UIslandWalkerSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ForceField.bPoweredDown)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ForceField.bPoweredDown)
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
		}
	}

	bool HasNewlyDetectedGrenade(AHazePlayerCharacter Player)
	{
		AIslandRedBlueStickyGrenade Grenade = Grenadiers[Player].Grenade;
		if (Grenade == nullptr)
			return false; 
		if (DetectedGrenades[Player] == Grenade)
			return false; // Already detected
		// if (!Grenade.IsGrenadeAttached())
		// 	return false;
		if (!Grenade.ActorLocation.IsWithinDist(ForceField.WorldLocation, Settings.CablesTargetGrenadeDetectionRange))
			return false;
		return true;
	}

	bool HasLostDetectedGrenade(AHazePlayerCharacter Player)
	{	
		AIslandRedBlueStickyGrenade Grenade = DetectedGrenades[Player];
		if (Grenade == nullptr)
			return false; // No detected grenade
		if (Grenade.IsGrenadeAttached())
		 	return false; 
		if (Grenade.ActorLocation.IsWithinDist(ForceField.WorldLocation, Settings.CablesTargetGrenadeDetectionRange + 100.0))
			return false;
		return true;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbDetectGrenade(AHazePlayerCharacter FromPlayer)
	{
		DetectGrenade(FromPlayer);
	}
	void DetectGrenade(AHazePlayerCharacter FromPlayer)
	{
		DetectedGrenades[FromPlayer] = Grenadiers[FromPlayer].Grenade;
		GrenadeResponseComp.UnblockImpactForPlayer(FromPlayer, this);

		if (FromPlayer == ForceField.UsablePlayer)
		{
			ForceField.Impact();
			UIslandWalkerCablesTargetEffectHandler::Trigger_OnGrenadeAttachedCorrect(Owner);
		}
		else 
		{
			UIslandWalkerCablesTargetEffectHandler::Trigger_OnGrenadeAttachedWrongColour(Owner);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbUndetectGrenade(AHazePlayerCharacter FromPlayer)
	{
		UndetectGrenade(FromPlayer);
	}
	void UndetectGrenade(AHazePlayerCharacter FromPlayer)
	{
		DetectedGrenades[FromPlayer] = nullptr;
		GrenadeResponseComp.BlockImpactForPlayer(FromPlayer, this);

		if (FromPlayer == ForceField.UsablePlayer)
			UIslandWalkerCablesTargetEffectHandler::Trigger_OnGrenadeRemovedCorreect(Owner);
		else 
			UIslandWalkerCablesTargetEffectHandler::Trigger_OnGrenadeRemovedWrongColour(Owner);
	}
};