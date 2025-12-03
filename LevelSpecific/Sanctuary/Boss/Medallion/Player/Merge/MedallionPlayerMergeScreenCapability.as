struct FMedallionImmediateBlendParams
{
	bool bImmediateBlend = false;
}

struct FMedallionMergePhaseDeactivationParams
{
	bool bNatural = false;
	float BlendDuration = 0.2;
}

class UMedallionPlayerMergeScreenCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionScreenMerged);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;
	bool bApplied = false;
	bool bRegistered = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionImmediateBlendParams &ActivationParams) const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		
		if (IsInWrongState())
			return false;

		if (MedallionComp.IsMedallionCoopFlying())
		{
			ActivationParams.bImmediateBlend = DeactiveDuration < 1.0;
			return true;
		}

		if (!MedallionComp.bCameraFocusFullyMerged)
			return false;

		ActivationParams.bImmediateBlend = DeactiveDuration < 1.0;
		ActivationParams.bImmediateBlend = true;
		return true;
	}

	bool IsInWrongState() const
	{
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::Return)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::Sidescroller1)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Sidescroller2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Sidescroller3)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMedallionMergePhaseDeactivationParams & Params) const
	{
		if (Player.bIsControlledByCutscene)
			return false;

		if (IsInWrongState())
		{
			Params.bNatural = true;
			Params.BlendDuration = 2.0;
			return true;
		}
		// if (MedallionComp.IsMedallionCoopFlying())
		// 	return false;

		// if (Game::Mio.GetHorizontalDistanceTo(Game::Zoe) > MedallionConstants::Merge::MergeScreenDistance + MedallionConstants::Merge::DeMergeScreenBufferDistance)
		// {
		// 	Params.bNatural = true;
		// 	return true;
		// }

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionImmediateBlendParams ActivationParams)
	{
		if (!bRegistered)
		{
			bRegistered = true;
			RefsComp.Refs.InBeforeMedallionEndSequenceEvent.AddUFunction(this, n"InBeforeMedallionEndSequence");
		}

		if (ActivationParams.bImmediateBlend)
		{
			if (Player == Game::Mio)
			{
				bApplied = true;
				Camera::BlendToFullScreenUsingProjectionOffset(Game::Mio, this, 0.0, 0.0);
			}
		}
		else
		{
			if (Player == Game::Mio)
			{
				bApplied = true;
				Camera::BlendToFullScreenUsingProjectionOffset(Game::Mio, this, 0.5, 0.5);
			}
		}

		UMedallionHydraAttackManagerEventHandler::Trigger_OnPlayersApproachHighFiveScreenMerge(RefsComp.Refs.HydraAttackManager);
	}

	UFUNCTION()
	private void InBeforeMedallionEndSequence()
	{
		if (bApplied && Player == Game::Mio)
		{
			bApplied = false;
			Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMedallionMergePhaseDeactivationParams Params)
	{
		if (bApplied && Player == Game::Mio)
		{
			bApplied = false;
			Camera::BlendToSplitScreenUsingProjectionOffset(this, 5.0);
		}
	}
};