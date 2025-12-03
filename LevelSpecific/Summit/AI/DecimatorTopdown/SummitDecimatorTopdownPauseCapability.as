class USummitDecimatorTopdownPauseCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownSettings Settings;
	USummitDecimatorTopdownPhaseComponent PhaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return false;
		if (PhaseComp.CurrentState == ESummitDecimatorState::RunningAttackSequence && PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::Pause)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > PhaseComp.CurrentPauseDuration)
			return true;

		if (PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return true;

		if (PhaseComp.CurrentState == ESummitDecimatorState::RunningAttackSequence && PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::Pause)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (PhaseComp.CurrentState == ESummitDecimatorState::RunningAttackSequence)
			PhaseComp.TryActivateNextAttackState();
	}
	
#if EDITOR

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Activated Substate: Pause", 5.0, Color=FLinearColor::Yellow);
	}
#endif


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PhaseComp.RemainingPauseDuration = PhaseComp.CurrentPauseDuration - ActiveDuration;
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("PauseTimer: " + (PhaseComp.CurrentPauseDuration - ActiveDuration), Color=FLinearColor::Green);
#endif
	}
	
};