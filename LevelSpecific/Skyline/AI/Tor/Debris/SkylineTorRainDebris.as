class ASkylineTorRainDebris : AHazeActor
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
	default ProjectileComp.TraceType = ETraceTypeQuery::WorldGeometry;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UBasicAIHomingProjectileComponent HomingProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	bool bLanded = false;
	bool bWhipGrabbed = false;
	bool bWhipThrown = false;
	bool bStopHoming = false;
	float ExpirationTime = 3.0;
	FVector TargetLandLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		ProjectileComp.OnPrime.AddUFunction(this, n"Prime");
		RespawnComp.OnUnspawn.AddUFunction(this, n"Unspawn");

		WhipTarget.Disable(this);
	}

	UFUNCTION()
	private void Unspawn(AHazeActor RespawnableActor)
	{
		USkylineTorRainDebrisEventHandler::Trigger_OnTelegraphStop(this);
	}

	UFUNCTION()
	private void Prime(UBasicAIProjectileComponent Projectile)
	{
		USkylineTorRainDebrisEventHandler::Trigger_OnTelegraphStart(this, FSkylineTorRainDebrisEventHandlerOnTelegraphStartData(TargetLandLocation));
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
		ProjectileComp.TraceType = ETraceTypeQuery::WorldGeometry;
		bLanded = false;
		bWhipGrabbed = false;
		bWhipThrown = false;
		bStopHoming = false;
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
		bLanded = false;
		USkylineTorRainDebrisEventHandler::Trigger_OnTelegraphStop(this);
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
		if(bLanded)
			return;

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

	private void Move(float DeltaTime)
	{
		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(GetUpdatedMovementLocation(DeltaTime, Hit));

		if (Hit.bBlockingHit)
			Explode(Hit);
	}

	// Helper function for simple trace projectiles
	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false, float SubStepDuration = BIG_NUMBER)
	{
		FVector OwnLoc = ProjectileComp.Owner.ActorLocation;
		
		FVector Delta = FVector::ZeroVector;

		// Perform substepping movement
		float RemainingTime = DeltaTime;
		for(; RemainingTime > SubStepDuration; RemainingTime -= SubStepDuration)
		{
			ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * SubStepDuration;
			ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * SubStepDuration;
			Delta += ProjectileComp.Velocity * SubStepDuration;
		}

		// Move the remaining fraction of a substep
		ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * RemainingTime;
		ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * RemainingTime;
		Delta += ProjectileComp.Velocity * RemainingTime;

		if (Delta.IsNearlyZero())
			return OwnLoc;

		if (!bIgnoreCollision)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
			Trace.UseCapsuleShape(Collision);
			Trace.IgnoreActors(ProjectileComp.AdditionalIgnoreActors);

			if (ProjectileComp.Launcher != nullptr)
			{	
				Trace.IgnoreActor(ProjectileComp.Launcher, ProjectileComp.bIgnoreDescendants);

				if (ProjectileComp.bIgnoreLauncherAttachParents)
				{
					AActor AttachParent = ProjectileComp.Launcher.AttachParentActor;
					while (AttachParent != nullptr)
					{
						Trace.IgnoreActor(AttachParent);
						AttachParent = AttachParent.AttachParentActor;
					}				
				}
			}
			OutHit = Trace.QueryTraceSingle(OwnLoc, OwnLoc + Delta);

			float DeltaDistance = Collision.WorldLocation.Distance(Collision.WorldLocation + Delta);
			float Factor = (OutHit.Distance / DeltaDistance);
			
			if(OutHit.bBlockingHit)
				return OwnLoc + Delta * Factor;
		}

		return OwnLoc + Delta;
	}

	void Expire(FHitResult Hit)
	{
		OnImpact(Hit);
		Explode(Hit);
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	void Land(FHitResult Hit)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseCapsuleShape(Collision);
		if (ProjectileComp.Launcher != nullptr)
			Trace.IgnoreActor(ProjectileComp.Launcher);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);

		for(FOverlapResult Overlap: Overlaps.BlockHits)
			Damage(Overlap);

		FSkylineTorDebrisOnImpactHitEventData Data;
		Data.HitResult = Hit;
		USkylineTorDebrisEventHandler::Trigger_OnImpactHit(this, Data);
		bLanded = true;

		USkylineTorRainDebrisEventHandler::Trigger_OnLanded(this, FSkylineTorRainDebrisEventHandlerOnLandedStartData(Hit));
		USkylineTorRainDebrisEventHandler::Trigger_OnTelegraphStop(this);
	}

	void Explode(FHitResult Hit)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
		Trace.UseCapsuleShape(Collision);
		if (ProjectileComp.Launcher != nullptr)
			Trace.IgnoreActor(ProjectileComp.Launcher);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);

		for(FOverlapResult Overlap: Overlaps.BlockHits)
			Damage(Overlap);

		FSkylineTorRainDebrisOnImpactEventData Data;
		Data.HitResult = Hit;
		USkylineTorRainDebrisEventHandler::Trigger_OnImpact(this, Data);
		ProjectileComp.Expire();
	}

	void Damage(FOverlapResult Overlap)
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