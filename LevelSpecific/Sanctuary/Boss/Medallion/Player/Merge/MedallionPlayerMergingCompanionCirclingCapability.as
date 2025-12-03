struct FMedallionPlayerMergingCompanionParams
{
	bool bNatural = false;
}

class UMedallionPlayerMergingCompanionCirclingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	FLightBirdInvestigationDestination LightBirdInvestigationDestination;
	FDarkPortalInvestigationDestination DarkPortalInvestigationDestination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;

		if (RefsComp.Refs.MioMergingFocus == nullptr)
			return false;
		
		if (RefsComp.Refs.ZoeMergingFocus == nullptr)
			return false;

		if (!IsInMerged())
			return false;

		if (MedallionComp.IsMedallionCoopFlying())
			return false;

		if (Game::Mio.GetHorizontalDistanceTo(Game::Zoe) > MedallionConstants::Highfive::StartOscillatingCompanionDistance)
			return false;

		if (DeactiveDuration < 1.0)
			return false;

		if (Player.IsPlayerDead())
			return false;

		if (Player.OtherPlayer.IsPlayerDead())
			return false;

		if (IsCompanionCutsceneControlled())
			return false;

		return true;
	}

	bool IsCompanionCutsceneControlled() const
	{
		if (Player.IsMio())
		{
			ULightBirdUserComponent LightBirdCompanionComp = ULightBirdUserComponent::Get(Game::Mio); // fetch every frame bc we don't know when network has created it
			if (LightBirdCompanionComp == nullptr || LightBirdCompanionComp.Companion.bIsControlledByCutscene)
				return true;
		}
		else
		{
			UDarkPortalUserComponent DarkPortalCompanionComp = UDarkPortalUserComponent::Get(Game::Zoe); // fetch every frame bc we don't know when network has created it
			if (DarkPortalCompanionComp == nullptr || DarkPortalCompanionComp.Companion.bIsControlledByCutscene)
				return true;
		}
		return false;
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
	bool ShouldDeactivate(FMedallionPlayerMergingCompanionParams & DeactivationParams) const
	{
		if (IsCompanionCutsceneControlled())
		{
			DeactivationParams.bNatural = true;
			return true;
		}

		if (MedallionComp.IsMedallionCoopFlying())
		{
			DeactivationParams.bNatural = true;
			return true;
		}

		if (Player.IsPlayerDead() || Player.OtherPlayer.IsPlayerDead() || !IsInMerged())
		{
			DeactivationParams.bNatural = true;
			return true;
		}

		if (Game::Mio.GetHorizontalDistanceTo(Game::Zoe) < MedallionConstants::Highfive::StartOscillatingCompanionDistance + MedallionConstants::Highfive::StopOscillatingCompanionBufferDistance)
			return false;

		DeactivationParams.bNatural = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Player.IsMio())
		{
			RefsComp.Refs.MioMergingFocus.bBelongsToMio = true;
			LightBirdInvestigationDestination.OverrideSpeed = 10000.0;
			LightBirdInvestigationDestination.Type = ELightBirdInvestigationType::Attach;
			LightBirdInvestigationDestination.TargetComp = RefsComp.Refs.MioMergingFocus.Root;
			LightBirdInvestigationDestination.bAutoIlluminate = false;
			LightBirdInvestigationDestination.bUseObjectRotation = true;
			LightBirdCompanion::LightBirdInvestigate(LightBirdInvestigationDestination,this);
		}
		else
		{
			DarkPortalInvestigationDestination.OverrideSpeed = 10000.0;
			DarkPortalInvestigationDestination.Type = EDarkPortalInvestigationType::Attach;
			DarkPortalInvestigationDestination.TargetComp = RefsComp.Refs.ZoeMergingFocus.Root;
			DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestigationDestination,this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMedallionPlayerMergingCompanionParams DeactivationParams)
	{
		if (!DeactivationParams.bNatural)
			return;

		if (Player.IsMio())
			LightBirdCompanion::LightBirdStopInvestigating(this);
		else
			DarkPortalCompanion::DarkPortalStopInvestigating(this);
	}
};