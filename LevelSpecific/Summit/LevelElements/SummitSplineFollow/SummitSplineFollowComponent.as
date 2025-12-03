class USummitSplineFollowComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASplineActor FollowSpline;

	FSplinePosition SplinePos;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bShouldMove = true;
	bool bDelayingMoveBack = false;

	float EndingReachedTimeStamp = 0.0;
	float MovingForwardsMultiplier = 1.0;
	UPROPERTY(EditAnywhere, Category = "Settings")
	USummitSplineFollowSettings Settings;

	AHazeActor ActorOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorOwner = Cast<AHazeActor>(Owner);
		Settings = USummitSplineFollowSettings::GetSettings(ActorOwner);

		if(FollowSpline == nullptr)
		{
			devError(f"{this} does not have a reference to a follow spline.");
			return;
		}
		SplinePos = FollowSpline.Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bDelayingMoveBack)
			return;

		if(Time::GetGameTimeSince(EndingReachedTimeStamp) >= Settings.EndDelay)
			StartReversing();
	}

	void MoveAlongSpline(float Distance)
	{
		if(!bShouldMove)
			return;

		bool bCouldMove = SplinePos.Move(Distance * MovingForwardsMultiplier);

		ActorOwner.SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation);

		if(bCouldMove)
			return;

		if(!Settings.bShouldPingPong)
			return;

		EndingReachedTimeStamp = Time::GetGameTimeSeconds();

		if(Settings.EndDelay == 0)
			StartReversing();
		else
		{
			bShouldMove = false;
			bDelayingMoveBack = true;
		}
	}

	void StartReversing()
	{
		MovingForwardsMultiplier *= -1;
		bDelayingMoveBack = false;
		bShouldMove = true;
	}
};