class UIslandShieldotronMortarLauncherLeft : UBasicAIProjectileLauncherComponent
{
}
class UIslandShieldotronMortarLauncherRight : UBasicAIProjectileLauncherComponent
{
}



delegate FVector FIslandShieldotronMortarTrajectoryOffset(FVector NewCurveLoc, FVector PrevCurveLoc, float Alpha);
struct FIslandShieldotronMortarTrajectory
{
	FRuntimeFloatCurve AlphaTransform;
	FIslandShieldotronMortarTrajectoryOffset CalculateOffsetFunc;

	bool bHasAlphaTransform = false;
	bool bHasLocalOffset = false;

	float TransformAlpha(float _Alpha)
	{
		if (bHasAlphaTransform)
			return AlphaTransform.GetFloatValue(_Alpha);
		else
			return _Alpha;
	}

	FVector CalculateLocalOffset(FVector NewCurveLoc, FVector PrevCurveLoc, float Alpha)
	{
		FVector Offset = FVector::ZeroVector;
		if (CalculateOffsetFunc.IsBound())
			Offset = CalculateOffsetFunc.Execute(NewCurveLoc, PrevCurveLoc, Alpha);
		return Offset;
	}
}

UCLASS(Abstract)
class AIslandShieldotronMortarProjectile : AHazeActor
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

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AIslandShieldotronMortarTelegraphDecal> TelegraphDecalClass;

	AIslandShieldotronMortarTelegraphDecal TelegraphDecal;

	FVector LaunchLocation;
	FVector LaunchVelocity;
	FVector LandTangent;
	FVector TargetLocation;
	AActor TargetGround;
	float TotalFlightDuration;
	bool bHasPeaked = false;

	UIslandShieldotronSettings Settings;

	FIslandShieldotronMortarTrajectory DefaultTrajectory;
	FIslandShieldotronMortarTrajectory CurrentTrajectory;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Transform alpha
		FRuntimeFloatCurve ApexSlowdownCurve;
		ApexSlowdownCurve.AddDefaultKey(0.0, 0.0);
		ApexSlowdownCurve.AddDefaultKey(0.1, 0.1);
		ApexSlowdownCurve.AddDefaultKey(0.2, 0.2);
		ApexSlowdownCurve.AddDefaultKey(0.3, 0.3);
		ApexSlowdownCurve.AddDefaultKey(0.4, 0.4);
		ApexSlowdownCurve.AddDefaultKey(0.5, 0.45);
		ApexSlowdownCurve.AddDefaultKey(0.6, 0.5);
		ApexSlowdownCurve.AddDefaultKey(1.0, 1.4);
		DefaultTrajectory.AlphaTransform = ApexSlowdownCurve;
		DefaultTrajectory.bHasAlphaTransform = true;
		DefaultTrajectory.bHasLocalOffset = false;
		//DefaultTrajectory.CalculateOffsetFunc.BindUFunction(this, n"LocalOffsetCorkscrew");
	}


	void LaunchAt(FVector TargetLoc, AActor _TargetGround,  FIslandShieldotronMortarTrajectory Trajectory)
	{
		Settings = UIslandShieldotronSettings::GetSettings(ProjectileComp.Launcher);

		CurrentTrajectory = Trajectory;
		
		LaunchLocation = ActorLocation;
		LaunchVelocity = ProjectileComp.Velocity;
		TargetLocation = TargetLoc;
		TargetGround = _TargetGround;
		float AirTimePerDist = Settings.MortarAttackProjectileAirTime / Settings.MortarAttackMinRange;
		float Dist = (TargetLoc - LaunchLocation).Size();
		TotalFlightDuration = Settings.MortarAttackProjectileAirTime; //AirTimePerDist * Dist;
		TotalFlightDuration = Math::Clamp(TotalFlightDuration, Settings.MortarAttackProjectileAirTime, Settings.MortarAttackProjectileAirTime * 2.0);
		PrevCurveLoc = FVector::ZeroVector;
		bHasPeaked = false;

		// LandTangent shares calculation with simulation for unobstructed trajectory check in MortarAttackBehaviour.
		LandTangent = IslandShieldotron::GetMortarLandTangent(LaunchLocation, TargetLoc, Settings.MortarAttackLandingSteepness);
		ActorRotation = ProjectileComp.Velocity.Rotation();
		
		UIslandShieldotronMortarProjectileEventHandler::Trigger_OnLaunch(this, FIslandShieldotronMortarProjectileOnLaunchEventData(LaunchLocation, LaunchVelocity.GetSafeNormal()));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchMortarAttack(Game::Zoe, FIslandShieldotronMortarAttackPlayerEventData(ProjectileComp.Launcher, TargetLocation));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchMortarAttack(Game::Mio, FIslandShieldotronMortarAttackPlayerEventData(ProjectileComp.Launcher, TargetLocation));
	}

	void LaunchAt(FVector TargetLoc, AActor _TargetGround = nullptr)
	{
		Settings = UIslandShieldotronSettings::GetSettings(ProjectileComp.Launcher);

		CurrentTrajectory = DefaultTrajectory;

		LaunchLocation = ActorLocation;
		LaunchVelocity = ProjectileComp.Velocity;
		TargetLocation = TargetLoc;
		TargetGround = _TargetGround;
		float AirTimePerDist = Settings.MortarAttackProjectileAirTime / Settings.MortarAttackMinRange;
		float Dist = (TargetLoc - LaunchLocation).Size();
		TotalFlightDuration = Settings.MortarAttackProjectileAirTime;
		TotalFlightDuration = Math::Clamp(TotalFlightDuration, Settings.MortarAttackProjectileAirTime, Settings.MortarAttackProjectileAirTime * 2.0);
		PrevCurveLoc = FVector::ZeroVector;
		bHasPeaked = false;

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

		// Local movement 
		float FlightDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		float Alpha = FlightDuration / TotalFlightDuration;
		Alpha = CurrentTrajectory.TransformAlpha(Alpha);

		FVector NewCurveLoc = BezierCurve::GetLocation_2CP(
			LaunchLocation,
			LaunchLocation + LaunchVelocity.RotateTowards(ProjectileComp.Launcher.ActorRightVector, 0),
		 	TargetLocation - LandTangent.RotateTowards(ProjectileComp.Launcher.ActorRightVector * 1.0, 0),
			TargetLocation,
			Alpha);
		
		// Add an optional local offset around the curve trajectory.
		FVector LocalOffset = FVector::ZeroVector;
		if (PrevCurveLoc != FVector::ZeroVector)
		{
			LocalOffset = CurrentTrajectory.CalculateLocalOffset(NewCurveLoc, PrevCurveLoc, Alpha);
			ActorRotation = ( (NewCurveLoc + LocalOffset) - ActorLocation).Rotation();
		}
		
		if (!bHasPeaked && NewCurveLoc.Z < PrevCurveLoc.Z)
		{
			bHasPeaked = true;
			UIslandShieldotronMortarProjectileEventHandler::Trigger_OnPeakTrajectory(this);
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
				
				// prevent screen shake in sidescroller
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

			BezierCurve::DebugDraw_2CP(LaunchLocation,
					LaunchLocation + LaunchVelocity.RotateTowards(ProjectileComp.Launcher.ActorRightVector, 0),
					TargetLocation - LandTangent.RotateTowards(ProjectileComp.Launcher.ActorRightVector * 1.0, 0),
					TargetLocation, 
					FLinearColor::DPink
					);
			Debug::DrawDebugSphere(TargetLocation, 50, 12, FLinearColor::DPink, 3.0, 0.0, true);
		}
#endif		
	}
	
	void Expire()
	{
		FIslandShieldotronMortarProjectileOnHitEventData Params;
		Params.HitGroundActor = TargetGround;
		UnspawnDecal();
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
			Player.DealTypedDamage(ProjectileComp.Owner, Settings.MortarAttackDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);

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

	UFUNCTION()
	FVector LocalOffsetCorkscrew(FVector _NewCurveLoc, FVector _PrevCurveLoc, float Alpha)
	{
		// Define a local space at the current curve point
		FVector Tangent = (_NewCurveLoc - _PrevCurveLoc).GetSafeNormal();
		FVector RightVector = FVector::UpVector.CrossProduct(Tangent);
		FVector NormalVector = Tangent.CrossProduct(RightVector);
		
		// Reach maximum amplitude at Alpha = 0.5 and then return to 0 at Alpha = 1.0.
		float Amplitude = 1 - Math::Square(1 - 2*Alpha);
		Amplitude *= 250;
		
		// Circle planar to the curve tangent.
		FVector LocalOffset;
		LocalOffset += NormalVector * Amplitude * Math::Sin(Alpha*5);
		LocalOffset += RightVector * Amplitude * Math::Cos(Alpha*5);
		return LocalOffset;
	}

	// This needs to be called by Behaviour.
	void SpawnDecal(FVector _TargetLocation)
	{
		if (TelegraphDecal == nullptr)
			TelegraphDecal = SpawnActor(TelegraphDecalClass, _TargetLocation, Level = Level);

		TelegraphDecal.ActorLocation = TargetLocation;
		TelegraphDecal.ShowDecal();
	}

	private void UnspawnDecal()
	{
		check(TelegraphDecal != nullptr, "Decal was never spawned before unspawning.");

		TelegraphDecal.HideDecal();
		if (TelegraphDecal.AttachParentActor != nullptr)
			TelegraphDecal.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

}
