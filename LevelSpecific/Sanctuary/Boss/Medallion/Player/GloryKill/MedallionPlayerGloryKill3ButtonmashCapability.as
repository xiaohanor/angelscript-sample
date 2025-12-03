class UMedallionPlayerGloryKillButtonmashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerAssetsComponent AssetsComp;

	FButtonMashSettings StrangleButtonMashSettings;
	default StrangleButtonMashSettings.Difficulty = EButtonMashDifficulty::Medium;
	default StrangleButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default StrangleButtonMashSettings.Mode = EButtonMashMode::ButtonMash;
	default StrangleButtonMashSettings.ButtonAction = ActionNames::Interaction;
	default StrangleButtonMashSettings.bAllowPlayerCancel = false;
	default StrangleButtonMashSettings.Duration = 2.5;

	bool bIsInButtonMash = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AssetsComp = UMedallionPlayerAssetsComponent::Get(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::Strangle)
			return false;
		if (!HasControl())
			return false;
		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::Strangle)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bIsInButtonMash = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GloryKillComp.SyncedStrangle.SetValue(1.0);
		if (!bIsInButtonMash)
			return;
		bIsInButtonMash = false;
		Player.StopButtonMash(MedallionTags::MedallionGloryKillButtonmashInstigator);
		GloryKillComp.AccStrangle.SnapTo(0.0);
		if (AssetsComp != nullptr && AssetsComp.CutHeadFFEffect != nullptr)
			Player.PlayForceFeedback(AssetsComp.CutHeadFFEffect, false, false, this);
	
		if (AssetsComp != nullptr && AssetsComp.CutHeadCS != nullptr)
			Player.PlayCameraShake(AssetsComp.CutHeadCS, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bIsInButtonMash && ActiveDuration > 0.1)
		{
			bIsInButtonMash = true;
			StrangleButtonMashSettings.WidgetAttachComponent = Player.IsMio() ? RefsComp.Refs.GloryKillCirclingSpotTemp.MioUIAttachComp : RefsComp.Refs.GloryKillCirclingSpotTemp.ZoeUIAttachComp;
			Player.StartButtonMash(StrangleButtonMashSettings, MedallionTags::MedallionGloryKillButtonmashInstigator);
			Player.SetButtonMashAllowCompletion(MedallionTags::MedallionGloryKillButtonmashInstigator, false);
			
			if (Player.IsMio())
			{
				auto AttackedHydra = GloryKillComp.GetCutsceneHydra();
				MedallionStatics::MedallionPlayersStartStrangle(AttackedHydra);
				FSanctuaryBossMedallionManagerHydraData Data;
				Data.Hydra = AttackedHydra;
				UMedallionHydraAttackManagerEventHandler::Trigger_OnDecapitationMashStart(RefsComp.Refs.HydraAttackManager, Data);
			}
		}

		if (bIsInButtonMash)
		{
			float Progress = Player.GetButtonMashProgress(MedallionTags::MedallionGloryKillButtonmashInstigator);
			// Debug::DrawDebugString(StrangleButtonMashSettings.WidgetAttachComponent.WorldLocation, "PROGRESS: " + Progress);
			GloryKillComp.AccStrangle.SpringTo(Progress, 20, 0.9, DeltaTime);
			GloryKillComp.SyncedStrangle.SetValue(Progress);

			float FFStrength = Progress * 0.4 + 0.1;
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = FFStrength;
			FF.RightMotor = FFStrength;
			FF.LeftTrigger = FFStrength;
			FF.RightTrigger = FFStrength;

			Player.SetFrameForceFeedback(FF);
		}
	}
};