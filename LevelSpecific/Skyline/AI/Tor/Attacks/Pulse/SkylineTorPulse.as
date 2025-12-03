class ASkylineTorPulse : AHazeActor
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

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	float ExpirationTime = 3.0;
	FHazeAcceleratedVector AccScale;
	float ScaleTimer;
	float TargetScale = 1;
	ASkylineTor TorBoss;

	UFUNCTION()
	private void GravityBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		FHitResult HitResult(HitData.Actor, HitData.Component, HitData.ImpactPoint, HitData.ImpactNormal);
		Explode(HitResult);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.WorldScale3D = FVector::ZeroVector;
		AccScale.SnapTo(FVector::ZeroVector);

		auto MusicManager = UHazeAudioMusicManager::Get();
		if(MusicManager != nullptr)
		{
			MusicManager.OnMainMusicBeat().AddUFunction(this, n"OnMusicBeat");
		}
	}

	UFUNCTION()
	private void OnMusicBeat()
	{
		TargetScale = 1.75;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TargetScale = Math::Clamp(TargetScale - DeltaTime * 4, 1, 2);
		AccScale.SpringTo(FVector::OneVector * TargetScale, 500, 0.5, DeltaTime);
		Mesh.WorldScale3D = AccScale.Value;

		if (!ProjectileComp.bIsLaunched)
			return;

		float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		Move(DeltaTime);

		if (LaunchDuration > ExpirationTime)
		{
			FHitResult Hit;
			Hit.Location = ActorLocation;
			Expire(Hit);
			ForceFeedbackComp.Stop();
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

		if(Hit.bBlockingHit)		
		{
			Impact(Hit);
			Expire(Hit);
			ForceFeedbackComp.Stop();
		}
	}

	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false, float SubStepDuration = BIG_NUMBER)
	{
		FVector OwnLoc = ProjectileComp.Owner.ActorLocation;
		
		FVector Delta = FVector::ZeroVector;

		float Accel = 3.5;

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
		USkylineTorPulseEventHandler::Trigger_OnImpact(this, FSkylineTorPulseEventHandlerOnImpactData(Hit));
		ProjectileComp.Expire();
		ForceFeedbackComp.Stop();
	}

	bool Impact(FHitResult Hit)
	{
		if (Hit.Actor != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if(Player != nullptr)
			{
				FStumble Stumble;
				FVector Dir = ProjectileComp.Velocity.GetSafeNormal2D() * 0.5 + FVector::UpVector * 0.5;
				Stumble.Move = Dir * 750;
				Stumble.Duration = 0.5;
				Player.ApplyStumble(Stumble);
				
				USkylineTorEventHandler::Trigger_OnPulseAttackImpact(TorBoss, FSkylineTorPulseImpactEventData(ActorLocation));
				
				UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Hit.Actor);
				if (PlayerHealthComp != nullptr)
					PlayerHealthComp.DamagePlayer(0.5, DamageEffect, DeathEffect, false);

				return true;
			}
		}
		return false;
	}
}