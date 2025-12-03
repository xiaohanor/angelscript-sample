class UIslandShieldotronRocketAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(n"RocketAttack");

	UGentlemanCostComponent GentCostComp;
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIHealthComponent HealthComp;

	UIslandShieldotronSettings ShieldotronSettings;

	float NextFireTime = 0.0;	
	int NumBurstProjectiles = 1;
	int NumFiredProjectiles = 0;
	bool bHasTriggeredTelegraph = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		
		ShieldotronSettings = UIslandShieldotronSettings::GetSettings(Owner);
		NumBurstProjectiles = ShieldotronSettings.AttackBurstNumber;	
	}

	bool WantsToAttack() const
	{
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.AttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.AttackMinRange))
			return false;
				
		// Only launch rocket when in camera view of target
		FVector FromTarget = (Owner.ActorCenterLocation - TargetComp.Target.ActorCenterLocation);
		FromTarget.Z = 0.0;
		FromTarget.Normalize();
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + ViewYawDir * 300, Duration = 2.0);
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + FromTarget * 300, Duration = 2.0, LineColor = FLinearColor::Red);
			if (ViewYawDir.DotProduct(FromTarget) < 0.707) // 45 degrees
				return false;
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + FromTarget * 300, Duration = 2.0, LineColor = FLinearColor::Green);
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!ShieldotronSettings.bHasRocketAttack)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(ShieldotronSettings.AttackGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ShieldotronSettings.AttackDuration + ShieldotronSettings.AttackTelegraphDuration && NumFiredProjectiles >= NumBurstProjectiles)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, ShieldotronSettings.AttackGentlemanCost);

		NumFiredProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + ShieldotronSettings.AttackTelegraphDuration + Math::RandRange(0.0, 0.25);
		
		AnimComp.bIsAiming = true;
		
		//NumBurstProjectiles = (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.MortarAttackMinRange)) ? ShieldotronSettings.AttackCloseRangeBurstNumber : ShieldotronSettings.AttackBurstNumber;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(ShieldotronSettings.AttackCooldown + Math::RandRange(-0.25, 0.25));
		AnimComp.bIsAiming = false;
		bHasTriggeredTelegraph = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > ShieldotronSettings.AttackTelegraphDuration - 0.25 && !bHasTriggeredTelegraph)
		{
			UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, ShieldotronSettings.AttackTelegraphDuration));
			UIslandShieldotronEffectHandler::Trigger_OnRocketAttackTelegraphStart(Owner, FIslandShieldotronRocketAttackTelegraphParams(Weapon));
			bHasTriggeredTelegraph = true;
		}
		if (ActiveDuration < ShieldotronSettings.AttackTelegraphDuration)
			return;

		if(NumFiredProjectiles < NumBurstProjectiles && NextFireTime < Time::GameTimeSeconds)
		{
			FireProjectile();			
			NextFireTime += ShieldotronSettings.AttackDuration / float(NumBurstProjectiles);
			if (NumFiredProjectiles >= NumBurstProjectiles)
				NextFireTime += BIG_NUMBER;
			AnimComp.RequestFeature(FeatureTagIslandSecurityMech::BullitShot, EBasicBehaviourPriority::Medium, this);
		}
		else
			AnimComp.ClearFeature(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		NumFiredProjectiles++;
		FVector AimDir = Weapon.UpVector;
		FVector LaunchVelocity = AimDir * ShieldotronSettings.AttackProjectileLaunchSpeed;
		LaunchVelocity += Owner.ActorVelocity;
		UBasicAIProjectileComponent Projectile = Weapon.Launch(LaunchVelocity);
		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, NumBurstProjectiles));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Zoe, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Mio, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
	}
	
} 