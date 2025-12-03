class AEnforcerRocketLauncherProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"EnforcerRocketLauncherProjectileIndicatorCapability");

	UPROPERTY(DefaultComponent)
	UEnforcerRocketLauncherProjectileIndicatorComponent IndicatorComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	USphereComponent ExplosionRange;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UBasicAIHomingProjectileComponent HomingProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 4.0;

	bool bWhipGrabbed = false;
	bool bStopHoming = false;
	bool bWhipThrown = false;
	bool bAppeared = false;
	float AppearedTimer = 0;

	float DefaultFriction;
	float GrabbedSpeed;
	AHazeActor Target;
	FVector AppearLocation;
	FVector TargetVelocity;
	FHazeAcceleratedVector AccVelocity;
	FHazeRuntimeSpline AppearSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		GravityBladeResponseComp.OnHit.AddUFunction(this, n"GravityBladeHit");
		DefaultFriction = ProjectileComp.Friction;

		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");

		AppearSpline.AddPoint(FVector::ZeroVector);
		AppearSpline.AddPoint(FVector::ZeroVector);
	}
	
	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		IndicatorComp.HideIndicator();
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		UEnforcerRocketLauncherSettings RocketLauncherSettings = UEnforcerRocketLauncherSettings::GetSettings(ProjectileComp.Launcher);
		AppearLocation = ActorLocation + (ProjectileComp.Launcher.ActorUpVector * RocketLauncherSettings.AppearHeight) + (ProjectileComp.Launcher.ActorForwardVector * 100);
		TargetVelocity = (AppearLocation - ActorLocation).GetSafeNormal() * RocketLauncherSettings.AppearSpeed;
		WhipTarget.Enable(this);
	}

	UFUNCTION()
	private void GravityBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		FHitResult HitResult(HitData.Actor, HitData.Component, HitData.ImpactPoint, HitData.ImpactNormal);
		Explode(HitResult);
	}

	UFUNCTION()
	private void OnReset()
	{
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceEnemy;
		bStopHoming = false;
		bWhipGrabbed = false;
		bWhipThrown = false;
		bAppeared = false;
		AppearedTimer = 0;
		AccVelocity.SnapTo(FVector::ZeroVector);
		WhipTarget.Disable(this);
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		bWhipGrabbed = false;
		bWhipThrown = true;
		ProjectileComp.bIsLaunched = false;
		bStopHoming = false;

		FVector AimDir = Impulse.GetSafeNormal();

		UTargetableComponent PrimaryTarget = UPlayerTargetablesComponent::GetOrCreate(UserComponent.Owner).GetPrimaryTargetForCategory(GravityWhip::Grab::SlingTargetableCategory);
		if(PrimaryTarget != nullptr)
		{
			if(HomingProjectileComp != nullptr)
				HomingProjectileComp.Target = Cast<AHazeActor>(PrimaryTarget.Owner);

			AimDir = (Cast<AHazeActor>(PrimaryTarget.Owner).FocusLocation - ActorLocation).GetSafeNormal();
		}
		else
		{
			HomingProjectileComp.Target = nullptr;
		}

		ProjectileComp.Friction = DefaultFriction;
		ProjectileComp.Launch(AimDir * GrabbedSpeed * 2.0);		
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		IndicatorComp.HideIndicator();
		bWhipGrabbed = true;
		bAppeared = true;

		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTracePlayer;
		ProjectileComp.Launcher = Cast<AHazeActor>(UserComponent.Owner);
		ProjectileComp.Friction = 0.8;
		GrabbedSpeed = ProjectileComp.Velocity.Size();
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		if(bWhipGrabbed)
			return;
		
		auto RocketLauncherSettings = UEnforcerRocketLauncherSettings::GetSettings(ProjectileComp.Launcher);
		float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);

		if(!bAppeared)
		{
			if(ActorLocation.Z > AppearLocation.Z || AppearedTimer > 0)
			{
				TargetVelocity = (Target.FocusLocation - ActorLocation).GetSafeNormal()  * RocketLauncherSettings.LaunchSpeed;

				AppearedTimer += DeltaTime;

				if(AppearedTimer > RocketLauncherSettings.AppearTurnDuration)
				{
					ProjectileComp.Velocity = TargetVelocity;
					bAppeared = true;
				}
			}

			AccVelocity.AccelerateTo(TargetVelocity, RocketLauncherSettings.AppearTurnDuration, DeltaTime);
			ProjectileComp.Velocity = AccVelocity.Value;
		}
		else if(!StopHoming())
		{
			FVector TargetLocation = HomingProjectileComp.Target.ActorCenterLocation;
			ProjectileComp.Velocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, ProjectileComp.Velocity.GetSafeNormal(), 50.0 * Math::Min(1, LaunchDuration)) * DeltaTime;
			bStopHoming = ActorLocation.IsWithinDist(TargetLocation, RocketLauncherSettings.HomingStopWithinDistance);
		}

		FRotator Rotation = FRotator::ZeroRotator;
		if(!bAppeared)
			Rotation = (Target.FocusLocation - ActorLocation).Rotation();
		else
			Rotation = ProjectileComp.Velocity.Rotation();

		Move(DeltaTime, Rotation);

		if (LaunchDuration > ExpirationTime)
		{
			FHitResult Hit;
			Hit.Location = ActorLocation;
			Expire(Hit);
		}
	}

	private bool StopHoming()
	{
		if(ProjectileComp.Launcher == nullptr)
			return true;
		if(HomingProjectileComp == nullptr)
			return true;
		if(HomingProjectileComp.Target == nullptr)
			return true;

		// Ignore bStopHoming if it's a whip throw rocket
		if(bWhipThrown)
			return false;
		if(bStopHoming)
			return true;

		return false;
	}

	private void Move(float DeltaTime, FRotator Rotation)
	{
		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		SetActorRotation(Rotation);

		if (Hit.bBlockingHit)
			Expire(Hit);
	}

	void Expire(FHitResult Hit)
	{
		OnImpact(Hit);
		Explode(Hit);
		IndicatorComp.HideIndicator();
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	void Explode(FHitResult Hit)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
		Trace.UseSphereShape(ExplosionRange);
		if (ProjectileComp.Launcher != nullptr)
			Trace.IgnoreActor(ProjectileComp.Launcher);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);

		for(FOverlapResult Overlap: Overlaps.BlockHits)
		{
			Impact(Overlap);
		}

		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, Data);
		ProjectileComp.Expire();
		IndicatorComp.HideIndicator();
	}

	void Impact(FOverlapResult Overlap)
	{
		if (Overlap.Actor != nullptr)
		{
			auto RocketLauncherSettings = UEnforcerRocketLauncherSettings::GetSettings(ProjectileComp.Launcher);

			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Overlap.Actor);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(RocketLauncherSettings.RocketDamagePlayer, nullptr, nullptr, false);

			UEnforcerRocketLauncherResponseComponent ResponseComp = UEnforcerRocketLauncherResponseComponent::Get(Overlap.Actor);
			if(ResponseComp != nullptr)
				ResponseComp.OnHit.Broadcast(RocketLauncherSettings.RocketDamageNpc, ProjectileComp.DamageType, ProjectileComp.Launcher);
		}
	}

	private void UpdatePlayerHud()
	{
		
	}
}