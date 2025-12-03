event void FSummitDecimatorTopdownPlayerTrapProjectileLanded(USummitDecimatorTopdownPlayerTrapProjectileComponent Projectile);

class USummitDecimatorTopdownPlayerTrapProjectileComponent : UActorComponent
{
	// NOTE: These are expected to be set by the launching actor, usually based on settings values
	float Friction = 0.0; // Normal air friction for bullet is 0.02.0
	float Gravity = 0.0; // Normal earth gravity is 982.0
	float Damage = 0.0; // Health lost when hit by projectile (default player health is 1.0)
	EDamageType DamageType = EDamageType::Projectile;
	ETraceTypeQuery TraceType = ETraceTypeQuery::WeaponTraceEnemy;
	bool bIgnoreLauncherAttachParents = false;

	FBasicAIProjectilePrime OnPrime;
	FBasicAIProjectileLaunch OnLaunch;
	FSummitDecimatorTopdownPlayerTrapProjectileLanded OnHitTargetPlayer;

	FVector UpVector = FVector::UpVector;

	FVector TargetedLocation;

	AHazeActor HazeOwner;
	UHazeMovementComponent MoveComp;
	UHazeActorRespawnableComponent RespawnComp;

	bool bIsPrimed = false;
	bool bIsLaunched = false;
	float LaunchTime = 0.0;
	FVector Velocity;
	AHazeActor Target;
	TArray<UPrimitiveComponent> ExclusiveTraceComponents;
	AHazeActor Launcher;
	UObject LaunchingWeapon;
	UNiagaraComponent LaunchedEffectComp;
	bool bIgnoreDescendants = true;

	TArray<AActor> AdditionalIgnoreActors;

	USummitDecimatorTopdownSettings Settings;

	FVector LaunchLocation;
	FVector LaunchVelocity;
	FVector LandTangent;
	FVector TargetLocation;
	float TotalFlightDuration;

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
		Target = nullptr;
	}

	// TODO: try switching targetloc with target player.
	void LaunchAt(FVector TargetLoc)
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Launcher);

		LaunchLocation = Owner.ActorLocation;
		LaunchVelocity = Velocity;
		TargetLocation = TargetLoc;		
		TotalFlightDuration = Settings.TrapProjectileAirTime;
		
		LandTangent = GetLandTangent(Settings.TrapProjectileLandingSteepness);
		Owner.SetActorRotation(Velocity.Rotation());
		
		//USummitDecimatorTopdownPlayerTrapProjectileEventHandler::Trigger_OnLaunch(this, ...);
	}

	FVector GetLandTangent(float LandingSteepness)
	{
		FVector ToTarget = TargetLocation - LaunchLocation;
		FVector LandDir = ToTarget - FVector::UpVector * LandingSteepness;
		LandDir = LaunchVelocity;
		LandDir.Z *= -1.0;
		return LandDir;
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
		return false;
	}

	void Impact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		//UBasicAIProjectileEffectHandler::Trigger_OnImpact(HazeOwner, Data);
		Expire();		
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
	}

	// Helper function for simple trace projectiles
	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false)
	{
		//FVector OwnLoc = Owner.ActorLocation;

		// Temp: will remove and replace with velocity from calculated trajectory
		// Local movement 
		float FlightDuration = Time::GetGameTimeSince(LaunchTime);
		float Alpha = FlightDuration / TotalFlightDuration;
		FVector NewLoc = BezierCurve::GetLocation_2CP(
			LaunchLocation,
			LaunchLocation + LaunchVelocity,
		 	TargetLocation - LandTangent,
			TargetLocation,
			Alpha);
		Owner.SetActorRotation((NewLoc - Owner.ActorLocation).Rotation());
				
		FHazeTraceSettings Trace = Trace::InitChannel(TraceType);
		Trace.UseLine();
		Trace.IgnoreActor(Launcher);

		if (Alpha <= SMALL_NUMBER)
			return Owner.ActorLocation;

		OutHit = Trace.QueryTraceSingle(Owner.ActorLocation, NewLoc);

		if (OutHit.bBlockingHit)
		{
			// Signal PlayerTrap to enable
			OnHitTargetPlayer.Broadcast(this);
			return OutHit.ImpactPoint;
		}
		else 
		{
			// Failsafe, expire			
			if (Alpha > 0.999)
			{
				// Signal PlayerTrap to enable
				OnHitTargetPlayer.Broadcast(this);
				Expire();
			}
		}

#if EDITOR
		//Launcher.bHazeEditorOnlyDebugBool = true;
		if (Launcher.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugArrow(LaunchLocation, LaunchLocation + LaunchVelocity, LineColor = FLinearColor::DPink);
			Debug::DrawDebugArrow(TargetLocation, TargetLocation - LandTangent, LineColor = FLinearColor::DPink);

			FVector PrevLoc = LaunchLocation;
			for (float A = 0.05; A < 1.01; A += 0.05)	
			{
				FVector Loc = BezierCurve::GetLocation_2CP(LaunchLocation, LaunchLocation + LaunchVelocity, TargetLocation - LandTangent, TargetLocation, A);
				Debug::DrawDebugLine(PrevLoc, Loc, FLinearColor::Red);
				PrevLoc = Loc;
			}
		}
#endif

		return NewLoc;
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
