struct FMedallionPlayerTriggerFlyingParams
{
	bool bNaturalProgression = true;
}

class UMedallionPlayerTriggerFlyingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);

	default TickGroup = EHazeTickGroup::Gameplay;

	float TimeDilationMultiplier = 1.0;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp; 
	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionPlayerTriggerFlyingParams & ActivationParams) const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (MedallionComp.IsMedallionCoopFlying())
			return false;
		if (HighfiveComp.IsHighfiveJumping())
			return false;
		if (!HighfiveComp.bAllowFlying && !RefsComp.Refs.MedallionBossPlane2D.bDevInstantFly)
			return false;
		if (!MedallionComp.bCutsceneAllowFlying)
			return false;
		ActivationParams.bNaturalProgression = DeactiveDuration > 1.0;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TimeDilationMultiplier >= 1.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionPlayerTriggerFlyingParams ActivationParams)
	{
		MedallionComp.StartMedallionFlying();
		HighfiveComp.bAllowFlying = false;
		if (ActivationParams.bNaturalProgression) // at beginplay the BP has set the state, dont bump it from here! right? 
		{
			switch (RefsComp.Refs.HydraAttackManager.Phase)
			{
				case EMedallionPhase::Sidescroller1:
				case EMedallionPhase::Merge1:
					RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying1);
				break;
				case EMedallionPhase::Sidescroller2:
				case EMedallionPhase::Merge2:
					RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying2);
				break;
					case EMedallionPhase::Sidescroller3:
				case EMedallionPhase::Merge3:
					RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying3);
				break;
				default:
					//devCheck(false, "unsupported transition!");
				break;
			}

			TimeDilationMultiplier = 0.4;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TimeDilationMultiplier += 1.0 * DeltaTime;
		Time::SetWorldTimeDilation(TimeDilationMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MedallionComp.bCutsceneAllowFlying = false;
		RefsComp.Refs.MedallionBossPlane2D.bDevInstantFly = false;
		Time::SetWorldTimeDilation(1.0);
	}
};