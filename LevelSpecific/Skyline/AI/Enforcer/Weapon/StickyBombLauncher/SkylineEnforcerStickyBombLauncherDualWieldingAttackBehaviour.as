
class USkylineEnforcerStickyBombLauncherDualWieldingAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	const FName WeaponTag = n"EnforcerWeaponStickyBombLauncher";
	default CapabilityTags.Add(WeaponTag);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineEnforcerStickyBombLauncherComponent Weapon;
	UEnforcerHoveringComponent HoveringComp;
	float EndTime;
	float PrimeTime;

	UEnforcerDualWieldingSettings Settings;
	
	bool bLaunched;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Weapon = USkylineEnforcerStickyBombLauncherComponent::Get(Owner);
		HoveringComp = UEnforcerHoveringComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = UEnforcerDualWieldingSettings::GetSettings(Owner);
		AnimComp.bIsAiming = true;

		if (Weapon == nullptr)
		{
			// Multiple WeaponWielders for HoverEnforcer. Assumes at most one rifle per owner. 
			TArray<UActorComponent> WielderComponents;
			Owner.GetAllComponents(UBasicAIWeaponWielderComponent, WielderComponents);
			for (UActorComponent& Comp : WielderComponents)
			{
				UBasicAIWeaponWielderComponent WielderComp = Cast<UBasicAIWeaponWielderComponent>(Comp);
				if (WielderComp != nullptr) 
				{
					WielderComp.OnWieldWeapon.AddUFunction(this, n"OnWieldWeapon");
					if (WielderComp.Weapon != nullptr)
					{
						Weapon = USkylineEnforcerStickyBombLauncherComponent::Get(WielderComp.Weapon);
						break;
					}
				}
			}
			if(Weapon == nullptr)
			{
				// You can't block yourself using yourself as instigator, will need to use a name
				Owner.BlockCapabilities(WeaponTag, FName(GetPathName()));
			}
		}
	}

	UFUNCTION()
	private void OnWieldWeapon(ABasicAIWeapon WieldedWeapon)
	{
		if (WieldedWeapon == nullptr)
			return;
		USkylineEnforcerStickyBombLauncherComponent NewWeapon = USkylineEnforcerStickyBombLauncherComponent::Get(WieldedWeapon);
		if (NewWeapon != nullptr)
		{
			Weapon = NewWeapon;
			Weapon.SetWielder(Owner);
			if(Owner.IsCapabilityTagBlocked(WeaponTag))
				Owner.UnblockCapabilities(WeaponTag, FName(GetPathName()));
		}
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
		if (Weapon == nullptr)
			return false;
		if(!TargetComp.HasValidTarget())
			return false;

		if(!PerceptionComp.Sight.VisibilityExists(Owner, TargetComp.Target, CollisionChannel = ECollisionChannel::WorldGeometry))
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.StickyBombAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.StickyBombMinimumAttackRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.StickyBombGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.StickyBombGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.StickyBombTelegraphDuration + Settings.StickyBombAttackDuration)
			return true;
			
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		ClaimToken();
		bLaunched = false;
		HoveringComp.StuckWithNoActionCounter = 0;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		UEnforcerWeaponEffectHandler::Trigger_OnTelegraph(Weapon.WeaponActor, FEnforcerWeaponEffectTelegraphData(Weapon.GetLaunchLocation(), Settings.StickyBombTelegraphDuration));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, Settings.StickyBombTelegraphDuration));
		UEnforcerEffectHandler::Trigger_OnTelegraphShooting(Owner, FEnforcerEffectOnTelegraphData(Settings.StickyBombTelegraphDuration));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.StopSlotAnimationByAsset(Animation = ShootingFeature.SingleShot);

		ReleaseToken();
		Cooldown.Set(Settings.StickyBombInterval);
		UEnforcerEffectHandler::Trigger_OnPostFire(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetComp.Target);

		if(ActiveDuration < Settings.StickyBombTelegraphDuration + (Settings.StickyBombAttackDuration / 2))
			return;
		
		if(!bLaunched)
		{
			bLaunched = true;
			Launch();
		}
	}

	private void Launch()
	{
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);

		// Launch projectile at predicted location
		FVector WeaponLoc = Weapon.WorldLocation;
		FVector TargetLoc = PlayerTarget.ActorLocation;
		float PredictionTime = WeaponLoc.Distance(TargetLoc) / Math::Max(100.0, Settings.StickyBombLaunchSpeed);
		FVector ViewDir = PlayerTarget.ViewRotation.ForwardVector.ConstrainToPlane(PlayerTarget.ActorUpVector);
		FVector Offset = (ViewDir * 300) + (PlayerTarget.ActorVelocity * PredictionTime);
		FVector PredictedTargetLoc = TargetLoc + Offset;
		FVector AimDir = (PredictedTargetLoc - WeaponLoc).GetSafeNormal();

		// We don't want shoot the orb into the abyss
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();
		FHitResult Hit = Trace.QueryTraceSingle(PredictedTargetLoc, PredictedTargetLoc + AimDir * 1000);
		if(Hit.bBlockingHit && Hit.Normal != PlayerTarget.ActorUpVector)
			AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * Settings.StickyBombLaunchSpeed);
		Projectile.Owner.SetActorRotation(FRotator::MakeFromZ(PlayerTarget.ActorUpVector));
		Projectile.Gravity = 0;
		auto StickyBomb = Cast<ASkylineEnforcerStickyBombLauncherProjectile>(Projectile.Owner);
		StickyBomb.Owner = Owner;

		UEnforcerWeaponEffectHandler::Trigger_OnLaunch(Weapon.WeaponActor, FEnforcerWeaponEffectLaunchParams(1, 1, WeaponLoc));
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, 1, 1));
		UEnforcerEffectHandler::Trigger_OnShotFired(Owner);
	}
	
	protected void ClaimToken()
	{
		GentCostComp.ClaimToken(this, Settings.StickyBombGentlemanCost);		
	}

	protected void ReleaseToken()
	{
		GentCostComp.ReleaseToken(this, Settings.StickyBombAttackTokenCooldown);
	}
}