class USummitDecimatorKnockedOutRecoverCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownSettings Settings;	
	USummitDecimatorTopdownPhaseComponent PhaseComp;
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	UBasicAIAnimationComponent AnimComp;
	USummitMeltComponent MeltComp;

	AAISummitDecimatorTopdown Decimator;
	UMaterialInstanceDynamic InvulnerableOverlayMaterial;

	bool bHasSpinStarted = false;
	float TakeDamageAnimationTimer;
	int NumHitsTaken = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		MeltComp = USummitMeltComponent::Get(Owner);
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
		InvulnerableOverlayMaterial = Material::CreateDynamicMaterialInstance(this, Decimator.InvulnerableOverlayMaterial);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::KnockedOutRecover)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::KnockedOutRecover)
			return true;
		
		if (ActiveDuration > Settings.KnockedOutRecoverDuration)
			return true;

		if (PhaseComp.CurrentPhase > 3)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		// After a knockdown, we enter a spin again		
		DecimatorTopdown::Animation::RequestFeatureSpinStart(AnimComp, this);
		MeltComp.DisableMelting(this);

		// May have been started in TakeDamageCapability
		//if (!PhaseComp.bHasTriggeredInvulnerableState)
		//	USummitDecimatorTopdownEffectsHandler::Trigger_OnInvulnerableStateStart(Owner);

		USummitDecimatorTopdownEffectsHandler::Trigger_OnRecoverFromKnockout(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MeltComp.EnableMelting(this);
		//USummitDecimatorTopdownEffectsHandler::Trigger_OnInvulnerableStateStop(Owner);
		// Disable invulnerable material overlay
		//Decimator.Mesh.SetOverlayMaterial(nullptr);
		bHasSpinStarted = false;
		
		if (PhaseComp.CurrentPhase > 3)
			return;
		
		PhaseComp.ChangeState(ESummitDecimatorState::RunningAttackSequence);
		PhaseComp.TrySkipPauseState();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		// After a knockdown, we enter a spin again
		if (!bHasSpinStarted && (Settings.KnockedOutRecoverDuration - ActiveDuration < 1.51) )
		{
			if (HasControl())
				CrumbTriggerRecovered();
			else
				TriggerRecoveredLocal();
		}
		

		
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Remaining knocked out recover time: " + (Settings.KnockedOutRecoverDuration - ActiveDuration), Color=FLinearColor::Green);
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerRecovered()
	{
		if (bHasSpinStarted) // skip if local has already triggered on remote
			return;
		TriggerRecoveredLocal();
	}

	void TriggerRecoveredLocal()
	{
		if (bHasSpinStarted) // skip if crumb was activated before remote local.
			return;

		USummitDecimatorTopdownEffectsHandler::Trigger_OnSpinChargeStart(Owner);
		// Disable invulnerable material overlay
		//Decimator.Mesh.SetOverlayMaterial(nullptr);
		//USummitDecimatorTopdownEffectsHandler::Trigger_OnInvulnerableStateStop(Owner);
		auto ShockwaveLauncherComp = USummitDecimatorTopdownShockwaveLauncherComponent::Get(Owner);
		ShockwaveLauncherComp.Launch();
		Game::Mio.PlayCameraShake(Decimator.CameraShakeLight, this);
		Game::Zoe.PlayCameraShake(Decimator.CameraShakeLight, this);
		bHasSpinStarted = true;
	}
};