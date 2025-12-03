//Capability for submerging irrelevent hydras during glory kill

class USanctuaryBossMedallionHydraGloryKillSubmergeCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 102;

	ASanctuaryBossMedallionHydra Hydra;
	USanctuaryBossMedallionHydraAnimComponent AnimComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent MioGloryKillComp;

	TOptional<float> ShouldEmergeTimestamp;
	TOptional<float> EmergeActiveTimestamp;
	const float DelayUntilEmerge = 2.0;
	bool bRemovedHeadBlocker = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		AnimComp = USanctuaryBossMedallionHydraAnimComponent::GetOrCreate(Hydra);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		MioGloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Hydra.HydraType == EMedallionHydra::MioLeft)
			return false;
		if (Hydra.HydraType == EMedallionHydra::ZoeRight)
			return false;
		if (RefsComp.Refs == nullptr)
			return false;
		if (MioGloryKillComp.GetCutsceneHydra() == Hydra)
			return false;
		if (!IsInStrangleSequence())
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return false;
		if (Hydra.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return true;
		if (Hydra.bIsControlledByCutscene)
			return true;
		if (!EmergeActiveTimestamp.IsSet())
			return false;
		if (AnimComp.GetFeatureTag() != EFeatureTagMedallionHydra::Emerge)
			return true;
		if (ActiveDuration - EmergeActiveTimestamp.Value < AnimComp.GetAnimationDuration())
			return false;
		return true;
	}

	bool ShouldEmerge() const
	{
		if (MioGloryKillComp.GloryKillState == EMedallionGloryKillState::Return)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Hydra.OneshotAnimationThenWait(EFeatureTagMedallionHydra::Submerge);
		Hydra.HeadPivotBlockers.Add(this);
		ShouldEmergeTimestamp.Reset();
		EmergeActiveTimestamp.Reset();
		bRemovedHeadBlocker = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!bRemovedHeadBlocker) // happens when we go to ballista run
		{
			Hydra.OneshotAnimation(EFeatureTagMedallionHydra::Emerge);
			Hydra.AppendIdleAnimation();
			Hydra.HeadPivotBlockers.Remove(this);
		}
		else
		{
			// in case we want to do something when emerge is done, like idk roaring maybeh
		}
	} 

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!ShouldEmergeTimestamp.IsSet() && ShouldEmerge())
			ShouldEmergeTimestamp = ActiveDuration;
		else if (ShouldEmergeTimestamp.IsSet() && !EmergeActiveTimestamp.IsSet() && ActiveDuration - ShouldEmergeTimestamp.Value > DelayUntilEmerge)
		{
			bRemovedHeadBlocker = true;
			Hydra.HeadPivotBlockers.Remove(this);
			Hydra.OneshotAnimation(EFeatureTagMedallionHydra::Emerge);
			Hydra.AppendIdleAnimation();
			EmergeActiveTimestamp = ActiveDuration;
		}
	}

	bool IsInStrangleSequence() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle1Sequence)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle2Sequence)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Strangle3Sequence)
			return true;

		return false;
	}
};