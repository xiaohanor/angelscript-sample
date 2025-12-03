class USummitDecimatorTopdownKnockedOutCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownSettings Settings;	
	USummitDecimatorTopdownPhaseComponent PhaseComp;
	USummitMeltComponent MeltComp;
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	UBasicAIAnimationComponent AnimComp;
	UAutoAimTargetComponent AutoAimComp;

	AAISummitDecimatorTopdown Decimator;

	bool bWasHit = false;
	bool bHasLanded = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		TailAttackResponseComp = UTeenDragonTailAttackResponseComponent::Get(Owner);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		MeltComp = USummitMeltComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		AutoAimComp = UAutoAimTargetComponent::Get(Owner);
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void DevWeaknessHitByRoll()
	{
		Decimator.DevImmediateMeltHead();
		OnHitByRoll(FRollParams());
	}
#endif

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!IsActive())
			return;

		if(!MeltComp.bMelted)
			return;

		if (bWasHit)
			return;

		Decimator.OnDecimatorDie.Broadcast();

		bWasHit = true;
		
		AutoAimComp.bIsAutoAimEnabled = false;
		PhaseComp.ChangeState(ESummitDecimatorState::TakingRollHitDamage);		
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::KnockedOut)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::KnockedOut)
			return true;
		if (ActiveDuration > Settings.KnockedOutDuration)
			return true;
		if (PhaseComp.CurrentPhase > 3)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{			
		DecimatorTopdown::Animation::RequestFeatureSpinStop(AnimComp, this);
		USummitDecimatorTopdownEffectsHandler::Trigger_OnSpinChargeStop(Owner);
		USummitDecimatorTopdownEffectsHandler::Trigger_OnKnockedOut(Owner);

		AutoAimComp.bIsAutoAimEnabled = true;

		// Kill any lingering spikebombs
		UHazeTeam SpikeBombTeam = HazeTeam::GetTeam((DecimatorTopdownSpikeBombTags::SpikeBombTeamTag));
		if (SpikeBombTeam != nullptr)
		{
			for (AHazeActor Member : SpikeBombTeam.GetMembers())
			{
				if (Member == nullptr)
					continue;
								
				// Enable explosion
				USummitDecimatorShockwaveSpikeBombResponseComponent ShockwaveResponseComp = USummitDecimatorShockwaveSpikeBombResponseComponent::Get(Member);
				if (ShockwaveResponseComp != nullptr)
					ShockwaveResponseComp.OnHitByShockwave.Broadcast(); // Fake shockwave...
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bWasHit = false;
		bHasLanded = false;
		
		AutoAimComp.bIsAutoAimEnabled = false;		

		if (PhaseComp.CurrentPhase > 3)
			return;
		
		// Only change state if no damage was taken during knocked out state
		if (PhaseComp.CurrentState == ESummitDecimatorState::KnockedOut)
			PhaseComp.ChangeState(ESummitDecimatorState::KnockedOutRecover);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Sneaky glide towards center while performing spin stop animation.
		if (ActiveDuration < 1.0 && Decimator.ArenaCenterLocation.Dist2D(Decimator.ActorLocation) > 500)
		{
			Decimator.AddActorWorldOffset((Decimator.ArenaCenterLocation - Owner.ActorLocation).GetSafeNormal2D() * 2000 * DeltaTime);
		}
		if (ActiveDuration > 0.7 && !bHasLanded)
		{
			bHasLanded = true;
			Game::Mio.PlayCameraShake(Decimator.CameraShakeLight, this);
			Game::Zoe.PlayCameraShake(Decimator.CameraShakeLight, this);
		}
				
		// Face the camera
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Game::Mio);
		float TurnRate = Settings.TurnInAirTurnRate;
		FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
		FVector DesiredDir = Owner.GetActorRotation().ForwardVector.RotateTowards(-ViewYawDir, TurnRate * DeltaTime);
		Owner.SetActorRotation(DesiredDir.Rotation());
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Remaining knocked out time: " + (Settings.KnockedOutDuration - ActiveDuration), Color=FLinearColor::Green);
#endif
	}
};