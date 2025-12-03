class USummitDecimatorTopdownSpinBeamCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownSettings Settings;
	USummitDecimatorTopdownPhaseComponent PhaseComp;
	ASummitDecimatorSpinBeam SpinBeam;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		SpinBeam = Cast<AAISummitDecimatorTopdown>(Owner).SpinBeam;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return false;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::EnablingSpinBeam)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.SpinPlatformsDuration)
			return true;
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return true;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::EnablingSpinBeam)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FRotator RotationRate(0, Settings.SpinPlatformsRotationRate, 0);
		SpinBeam.ActivateAttack();
		PhaseComp.TryActivateNextAttackState(); // perform simultaneously
		
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Activated Substate: SpinBeam", 5.0, Color=FLinearColor::Yellow);
#endif

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{		
	}

};