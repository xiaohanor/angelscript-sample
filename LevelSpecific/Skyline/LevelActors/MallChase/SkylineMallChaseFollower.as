event void FSkylineMallChaseFollowerSignature();
event void FSkylineMallChaseFollowerAttackSignature(AHazePlayerCharacter Player);

class ASkylineMallChaseFollower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASkylineMallChaseSpline MallChaseSpline;

	FSplinePosition SplinePosition;

	UPROPERTY(EditAnywhere)
	bool bIsActivated = false;

	UPROPERTY(EditAnywhere)
	bool bOnlyFireWhenInRange = false;
	bool bAnyPlayerInRange = false;

	float Speed = 0.0;

	UPROPERTY(EditAnywhere)
	float MinFollowSpeed = 300.0;
	float MaxFollowSpeed = 1000.0;

	UPROPERTY(EditAnywhere)
	float DistanceSpeedScale = 0.2;

	float ImpactInterval = 0.02;
	float ImpactTime = 0.0;
	int NumOfImpacts = 6;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem BulletImpact;

	UPROPERTY(EditAnywhere)
	UPlayerHealthSettings PlayerHealthSettings;

	UPROPERTY()
	FSkylineMallChaseFollowerSignature OnBothPlayerDead;

	UPROPERTY()
	FSkylineMallChaseFollowerSignature OnFollowerStart;

	UPROPERTY()
	FSkylineMallChaseFollowerAttackSignature OnPlayerBehindLine;

	TOptional<FAlongSplineComponentData> NextAlongSplineComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Speed = MinFollowSpeed;

		if (MallChaseSpline != nullptr)
			SplinePosition = MallChaseSpline.Spline.GetSplinePositionAtSplineDistance(0.0);		
	
		NextAlongSplineComp = MallChaseSpline.Spline.FindNextComponentAlongSpline(USkylineMallChaseAlongSplineComponent, false, SplinePosition.CurrentSplineDistance);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
			Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActivated)
			return;

		bAnyPlayerInRange = false;

		// Track Players
		float ClosestDistance = BIG_NUMBER;
		for (auto Player : Game::Players)
		{
			FVector ProjectedPlayerLocation = Math::ProjectPositionOnInfiniteLine(SplinePosition.WorldLocation, ActorForwardVector, Player.ActorLocation);
			float DistanceToFront = ActorTransform.InverseTransformPositionNoScale(ProjectedPlayerLocation).X;
	
			if (DistanceToFront < ClosestDistance)
				ClosestDistance = Math::Max(0.0, DistanceToFront);

			if (DistanceToFront < -400.0)
				bAnyPlayerInRange = true;

			// Kill Players behind death wall
			if (DistanceToFront < -500.0)
			{				
				OnPlayerBehindLine.Broadcast(Player);

/*
				Player.KillPlayer();

				if (Player.OtherPlayer.IsPlayerDead())
					OnBothPlayerDead.Broadcast();
*/
			}
		}

		Speed = Math::Lerp(Speed, MinFollowSpeed + (ClosestDistance * DistanceSpeedScale), 5.0 * DeltaSeconds);

		if (!SplinePosition.Move(Speed * DeltaSeconds))
		{
			Deactivate();
		}

		// Debug draw follower location
//		Debug::DrawDebugSphere(SplinePosition.WorldLocation, 50.0, 4, FLinearColor::LucBlue, 10.0, 0.0);

//		if (NextAlongSplineComp.IsSet())
//			Debug::DrawDebugSphere(NextAlongSplineComp.Value.Component.WorldLocation, 100.0, 4, FLinearColor::Green, 10.0, 0.0);

		// See if we past any component along the spline and activate it
		TOptional<FAlongSplineComponentData> PreviousAlongSplineComp = MallChaseSpline.Spline.FindPreviousComponentAlongSpline(USkylineMallChaseAlongSplineComponent, false, SplinePosition.CurrentSplineDistance);

		if (PreviousAlongSplineComp == NextAlongSplineComp)
		{
			NextAlongSplineComp = MallChaseSpline.Spline.FindNextComponentAlongSpline(USkylineMallChaseAlongSplineComponent, false, SplinePosition.CurrentSplineDistance);
			if (PreviousAlongSplineComp.IsSet())
			{
				auto MallChaseComp = Cast<USkylineMallChaseAlongSplineComponent>(PreviousAlongSplineComp.Value.Component);
				if (MallChaseComp != nullptr)
					MallChaseComp.Activate();
			}
		}

		FVector Location = SplinePosition.WorldLocation;
		FVector Direction = SplinePosition.WorldRotation.ForwardVector;

		FRotator Rotation = FRotator::MakeFromZX(FVector::UpVector, Direction);

		SetActorLocationAndRotation(Location, Rotation);
/*
		if (Time::GameTimeSeconds > ImpactTime)
		{
			// Effects
			for (int i = 0; i < NumOfImpacts; i++)
			{
				float RandomOffsetSide = Math::RandRange(-1000.0, 1000.0);
				float RandomOffsetDepth = Math::RandRange(-1000.0, 0.0);

				FVector Offset = ActorRightVector * RandomOffsetSide + ActorForwardVector * RandomOffsetDepth;

				FVector Start = ActorLocation + Offset + ActorUpVector * 1000.0;
				FVector End = Start - ActorUpVector * 5000.0;

				auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				auto HitResult = Trace.QueryTraceSingle(Start, End);

				FVector TraceDirection = (Start - End).SafeNormal;

				if (HitResult.bBlockingHit)
				{
					Niagara::SpawnOneShotNiagaraSystemAtLocation(BulletImpact, HitResult.ImpactPoint, TraceDirection.Rotation() + FRotator(-90.0, 0.0, 0.0));
				}
			}

			ImpactTime = Time::GameTimeSeconds + ImpactInterval;
		}
*/
	}

	UFUNCTION()
	void Activate()
	{
		TListedActors<ASkylineMallChaseRespawnPoint> RespawnPoints;
		for (auto Player : Game::Players)
		{
			for (auto RespawnPoint : RespawnPoints)
				RespawnPoint.EnableForPlayer(Player, Player);
		}

		bIsActivated = true;
		SetActorTickEnabled(true);

		OnFollowerStart.Broadcast();

		for (auto Player : Game::Players)
			Player.ApplySettings(PlayerHealthSettings, this);	
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActivated = false;
		SetActorTickEnabled(false);

		for (auto Player : Game::Players)
			Player.ClearSettingsByInstigator(this);
	}
};