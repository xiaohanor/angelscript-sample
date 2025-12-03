event void FSkylineTorHammerProjectilePrime(USkylineTorHammerProjectileComponent Projectile);
event void FSkylineTorHammerProjectileLaunch(USkylineTorHammerProjectileComponent Projectile);

class USkylineTorHammerProjectileComponent : UActorComponent
{
	//// NOTE: These are expected to be set by the launching actor, usually based on settings values

	// Normal air friction for bullet is 0.02
	float Friction = 0.0; 
	// Normal earth gravity is 982.0
	float Gravity = 0.0;
	// Health lost when hit by projectile (default player health is 1.0)
	float Damage = 0.0;
	EDamageType DamageType = EDamageType::Projectile;
	ETraceTypeQuery TraceType = ETraceTypeQuery::WeaponTraceEnemy;

	////

	FSkylineTorHammerProjectilePrime OnPrime;
	FSkylineTorHammerProjectileLaunch OnLaunch;

	FVector UpVector = FVector::UpVector;

	FVector TargetedLocation;

	AHazeActor HazeOwner;
	UHazeMovementComponent MoveComp;
	UHazeActorRespawnableComponent RespawnComp;
	USkylineTorHammerPivotComponent PivotComp;

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
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
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
		PivotComp.Pivot.SetActorRotation(LaunchRotation);	
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
		BasicAIProjectile::DealDamage(Hit, Damage, DamageType, Launcher, FPlayerDeathDamageParams(Hit.ImpactPoint, 0.1));
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
	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false, float SubStepDuration = BIG_NUMBER)
	{
		FVector OwnLoc = PivotComp.Pivot.ActorLocation;
		
		FVector Delta = FVector::ZeroVector;

		// Perform substepping movement
		float RemainingTime = DeltaTime;
		for(; RemainingTime > SubStepDuration; RemainingTime -= SubStepDuration)
		{
			Velocity -= UpVector * Gravity * SubStepDuration;
			Velocity -= Velocity * Friction * SubStepDuration;
			Delta += Velocity * SubStepDuration;
		}

		// Move the remaining fraction of a substep
		Velocity -= UpVector * Gravity * RemainingTime;
		Velocity -= Velocity * Friction * RemainingTime;
		Delta += Velocity * RemainingTime;

		if (Delta.IsNearlyZero())
			return OwnLoc;

		if (!bIgnoreCollision)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(TraceType);
			Trace.UseLine();
			Trace.IgnoreActors(AdditionalIgnoreActors);
			OutHit = Trace.QueryTraceSingle(PivotComp.Pivot.ActorLocation, PivotComp.Pivot.ActorLocation + Delta);
			
			float DeltaDistance = PivotComp.Pivot.ActorLocation.Distance(PivotComp.Pivot.ActorLocation + Delta);
			float Factor = (OutHit.Distance / DeltaDistance);
			
			if(OutHit.bBlockingHit && !OutHit.Actor.IsA(AHazeCharacter))
			{
				FVector Point = OwnLoc + Delta * Factor;
				FVector NavMeshPoint;
				if(Pathfinding::FindNavmeshLocation(Point, 0, 500, NavMeshPoint))
					return NavMeshPoint;
				else
					return Point;
			}
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
