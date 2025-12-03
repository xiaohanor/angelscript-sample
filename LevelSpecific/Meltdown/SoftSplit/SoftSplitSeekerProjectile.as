class ASoftSplitSeekerProjectile : AWorldLinkDoubleActor
{
	UPROPERTY(EditAnywhere)
	float Speed = 500.0;

	UPROPERTY(EditAnywhere)
	float TurnSpeed = 1;

	AHazePlayerCharacter Target;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Manager = ASoftSplitManager::GetSoftSplitManger();

		EHazeWorldLinkLevel VisibleInSplit = Manager.GetVisibleSoftSplitAtLocation(ActorLocation);

		// Determine which player is closest for targeting
		Target = Manager.GetClosestPlayerTo(ActorLocation, GetBaseSoftSplit());

		if (Target != nullptr)
		{
			FVector TargetLocation = Manager.Position_Convert(Target.ActorCenterLocation, Manager.GetSplitForPlayer(Target), GetBaseSoftSplit());

			FVector ToTarget = TargetLocation - ActorLocation;
			FQuat NewRotation = FQuat::Slerp(ActorQuat,ToTarget.ToOrientationQuat(),TurnSpeed * DeltaSeconds);
			FVector DeltaMove = NewRotation.ForwardVector * Speed * DeltaSeconds;

			auto Trace = Trace::InitProfile(n"BlockAllDynamic");

			FVector SplitLocation = Manager.Position_Convert(ActorLocation, GetBaseSoftSplit(), VisibleInSplit);
			auto HitResult = Trace.QueryTraceSingle(SplitLocation, SplitLocation + DeltaMove);
			if (HitResult.bBlockingHit)
			{
				auto Player = Cast<AHazePlayerCharacter>(HitResult.Actor);

				if (Player != nullptr)
					Player.DamagePlayerHealth(0.5);

				SetActorLocationAndRotation(HitResult.Location, NewRotation);
				DestroyActor();
			}
			else
			{
				SetActorLocationAndRotation(ActorLocation + DeltaMove, NewRotation);
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void KillEvent()
	{
		DestroyActor();
	}
};