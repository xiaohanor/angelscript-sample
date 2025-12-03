class AMeltdownScreenWalkEnemy : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Enemy_Mesh;
	
	UPROPERTY(EditAnywhere)
	float Speed = 500.0;

	UPROPERTY(EditAnywhere)
	float TurnSpeed = 1;

	AHazeActor Target;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Target = Game::GetClosestPlayer(ActorLocation);

		FVector ToTarget = Target.ActorCenterLocation - ActorLocation;

		FQuat NewRotation = FQuat::Slerp(ActorQuat,ToTarget.ToOrientationQuat(),TurnSpeed * DeltaSeconds);

		FVector DeltaMove = NewRotation.ForwardVector * Speed * DeltaSeconds;

		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);

		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if(HitResult.bBlockingHit)
		{
			auto Player = Cast<AHazePlayerCharacter>(HitResult.Actor);

			if (Player != nullptr)
				Player.DamagePlayerHealth(1.0);

		//	DestroyActor();
		}

		SetActorLocationAndRotation(ActorLocation + DeltaMove, NewRotation);

	}

	UFUNCTION(BlueprintCallable)
	void KillEvent()
	{
		DestroyActor();
	}
};