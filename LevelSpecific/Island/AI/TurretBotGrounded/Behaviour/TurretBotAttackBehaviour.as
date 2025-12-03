

class UIslandTurretBotAttackSettings : UHazeComposableSettings
{
	// Cost of attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost GentlemanCost = EGentlemanCost::Small;

	// Seconds in between launched projectiles
	UPROPERTY(Category = "Launch")
	float CooldownBetweenFireDurations = 3.0;

	UPROPERTY(Category = "Attack")
	float FireDuration = 2.0;

	UPROPERTY(Category = "Attack")
	float DelayBetweenBullets = 0.15;

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphDuration = 1.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	FHazeRange AttackRange = FHazeRange(300.0, 2500);

	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 3.0;
}

UCLASS(Abstract)
class ATurretBotProjectile : ABasicAIProjectile
{
	FVector LaunchDirection = FVector::ZeroVector;
}


class UIslandTurretBotAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIProjectileLauncherComponent LeftWeapon;
	UBasicAIProjectileLauncherComponent RightWeapon;

	AAIIslandTurretBotGrounded BotOwner;
	UIslandTurretBotAttackSettings TurretSettings;

	
	float CooldownToNextAttack = 0;
	float AttackTimeLeft = 0;
	bool bNextTurretIsLeft = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		BotOwner = Cast<AAIIslandTurretBotGrounded>(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		
		LeftWeapon = BotOwner.LeftWeaponComponent;
		RightWeapon = BotOwner.RightWeaponComponent;
		TurretSettings = UIslandTurretBotAttackSettings::GetSettings(Owner);				
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && BotOwner.HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
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

		if (!Owner.ActorCenterLocation.IsWithinRange(TargetComp.Target.ActorCenterLocation, TurretSettings.AttackRange))
			return false;

		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasVisibleTarget())
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
		if(!GentCostQueueComp.IsNext(this) && (TurretSettings.GentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(TurretSettings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if (!TargetComp.HasValidTarget())
			return true;

		if (!Owner.ActorCenterLocation.IsWithinRange(TargetComp.Target.ActorCenterLocation, TurretSettings.AttackRange))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		AttackTimeLeft = TurretSettings.FireDuration;
		GentCostComp.ClaimToken(this, TurretSettings.GentlemanCost);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		GentCostComp.ReleaseToken(this, TurretSettings.AttackTokenCooldown);
		CooldownToNextAttack = 0;
		AttackTimeLeft = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(AttackTimeLeft > 0)
		{
			if(CooldownToNextAttack <= 0)
			{
				CooldownToNextAttack += TurretSettings.DelayBetweenBullets;
				CrumbFireProjectile(bNextTurretIsLeft);
				bNextTurretIsLeft = !bNextTurretIsLeft;
			}
			else
			{
				CooldownToNextAttack -= DeltaTime;
			}

			AttackTimeLeft -= DeltaTime;
			if(AttackTimeLeft <= 0)
			{
				CooldownToNextAttack += TurretSettings.CooldownBetweenFireDurations;
			}
		}
		else
		{
			CooldownToNextAttack -= DeltaTime;
			if(CooldownToNextAttack <= 0)
			{
				AttackTimeLeft = TurretSettings.FireDuration;
			}
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbFireProjectile(bool bAttackWithLeft)
	{
		UBasicAIProjectileLauncherComponent Weapon = bAttackWithLeft ? LeftWeapon : RightWeapon;
		const float ProjectileSpeed = 3000;

		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;	
		FVector TargetVelocity = Cast<AHazePlayerCharacter>(TargetComp.Target).GetRawLastFrameTranslationVelocity();

		float Distance = TargetLoc.Distance(Weapon.LaunchLocation);
		TargetLoc += TargetVelocity.GetSafeNormal() * (Distance * (TargetVelocity.Size() / ProjectileSpeed) * Math::RandRange(0.5, 1.5));

		FVector WeaponLoc = Weapon.WorldLocation;
		FVector AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();
		
	    auto ProjectileComp = Weapon.Launch(AimDir * ProjectileSpeed, AimDir.ToOrientationRotator());
		auto Projectile = Cast<ATurretBotProjectile>(ProjectileComp.Owner);
		Projectile.LaunchDirection = AimDir;

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, 1));
	}
}

