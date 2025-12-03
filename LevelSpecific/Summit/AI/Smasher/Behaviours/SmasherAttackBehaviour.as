class USmasherAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	USmasherSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USmasherMeleeComponent MeleeComp;
	UAnimInstanceAIBase AnimInstance;

	TArray<AHazePlayerCharacter> AvailableTargets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USmasherSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MeleeComp = USmasherMeleeComponent::Get(Owner);
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetLoc, Settings.AttackRange))
			return false;
		FVector ToTarget = TargetComp.Target.ActorLocation - Owner.ActorLocation;
		ToTarget.Z = 0.0;
		if(Owner.ActorForwardVector.GetAngleDegreesTo(ToTarget) > Settings.AttackMaxAngleDegrees)
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
		GentCostComp.ClaimToken(this, Settings.GentlemanCost);

		Durations = FBasicAIAnimationActionDurations();
		AnimInstance.FinalizeDurations(SummitSmasherFeatureTag::Attack, NAME_None, Durations);
		Durations.ScaleAll(Settings.AttackAnimDurationScale);

		AvailableTargets = Game::Players;

		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector PathLoc;
		if (Pathfinding::FindNavmeshLocation(TargetLoc, 1000.0, 2000.0, PathLoc))
			TargetLoc = PathLoc;
		FVector AttackMove = (TargetLoc - Owner.ActorLocation) * Settings.AttackMovementReachFactor;
		AnimComp.RequestAction(SummitSmasherFeatureTag::Attack, EBasicBehaviourPriority::Medium, this, Durations, AttackMove, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (Durations.IsInRecoveryRange(ActiveDuration))
		{
			// Interrupted after completion of attack, set cooldowns
			float GentlemanCooldown = Settings.AttackGentlemanCooldown;
			if (AvailableTargets.Num() < Game::Players.Num())
				GentlemanCooldown += Settings.AttackSuccessExtraCooldown; // We hit a player, take some time to bask in our accomplishments
			GentCostComp.ReleaseToken(this, GentlemanCooldown);
			Cooldown.Set(Settings.AttackCooldown); 
		}
		else
		{
			GentCostComp.ReleaseToken(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Durations.IsInTelegraphRange(ActiveDuration))
		{
			// Update focus while telegraphing, but not move
			DestinationComp.RotateTowards(TargetComp.Target.ActorCenterLocation);
		}

		if (Durations.IsInActionRange(ActiveDuration))
		{
			for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
			{
				AHazePlayerCharacter PlayerTarget = AvailableTargets[i];
				if (!PlayerTarget.HasControl())
					continue;
				if(!MeleeComp.CanHit(PlayerTarget, Settings.AttackHitRadius))
					continue;
				CrumbHit(PlayerTarget);
			}
		}			

		if(ActiveDuration > Durations.GetTotal())
			Cooldown.Set(Settings.AttackCooldown);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			if (Durations.IsInActionRange(ActiveDuration))
				Debug::DrawDebugSphere(MeleeComp.WorldLocation, Settings.AttackHitRadius, 12, FLinearColor::Red, 20.0);
		}
#endif		
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbHit(AHazePlayerCharacter PlayerTarget)
	{
		AvailableTargets.Remove(PlayerTarget);
		PlayerTarget.DealTypedDamage(Owner, Settings.AttackDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);	

		if ((Settings.AttackHitStumbleDuration > 00) && !Settings.AttackHitStumbleDistance.IsNearlyZero(1.0))
		{
			FTeenDragonStumble Stumble;
			Stumble.Duration = Settings.AttackHitStumbleDuration;
			Stumble.Move = MeleeComp.GetImpactImpulse(PlayerTarget.ActorLocation, Settings.AttackHitStumbleDistance.X, Settings.AttackHitStumbleDistance.Z);
			Stumble.Apply(PlayerTarget);
			PlayerTarget.SetActorRotation((-Stumble.Move).ToOrientationQuat());
		}
	}
}

