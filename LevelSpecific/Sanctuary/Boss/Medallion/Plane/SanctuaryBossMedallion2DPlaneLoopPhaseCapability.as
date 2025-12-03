class USanctuaryBossMedallion2DPlaneLoopPhaseCapability : UHazeCapability
{
	ASanctuaryBossMedallion2DPlane Plane;
	UMedallionPlayerReferencesComponent MioRefs;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plane = Cast<ASanctuaryBossMedallion2DPlane>(Owner);
		Plane.OnSplineEvent.AddUFunction(this, n"OnSplineEvent");
		MioRefs = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION()
	private void OnSplineEvent(ESanctuaryMedallionSplineEventType EventType, FSanctuaryMedallionSplineEventData EventData)
	{
		if (IsActive())
		{
			if (EventType == ESanctuaryMedallionSplineEventType::LoopBack)
				SetLoopBack();
			if (EventType == ESanctuaryMedallionSplineEventType::LoopBackBack)
				SetLoopBackBack();
		}
	}

	void SetLoopBack()
	{
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying1LoopBack)
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying1Loop);
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying2LoopBack)
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying2Loop);
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying3LoopBack)
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying3Loop);
	}

	void SetLoopBackBack()
	{
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying1Loop)
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying1LoopBack);
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying2Loop)
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying2LoopBack);
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying3Loop)
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying3LoopBack);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MioRefs.Refs == nullptr)
			return false;
		if (MioRefs.Refs.HydraAttackManager == nullptr)
			return false;
		if (!IsInLoopingState())
			return false;
		return true;
	}

	bool IsInLoopingState() const
	{
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying1Loop)
			return true;
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying2Loop)
			return true;
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying3Loop)
			return true;
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying1LoopBack)
			return true;
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying2LoopBack)
			return true;
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying3LoopBack)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MioRefs.Refs == nullptr)
			return true;
		if (MioRefs.Refs.HydraAttackManager == nullptr)
			return true;
		if (!IsInLoopingState())
			return true;
		return false;
	}
};