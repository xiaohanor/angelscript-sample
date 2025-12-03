event void FBasicAIProjectilePrime(UBasicAIProjectileComponent Projectile);
event void FBasicAIProjectileLaunch(UBasicAIProjectileComponent Projectile);

namespace BasicAIProjectile
{
	void DealDamage(FHitResult Hit, float Damage, EDamageType DamageType, AHazeActor Launcher, FPlayerDeathDamageParams DeathDamageParams = FPlayerDeathDamageParams(), TSubclassOf<UDamageEffect> DamageEffect = nullptr, TSubclassOf<UDeathEffect> DeathEffect = nullptr)
	{
		if (Hit.Actor == nullptr)
			return;

		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Hit.Actor);
		if (PlayerHealthComp != nullptr)
		{
			PlayerHealthComp.DamagePlayer(Damage, DamageEffect, DeathEffect, DeathDamageParams = DeathDamageParams); 
		}

		UBasicAIHealthComponent NPCHealthComp = UBasicAIHealthComponent::Get(Hit.Actor);
		if (NPCHealthComp != nullptr)
			NPCHealthComp.TakeDamage(Damage, DamageType, Launcher);
	}

	// Version for damage type handled by UDealPlayerDamageComponent
	void DealPlayerTypedDamage(FHitResult Hit, float Damage, AHazeActor Launcher, EDamageEffectType DamageEffectType = EDamageEffectType::Generic, EDeathEffectType DeathEffectType = EDeathEffectType::Generic)
	{
		if (Hit.Actor == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
		if (Player != nullptr)
		{
			Player.DealTypedDamage(Launcher, Damage, DamageEffectType, DeathEffectType);
		}
	}
}

class UBasicAIProjectileComponent : UActorComponent
{
	// NOTE: These are expected to be set by the launching actor, usually based on settings values
	float Friction = 0.0; // Normal air friction for bullet is 0.02
	float Gravity = 0.0; // Normal earth gravity is 982.0
	float Damage = 0.0; // Health lost when hit by projectile (default player health is 1.0)
	EDamageType DamageType = EDamageType::Projectile;
	ETraceTypeQuery TraceType = ETraceTypeQuery::WeaponTraceEnemy;
	bool bIgnoreLauncherAttachParents = false;

	FBasicAIProjectilePrime OnPrime;
	FBasicAIProjectileLaunch OnLaunch;

	FVector UpVector = FVector::UpVector;

	FVector TargetedLocation;

	AHazeActor HazeOwner;
	UHazeMovementComponent MoveComp;
	UHazeActorRespawnableComponent RespawnComp;

	bool bIsPrimed = false;
	bool bIsLaunched = false;
	bool bIsExpired = false;
	float LaunchTime = 0.0;
	FVector Velocity;
	AHazeActor Target;
	TArray<UPrimitiveComponent> ExclusiveTraceComponents;
	AHazeActor Launcher;
	UObject LaunchingWeapon;
	UNiagaraComponent LaunchedEffectComp;
	bool bIgnoreDescendants = true;

	TArray<AActor> AdditionalIgnoreActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
	}

	void Reset()
	{
		bIsPrimed = false;
		bIsLaunched = false;
		bIsExpired = false;
		Target = nullptr;
	}

	void Prime()
	{
		if (bIsPrimed)
			return;
		
		bIsPrimed = true;
		bIsExpired = false;

		UBasicAIProjectileEffectHandler::Trigger_OnPrime(HazeOwner);

		//if (HazeOwner.IsActorDisabled(this)) 
			HazeOwner.RemoveActorDisable(this);

		OnPrime.Broadcast(this);
	}

	void Launch(FVector LaunchVelocity)
	{
		Launch(LaunchVelocity, LaunchVelocity.Rotation());
	}

	void Launch(FVector LaunchVelocity, FRotator LaunchRotation)
	{
		if (bIsLaunched)
			return;

		Prime();
		bIsLaunched = true;
		LaunchTime = Time::GameTimeSeconds;
		Velocity = LaunchVelocity;
		Owner.SetActorRotation(LaunchRotation);	
		Owner.SetActorTickEnabled(true);
		
		if ((MoveComp != nullptr) && (HazeOwner != nullptr))
			HazeOwner.AddMovementImpulse(LaunchVelocity);

		UBasicAIProjectileEffectHandler::Trigger_OnLaunch(HazeOwner);

		OnLaunch.Broadcast(this);
	}

	void SetTargetLocation(FVector Loc)
	{
		TargetedLocation = Loc;
	}

	bool IsSignificantImpact(FHitResult Hit)
	{
		if (Hit.Actor == nullptr)
			return false;
		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Hit.Actor);
		if (PlayerHealthComp != nullptr)
			return true;
		UBasicAIHealthComponent NPCHealthComp = UBasicAIHealthComponent::Get(Hit.Actor);
		if (NPCHealthComp != nullptr)	
			return true;
		return false;
	}

	void Impact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(HazeOwner, Data);
		Expire();
		auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
		FVector ImpactDirection = FVector(0.0); 

		if (Player != nullptr)
			ImpactDirection = (Player.ActorCenterLocation - Hit.ImpactPoint).GetSafeNormal(); 
		
		// Debug::DrawDebugLine(Hit.Actor, Hit.ImpactPoint, 12, FLinearColor::Green, Duration = 10.0);
		BasicAIProjectile::DealDamage(Hit, Damage, DamageType, Launcher, FPlayerDeathDamageParams(ImpactDirection));
	}

	void Expire()
	{
		Reset();
		Owner.SetActorTickEnabled(false);
		HazeOwner.AddActorDisable(this);
		if (LaunchedEffectComp != nullptr)
			LaunchedEffectComp.Deactivate();

		// Make this available for respawn
		RespawnComp.UnSpawn();

		bIsExpired = true;
	}

	// Helper function for simple trace projectiles
	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false)
	{
		FVector OwnLoc = Owner.ActorLocation;
		
		FVector Delta = FVector::ZeroVector;

		// Frame time independent gravity acceleration and friction
		// Position changes by _initial_ velocity * dt + acceleration * dt^2 / 2
		Delta += Velocity * DeltaTime;
		Delta -= UpVector * Gravity * Math::Square(DeltaTime) * 0.5;
		Velocity -= UpVector * Gravity * DeltaTime;
		Velocity *= Math::Pow(Math::Exp(-Friction), DeltaTime);

		if (Delta.IsNearlyZero())
			return OwnLoc;

		if (!bIgnoreCollision)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(TraceType);
			Trace.UseLine();
			Trace.IgnoreActors(AdditionalIgnoreActors);

			if (Launcher != nullptr)
			{	
				Trace.IgnoreActor(Launcher, bIgnoreDescendants);

				if (bIgnoreLauncherAttachParents)
				{
					AActor AttachParent = Launcher.AttachParentActor;
					while (AttachParent != nullptr)
					{
						Trace.IgnoreActor(AttachParent);
						AttachParent = AttachParent.AttachParentActor;
					}				
				}
			}
			OutHit = Trace.QueryTraceSingle(OwnLoc, OwnLoc + Delta);

			if (OutHit.bBlockingHit)
				return OutHit.ImpactPoint;
		}

		return OwnLoc + Delta;
	}
	UFUNCTION(BlueprintPure)
	UObject GetLaunchingWeapon()
	{
		return LaunchingWeapon;
	}
	UFUNCTION(BlueprintPure)
	AHazeActor GetLauncher()
	{
		return Launcher;
	}
}
