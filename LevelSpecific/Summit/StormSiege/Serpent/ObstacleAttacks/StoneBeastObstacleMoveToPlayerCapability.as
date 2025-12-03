class UStoneBeastObstacleMoveToPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AHazeActor OwningActor;
	UStoneBeastObstacleComponent ObstacleComp;

	FVector CurrentDirection;

	float MoveSpeed = 1200.0;

	float Radius = 2500.0;

	float LifeTime = 8.0;

	FHazeAcceleratedVector AccelVectorDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OwningActor = Cast<AHazeActor>(Owner);
		ObstacleComp = UStoneBeastObstacleComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (OwningActor.IsActorDisabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (OwningActor.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentDirection = (ObstacleComp.TargetPlayer.ActorLocation - OwningActor.ActorLocation).GetSafeNormal();
		float XRandomOffset = Math::RandRange(-0.6, 0.6);
		float YRandomOffset = Math::RandRange(-0.6, 0.6);
		float ZRandomOffset = Math::RandRange(-0.6, 0.6);
		CurrentDirection += FVector(XRandomOffset, YRandomOffset, ZRandomOffset);
		CurrentDirection.Normalize();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Target = ObstacleComp.TargetPlayer.ActorLocation + FVector(0.0, 0.0, 500.0);
		FVector TargetDir = (Target - OwningActor.ActorLocation).GetSafeNormal();
		// CurrentDirection = Math::VInterpConstantTo(CurrentDirection, TargetDir, DeltaTime, 0.8);
		FVector ViewDirection = ObstacleComp.TargetPlayer.GetViewRotation().Vector();
		FVector AddSpeedDirection = TargetDir.ConstrainToPlane(ViewDirection).GetSafeNormal();
		AccelVectorDirection.AccelerateTo(AddSpeedDirection, 0.5, 0.5);
		TargetDir += AccelVectorDirection.Value;
		TargetDir.Normalize();

		OwningActor.ActorLocation += TargetDir * MoveSpeed * DeltaTime;
		OwningActor.ActorRotation = (Target - OwningActor.ActorLocation).Rotation();

		if ((ObstacleComp.TargetPlayer.ActorLocation - OwningActor.ActorLocation).Size() <= Radius)
		{
			if (!ObstacleComp.TargetPlayer.IsAnyCapabilityActive(AdultDragonCapabilityTags::AdultDragonSmashMode) && !ObstacleComp.TargetPlayer.IsAnyCapabilityActive(AdultDragonTailSmash::Tags::AdultDragonTailSmash))
			{
				ObstacleComp.TargetPlayer.DamagePlayerHealth(ObstacleComp.Damage);
				DestroyObstacle();
			}
			else
			{
				return;
			}
		}

		LifeTime -= DeltaTime;

		if (LifeTime <= 0.0)
			DestroyObstacle();
	}

	//TODO when in range, trigger through obstacle component instead and have crystal and metal obstacles read from that
	void DestroyObstacle()
	{
		FOnStoneBeastObstacleDestructionParams Params;
		Params.Location = OwningActor.ActorLocation;
		UStoneBeastObstacleEffectHandler::Trigger_OnDestruction(OwningActor, Params);
		OwningActor.AddActorDisable(OwningActor);
	}
};