// Play hit reaction animation and take damage.
class USummitDecimatorTopdownTakeDamageCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownSettings Settings;	
	USummitDecimatorTopdownPhaseComponent PhaseComp;
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	UBasicAIAnimationComponent AnimComp;
	USummitMeltComponent MeltComp;

	AAISummitDecimatorTopdown Decimator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		MeltComp = USummitMeltComponent::Get(Owner);
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::TakingRollHitDamage)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::TakingRollHitDamage)
			return true;
		
		if (ActiveDuration > Settings.RollHitDamageReactionDuration)
			return true;

		if (PhaseComp.CurrentPhase > 3)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TriggerHitReaction();
		MeltComp.ImmediateRestore();
		MeltComp.DisableMelting(this);
		USummitDecimatorTopdownEffectsHandler::Trigger_OnSpinChargeStop(Owner);
		PhaseComp.bHasTriggeredInvulnerableState = false;
		PhaseComp.NumRollHitsTaken++;
		if (PhaseComp.NumRollHitsTaken >= 3)
			PhaseComp.ActivateNextPhase();
		else
			DecimatorTopdown::Animation::RequestFeatureTakeDamage(AnimComp, this);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{		
		MeltComp.EnableMelting(this);
		if (PhaseComp.CurrentPhase > 3)
			return;

		PhaseComp.ChangeState(ESummitDecimatorState::KnockedOutRecover);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > 1.0 && !PhaseComp.bHasTriggeredInvulnerableState && PhaseComp.CurrentPhase == 3)
		{
			if (HasControl())
				CrumbSetHasTriggeredInvulnerableState();
			//else
			//	USummitDecimatorTopdownEffectsHandler::Trigger_OnInvulnerableStateStart(Owner); // immediately run vfx on remote
			PhaseComp.bHasTriggeredInvulnerableState = true;
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Remaining knocked out time: " + (Settings.KnockedOutDuration - ActiveDuration), Color=FLinearColor::Green);
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetHasTriggeredInvulnerableState()
	{
		if (PhaseComp.bHasTriggeredInvulnerableState)
			return;
		PhaseComp.bHasTriggeredInvulnerableState = true;
		//USummitDecimatorTopdownEffectsHandler::Trigger_OnInvulnerableStateStart(Owner);
	}
	
	void TriggerHitReaction()
	{		
		USummitDecimatorTopdownEffectsHandler::Trigger_OnWeakPointHit(Owner);
		Game::Mio.PlayCameraShake(Decimator.CameraShakeLight, this);
		Game::Zoe.PlayCameraShake(Decimator.CameraShakeLight, this);		
		DamageFlash::DamageFlashActor(Owner, 1.0);		

		UBasicAIHealthComponent AIHealthComp = UBasicAIHealthComponent::Get(Owner);
		if (AIHealthComp != nullptr)
		{
			float Damage = (AIHealthComp.CurrentHealth * 0.33);
			Damage::AITakeDamage(Owner, Damage, Owner, EDamageType::Impact);
		}
	}
};