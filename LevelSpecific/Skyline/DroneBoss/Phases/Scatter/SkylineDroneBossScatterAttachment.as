enum ESkylineDroneBossScatterAttachmentState
{
	Attached,
	Loose,
	Grabbed,
	Thrown
}

class ASkylineDroneBossScatterAttachment : ASkylineDroneBossAttachment
{
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineDroneBossScatterAttachmentAttackCapability");

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectilePivot;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeTargetComponent;
	default BladeTargetComponent.bOverrideSuctionReachDistance = true;
	default BladeTargetComponent.SuctionReachDistance = 150.0;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTargetComponent;
	default WhipTargetComponent.MaximumDistance = 5000.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComponent;
	default WhipResponseComponent.GrabMode = EGravityWhipGrabMode::Sling;
	default WhipResponseComponent.CategoryName = n"Attachment";
	default WhipResponseComponent.OffsetRadius = 150.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	TSubclassOf<ASkylineDroneBossScatterProjectile> ProjectileClass;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	TSubclassOf<ASkylineDroneBossScatterTrail> TrailClass;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	int NumProjectiles = 6;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	float ProjectileOffsetDistance = 300.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	float AttackDelay = 2.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	float AttackInterval = 2.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	float FireDelay = 2.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	float FireInterval = 0.2;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attack")
	float ImpactBossDamage = 0.04;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Movement")
	float AccelerationDuration = 0.8;

	FHazeTimeLike LoosenTimeLike;
	default LoosenTimeLike.Duration = 0.5;
	default LoosenTimeLike.UseSmoothCurveZeroToOne();

	float GrabTimestamp = 0.0;
	USweepingMovementData Movement;
	ESkylineDroneBossScatterAttachmentState State;

	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedQuat AcceleratedRotation;

	FVector Velocity;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComponent.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");
		BladeResponseComponent.OnHit.AddUFunction(this, n"HandleHit");
		WhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComponent.OnThrown.AddUFunction(this, n"HandleThrown");

		LoosenTimeLike.BindUpdate(this, n"HandleLoosenUpdate");
		LoosenTimeLike.BindFinished(this, n"HandleLoosenFinished");

		WhipTargetComponent.Disable(this);

		Movement = MovementComponent.SetupSweepingMovementData();
		MovementComponent.AddMovementIgnoresActor(n"Default", Game::Zoe);
		MovementComponent.AddMovementIgnoresActor(this, AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		switch (State)
		{
		case ESkylineDroneBossScatterAttachmentState::Grabbed:
			GrabMovement(DeltaTime);
			break;
		case ESkylineDroneBossScatterAttachmentState::Thrown:
			ThrowMovement(DeltaTime);
			break;
		default:
			break;
		}
	}

	private void GrabMovement(float DeltaTime)
	{
	}

	private void ThrowMovement(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(Movement))
		{
			Movement.AddVelocity(Velocity);
			Movement.BlockGroundTracingForThisFrame();
			MovementComponent.ApplyMove(Movement);

			if (MovementComponent.HasAnyValidBlockingContacts())
			{
				TArray<AActor> AttachedActors;
				GetAttachedActors(AttachedActors);

				for (auto AttachedActor : AttachedActors)
					AttachedActor.DestroyActor();

				if (MovementComponent.HasWallContact())
				{
					auto ImpactBoss = Cast<ASkylineDroneBoss>(MovementComponent.WallContact.Actor);
					if (ImpactBoss != nullptr)
					{
						ImpactBoss.HealthComponent.TakeDamage(ImpactBossDamage);
					}
				}

				DestroyAttachment();
			}
		}
	}
	
	UFUNCTION()
	private void HandleLoosenUpdate(float CurrentValue)
	{
		auto Parent = Root.AttachParent;

		FVector OffsetLocation =
			Parent.WorldLocation + 
			Parent.UpVector * 125.0 + 
			-FVector::UpVector * 150.0;

		FQuat OffsetRotation = FQuat::MakeFromEuler(FVector(
			10.0,
			0.0,
			5.0
		));
		FQuat TargetQuat = OffsetRotation.Inverse() * Parent.ComponentQuat;

		FVector Location = Math::Lerp(Parent.WorldLocation, OffsetLocation, CurrentValue);
		FQuat Rotation = FQuat::Slerp(Parent.ComponentQuat, TargetQuat, CurrentValue);
		
		SetActorLocationAndRotation(Location, Rotation);
	}

	UFUNCTION()
	private void HandleLoosenFinished()
	{
		State = ESkylineDroneBossScatterAttachmentState::Loose;
		WhipTargetComponent.Enable(this);
	}

	UFUNCTION()
	private void HandleTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		if (State != ESkylineDroneBossScatterAttachmentState::Attached)
			return;

		if (HealthComponent.CurrentHealth < SMALL_NUMBER)
		{
			BladeTargetComponent.Disable(this);
			LoosenTimeLike.PlayFromStart();
		}
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (State == ESkylineDroneBossScatterAttachmentState::Loose)
			return;

		auto HazeActor = Cast<AHazeActor>(CombatComp.Owner);
		HealthComponent.TakeDamage(HitData.Damage * 0.5, HitData.DamageType, HazeActor);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		State = ESkylineDroneBossScatterAttachmentState::Grabbed;

		AcceleratedLocation.SnapTo(ActorLocation);
		AcceleratedRotation.SnapTo(ActorQuat);
		GrabTimestamp = Time::GameTimeSeconds;

		TArray<UPrimitiveComponent> Primitives;
		GetComponentsByClass(Primitives);

		for (auto Primitive : Primitives)
		{
			Primitive.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
		}

		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		State = ESkylineDroneBossScatterAttachmentState::Thrown;
		Velocity = Impulse;

		MovementComponent.RemoveMovementIgnoresActor(this);
	}
}