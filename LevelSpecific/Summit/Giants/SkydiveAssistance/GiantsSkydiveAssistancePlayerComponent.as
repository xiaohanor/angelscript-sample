class UGiantsSkydiveAssistancePlayerComponent : UActorComponent
{
	AGiantsSkydiveAssistancePoint AssistancePoint;

	UPlayerMovementComponent MoveComp;
	UPlayerSkydiveComponent SkydiveComp;
	UPlayerWallRunComponent WallRunComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		SkydiveComp = UPlayerSkydiveComponent::Get(Owner);
		WallRunComp = UPlayerWallRunComponent::Get(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MoveComp.HasGroundContact()
		|| WallRunComp.HasActiveWallRun())
			AssistancePoint = nullptr;

		auto TempLog = TEMPORAL_LOG(this);

		if(AssistancePoint == nullptr)
			return;

		if(!SkydiveComp.IsSkydiveActive())
			return;
			
		float Dist = AssistancePoint.ActorLocation.Dist2D(Owner.ActorLocation, FVector::UpVector);
		TempLog.Value("Dist", Dist);

		if(Dist > AssistancePoint.MaxDistanceForAssistance)
		{
			// Debug::DrawDebugString(Owner.ActorLocation, "TOO FAR!");
			return;
		}

		if(Dist < AssistancePoint.MinDistanceForAssistance)
		{
			// Debug::DrawDebugString(Owner.ActorLocation, "TOO CLOSE!");
			return;
		}

		FVector DirToPoint = (AssistancePoint.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		DirToPoint = DirToPoint.ConstrainToPlane(FVector::UpVector);

		float DirPointForwardDot = DirToPoint.DotProduct(AssistancePoint.ActorForwardVector);
		TempLog.Value("Dir to Point Dot Point Forward", DirPointForwardDot);

		// Point is behind
		if(DirPointForwardDot < 0)
			return;

		FVector MovementInput = MoveComp.MovementInput;
		float InputDotPoint = MovementInput.DotProduct(DirToPoint);
		const float MinimumAssistanceFraction = 0.7;
		float FractionOfInputNotTowardsPoint = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(1.0, MinimumAssistanceFraction), InputDotPoint);
		
		// Debug::DrawDebugString(Owner.ActorLocation, "DOT " + InputDotPoint);

		TempLog
			.Value("Input dot point", InputDotPoint)
			.Value("Fraction Of Input Not Towards Point", FractionOfInputNotTowardsPoint)
		;

		FVector Impulse;

		float SpeedTowardsPoint = MoveComp.HorizontalVelocity.DotProduct(DirToPoint);
		if(SpeedTowardsPoint < AssistancePoint.MinSpeedThreshold)
			Impulse += DirToPoint * AssistancePoint.MinSpeedAcceleration * DeltaSeconds;

		Impulse += DirToPoint * FractionOfInputNotTowardsPoint * AssistancePoint.AssistanceForce * DeltaSeconds;
		MoveComp.AddPendingImpulse(Impulse);

		TempLog.Value("Assistance Impulse", Impulse);
	}

	UFUNCTION(BlueprintCallable)
	void SetAssistancePoint(AGiantsSkydiveAssistancePoint Point)
	{
		// PrintToScreen("SET ASSIST POINT " + Owner.ActorNameOrLabel, 10.0);
		AssistancePoint = Point;
	}
};