struct FMedallionPlayerMergeHighfiveActivationParams
{
	float PingLenience = 0.0;
}

class UMedallionPlayerMergeHighfiveActiveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerMergeHighfiveJumpComponent OtherHighfiveComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerComponent MedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		OtherHighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player.OtherPlayer);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionPlayerMergeHighfiveActivationParams & Params) const
	{
		// only host or local mio decides
		bool bIsGuest = Network::IsGameNetworked() && !Network::HasWorldControl();
		if (bIsGuest)
			return false;
		if (!Network::IsGameNetworked() && Player.IsZoe())
			return false;
		// --

		if (RefsComp.Refs == nullptr)
			return false;

		if (RefsComp.Refs.HighfiveTargetLocation == nullptr)
			return false;

		if (!IsInMerged())
			return false;

		if (MedallionComp.IsMedallionCoopFlying())
			return false;

		if (Game::Mio.GetHorizontalDistanceTo(Game::Zoe) > HighfiveComp.GetHighfiveJumpTriggerDistance())
			return false;

		if (DeactiveDuration < 1.0)
			return false;

		if (Player.IsPlayerDead())
			return false;

		if (Player.OtherPlayer.IsPlayerDead())
			return false;

		if (!HighfiveComp.AllowHighfiveJumpStart())
			return false;

		if (HighfiveComp.bHighfiveJumpStartTriggered)
			return false;

		Params.PingLenience = Network::PingRoundtripSeconds;
		return true;
	}

	bool IsInMerged() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge1)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{ 
		if (!HighfiveComp.bHighfiveResolveTriggered)
			return false;
		if (!HighfiveComp.bHighfiveSuccess && ActiveDuration < HighfiveComp.GetHighfiveJumpDuration())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionPlayerMergeHighfiveActivationParams Params)
	{
		HighfiveComp.StartHighfiveJumping(Params.PingLenience);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::StickInput, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);

		OtherHighfiveComp.StartHighfiveJumping(Params.PingLenience);
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::StickInput, this);
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::Input, this);

		MedallionStatics::MedallionPlayersStartHighfive();
		UMedallionHydraAttackManagerEventHandler::Trigger_OnPlayersStartTryHighfive(RefsComp.Refs.HydraAttackManager);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::StickInput, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		HighfiveComp.StopHighfiveJumping();

		Player.OtherPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.OtherPlayer.UnblockCapabilities(CapabilityTags::StickInput, this);
		Player.OtherPlayer.UnblockCapabilities(CapabilityTags::Input, this);
		OtherHighfiveComp.StopHighfiveJumping();

		if (HighfiveComp.bHighfiveSuccess)
		{
			HighfiveComp.bAllowFlying = true;
			OtherHighfiveComp.bAllowFlying = true;
		}
	}
};