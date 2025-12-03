class UCentipedeStretchyHurtCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(n"BlockedWhileDead");
	default TickGroup = EHazeTickGroup::Gameplay;

	UCentipedeLavaIntoleranceComponent LavaIntolerance;
	// handle lethal stretching
	UPlayerCentipedeSwingComponent OtherPlayerCentipedeSwingComponent;
	USanctuaryLavaApplierComponent LavaSuicideComp;
	UPlayerCentipedeComponent CentipedeComponent;

	FHazeAcceleratedFloat AccMaxStretchDistance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LavaSuicideComp = USanctuaryLavaApplierComponent::GetOrCreate(Owner);
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		AccMaxStretchDistance.SnapTo(CentipedeComponent.BaseStretchMaxDistanceBeforeKill);
		SanctuaryCentipedeDevToggles::Draw::Stretch.MakeVisible();

		LavaSuicideComp.DamagePerSecond = 1.0;
		LavaSuicideComp.bDeathEvenIfInfiniteHealth = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CentipedeComponent.StretchAlpha < 1.0)
			return false;
		if (AnyPlayerDeadRespawning())
			return false;
		if (CentipedeComponent.Centipede == nullptr)
			return false;
		if (CentipedeComponent.AllowStretchDeathVolumes.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AnyPlayerDeadRespawning())
			return true;
		if (CentipedeComponent.StretchAlpha < 1.0)
			return true;
		if (CentipedeComponent.AllowStretchDeathVolumes.Num() == 0)
			return true;
		return false;
	}

	bool AnyPlayerDeadRespawning() const
	{
		if (Player.IsPlayerDead())
			return true;
		if (Player.OtherPlayer.IsPlayerDead())
			return true;
		if (Player.IsPlayerRespawning())
			return true;
		if (Player.OtherPlayer.IsPlayerRespawning())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UCentipedeEventHandler::Trigger_OnCentipedeStretchStart(Player);
		UCentipedeEventHandler::Trigger_OnCentipedeStretchStart(CentipedeComponent.Centipede);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCentipedeEventHandler::Trigger_OnCentipedeStretchStop(Player);
		UCentipedeEventHandler::Trigger_OnCentipedeStretchStop(CentipedeComponent.Centipede);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		if (AnyPlayerDeadRespawning())
		{
			CentipedeComponent.StretchAlpha = 0.0;
		}
		else
		{
			UpdateMaxStretchDistance(DeltaTime);
			float DistanceBetweenPlayers = (Player.ActorLocation - Player.OtherPlayer.ActorLocation).Size();
			CentipedeComponent.StretchAlpha = DistanceBetweenPlayers / AccMaxStretchDistance.Value;
		}
		
		if (SanctuaryCentipedeDevToggles::Draw::Stretch.IsEnabled())
		{
			Debug::DrawDebugString(Player.ActorLocation, "Stretch Alpha " + CentipedeComponent.StretchAlpha, Player.GetPlayerUIColor());
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (CentipedeComponent.StretchAlpha > 1.5)
			LavaSuicideComp.SingleApplyLavaHitOnWholeCentipede();
	}

	bool TryCacheThings()
	{
		if (OtherPlayerCentipedeSwingComponent == nullptr)
			OtherPlayerCentipedeSwingComponent = UPlayerCentipedeSwingComponent::Get(Player.OtherPlayer);
		return OtherPlayerCentipedeSwingComponent != nullptr;
	}

	void UpdateMaxStretchDistance(float DeltaTime)
	{
		if (CentipedeComponent.AllowStretchDeathVolumes.Num() == 0)
			return;

		float AllowedMaxDistanceBeforeKill = CentipedeComponent.AllowStretchDeathVolumes[0].bSwingStretchVolume ? 
											CentipedeComponent.SwingStretchMaxDistanceBeforeKill :
											CentipedeComponent.BaseStretchMaxDistanceBeforeKill;

		// if (OtherPlayerCentipedeSwingComponent != nullptr && OtherPlayerCentipedeSwingComponent.bSwingBiting)
		// 	AllowedMaxDistanceBeforeKill = CentipedeComponent.SwingStretchMaxDistanceBeforeKill;
		
		if (Network::IsGameNetworked())
		{
			float RoundtripSeconds = Network::GetPingRoundtripSeconds();
			float PingAlpha = Math::Clamp(RoundtripSeconds / 0.4, 0.0, 1.0);
			AllowedMaxDistanceBeforeKill += Math::Lerp(0.0, CentipedeComponent.SwingStretchNetworkAddedDistance, PingAlpha);
		}
		AccMaxStretchDistance.AccelerateTo(AllowedMaxDistanceBeforeKill, 0.1, DeltaTime);
		AccMaxStretchDistance.SnapTo(AllowedMaxDistanceBeforeKill);
	}
};