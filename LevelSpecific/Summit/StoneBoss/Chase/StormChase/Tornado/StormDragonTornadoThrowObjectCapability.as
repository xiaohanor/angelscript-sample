class UStormDragonTornadoThrowObjectCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStormDragonTornado Tornado;
	UHazeSplineComponent SplineComp;
	
	FSplinePosition SplinePosition;
	AHazeActor Object;
	AHazePlayerCharacter TargetPlayer;

	bool bLeftSpline;
	FHazeAcceleratedVector AccelDirection;
	FVector TargetDirection;
	float SplineAccelTime = 0.2;
	float ToPlayerAccelTime = 0.3;

	float MoveSpeed = 10000.0;

	bool bPlayerKilled;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Tornado = Cast<AStormDragonTornado>(Owner);

		if (Tornado.ThrowObjectSpline == nullptr)
			return;

		SplineComp = Tornado.ThrowObjectSpline.Spline;
		Object = Tornado.ThowObject;
		SplinePosition = SplineComp.GetSplinePositionAtSplineDistance(0.0);
		Object.ActorLocation = SplinePosition.WorldLocation;
		Object.ActorRotation = SplinePosition.WorldRotation.Rotator();

		if (Tornado.TargetPlayer == EHazeSelectPlayer::Mio)
			TargetPlayer = Game::Mio;
		else 
			TargetPlayer = Game::Zoe; 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Tornado.bThrowObject)
			return false;

		if (Tornado.ThrowObjectSpline.Spline == nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Tornado.bThrowObject)
			return true;

		if (Tornado.ThrowObjectSpline.Spline == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplinePosition = SplineComp.GetSplinePositionAtSplineDistance(0.0);
		AccelDirection.SnapTo(SplinePosition.WorldForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SplinePosition.CurrentSplineDistance <= Tornado.ThrowObjectSpline.Spline.SplineLength - (MoveSpeed * DeltaTime))
		{
			bLeftSpline = true;
		}

		if (!bLeftSpline)
		{
			SplinePosition.Move(MoveSpeed * DeltaTime);
			AccelDirection.AccelerateTo(SplinePosition.WorldForwardVector, SplineAccelTime, DeltaTime); 
		}
		else
		{
			if (!TargetPlayer.IsPlayerDead() && !bPlayerKilled)
			{
				TargetDirection = (TargetPlayer.ActorLocation - Object.ActorLocation).GetSafeNormal();
			}
			else
			{
				bPlayerKilled = true;
			}

			AccelDirection.AccelerateTo(TargetDirection, ToPlayerAccelTime, DeltaTime); 
		}

		FVector Direction = AccelDirection.Value.GetSafeNormal();
		Object.ActorLocation += Direction * MoveSpeed * DeltaTime;
	}
};