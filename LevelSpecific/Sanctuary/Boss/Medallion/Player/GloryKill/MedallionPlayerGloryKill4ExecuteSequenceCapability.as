class UMedallionPlayerGloryKill4ExecuteSequenceCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 60;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerGloryKillComponent OtherPlayerGloryKillComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		OtherPlayerGloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player.OtherPlayer);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		AirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::ExecuteSequence)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return true;
		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RefsComp.Refs.GloryKillCirclingSpotTemp.SetActorHiddenInGame(true);
		if (Player.IsMio())
		{
			AAISanctuaryLightBirdCompanion Birb = LightBirdCompanion::GetLightBirdCompanion();
			Birb.CompanionComp.bSpecialCaseDelayVisibleAfterFallFromCompanionsCutscene = true;
			AAISanctuaryDarkPortalCompanion Fishy = DarkPortalCompanion::GetDarkPortalCompanion();
			Fishy.CompanionComp.bSpecialCaseDelayVisibleAfterFallFromCompanionsCutscene = true;

			if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::Strangle1Sequence)
				RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::GloryKill1);
			else if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::Strangle2Sequence)
				RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::GloryKill2);
			else if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::Strangle3Sequence)
				RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::GloryKill3);
			RefsComp.Refs.EndGloryKillEvent.Broadcast();
		}

		if(Player == Hydra::GetAudioTetherPlayerOwner())
		{
			FSanctuaryBossHydraPlayerTetherEventParams EventParams;
			EventParams.Hydra = nullptr;
			UMedallionPlayerTetherEventHandler::Trigger_OnHydraGloryKillCompleted(Player, EventParams);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::AirMotion, MedallionConstants::Tags::StrangleBlockPlayerFalling);
		Player.UnblockCapabilities(n"Death", MedallionConstants::Tags::StrangleBlockPlayerFalling);
		bool bSplineRun = false;
		if (Player.IsMio())
		{
			{
				if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::GloryKill1)
					RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::FlyingExitReturn1);
				else if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::GloryKill2)
					RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::FlyingExitReturn2);
				else if (RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::GloryKill3)
				{
					if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::GloryKill3)
						RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Ballista1);
					bSplineRun = true;
				}
			}
		}

		if (bSplineRun || RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
		{
			GloryKillComp.SetGloryKillState(EMedallionGloryKillState::None, this);
			GloryKillComp.bTetherToHydra = false;
			UMedallionPlayerComponent MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
			MedallionComp.StopMedallionFlying();
			Player.SetActorVelocity(FVector());

			OtherPlayerGloryKillComp.SetGloryKillState(EMedallionGloryKillState::None, this);
			OtherPlayerGloryKillComp.bTetherToHydra = false;
			UMedallionPlayerComponent OtherMedallionComp = UMedallionPlayerComponent::GetOrCreate(Player.OtherPlayer);
			OtherMedallionComp.StopMedallionFlying();
			Player.OtherPlayer.SetActorVelocity(FVector());
			Player.ResetMovement(true, FVector::UpVector, false);
		}
		else
		{
			GloryKillComp.SetGloryKillState(EMedallionGloryKillState::Return, this);
		}

		if (GloryKillComp.AttackedHydra != nullptr)
		{
			GloryKillComp.AttackedHydra.AttackedTransformOverride.Remove(MedallionConstants::Tags::StrangleBlockRotation);
			GloryKillComp.AttackedHydra.AttackedTransformStartRotation = FQuat();
		}
		GloryKillComp.AttackedHydra = nullptr;
	}
};