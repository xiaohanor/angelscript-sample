struct FMedallionPlayerMergeHighfiveSuccessOrFailParams
{
	bool bSuccess = false;
	bool bNatural = false;
}

class UMedallionPlayerMergeHighfiveSuccessOrFailCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerMergeHighfiveJumpComponent OtherHighfiveComp;
	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerComponent MedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OtherHighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player.OtherPlayer);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (HighfiveComp.bGameOvering)
		{
			UPlayerHealthSettings::ClearGameOverWhenBothPlayersDead(Player, this);
			UPlayerHealthSettings::ClearRespawnTimer(Player, this);
			UPlayerHealthSettings::ClearEnableRespawnTimer(Player, this);
			Player.UnblockCapabilities(n"Respawn", this);
			Player.OtherPlayer.UnblockCapabilities(n"Respawn", this);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HighfiveComp.IsHighfiveJumping())
			return false;
		if (HighfiveComp.bHighfiveResolveTriggered)
			return false;
		if (HighfiveComp.bGameOvering)
			return false;

		// only host or local mio decides
		bool bIsGuest = Network::IsGameNetworked() && !Network::HasWorldControl();
		if (bIsGuest)
			return false;
		if (!Network::IsGameNetworked() && Player.IsZoe())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMedallionPlayerMergeHighfiveSuccessOrFailParams & Params) const
	{
		// only host or local mio decides
		bool bIsGuest = Network::IsGameNetworked() && !Network::HasWorldControl();
		if (bIsGuest)
			return false;
		if (!Network::IsGameNetworked() && Player.IsZoe())
			return false;

		if (ActiveDuration > HighfiveComp.GetHighfiveJumpDuration())
		{
			float MyProgress = Player.GetButtonMashProgress(MedallionTags::MedallionHighfiveHoldInstigator);
			float YourProgress = Player.OtherPlayer.GetButtonMashProgress(MedallionTags::MedallionHighfiveHoldInstigator);
			bool bSuccess = MyProgress >= 0.95 && YourProgress >= 0.95;
			Params.bSuccess = bSuccess;
			Params.bNatural = true;
			return true;
		}

		if (!HighfiveComp.IsHighfiveJumping())
		{
			Params.bNatural = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMedallionPlayerMergeHighfiveSuccessOrFailParams Params)
	{
		if (!Params.bNatural)
		{
			return;
		}
		bool bSuccess = HighfiveComp.bHighfiveSuccess || OtherHighfiveComp.bHighfiveSuccess || Params.bSuccess;
		if (bSuccess)
		{
			HighfiveComp.HighfiveHoldAlpha = 1.0;
			HighfiveComp.bHighfiveSuccess = true;
			OtherHighfiveComp.bHighfiveSuccess = true;
			OtherHighfiveComp.HighfiveHoldAlpha = 1.0;

			FVector MioLocation = Game::Mio.ActorLocation;
			FVector ZoeLocation = Game::Zoe.ActorLocation;
			FVector BetweenPlayers = MioLocation - ZoeLocation;
			FVector LocationInBetween = ZoeLocation + BetweenPlayers * 0.5;

			FQuat RotateRight90 = FQuat(FVector::UpVector, Math::DegreesToRadians(-90));
			FRotator TowardsCenter = FQuat::ApplyRelative(RefsComp.Refs.HighfiveTargetLocation.ActorQuat, RotateRight90).Rotator();
			if (SanctuaryMedallionHydraDevToggles::Draw::Highfive.IsEnabled())
				Debug::DrawDebugCoordinateSystem(LocationInBetween, TowardsCenter, 1000, 10, 10.0);
			RefsComp.Refs.StartHighfiveEvent.Broadcast(LocationInBetween, TowardsCenter);
		}
		else
		{
			HighfiveComp.HighfiveHoldAlpha = 0.0;
			OtherHighfiveComp.HighfiveHoldAlpha = 0.0;
			HighfiveComp.bHighfiveSuccess = false;
			OtherHighfiveComp.bHighfiveSuccess = false;

			HighfiveComp.bGameOvering = true;
			PlayerHealth::TriggerGameOver();
			UPlayerHealthSettings::SetGameOverWhenBothPlayersDead(Player, true, this, EHazeSettingsPriority::Final);
			UPlayerHealthSettings::SetRespawnTimer(Player, BIG_NUMBER, this, EHazeSettingsPriority::Final);
			UPlayerHealthSettings::SetEnableRespawnTimer(Player, true, this, EHazeSettingsPriority::Final);
			Player.BlockCapabilities(n"Respawn", this);
			Player.OtherPlayer.BlockCapabilities(n"Respawn", this);
			if (Network::IsGameNetworked())
				Timer::SetTimer(this, n"AutoKillPlayers", 1.0);
		}

		HighfiveComp.bHighfiveResolveTriggered = true;
		OtherHighfiveComp.bHighfiveResolveTriggered = true;
	}

	UFUNCTION()
	private void AutoKillPlayers()
	{
		Player.KillPlayer();
		Player.OtherPlayer.KillPlayer();
	}
};