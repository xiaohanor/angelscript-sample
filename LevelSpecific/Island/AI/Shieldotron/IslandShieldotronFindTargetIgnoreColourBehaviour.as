class UIslandShieldotronFindTargetIgnoreColourBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAIHealthComponent HealthComp;
	UIslandForceFieldComponent ForceFieldComp;

	float RespondToAlarmDelay;
	AHazeActor LastAttacker;
	float LastAttackedTime = -BIG_NUMBER;
	float RememberTimer;
	const float RememberTimeDefault = 2.0;

	UIslandShieldotronSettings Settings;

#if !RELEASE
	AHazeActor PrevTarget = nullptr;
	EIslandShieldotronTargetSelectedBy TargetSelectedBy = EIslandShieldotronTargetSelectedBy::MAX;
#endif

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
	}

	UFUNCTION()
	private void Reset()
	{	
		LastAttacker = nullptr;
		LastAttackedTime = -BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		RespondToAlarmDelay = Math::RandRange(BasicSettings.FindTargetRespondToAlarmDelay, BasicSettings.FindTargetRespondToAlarmDelay * 1.5);
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType Type)
	{
		// The dead do not care
		if (HealthComp.IsDead())
			return;

		// Take note of attackers even when not active, so we can remember them later
		// Ignore when blocked though
		if (IsBlocked())
			return;

		// We forgive any non-potential targets for attacking us.
		if (!TargetComp.IsPotentialTarget(Attacker))
			return;

		// Within range?
		if (!Attacker.ActorCenterLocation.IsWithinDist(Owner.FocusLocation, BasicSettings.DetectAttackerRange))
			return;

		LastAttacker = Attacker;
		LastAttackedTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't switch target in the middle of an ongoing attack
		if (Owner.IsAnyCapabilityActive(BasicAITags::Attack))
			return;

#if !RELEASE		
		TargetSelectedBy = EIslandShieldotronTargetSelectedBy::MAX;
#endif
	
		// Use specific aggro target if any
		AHazeActor Target = TargetComp.AggroTarget;
#if !RELEASE
		if (Target != nullptr)
			TargetSelectedBy = EIslandShieldotronTargetSelectedBy::AggroTarget;
#endif

		// Find all potential targets in visible range
		TArray<AHazeActor> PotentialTargets;
		TargetComp.FindAllTargets(Settings.AwarenessRange, PotentialTargets);
		for (int i = PotentialTargets.Num() - 1; i >= 0; i--)
		{
			if (!TargetComp.HasValidTarget() && PotentialTargets[i].ActorLocation.DistSquared(Owner.ActorLocation) < Settings.OmniAwarenessRange * Settings.OmniAwarenessRange)
			{
				// Discover new target if within omniawareness range, even if not visible.
				RememberTimer = RememberTimeDefault;
			}
			else if (!PerceptionComp.Sight.VisibilityExists(Owner, PotentialTargets[i], FVector::ZeroVector, FVector::ZeroVector, ECollisionChannel::WeaponTraceEnemy))
			{
				// Try to remember the current target when visibility is lost
				if (PotentialTargets[i] == TargetComp.Target && TargetComp.HasValidTarget())
				{
					// Deduct from remember time
					RememberTimer -= DeltaTime;
					// When time runs out, remove from potential targets.
					if (RememberTimer < 0)
						PotentialTargets.RemoveAtSwap(i);
				}				
				else
				{
					// Can't see this potential target
					PotentialTargets.RemoveAtSwap(i);
				}
			}
			else if (PotentialTargets[i] == TargetComp.Target && TargetComp.HasValidTarget())
			{
				// Reset remember timer when target is in sight
				RememberTimer = RememberTimeDefault;
			}
		}

		// Pick the only one
		if (PotentialTargets.Num() == 1)
		{
			Target = PotentialTargets[0];
#if !RELEASE			
			TargetSelectedBy = EIslandShieldotronTargetSelectedBy::OnlyPotentialTarget;
#endif
		}

		// Rebalance if the other player has no attacker
		if (PotentialTargets.Num() > 1 && Target != nullptr)
		{
			Target = FindRebalancedTarget(Target);
		}

		// Check if we've detected an attacker. Only if we have no valid target, to prevent switching back and forth between targets.
		if ((Target == nullptr) && (LastAttacker != nullptr) && !TargetComp.HasValidTarget())
		{
			if (Time::GetGameTimeSince(LastAttackedTime) < BasicSettings.FindTargetRememberAttackerDuration)
			{
				Target = LastAttacker;
#if !RELEASE
				TargetSelectedBy = EIslandShieldotronTargetSelectedBy::LastAttacker;
#endif
			}
			LastAttacker = nullptr;
		}
		
		// No forcefield and no attacker, take the closest target
		if (Target == nullptr && PotentialTargets.Num() == 2)
		{
	 		Target = FindCloseTarget(Settings.AwarenessRange, PotentialTargets);
#if !RELEASE
			if (Target != nullptr)
				TargetSelectedBy = EIslandShieldotronTargetSelectedBy::ClosestTarget;
#endif
		}
		
		// Have alarm been raised for any targets?
		if (Target == nullptr)
		{
			Target = TargetComp.FindAlarmTarget(BasicSettings.RespondToAlarmRange, RespondToAlarmDelay, BasicSettings.FindTargetRememberAlarmDuration);			
#if !RELEASE
			if (Target != nullptr)
				TargetSelectedBy = EIslandShieldotronTargetSelectedBy::RaisedAlarm;
#endif
		}

		
		if (Target != nullptr && TargetComp.IsValidTarget(Target))
		{
#if !RELEASE
			LogSetTarget(Target);
#endif
			TargetComp.SetTarget(Target);
		}
	}
	// if Target has at least 1 other attacker and other player has none, switch
	AHazeActor FindRebalancedTarget(AHazeActor Target)
	{
		AHazePlayerCharacter OtherTarget = Cast<AHazePlayerCharacter>(Target).OtherPlayer;
		int TargetOpponents = UGentlemanComponent::GetOrCreate(Target).GetNumOtherOpponents(Owner);
		int OtherTargetOpponents = UGentlemanComponent::GetOrCreate(OtherTarget).GetNumOtherOpponents(Owner);
		if (OtherTargetOpponents < 1 && TargetOpponents > 0)
		{
#if !RELEASE
			TargetSelectedBy = EIslandShieldotronTargetSelectedBy::RebalancedTarget;
#endif
			return OtherTarget;
		}
		return Target;
	}

	// Tries to pick closest target, if we not already have a target and the distance to each target is relatively similar.
	AHazeActor FindCloseTarget(float Range, TArray<AHazeActor> PotentialTargets)
	{
		AHazeActor BestTarget = nullptr;
		float BestDistSqr = Math::Square(Range);
		FVector SenseLoc = 	Cast<AHazeActor>(Owner).FocusLocation;
		float SwitchClosestTargetTresholdDistSqr = 0.0;

		if (TargetComp.HasValidTarget())
		{
			BestTarget = TargetComp.Target;
			BestDistSqr = SenseLoc.DistSquared(BestTarget.FocusLocation);
			SwitchClosestTargetTresholdDistSqr = Settings.SwitchClosestTargetTresholdDist * Settings.SwitchClosestTargetTresholdDist; // If we already have a valid target, the other target must be at least this much closer (squared).
		}

		for (AHazeActor PotentialTarget : PotentialTargets)
		{
			if (BestTarget == PotentialTarget)
				continue;

			float DistSqr = SenseLoc.DistSquared(PotentialTarget.FocusLocation);
			
			if (DistSqr + SwitchClosestTargetTresholdDistSqr < BestDistSqr)
			{
				BestDistSqr = DistSqr;
				BestTarget = PotentialTarget;
			}
		}
		return BestTarget;
	}


