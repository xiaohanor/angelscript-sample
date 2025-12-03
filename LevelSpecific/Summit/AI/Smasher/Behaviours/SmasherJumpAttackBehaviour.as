class USmasherJumpAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	USmasherSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitSmasherJumpAttackComponent JumpAttackComp;
	UAnimInstanceAIBase AnimInstance;

	AHazeActor Target;
	TArray<AHazePlayerCharacter> AvailableTargets;
	bool bHasTriggeredImpact = false;

	bool bStartedTelegraph;
	bool bStartedAttack;
	FVector StartLocation;
	FVector JumpAttackMove;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USmasherSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		JumpAttackComp = USummitSmasherJumpAttackComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimInstance = Cast<UAnimInstanceAIBase>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
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
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetLoc, Settings.JumpAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetLoc, Settings.JumpAttackMinRange))
			return false;
		FVector ToTarget = TargetComp.Target.ActorLocation - Owner.ActorLocation;
		ToTarget.Z = 0.0;
		if(Owner.ActorForwardVector.GetAngleDegreesTo(ToTarget) > Settings.JumpAttackMaxAngleDegrees)
			return false;
		if (!Pathfinding::IsNearNavmesh(TargetLoc, 100.0, 250.0))
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
		if(!GentCostQueueComp.IsNext(this) && (Settings.GentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		StartLocation = Owner.ActorLocation;
		GentCostComp.ClaimToken(this, Settings.GentlemanCost);

		Durations = FBasicAIAnimationActionDurations();
		AnimInstance.FinalizeDurations(SummitSmasherFeatureTag::JumpAttack, NAME_None, Durations);
		Durations.ScaleAll(Settings.JumpAttackAnimDurationScale);

		AvailableTargets = Game::Players;
		bHasTriggeredImpact = false;
		bStartedTelegraph = false;
		bStartedAttack = false;

		JumpAttackMove = GetAttackMove();
		JumpAttackComp.ExtraVerticalVelocity = 0.0;
		AnimComp.RequestAction(SummitSmasherFeatureTag::JumpAttack, EBasicBehaviourPriority::Medium, this, Durations, JumpAttackMove, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.JumpAttackGentlemanCooldown);
		if (Durations.IsInRecoveryRange(ActiveDuration))
			Cooldown.Set(Settings.JumpAttackCooldown); // Interrupted after completion of attack
		USmasherEventHandler::Trigger_AttackCompleted(Owner);
		if(bStartedAttack)
			Owner.RemoveActorCollisionBlock(this);
		JumpAttackComp.ExtraVerticalVelocity = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Durations.IsInTelegraphRange(ActiveDuration))
		{
			// Update targeting while telegraphing
 			JumpAttackMove = GetAttackMove();
 			AnimComp.RequestAction(SummitSmasherFeatureTag::JumpAttack, EBasicBehaviourPriority::Medium, this, Durations, JumpAttackMove, true);
 			DestinationComp.RotateTowards(Target.ActorCenterLocation);
 			JumpAttackComp.AttackLocation = Target.ActorLocation;
			if(!bStartedTelegraph)
			{
				bStartedTelegraph = true;
				USmasherEventHandler::Trigger_AttackTelegraph(Owner);
			}
		}
		else if(!bStartedAttack)
		{
			// We've launched ourselves at our target
			bStartedAttack = true;
			USmasherEventHandler::Trigger_AttackStart(Owner);
			Owner.AddActorCollisionBlock(this);

			// Adjust elevation of attack so we'll land at floor height by target
			FVector TargetLoc = StartLocation + JumpAttackMove;
			TargetLoc.Z = StartLocation.Z;
			FVector PathLoc;
			if (!Pathfinding::FindNavmeshLocation(TargetLoc, 80.0, 1500.0, PathLoc))
				PathLoc = TargetLoc;
			float Elevation = PathLoc.Z - StartLocation.Z;
			JumpAttackComp.ExtraVerticalVelocity = Elevation / Durations.Anticipation; // We will only adjust height during the anticipation part of the attack
		}

		if (Durations.IsInAnticipationRange(ActiveDuration))
		{
			DealDamage(Owner.ActorCenterLocation);
		}

		if (Durations.IsInActionRange(ActiveDuration))
		{
			JumpAttackComp.ExtraVerticalVelocity = 0.0;
			FVector ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.JumpAttackImpactOffset;
			DealDamage(ImpactLocation);

			JumpAttackComp.PlayFeedback();

			if (!bHasTriggeredImpact)
			{
				USmasherEventHandler::Trigger_AttackImpact(Owner, FSmasherEventAttackImpactParams(ImpactLocation));			
				bHasTriggeredImpact = true;
			}
		}			

		if(ActiveDuration > Durations.GetTotal())
			Cooldown.Set(Settings.JumpAttackCooldown);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbHit(AHazePlayerCharacter PlayerTarget, float DamageFactor)
	{
		AvailableTargets.Remove(PlayerTarget);
		PlayerTarget.DealTypedDamage(Owner, Settings.JumpAttackDamage * DamageFactor, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);	

		if (!Settings.JumpAttackHitImpulse.IsZero() && DamageFactor > 0.5)
		{
			FTeenDragonStumble Stumble;
			Stumble.Duration = 1;
			Stumble.Move = Owner.ActorForwardVector * 1600;
			Stumble.Apply(PlayerTarget);
			PlayerTarget.SetActorRotation((-Stumble.Move).ToOrientationQuat());
		}
	}

	private void DealDamage(FVector Location)
	{
		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			if (!AvailableTargets[i].HasControl())
				continue;

			float DamageFactor = Damage::GetRadialDamageFactor(AvailableTargets[i].ActorCenterLocation, Location, Settings.JumpAttackRadius);
			if (DamageFactor > 0.0)
				CrumbHit(AvailableTargets[i], DamageFactor);
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			if (Durations.IsInActionRange(ActiveDuration))
				Debug::DrawDebugSphere(Location, Settings.JumpAttackRadius, 12, FLinearColor::Red, 20.0);
		}
#endif		
	}

	private FVector GetAttackMove()
	{
		FVector TargetLoc = Target.ActorLocation;
		FVector PathLoc;
		if (Pathfinding::FindNavmeshLocation(TargetLoc, 1000.0, 2000.0, PathLoc))
			TargetLoc = PathLoc;

		FVector Move = TargetLoc - StartLocation;
		Move.Z = Settings.JumpAttackHeight;
		return Move;
	}
}

