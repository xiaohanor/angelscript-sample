class USummitCritterSwarmAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCritterSwarmSettings SwarmSettings;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitCritterSwarmComponent SwarmComp;

	USummitSwarmingCritterComponent AttackingCritter;
	bool bStartedAttack;
	FVector TargetLocation;
	float PunchThroughLength;
	TArray<AHazeActor> AvailableTargets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SwarmSettings = USummitCritterSwarmSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner); 
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, SwarmSettings.AttackMaxRange))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, SwarmSettings.AttackMinRange))
			return false;
		
		// Don't attack right after taking damage
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) < SwarmSettings.AcidDamageCooldown)
			return false; 

		// Only start attack when on screen
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (!SceneView::IsInView(PlayerTarget, Owner.ActorLocation))	
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (SwarmSettings.AttackGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(SwarmSettings.AttackGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (ActiveDuration > SwarmSettings.AttackTelegraphDuration + SwarmSettings.AttackDuration)
			return true;

		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) < SwarmSettings.AcidDamageCooldown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, SwarmSettings.AttackGentlemanCost);
		AvailableTargets.Empty(2);
		AvailableTargets.Add(Game::Mio);
		AvailableTargets.Add(Game::Zoe);

		USummitCritterSwarmEventHandler::Trigger_OnTelegraphAttack(Owner);
		bStartedAttack = false;
		AttackingCritter = SwarmComp.Critters[Math::RandRange(0, SwarmComp.Critters.Num() - 1)];
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(SwarmSettings.AttackCooldown);
		GentCostComp.ReleaseToken(this, SwarmSettings.AttackTokenCooldown);
		USummitCritterSwarmEventHandler::Trigger_OnAttackStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move in a straight line when attacking
		FVector Dest = Owner.ActorLocation + Owner.ActorVelocity;
		Dest = SwarmComp.ProjectToArea(Dest);
		DestinationComp.MoveTowards(Dest, SwarmSettings.AttackMoveSpeed);

		if(ActiveDuration < SwarmSettings.AttackTelegraphDuration)
			return;

		if (!bStartedAttack)
		{
			// Timing is deterministic, so is network synced, but positioing of attack will not be synced.
			// This improves local accuracy and since attack is fairly quick should be fine. 
			// At worst you might see your friend take damage without seeing the hit.
			bStartedAttack = true;
			TargetLocation = TargetComp.Target.ActorLocation;
			
			// Predict target location
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
			TargetLocation += Player.ActorVelocity * SwarmSettings.AttackDuration * SwarmSettings.AttackPredictFraction;

			// Zap will continue beyond target location so you can't dodge easily by pulling away 
			PunchThroughLength = SwarmSettings.AttackMaxRange * 0.25;

			USummitCritterSwarmEventHandler::Trigger_OnAttack(Owner, FCritterSwarmAttackEventParams(AttackingCritter, TargetLocation, PunchThroughLength));
		}	
		else
		{
			FVector ZapStart = AttackingCritter.WorldLocation;
			FVector ZapEnd = TargetLocation + (TargetLocation - ZapStart).GetSafeNormal() * PunchThroughLength;
			for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
			{
				// Capsule check against target
				if (!AvailableTargets[i].HasControl())
					continue;

				// Capusule check, truncated behind start to reward a player that manages to burst through the swarm.
				FVector TargetLoc = AvailableTargets[i].ActorLocation;
				FVector LineLoc;
				float Fraction = 0.0;
				Math::ProjectPositionOnLineSegment(ZapStart, ZapEnd, TargetLoc, LineLoc, Fraction);
				if ((Fraction > 0.0) && TargetLoc.IsWithinDist(LineLoc, SwarmSettings.AttackHitRadius))
					CrumbHit(Cast<AHazePlayerCharacter>(AvailableTargets[i]));				
			}
		}

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Purple, 10);
		}
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbHit(AHazePlayerCharacter Target)
	{
		Target.DamagePlayerHealth(SwarmSettings.AttackDamage);
		USummitCritterSwarmEventHandler::Trigger_OnAttackHit(Owner, FCritterSwarmAttackHitEventParams(Target));
		AvailableTargets.Remove(Target);
	}
}

