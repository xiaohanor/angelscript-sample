class UEnforcerRifleShootAtFocusPointBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	const FName WeaponTag = n"EnforcerWeaponRifle";
	default CapabilityTags.Add(WeaponTag);
	default CapabilityTags.Add(n"Attack");

	UEnforcerShootAtFocusPointComponent ShootAtComp;
	UEnforcerRifleComponent Weapon;

	int FiredProjectiles = 0;
	float FireTime = 0.0;
	float PauseTime = 0.0;
	UAIFirePatternManager FirePatternManager = nullptr;
	FAIFirePattern FirePattern;
	UEnforcerRifleSettings RifleSettings;
	bool bWasAiming;
	TPerPlayer<int> StreamHits;
	bool bHasDealtDamage = false;
	bool bHasCausedStumble = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShootAtComp = UEnforcerShootAtFocusPointComponent::GetOrCreate(Owner);			
		RifleSettings = UEnforcerRifleSettings::GetSettings(Owner);		
		Weapon = UEnforcerRifleComponent::Get(Owner);
		if (Weapon == nullptr)
		{
			UBasicAIWeaponWielderComponent WielderComp = UBasicAIWeaponWielderComponent::Get(Owner);
			if (ensure(WielderComp != nullptr)) 
			{
				if (WielderComp.Weapon != nullptr)
					Weapon = UEnforcerRifleComponent::Get(WielderComp.Weapon);
				WielderComp.OnWieldWeapon.AddUFunction(this, n"OnWieldWeapon");
			}
		}
	}

	UFUNCTION()
	private void OnWieldWeapon(ABasicAIWeapon WieldedWeapon)
	{
		if (WieldedWeapon == nullptr)
			return;
		UEnforcerRifleComponent NewWeapon = UEnforcerRifleComponent::Get(WieldedWeapon);
		if (NewWeapon != nullptr)
		{
			Weapon = NewWeapon;
			Weapon.SetWielder(Owner);
			WieldedWeapon.AddTickPrerequisiteActor(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!ShootAtComp.HasTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!ShootAtComp.HasTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Note that this assumes target has been crumb synced already, see UEnforcerShootAtFocusPointComponent
		Super::OnActivated();
		
		if ((FirePatternManager == nullptr) && (Weapon.FirePatterns != nullptr))
			FirePatternManager = AIFirePattern::GetOrCreateManager(Owner, Weapon.FirePatterns);	

		bWasAiming = AnimComp.bIsAiming;
		AnimComp.bIsAiming = true;	
		PauseTime = 0.0;

		StartNewBurst();		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		AnimComp.bIsAiming = bWasAiming;

		if (ActiveDuration > PauseTime)
			UEnforcerEffectHandler::Trigger_OnPostFire(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!ShootAtComp.HasTarget())
			return; // Can occur on remote side. Note that it is fine if number of shots may differ on control and remote.

		FVector TargetLoc = ShootAtComp.TargetLocation;
		DestinationComp.RotateTowards(TargetLoc);

		if (ActiveDuration < PauseTime)
			return;
		if (PauseTime > 0.0)
			StartNewBurst();

		if((FiredProjectiles < FirePattern.NumberOfProjectiles) && (ActiveDuration > FireTime))
			FireProjectile(TargetLoc);
		
		if(FiredProjectiles >= FirePattern.NumberOfProjectiles)
			Pause();
	}

	void StartNewBurst()
	{
		FiredProjectiles = 0;
		GetFirePattern(FirePattern);
		StreamHits[Game::Mio] = 0;
		StreamHits[Game::Zoe] = 0;
		bHasDealtDamage = false;
		bHasCausedStumble = false;
		FireTime = ActiveDuration + RifleSettings.TelegraphDuration + FirePattern.ProjectileIntervals[0];
		PauseTime = 0.0;

		UEnforcerWeaponEffectHandler::Trigger_OnTelegraph(Weapon.WeaponActor, FEnforcerWeaponEffectTelegraphData(Weapon.GetLaunchLocation(), RifleSettings.TelegraphDuration));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, RifleSettings.TelegraphDuration));
		UEnforcerEffectHandler::Trigger_OnTelegraphShooting(Owner, FEnforcerEffectOnTelegraphData(RifleSettings.TelegraphDuration));
	}

	void Pause()
	{
		PauseTime = ActiveDuration + Math::RandRange(0.8, 1.2);
		UEnforcerEffectHandler::Trigger_OnPostFire(Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile(FVector TargetLoc)
	{
		FVector FireDir = (TargetLoc - Weapon.LaunchLocation).GetSafeNormal();

		FRotator Scatter; 
		Scatter.Yaw = Math::RandRange(-RifleSettings.ScatterYaw, RifleSettings.ScatterYaw);
		Scatter.Pitch = Math::RandRange(-RifleSettings.ScatterPitch, RifleSettings.ScatterPitch);
		FVector ScatterDir = Scatter.RotateVector(FireDir);

		// Launch projectile in same direction
		UBasicAIProjectileComponent Projectile = Weapon.Launch(ScatterDir * RifleSettings.LaunchSpeed);
		Projectile.Damage = 0.0; // Projectile will not do damage, stream does as a whole
		AEnforcerRifleProjectile StreamProjectile = Cast<AEnforcerRifleProjectile>(Projectile.Owner);
		StreamProjectile.OnPlayerHit.AddUFunction(this, n"OnPlayerHit");
		StreamProjectile.OnExpire.AddUFunction(this, n"OnProjectileExpire");
		
		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		FiredProjectiles++;
		FireTime += (FiredProjectiles < FirePattern.NumberOfProjectiles) ? FirePattern.ProjectileIntervals[FiredProjectiles] : BIG_NUMBER;

		UEnforcerWeaponEffectHandler::Trigger_OnLaunch(Weapon.WeaponActor, FEnforcerWeaponEffectLaunchParams(FiredProjectiles, RifleSettings.ProjectileAmount, Weapon.GetLaunchLocation()));
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, FiredProjectiles, RifleSettings.ProjectileAmount));
		UEnforcerEffectHandler::Trigger_OnShotFired(Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnProjectileExpire(AEnforcerRifleProjectile Projectile)
	{
		// Projectile is ready for reuse, we need not keep track of it any longer
		Projectile.OnExpire.UnbindObject(this);
		Projectile.OnPlayerHit.UnbindObject(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerHit(AHazePlayerCharacter Player, FPlayerDeathDamageParams DeathParams = FPlayerDeathDamageParams())
	{
		StreamHits[Player]++;
		if (StreamHits[Player] < RifleSettings.StreamHighDamageThreshold)
		{
			// Just warning damage
			// Player.DealBatchedDamageOverTime(0.01, DamageEffect = Weapon.DamageEffect, DeathEffect = Weapon.DeathEffect); // Can't deal batched damage or we will negate "second chance" grace period.
			UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(Player);
		}
		else
		{
			// Bring them hurtsies, but only once
			if (!bHasDealtDamage)
				Player.DamagePlayerHealth(RifleSettings.StreamHighDamage, DamageEffect = Weapon.DamageEffect, DeathEffect = Weapon.DeathEffect);

			bHasDealtDamage = true;
			UPlayerDamageEventHandler::Trigger_TakeSmallDamage(Player);
		}

		FVector FireDir = (Player.ActorCenterLocation - Weapon.LaunchLocation).GetSafeNormal();
		Player.ApplyAdditiveHitReaction(FireDir);

		if (!bHasCausedStumble && (StreamHits[Player] >= RifleSettings.StreamStumbleThreshold))
		{
			bHasCausedStumble = true;
			Player.ApplyStumble(FireDir.VectorPlaneProject(Player.ActorUpVector).GetSafeNormal() * RifleSettings.StreamStumbleDistance, RifleSettings.StreamStumbleDuration);
		}
	}

	void GetFirePattern(FAIFirePattern& Pattern)
	{
		// Fire patterns for this kind of attack should not be functionally different enough to make a difference in network
		if (FirePatternManager != nullptr)
			Pattern = FirePatternManager.ConsumePattern();

		// Fill out pattern if it was too short. We need to be able to cause damage propely at the very least
		for (int i = Pattern.ProjectileIntervals.Num(); i < RifleSettings.StreamHighDamageThreshold; i++)
		{
			Pattern.ProjectileIntervals.Add((i == 0) ? 0.0 : 0.1);
		}
	}
}

struct FEnforcerShootAtTarget
{
	AActor Actor;
	USceneComponent Component;
	FVector Location;

	FVector GetTargetLocation() const 
	{
		if (Actor != nullptr)
		{
			FVector Loc = Actor.ActorLocation;
			AHazeActor HazeActor = Cast<AHazeActor>(Actor);
			if (HazeActor != nullptr)
				Loc = HazeActor.FocusLocation;
			if (!Location.IsZero())
				Loc += HazeActor.ActorRotation.RotateVector(Location);
			return Loc;
		}
		if (Component != nullptr)
		{
			FVector Loc = Component.WorldLocation;
			if (!Location.IsZero())
				Loc += Component.WorldRotation.RotateVector(Location);
			return Loc;
		}
		return Location;
	}
}

class UEnforcerShootAtFocusPointComponent : UActorComponent
{
	private TInstigated<FEnforcerShootAtTarget> Target;

	bool HasTarget() const
	{
		return !Target.IsDefaultValue();
	}

	FVector GetTargetLocation() const property
	{
		return Target.Get().GetTargetLocation();
	}

	void ShootAtActor(AActor Actor, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal, FVector LocalOffset = FVector::ZeroVector)
	{
		if (!HasControl())
			return;
		FEnforcerShootAtTarget ShootAt;
		ShootAt.Actor = Actor;
		ShootAt.Location = LocalOffset;
		CrumbShootAtTarget(ShootAt, Instigator, Prio);
	}		

	void ShootAtComponent(USceneComponent Component, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal, FVector LocalOffset = FVector::ZeroVector)
	{
		if (!HasControl())
			return;
		FEnforcerShootAtTarget ShootAt;
		ShootAt.Component = Component;
		ShootAt.Location = LocalOffset;
		CrumbShootAtTarget(ShootAt, Instigator, Prio);
	}		

	void ShootAtLocation(FVector WorldLocation, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal)
	{
		if (!HasControl())
			return;
		FEnforcerShootAtTarget ShootAt;
		ShootAt.Location = WorldLocation;
		CrumbShootAtTarget(ShootAt, Instigator, Prio);
	}		

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbShootAtTarget(FEnforcerShootAtTarget ShootAt, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal)
	{
		Target.Apply(ShootAt, Instigator, Prio);
	}		

	void StopShooting(FInstigator Instigator)
	{
		if (!HasControl())
			return;
		CrumbStopShooting(Instigator);
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbStopShooting(FInstigator Instigator)
	{
		Target.Clear(Instigator);
	}
}

namespace EnforcerShootAtPoint
{
	UFUNCTION(BlueprintCallable, Category = "EnforcerShootAt")
	void ShootAtActor(AHazeActor Enforcer, AActor Actor, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal, FVector LocalOffset = FVector::ZeroVector)
	{
		UEnforcerShootAtFocusPointComponent ShootAtComp = GetShootAtComponent(Enforcer);
		if (ShootAtComp != nullptr)
			ShootAtComp.ShootAtActor(Actor, Instigator, Prio, LocalOffset);
	}		

	UFUNCTION(BlueprintCallable, Category = "EnforcerShootAt")
	void ShootAtComponent(AHazeActor Enforcer, USceneComponent Component, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal, FVector LocalOffset = FVector::ZeroVector)
	{
		UEnforcerShootAtFocusPointComponent ShootAtComp = GetShootAtComponent(Enforcer);
		if (ShootAtComp != nullptr)
			ShootAtComp.ShootAtComponent(Component, Instigator, Prio, LocalOffset);
	}		

	UFUNCTION(BlueprintCallable, Category = "EnforcerShootAt")
	void ShootAtLocation(AHazeActor Enforcer, FVector WorldLocation, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal)
	{
		UEnforcerShootAtFocusPointComponent ShootAtComp = GetShootAtComponent(Enforcer);
		if (ShootAtComp != nullptr)
			ShootAtComp.ShootAtLocation(WorldLocation, Instigator, Prio);
	}		

	UFUNCTION(BlueprintCallable, Category = "EnforcerShootAt")
	void StopShooting(AHazeActor Enforcer, FInstigator Instigator)
	{
		UEnforcerShootAtFocusPointComponent ShootAtComp = GetShootAtComponent(Enforcer);
		if (ShootAtComp != nullptr)
			ShootAtComp.StopShooting(Instigator);
	}

	UEnforcerShootAtFocusPointComponent GetShootAtComponent(AHazeActor Enforcer)
	{
		if (!IsValid(Enforcer))
			return nullptr;
		auto ShootAtComp = UEnforcerShootAtFocusPointComponent::Get(Enforcer);		
		if (devEnsure(ShootAtComp != nullptr, "Tried to use Enforcer Shoot At function on an actor without support for it."))
			return ShootAtComp;
		return nullptr;
	}
}

