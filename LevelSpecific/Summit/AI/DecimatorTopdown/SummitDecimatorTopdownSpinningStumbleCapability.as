// Stumble any player overlapping the Decimator in phase 3.
class USummitDecimatorTopdownSpinningStumbleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default DebugCategory = CapabilityTags::Movement;

	AAISummitDecimatorTopdown Decimator;

	USummitDecimatorTopdownSettings Settings;

	// Movecomp and movement data
	UBasicAIAnimationComponent AnimComp;
	USummitDecimatorTopdownPhaseComponent PhaseComp;

	TMap<AHazeActor, FStructSummitDecimatorTopdownSpinChargeCooldownEntry> CooldownMap;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);

		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			CooldownMap.Add(Player, FStructSummitDecimatorTopdownSpinChargeCooldownEntry());
		}

		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.CurrentPhase != 3)
			return false;
		if (PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence
			&& PhaseComp.CurrentState != ESummitDecimatorState::KnockedOutRecover
			&& PhaseComp.CurrentState != ESummitDecimatorState::JumpingDown
			&& PhaseComp.CurrentState != ESummitDecimatorState::JumpingDownRecover)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.CurrentPhase != 3)
			return true;
		if (PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence
			&& PhaseComp.CurrentState != ESummitDecimatorState::KnockedOutRecover
			&& PhaseComp.CurrentState != ESummitDecimatorState::JumpingDown
			&& PhaseComp.CurrentState != ESummitDecimatorState::JumpingDownRecover)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Reset cooldowns
		for (AHazePlayerCharacter Player : Game::Players)
		{
			CooldownMap[Player].CooldownTimer = 0;
			CooldownMap[Player].bHasSetDealDelayedDamageCooldown = false;
		}

		if (PhaseComp.CurrentState == ESummitDecimatorState::JumpingDown)
			return;
		
		DecimatorTopdown::Collision::SetPlayerBlockingCollision(Decimator);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Activated: SpinStumble", 5.0, Color=FLinearColor::Yellow);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{		
		DecimatorTopdown::Collision::SetPlayerBlockingCollision(Decimator);	
		
		// Deal delayed damage now if capability deactivates during the middle of a running cooldown timer.
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (CooldownMap[Player].bHasSetDealDelayedDamageCooldown)
			{
				Player.DealTypedDamage(Owner, Settings.SpinChargeDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);
				CooldownMap[Player].bHasSetDealDelayedDamageCooldown = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Still crawling to his feet and about to jump into spin
		if (PhaseComp.CurrentState == ESummitDecimatorState::KnockedOutRecover && ActiveDuration < 3.5)
			return;
		
		// Still crawling to his feet and about to jump into spin
		if (PhaseComp.CurrentState == ESummitDecimatorState::JumpingDownRecover && ActiveDuration < 5.8)
			return;

		DecimatorTopdown::Collision::SetPlayerIgnoreCollision(Decimator);

		HandlePlayerOverlap(DeltaTime);

#if EDITOR
		// Debug info
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Remaining spin charge time: " + (Settings.SpinChargeDuration - ActiveDuration), Color=FLinearColor::Green);
#endif
	}

	private void HandlePlayerOverlap(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			// Check cooldown timer and apply delayed damage
			if (CooldownMap[Player].bHasSetDealDelayedDamageCooldown)
			{
				CooldownMap[Player].CooldownTimer -= DeltaTime;
				if (CooldownMap[Player].CooldownTimer < 0)
				{
					Player.DealTypedDamage(Owner, Settings.SpinChargeDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);
					CooldownMap[Player].bHasSetDealDelayedDamageCooldown = false;
				}
			}
			// Prepare delayed damage and apply stumble if enabled
			else if (Decimator.IsOverlappingPlayer(Player))
			{
				CooldownMap[Player].CooldownTimer = 0.33;
				CooldownMap[Player].bHasSetDealDelayedDamageCooldown = true;
				
				if (Settings.bSpinChargeEnablePlayerStumble)
				{
					FVector StumbleDir = (Player.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
					FTeenDragonStumble Stumble;
					Stumble.Duration = Settings.SpinChargeStumbleDuration;
					Stumble.Move = StumbleDir * 1000;
					Stumble.Apply(Player);
					Player.SetActorRotation((-Stumble.Move).ToOrientationQuat());
				}
			}
		}
	}


}