#if !RELEASE
	void LogSetTarget(AHazeActor Target)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			if (PrevTarget != Target)
				TemporalLog.Event("Target Changed to " + Target + ", selected by: " + TargetSelectedBy);
			PrevTarget = Target;

		FLinearColor DebugColor = FLinearColor::Transparent;
		switch(TargetSelectedBy)
		{
			case EIslandShieldotronTargetSelectedBy::AggroTarget:
				DebugColor = FLinearColor::Black;
				break;
			case EIslandShieldotronTargetSelectedBy::Colour:
				DebugColor = FLinearColor::Purple;
				break;
			case EIslandShieldotronTargetSelectedBy::OnlyPotentialTarget:
				DebugColor = FLinearColor::Green;
				break;
			case EIslandShieldotronTargetSelectedBy::RebalancedTarget:
				DebugColor = FLinearColor::LucBlue;
				break;
			case EIslandShieldotronTargetSelectedBy::LastAttacker:
				DebugColor = FLinearColor::DPink;
				break;
			case EIslandShieldotronTargetSelectedBy::ClosestTarget:
				DebugColor = FLinearColor::Gray;
				break;
			case EIslandShieldotronTargetSelectedBy::RaisedAlarm:
				DebugColor = FLinearColor::Red;
				break;
			default:
				DebugColor = FLinearColor::Transparent;
		}


		TemporalLog.CustomStatus("Target selected by", ""+TargetSelectedBy, DebugColor);
		TemporalLog.Line(
			"ToTarget",
			Owner.ActorLocation,
			Target.ActorLocation,
			Color = FLinearColor::Red
		);
	}
#endif
}
