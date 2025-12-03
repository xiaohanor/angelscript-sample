class USanctuaryRangedGhostRangedAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIProjectileLauncherComponent Weapon;
	USanctuaryRangedGhostSettings GhostSettings;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	AAISanctuaryRangedGhost Ghost;

	float MinAttackDot = -1.0;
	bool bReequipped;
	float TokenCooldownTime;
	float LaunchTime;
	int LaunchedProjectiles;
	float AttackDuration;

	bool bHasTargetLocation;
	FVector TargetLocation;
	TArray<FVector> AttackLocations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Ghost = Cast<AAISanctuaryRangedGhost>(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		GhostSettings = USanctuaryRangedGhostSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		MinAttackDot = Math::Cos(Math::DegreesToRadians(GhostSettings.RangedAttackMaxAngleDegrees));
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Weapon == nullptr) 
			return;

		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);

		if(TokenCooldownTime != 0 && Time::GetGameTimeSince(TokenCooldownTime) > GhostSettings.RangedAttackTokenCooldown)
		{
			GentCostComp.ReleaseToken(this);
			TokenCooldownTime = 0;
		}
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, GhostSettings.RangedAttackRange))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetLoc, GhostSettings.RangedAttackMinRange))
			return false;
		if (!TargetComp.HasVisibleTarget())
			return false;
		FVector ToTargetDir = (TargetLoc - Owner.ActorLocation).GetSafeNormal2D();
		if (Owner.ActorForwardVector.DotProduct(ToTargetDir) < MinAttackDot)
			return false;
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (PlayerTarget != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, PlayerTarget.ViewRotation.Yaw, 0.0).Vector();
			if (ViewYawDir.DotProduct(-ToTargetDir) < 0.7)
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(GhostSettings.RangedAttackGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		if(ActiveDuration > GhostSettings.RangedAttackTelegraphDuration + GhostSettings.RangedAttackAnticipationDuration + AttackDuration + GhostSettings.RangedAttackRecoveryDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, GhostSettings.RangedAttackGentlemanCost);

		bReequipped = false;
		LaunchTime = 0;
		LaunchedProjectiles = 0;
		AttackDuration = GhostSettings.RangedAttackAttackDuration * GhostSettings.RangedAttackProjectileCount;
		bHasTargetLocation = false;
		Ghost.TargetLocationDecals.Empty();

		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph = GhostSettings.RangedAttackTelegraphDuration;
		AttackDurations.Anticipation = GhostSettings.RangedAttackAnticipationDuration; 
		AttackDurations.Action = AttackDuration; 
		AttackDurations.Recovery = GhostSettings.RangedAttackRecoveryDuration;
		AnimComp.RequestAction(LocomotionFeatureAISanctuaryTags::RangedGhostAttack, SubTagSanctuaryRangedGhostAttack::Attack, EBasicBehaviourPriority::Medium, this, AttackDurations);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(GhostSettings.RangedAttackCooldown);
		Weapon.SetVisibility(true, true);
		TokenCooldownTime = Time::GetGameTimeSeconds();

		if(bHasTargetLocation)
		{
			for(int i = LaunchedProjectiles; i < GhostSettings.RangedAttackProjectileCount; i++)
			{
				USanctuaryRangedGhostEventHandler::Trigger_OnRemoveTargetIndicator(Ghost, FSanctuaryRangedGhostRemoveTargetIndicatorParameters(i));
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bHasTargetLocation)
			DestinationComp.RotateTowards(TargetLocation);
		else
			DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);

		// TODO: Crumb the entire projectile salvo in one message
		if(HasControl() && DoLaunch())
			CrumbShoot();

		if(!bReequipped && ActiveDuration > 0.25 + GhostSettings.RangedAttackTelegraphDuration + GhostSettings.RangedAttackAnticipationDuration + AttackDuration)
		{
			Weapon.SetVisibility(true, true);
			bReequipped = true;
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbShoot()
	{
		if(!bHasTargetLocation)
		{
			bHasTargetLocation = true;
			TargetLocation = TargetComp.Target.ActorLocation;
			AttackLocations.Empty();

			for(int i = 0; i < GhostSettings.RangedAttackProjectileCount; i++)
			{
				float Angle = -(GhostSettings.RangedAttackProjectileIntervalAngle * Math::IntegerDivisionTrunc((GhostSettings.RangedAttackProjectileCount-1), 2)) + (GhostSettings.RangedAttackProjectileIntervalAngle * i);
				FVector Dir = (TargetLocation - Weapon.LaunchLocation).GetSafeNormal();
				Dir = FRotator(0, Angle, 0).RotateVector(Dir);
				FVector AttackLocation = Weapon.LaunchLocation + (Dir*TargetLocation.Distance(Weapon.LaunchLocation));
				AttackLocations.Add(AttackLocation);
				USanctuaryRangedGhostEventHandler::Trigger_OnAddTargetIndicator(Ghost, FSanctuaryRangedGhostAddTargetIndicatorParameters(i, AttackLocation));
			}
		}

		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Weapon.LaunchLocation, AttackLocations[LaunchedProjectiles], GhostSettings.RangedAttackProjectileGravity, GhostSettings.RangedAttackProjectileSpeed);
		UBasicAIProjectileComponent Projectile = Weapon.Launch(Velocity, Weapon.WorldRotation.UpVector.Rotation());		
		Projectile.Gravity = GhostSettings.RangedAttackProjectileGravity;
		ASanctuaryRangedGhostJavelin Javelin = Cast<ASanctuaryRangedGhostJavelin>(Projectile.Owner);
		Javelin.Index = LaunchedProjectiles;
		//Weapon.SetVisibility(false, true);
		LaunchedProjectiles++;
		LaunchTime = Time::GetGameTimeSeconds();
	}

	bool DoLaunch()
	{
		if(ActiveDuration < GhostSettings.RangedAttackTelegraphDuration + GhostSettings.RangedAttackAnticipationDuration)
			return false;

		if(ActiveDuration > GhostSettings.RangedAttackTelegraphDuration + GhostSettings.RangedAttackAnticipationDuration + AttackDuration)
			return false;

		if(LaunchTime > 0 && Time::GetGameTimeSince(LaunchTime) < GhostSettings.RangedAttackAttackDuration)
			return false;

		return true;
	}
}