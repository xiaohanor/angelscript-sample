class ASkylineTorHammerBullet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;
	default Collision.CollisionProfileName = n"NoCollision";

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

	float ExpirationTime = 15.0;
	FHazeAcceleratedVector AccScale;
	float ScaleTimer;

	UFUNCTION()
	private void GravityBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		FHitResult HitResult(HitData.Actor, HitData.Component, HitData.ImpactPoint, HitData.ImpactNormal);
		Explode(HitResult);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorScale3D = FVector::ZeroVector;
		AccScale.SnapTo(FVector::ZeroVector);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AccScale.AccelerateTo(FVector::OneVector, 0.5, DeltaTime);
		ScaleTimer += DeltaTime * 6;
		ActorScale3D = AccScale.Value * (1 - (0.1 * Math::Sin(ScaleTimer)));

		if (!ProjectileComp.bIsLaunched)
			return;

		float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
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

		return false;
	}

	private void Move(float DeltaTime)
	{
		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(GetUpdatedMovementLocation(DeltaTime, Hit));
		SetActorRotation(ProjectileComp.Velocity.Rotation());

		FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
		Trace.UseCapsuleShape(Collision);
		if (ProjectileComp.Launcher != nullptr)
			Trace.IgnoreActor(ProjectileComp.Launcher);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);

		bool bImpacted = false;
		for(FOverlapResult Overlap: Overlaps.BlockHits)
		{
			if(Impact(Overlap))
				bImpacted = true;
		}

		if(bImpacted)
			Expire(FHitResult());
	}

	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false, float SubStepDuration = BIG_NUMBER)
	{
		FVector OwnLoc = ProjectileComp.Owner.ActorLocation;
		
		FVector Delta = FVector::ZeroVector;

		float Accel = 10;

		// Perform substepping movement
		float RemainingTime = DeltaTime;
		for(; RemainingTime > SubStepDuration; RemainingTime -= SubStepDuration)
		{
			ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * SubStepDuration;
			ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * SubStepDuration;
			Delta += ProjectileComp.Velocity * Accel * SubStepDuration;
		}

		// Move the remaining fraction of a substep
		ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * RemainingTime;
		ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * RemainingTime;
		Delta += ProjectileComp.Velocity * Accel * RemainingTime;

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
			}
			OutHit = Trace.QueryTraceSingle(OwnLoc, OwnLoc + Delta);
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

	void Explode(FHitResult Hit)
	{
		ProjectileComp.Expire();
	}

	bool Impact(FOverlapResult Overlap)
	{
		if (Overlap.Actor != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if(Player != nullptr)
			{
				FStumble Stumble;
				FVector Dir = ProjectileComp.Velocity.GetSafeNormal2D() * 0.5 + FVector::UpVector * 0.5;
				Stumble.Move = Dir * 250;
				Stumble.Duration = 0.5;
				Player.ApplyStumble(Stumble);
				
				USkylineTorPulseEventHandler::Trigger_OnImpact(this, FSkylineTorPulseEventHandlerOnImpactData(FHitResult()));
				
				UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Overlap.Actor);
				if (PlayerHealthComp != nullptr)
					PlayerHealthComp.DamagePlayer(0.5, nullptr, nullptr, false);

				return true;
			}
		}
		return false;
	}
}