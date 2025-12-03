class UTundraGnatapultProjectileLauncherComponent : UBasicAIProjectileLauncherComponent
{
	bool bLoaded = false;
	ATundraGnatapultProjectile Projectile = nullptr;
}

class ATundraGnatapultProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UDecalComponent DangerIndicator;

	UTundraGnatapultSettings Settings;
	bool bLaunched;
	float StartGrowingTime;
	bool bCompletedGrowth;
	bool bDestroyed;
	float LaunchTime;
	float ExpirationTime;
	AHazeActor Target;

	FVector BaseScale = FVector::OneVector;
	FVector FinalRelativeLocation = FVector(0.0, 0.0, 100.0);

	UPrimitiveComponent TrajectoryBody;
	float TrajectoryDuration;
	FVector LocalLaunchLoc;
	FVector LocalTargetLoc;
	FVector LocalLaunchTangent;
	
	const FVector DangerIndicatorOffset = FVector::UpVector * 100.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		BaseScale = ActorScale3D;
		DangerIndicator.AddComponentVisualsBlocker(this);
		Mesh.AddComponentVisualsBlocker(this);
	}

	void StartMaking(USceneComponent Launcher, AHazeActor IntendedTarget)
	{
		Settings = UTundraGnatapultSettings::GetSettings(ProjectileComp.Launcher);
		bLaunched = false;
		StartGrowingTime = Time::GameTimeSeconds;
		bCompletedGrowth = false;
		bDestroyed = false;
		ExpirationTime = BIG_NUMBER;
		Target = IntendedTarget;
		SetActorTickEnabled(true);
		AttachToComponent(Launcher, NAME_None, EAttachmentRule::SnapToTarget);
		SetActorScale3D(BaseScale * 0.01);
		Mesh.RemoveComponentVisualsBlocker(this);

		DangerIndicator.WorldScale3D = FVector(Settings.ProjectileBlastRadius * 0.008);
		DangerIndicator.WorldRotation = FRotator(90.0, 0.0, 0.0);

		// Projectile is destroyed whenever launcher dies
		UBasicAIHealthComponent::Get(ProjectileComp.Launcher).OnDie.AddUFunction(this, n"OnLauncherDie");

		UTundraGnatapultProjectileEffectHandler::Trigger_OnStartGrowing(this);
	}

	UFUNCTION()
	private void OnLauncherDie(AHazeActor ActorBeingKilled)
	{
		FallApart();		
	}

	void FallApart()
	{
		if (!bDestroyed)
			UTundraGnatapultProjectileEffectHandler::Trigger_OnFallApart(this);
		PrepareForExpiration();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Target = nullptr;
		ProjectileComp.Reset();
		SetActorScale3D(BaseScale);
	}

	void Launch(FVector LocalTargetLocation, UPrimitiveComponent Body, AHazeActor LaunchTarget)
	{
		if (bDestroyed)
			return; // Can potentially occur in network

		bLaunched = true;
		LaunchTime = Time::GameTimeSeconds;
		Target = LaunchTarget;

		// Swell projectile to full size and final positioning if not already readied
		ActorScale3D = BaseScale;
		ActorRelativeLocation = FinalRelativeLocation;
		if (!bCompletedGrowth)
			CompleteGrowth();

		DetachRootComponentFromParent(true);	

		// Projectile trajectory will travel in walking stick local space
		TrajectoryBody = Body; 
		FTransform TrajetoryToLocal = TrajectoryBody.WorldTransform.Inverse();
		LocalLaunchLoc = TrajetoryToLocal.TransformPosition(ActorLocation);
		LocalTargetLoc = LocalTargetLocation;
		float HorizontalDistance = LocalLaunchLoc.Dist2D(LocalTargetLoc);
		TrajectoryDuration = Math::Max(0.5, HorizontalDistance / Settings.ProjectileSpeed);
		LocalLaunchTangent = (LocalTargetLoc - LocalLaunchLoc) * 0.5 + FVector::UpVector * Settings.ProjectileHeightFactor * HorizontalDistance;

		// Find where we would hit body
		FHitResult BodyHit;
		FHazeTraceSettings Trace = Trace::InitAgainstComponent(TrajectoryBody);
		Trace.UseLine();
		FTransform TrajectoryToWorld = TrajectoryBody.WorldTransform;
		FVector Start = TrajectoryToWorld.TransformPosition(BezierCurve::GetLocation_1CP(LocalLaunchLoc, LocalLaunchLoc + LocalLaunchTangent, LocalTargetLoc, 0.5));
		for (float Alpha = 0.7; Alpha < 1.0001; Alpha += 0.2)
		{
			FVector End = TrajectoryToWorld.TransformPosition(BezierCurve::GetLocation_1CP(LocalLaunchLoc, LocalLaunchLoc + LocalLaunchTangent, LocalTargetLoc, Alpha));
			BodyHit = Trace.QueryTraceComponent(Start, End);
			if (BodyHit.bBlockingHit)
				break;
			Start = End;
		}

		FVector DangerLoc = (BodyHit.bBlockingHit) ? BodyHit.ImpactPoint : TrajectoryToWorld.TransformPosition(BezierCurve::GetLocation_1CP(LocalLaunchLoc, LocalLaunchLoc + LocalLaunchTangent, LocalTargetLoc, 1.0));
		DangerIndicator.SetWorldLocation(DangerLoc + DangerIndicatorOffset);
		DangerIndicator.AttachToComponent(TrajectoryBody, NAME_None, EAttachmentRule::KeepWorld);
		DangerIndicator.RemoveComponentVisualsBlocker(this);

		UTundraGnatapultProjectileEffectHandler::Trigger_OnLaunch(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		if (Time::GameTimeSeconds > ExpirationTime)
			ProjectileComp.Expire();

		if (bDestroyed)
			return;

		// TODO: Can't set this in start making for some reason fix after UXR
		DangerIndicator.WorldScale3D = FVector(Settings.ProjectileBlastRadius * 0.004);
		DangerIndicator.WorldRotation = FRotator(90.0, 0.0, 0.0);

		if (!bLaunched)
		{
			// Grow to full size
			float GrowthDuration = Time::GetGameTimeSince(StartGrowingTime);
			float GrowthAlpha = Math::Clamp(GrowthDuration / Settings.ReloadMinDuration, 0.01, 1.0);
			ActorScale3D = BaseScale * GrowthAlpha;
			ActorRelativeLocation = FinalRelativeLocation * GrowthAlpha;
			Mesh.RelativeRotation = FRotator(-GrowthDuration * 480.0, 0.0, 0.0); // Spin projectile as it is growing
			if (!bCompletedGrowth && (GrowthAlpha > 1.0 - SMALL_NUMBER))
				CompleteGrowth();
			if ((GrowthDuration > Settings.ReloadDangerIndicatorDelay) && IsValid(Target) && (DangerIndicator.AttachParent != Target.RootComponent))
			{
				DangerIndicator.WorldLocation = Target.ActorLocation + DangerIndicatorOffset;
				DangerIndicator.AttachToComponent(Target.RootComponent, NAME_None, EAttachmentRule::KeepWorld);
				DangerIndicator.RemoveComponentVisualsBlocker(this);
			}
			return;
		}

		float LaunchDuration = Time::GetGameTimeSince(LaunchTime);
		float Alpha = LaunchDuration / TrajectoryDuration;
		FVector NewLoc = TrajectoryBody.WorldTransform.TransformPosition(BezierCurve::GetLocation_1CP(LocalLaunchLoc, LocalLaunchLoc + LocalLaunchTangent, LocalTargetLoc, Alpha));
		if (Alpha > 0.5)
		{ 
			// Falling, see if we hit body
			FHazeTraceSettings Trace = Trace::InitAgainstComponent(TrajectoryBody);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceComponent(ActorLocation, NewLoc);
			if (Hit.bBlockingHit)
				Detonate();
		}
		// Always detonate at end of trajectory currently
		if (!bDestroyed && (Alpha > 1.0))
			Detonate(); 

		if (!bDestroyed && (LaunchDuration > 2.0 * TrajectoryDuration))
			PrepareForExpiration();

		ActorLocation = NewLoc;
	}

	void PrepareForExpiration()
	{
		bDestroyed = true;
		UBasicAIHealthComponent::Get(ProjectileComp.Launcher).OnDie.UnbindObject(this);
		Mesh.AddComponentVisualsBlocker(this);
		DangerIndicator.AddComponentVisualsBlocker(this);
		ExpirationTime = Time::GameTimeSeconds + Settings.ProjectileRemainAfterDestructionTime;
	}

	void CompleteGrowth()
	{
		UTundraGnatapultProjectileEffectHandler::Trigger_OnDoneGrowing(this);
		bCompletedGrowth = true;
	}

	void Detonate()
	{
		PrepareForExpiration();
		DangerIndicator.AddComponentVisualsBlocker(this);

		// Attach so that any lingering effects will stay in body local space where we detonated
		AttachRootComponentTo(TrajectoryBody, NAME_None, EAttachLocation::KeepWorldPosition);		

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsZoe())
				continue; //Never hurt poor Zoe (maybe change this to never hurt lifegiving Zoe or something down the line)
			if (!Player.HasControl())
				continue; 
			if (!Player.ActorLocation.IsWithinDist(ActorLocation, Settings.ProjectileBlastRadius))
				continue;
			Player.DamagePlayerHealth(Settings.ProjectileDamage);
		}
		
		UTundraGnatapultProjectileEffectHandler::Trigger_OnHit(this);
	}
}

UCLASS(Abstract)
class UTundraGnatapultProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGrowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoneGrowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFallApart() {}
}
