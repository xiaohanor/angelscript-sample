class ASkylineTorDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;
	default Collision.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;
	default WhipResponse.bAllowMultiGrab = false;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent WhipOutline;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0;
	default ProjectileComp.Gravity = 0;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UBasicAIHomingProjectileComponent HomingProjectileComp;

	bool bWhipGrabbed = false;
	bool bWhipThrown = false;
	bool bStopHoming = false;
	float ExpirationTime = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
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
		bWhipGrabbed = false;
		bWhipThrown = false;
		bStopHoming = false;
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

		ProjectileComp.Launch(AimDir * Impulse.Size());
		bStopHoming = false;
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bWhipGrabbed = true;
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTracePlayer;
		ProjectileComp.Launcher = Cast<AHazeActor>(UserComponent.Owner);
		ProjectileComp.Friction = 0.8;
		ProjectileComp.AdditionalIgnoreActors.Empty();
		ProjectileComp.AdditionalIgnoreActors.Add(UserComponent.Owner);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshOffsetComp.AddLocalRotation(FRotator(500, 500, 0) * DeltaTime);

		if (!ProjectileComp.bIsLaunched)
			return;

		if(bWhipGrabbed)
			return;

		float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		if(!StopHoming())
		{
			FVector TargetLocation = HomingProjectileComp.Target.ActorCenterLocation;
			ProjectileComp.Velocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, ProjectileComp.Velocity.GetSafeNormal(), 300.0 * Math::Min(1, LaunchDuration)) * DeltaTime;
			bStopHoming = ActorLocation.IsWithinDist(TargetLocation, 50);
		}

		Move(DeltaTime);

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
		if(bStopHoming)
			return true;

		return false;
	}

	private void Deflect(AActor BounceActor)
	{
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceEnemy;
		ProjectileComp.Launcher = Cast<AHazeActor>(BounceActor);
		ProjectileComp.Friction = 0.8;
		ProjectileComp.AdditionalIgnoreActors.Empty();
		ProjectileComp.AdditionalIgnoreActors.Add(BounceActor);
		FVector Velocity = BounceActor.ActorRotation.RightVector.RotateAngleAxis(Math::RandRange(0, 360), BounceActor.ActorForwardVector) * ProjectileComp.Velocity.Size();
		ProjectileComp.bIsLaunched = false;
		bStopHoming = true;
		ProjectileComp.Launch(Velocity);

		FSkylineTorDebrisOnDeflectEventData Data;
		Data.DeflectingActor = Cast<AHazeActor>(BounceActor);
		USkylineTorDebrisEventHandler::Trigger_OnDeflected(this, Data);
	}

	private void Move(float DeltaTime)
	{
		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));

		if (Hit.bBlockingHit)
		{
			if(Hit.Actor.IsA(ASkylineTor))
				Deflect(Hit.Actor);
			else
				Expire(Hit);
		}
	}

	void Expire(FHitResult Hit)
	{
		OnImpact(Hit);
		Explode(Hit);
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	void Explode(FHitResult Hit)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
		Trace.UseCapsuleShape(Collision);
		if (ProjectileComp.Launcher != nullptr)
			Trace.IgnoreActor(ProjectileComp.Launcher);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);

		for(FOverlapResult Overlap: Overlaps.BlockHits)
		{
			Impact(Overlap);
		}

		FSkylineTorDebrisOnImpactHitEventData Data;
		Data.HitResult = Hit;
		USkylineTorDebrisEventHandler::Trigger_OnImpactHit(this, Data);
		ProjectileComp.Expire();
	}

	void Impact(FOverlapResult Overlap)
	{
		if (Overlap.Actor != nullptr)
		{
			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Overlap.Actor);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(0.5, nullptr, nullptr, false);

			USkylineTorDebrisResponseComponent ResponseComp = USkylineTorDebrisResponseComponent::Get(Overlap.Actor);
			if(ResponseComp != nullptr)
				ResponseComp.OnHit.Broadcast(0.25, ProjectileComp.DamageType, ProjectileComp.Launcher);
		}
	}
}