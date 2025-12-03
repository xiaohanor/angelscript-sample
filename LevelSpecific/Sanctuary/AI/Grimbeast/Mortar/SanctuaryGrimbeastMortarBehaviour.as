class USanctuaryGrimbeastMortarBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIProjectileLauncherComponent ProjectileLauncher;
	USanctuaryGrimbeastSettings Settings;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	float TokenCooldownTime;
	bool bLaunched;
	FBasicAIAnimationActionDurations Durations;
	UBasicAIProjectileComponent Projectile;
	FHazeAcceleratedVector AccScale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ProjectileLauncher = UBasicAIProjectileLauncherComponent::Get(Owner);
		Settings = USanctuaryGrimbeastSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		if(Projectile != nullptr && !Projectile.bIsLaunched)
			Projectile.Expire();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);

		if(TokenCooldownTime != 0 && Time::GetGameTimeSince(TokenCooldownTime) > Settings.MortarTokenCooldown)
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
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, Settings.MortarRange))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetLoc, Settings.MortarMinRange))
			return false;
		if (!TargetComp.HasVisibleTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.MortarGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.MortarGentlemanCost))
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
		if(ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.MortarGentlemanCost);
		bLaunched = false;

		Durations.Telegraph = Settings.MortarTelegraphDuration;
		Durations.Anticipation = Settings.MortarAnticipationDuration;
		Durations.Action = Settings.MortarAttackDuration;
		Durations.Recovery = Settings.MortarRecoveryDuration;
		AnimComp.RequestAction(SanctuaryWeeperTags::Attack, EBasicBehaviourPriority::Low, this, Durations);

		Projectile = ProjectileLauncher.Prime();
		Cast<ASanctuaryGrimbeastMortarProjectile>(Projectile.Owner).Owner = Owner;
		FVector TinyScale = FVector::OneVector * 0.0001;
		Projectile.Owner.SetActorScale3D(TinyScale);
		AccScale.Value = TinyScale;

		USanctuaryGrimbeastEventHandler::Trigger_OnMortarTelegraph(Owner, FSanctuaryGrimbeastOnMortarTelegraphEventData(ProjectileLauncher.LaunchLocation));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(ProjectileLauncher, Durations.GetPreActionDuration()));	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.MortarCooldown);
		TokenCooldownTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Durations.IsInTelegraphRange(ActiveDuration))
		{
			AccScale.AccelerateTo(FVector::OneVector, Durations.Telegraph, DeltaTime);
			Projectile.Owner.SetActorScale3D(AccScale.Value);
			DestinationComp.RotateTowards(TargetComp.Target);
		}

		if(!bLaunched && Durations.IsInActionRange(ActiveDuration))
		{
			bLaunched = true;

			if (HasControl())
			{
				TArray<FVector> Locations = GetTailLocations();
				FVector AttackLocation;
				for(FVector Location: Locations)
					AttackLocation += Location;
				AttackLocation = AttackLocation / Locations.Num();

				CrumbLaunch(AttackLocation);				
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunch(FVector AttackLocation)
	{
		Cast<ASanctuaryGrimbeastMortarProjectile>(Projectile.Owner).AttackLocation = AttackLocation;
		float DistAlpha = Math::Clamp(AttackLocation.Distance(Owner.ActorLocation) / Settings.MortarRange, 0.25, 1);
		float Speed = Settings.MortarProjectileSpeed * (0.5 + (0.5 * DistAlpha));
		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ProjectileLauncher.LaunchLocation, AttackLocation, Settings.MortarProjectileGravity, Speed);
		ProjectileLauncher.Launch(Velocity);
		Projectile.Gravity = Settings.MortarProjectileGravity;
		
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(ProjectileLauncher, 1, 1));			
	}

	private TArray<FVector> GetTailLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(TargetComp.Target);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}
}