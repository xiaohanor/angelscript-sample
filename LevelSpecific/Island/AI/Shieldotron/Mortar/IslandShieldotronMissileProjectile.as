class UIslandShieldotronMissileLauncherLeft : UBasicAIProjectileLauncherComponent
{
}
class UIslandShieldotronMissileLauncherRight : UBasicAIProjectileLauncherComponent
{
}

UCLASS(Abstract)
class AIslandShieldotronMissileProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UIslandProjectileComponent ProjectileComp;
	//default ProjectileComp.Friction = 0.01;
	//default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;
	
	FVector LaunchLocation;
	FVector LaunchVelocity;
	FVector LandTangent;
	FVector TargetLocation;
	AActor TargetGround;
	float TotalFlightDuration;

	UIslandShieldotronSettings Settings;

	void LaunchAt(FVector TargetLoc, AActor _TargetGround = nullptr)
	{
		Settings = UIslandShieldotronSettings::GetSettings(ProjectileComp.Launcher);

		LaunchLocation = ActorLocation;
		LaunchVelocity = ProjectileComp.Velocity;
		TargetLocation = TargetLoc;
		TargetGround = _TargetGround;
		TotalFlightDuration = Settings.MortarAttackProjectileAirTime;
		PrevCurveLoc = FVector::ZeroVector;

		// LandTangent shares calculation with simulation for unobstructed trajectory check in MortarAttackBehaviour.
		LandTangent = IslandShieldotron::GetMortarLandTangent(LaunchLocation, TargetLoc, Settings.MortarAttackLandingSteepness);
		ActorRotation = ProjectileComp.Velocity.Rotation();
		
		UIslandShieldotronMortarProjectileEventHandler::Trigger_OnLaunch(this, FIslandShieldotronMortarProjectileOnLaunchEventData(LaunchLocation, LaunchVelocity.GetSafeNormal()));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchMortarAttack(Game::Zoe, FIslandShieldotronMortarAttackPlayerEventData(ProjectileComp.Launcher, TargetLocation));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchMortarAttack(Game::Mio, FIslandShieldotronMortarAttackPlayerEventData(ProjectileComp.Launcher, TargetLocation));
	}

	FVector PrevCurveLoc;
	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Simulate initial launch impulse, reduce launch velocity to capped max velocity
		float CurrentSpeed = LaunchVelocity.Size();
		if (CurrentSpeed > Settings.MortarAttackProjectileEndSpeed)
		{
			float SpeedDiff = CurrentSpeed - Settings.MortarAttackProjectileEndSpeed;
			float Acceleration = 5;
			CurrentSpeed = Math::Max(Settings.MortarAttackProjectileEndSpeed, CurrentSpeed - SpeedDiff * Acceleration * DeltaTime);
			LaunchVelocity = LaunchVelocity.GetSafeNormal() * CurrentSpeed;
		}

		if (TargetGround != nullptr)
			TargetLocation.Z = TargetGround.ActorLocation.Z;

		// Local movement 
		float FlightDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		float Alpha = FlightDuration / TotalFlightDuration;
		FVector NewCurveLoc = BezierCurve::GetLocation_2CP(
			LaunchLocation,
			LaunchLocation + LaunchVelocity.RotateTowards(ProjectileComp.Launcher.ActorRightVector, 0),
		 	TargetLocation - LandTangent.RotateTowards(ProjectileComp.Launcher.ActorRightVector * 1.0, 0),
			TargetLocation,
			Alpha);

		// Add a corkscrewish local offset around the curve trajectory.
		FVector LocalOffset;
		if (PrevCurveLoc != FVector::ZeroVector)
		{
			// Define a local space at the current curve point
			FVector Tangent = (NewCurveLoc - PrevCurveLoc).GetSafeNormal();
			FVector RightVector = FVector::UpVector.CrossProduct(Tangent);
			FVector NormalVector = Tangent.CrossProduct(RightVector);
			
			// Reach maximum amplitude at Alpha = 0.5 and then return to 0 at Alpha = 1.0.
			float Amplitude = 1 - Math::Square(1 - 2*Alpha);
			Amplitude *= 250;
			
			// Circle planar to the curve tangent.
			LocalOffset += NormalVector * Amplitude * Math::Sin(Alpha*5);
			LocalOffset += RightVector * Amplitude * Math::Cos(Alpha*5);
		
			ActorRotation = ( (NewCurveLoc + LocalOffset) - ActorLocation).Rotation();
		}
		
		PrevCurveLoc = NewCurveLoc;
		FVector NewLoc = NewCurveLoc + LocalOffset;
		FHitResult Hit;
		FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
		Trace.UseLine();
		Trace.IgnoreActor(ProjectileComp.Launcher);

		if (Alpha <= SMALL_NUMBER)
			return;

		FVector MoveDir = (NewLoc - ActorLocation).GetSafeNormal();
		//Debug::DrawDebugLine(ActorLocation, NewLoc + MoveDir*50, FLinearColor::Blue, bDrawInForeground = true);
		Hit = Trace.QueryTraceSingle(ActorLocation, NewLoc + MoveDir*50);
		if (Hit.bBlockingHit)
		{
			// Impact!
			SetActorLocation(Hit.Location);
						
			if (Hit.Actor.IsA(AHazePlayerCharacter))
			{
				// Damage is networked internally
				AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);

				FIslandShieldotronMortarProjectileOnHitPlayerEventData Params;
				Params.Location = Hit.Location;
				Params.ImpactDirection = Hit.ImpactNormal * -1.0;				
				if (Params.ImpactDirection.Size2D() < SMALL_NUMBER)
					Params.ImpactDirection = HitPlayer.ActorForwardVector * -1.0;
				Params.HitPlayer = HitPlayer;
				// temp, prevent screen shake in sidescroller
				UPlayerMovementPerspectiveModeComponent PerspectiveComp = UPlayerMovementPerspectiveModeComponent::Get(HitPlayer);
				if (PerspectiveComp == nullptr || (PerspectiveComp != nullptr && PerspectiveComp.IsIn3DPerspective()))
					UIslandShieldotronMortarProjectileEventHandler::Trigger_OnHitPlayer(this, Params);
				
				TryDamageAOE();
			}
			else
			{
				FIslandShieldotronMortarProjectileOnHitEventData Params;
				Params.Location = Hit.Location;
				Params.ImpactNormal = Hit.ImpactNormal;
				Params.HitGroundActor = TargetGround;
				UIslandShieldotronMortarProjectileEventHandler::Trigger_OnHit(this, Params);
				TryDamageAOE();
			}
			Expire();
		}
		else 
		{
			SetActorLocation(NewLoc);

			// Debug points make a trail. Consider adding a longer trail to vfx.
			//Debug::DrawDebugPoint(NewLoc + LocalOffset, 1, Duration = 2.0);

			// Failsafe, expire
			if (Alpha > 0.999)
			{
				TryDamageAOE();
				Expire();
			}
		}

