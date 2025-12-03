class USanctuaryDodgerRangedAttackBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(SanctuaryDodgerTags::SanctuaryDodgerDarkPortalBlock);
	default CapabilityTags.Add(SanctuaryDodgerTags::SanctuaryDodgerLandBlock);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIProjectileLauncherComponent Weapon;
	USanctuaryDodgerSettings DodgerSettings;
	USanctuaryDodgerGrabComponent GrabComp;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	int ExpiredProjectiles = 0;
	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(Owner);
		GrabComp = USanctuaryDodgerGrabComponent::Get(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
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
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if (!Owner.FocusLocation.IsWithinDist(TargetComp.Target.FocusLocation, DodgerSettings.RangedAttackMaxRange))
			return false;
		if (!TargetComp.HasVisibleTarget())
			return false;
		// if(GrabComp.ReleaseTime != 0 && Time::GetGameTimeSince(GrabComp.ReleaseTime) < 3.0)
		// 	return false;
		if(GrabComp.bGrabbing)
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
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(DodgerSettings.RangedAttackGentlemanCost))
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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		USanctuaryDodgerEventHandler::Trigger_OnRangedAttackTelegraphStart(Owner);
		GentCostComp.ClaimToken(this, DodgerSettings.RangedAttackGentlemanCost);
		ExpiredProjectiles = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USanctuaryDodgerEventHandler::Trigger_OnRangedAttackTelegraphStop(Owner);
		GentCostComp.ReleaseToken(this, DodgerSettings.RangedAttackTokenCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetComp.Target.ActorCenterLocation);

		if(ActiveDuration < DodgerSettings.RangedAttackTelegraphDuration)
			return;

		AnimComp.RequestFeature(FeatureTagDodger::Default, SubTagDodger::Shoot, EBasicBehaviourPriority::Medium, this);

		if(ActiveDuration < DodgerSettings.RangedAttackTelegraphDuration + DodgerSettings.RangedAttackAnticipationDuration)
			return;

		Launch();
		Cooldown.Set(DodgerSettings.RangedAttackCooldown);
	}

	private void Launch()
	{
		USanctuaryDodgerEventHandler::Trigger_OnRangedAttackTelegraphStop(Owner);
		USanctuaryDodgerEventHandler::Trigger_OnRangedAttackStart(Owner);

		// We are going for an even amount of rows and columns
		int Columns = Math::CeilToInt(Math::Sqrt(float(DodgerSettings.ProjectileAmount))) - 1;
		int CurrentRow = 0;
		int CurrentCol = 0;
		float Spacing = DodgerSettings.RangedAttackProjectileSpacing;
		float RandomSpacing = DodgerSettings.RangedAttackProjectileRandomSpacing;
		float LocationOffset = (Columns * Spacing) / -2;

		// TODO: This needs networking if this comes back to use
		for(int i = 0; i < DodgerSettings.ProjectileAmount; ++i)
		{			
			FRotator AimDir = (TargetComp.Target.ActorCenterLocation - Weapon.LaunchLocation).Rotation();
			FVector AdjustedUpVector = AimDir.RotateVector(Owner.ActorUpVector);
			FVector Offset = (Owner.ActorRightVector * LocationOffset) + (Owner.ActorRightVector * CurrentCol * Spacing) + (AdjustedUpVector * LocationOffset) + (AdjustedUpVector * CurrentRow * Spacing);
			Offset += (Owner.ActorRightVector * Math::RandRange(-RandomSpacing, RandomSpacing)) + (AdjustedUpVector * Math::RandRange(-RandomSpacing, RandomSpacing));
			FVector LaunchLocation = Weapon.LaunchLocation + Offset;
			FVector TargetLoc = TargetComp.Target.ActorCenterLocation + Offset;
			FVector Velocity = (TargetLoc - LaunchLocation).GetSafeNormal() * DodgerSettings.ProjectileSpeed;
			UBasicAIProjectileComponent Projectile = Weapon.Launch(Velocity);

			Projectile.Owner.SetActorLocation(LaunchLocation);
			if(GrabComp.GrabbedActor != nullptr)
				Projectile.AdditionalIgnoreActors.Add(GrabComp.GrabbedActor);
			// Projectile.Gravity = DodgerSettings.ProjectileGravity;

			if(CurrentCol >= Columns)
			{
				CurrentCol = 0;
				CurrentRow++;
			}
			else 
			{
				CurrentCol++;
			}
		}
	}
}