#if EDITOR
		//ProjectileComp.Launcher.bHazeEditorOnlyDebugBool = true;
		if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
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
	}
	
	void Expire()
	{
		FIslandShieldotronMortarProjectileOnHitEventData Params;
		Params.HitGroundActor = TargetGround;
		UIslandShieldotronMortarProjectileEventHandler::Trigger_OnExpire(this, Params);
		ProjectileComp.Expire();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbLocalImpact(FHitResult Hit)
	{	
		ProjectileComp.Impact(Hit);
	}

	void TryDamageAOE()
	{
		float HitSphereRadius = Settings.MortarAttackHitSphereRadius;
		TPerPlayer<bool> HasHitPlayer;
		
		FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
		Trace.UseSphereShape(HitSphereRadius);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);
		for (FOverlapResult Overlap : Overlaps.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player == nullptr)
				continue;
			if (!Player.HasControl())
				continue;
			if (HasHitPlayer[Player])
				continue;

			HasHitPlayer[Player] = true;
			// Damage is networked internally
			Player.DamagePlayerHealth(Settings.MortarAttackDamage);

			if (!Settings.bHasMortarAttackKnockdown)
				continue;

			FVector ImpactDirection = (Player.ActorCenterLocation - ActorCenterLocation).GetNormalizedWithFallback(-Player.ActorForwardVector);
			float KnockdownDistance = Settings.MortarAttackKnockdownDistance;
			FKnockdown Knockdown;
			Knockdown.Move = FVector(ImpactDirection.X * KnockdownDistance,
									 ImpactDirection.Y * KnockdownDistance,
									 ImpactDirection.Z);
			Knockdown.Duration = Settings.MortarAttackKnockdownDuration;;
			if (Knockdown.Move.Size() > 0.0)
				Player.ApplyKnockdown(Knockdown);
			
		}

#if EDITOR
		// Draw hit sphere
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool) 
			Debug::DrawDebugSphere(ActorLocation, HitSphereRadius, LineColor = FLinearColor::Red, Duration = 2.0);
#endif
	}

}
