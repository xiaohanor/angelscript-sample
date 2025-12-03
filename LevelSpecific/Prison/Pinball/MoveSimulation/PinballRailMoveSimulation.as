struct FPinballRailMoveSimulation
{
	private const APinballRail Rail;

	void Initialize(const APinballRail InRail)
	{
		check(InRail != nullptr);
		Rail = InRail;
	}

	FVector Tick(float& DistanceAlongSpline, EPinballRailHeadOrTail EnterSide, float DeltaTime, float& Speed, bool&out bShouldExit, EPinballRailHeadOrTail&out ExitSide)
	{
		const UHazeSplineComponent RailSpline = Rail.Spline;
		
		const FTransform SplineTransform = RailSpline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		const float SplineVerticalFactor = SplineTransform.Rotation.ForwardVector.DotProduct(FVector::UpVector);

		if(Rail.bApplyGravity)
		{
			const float GravityAcceleration = -Drone::Gravity * SplineVerticalFactor;
			Speed += GravityAcceleration * DeltaTime;
		}

		if(Rail.bInterpTowardsTargetSpeed)
		{
			const FPinballTargetSpeedData TargetSpeedData = Rail.GetTargetSpeedData(DistanceAlongSpline, EnterSide);
			if(Math::Abs(Speed) < Math::Abs(TargetSpeedData.TargetSpeed))
				Speed = Math::FInterpConstantTo(Speed, TargetSpeedData.TargetSpeed, DeltaTime, TargetSpeedData.TargetSpeedAcceleration);
			else
				Speed = Math::FInterpConstantTo(Speed, TargetSpeedData.TargetSpeed, DeltaTime, TargetSpeedData.TargetSpeedDeceleration);
		}

		DistanceAlongSpline += (Speed * DeltaTime);

		FVector NewLocation = RailSpline.GetWorldLocationAtSplineDistance(DistanceAlongSpline);

		bShouldExit = false;
		if(DistanceAlongSpline < 0)
		{
			float DistanceLeft = Math::Abs(DistanceAlongSpline);
			FVector Direction = Rail.GetExitDirection(EPinballRailHeadOrTail::Head);
			NewLocation += Direction * DistanceLeft;
			bShouldExit = true;
			ExitSide = EPinballRailHeadOrTail::Head;
		}
		else if(DistanceAlongSpline > RailSpline.SplineLength)
		{
			float DistanceLeft = DistanceAlongSpline - RailSpline.SplineLength;
			FVector Direction = Rail.GetExitDirection(EPinballRailHeadOrTail::Head);
			NewLocation += Direction * DistanceLeft;
			bShouldExit = true;
			ExitSide = EPinballRailHeadOrTail::Tail;
		}

		DistanceAlongSpline = Math::Clamp(DistanceAlongSpline, 0, RailSpline.SplineLength);

		return NewLocation;
	}

#if EDITOR
	void Visualize(UHazeScriptComponentVisualizer Visualizer)
	{
		float Time = 0;
		float DistanceAlongSpline = Rail.VisualizeEnterSide == EPinballRailHeadOrTail::Head ? 0 : Rail.Spline.SplineLength;
		float Speed = Rail.GetSyncPoint(Rail.VisualizeEnterSide).GetEnterRailSpeed();
		const float Duration = Rail.VisualizeDuration;
		const float DeltaTime = 0.016;

		float PointTime = Time::GameTimeSeconds % Duration;
		bool bHasDrawnPoint = false;

		while(Time < Duration)
		{
			bool bShouldExit = false;
			EPinballRailHeadOrTail ExitSide;
			Tick(DistanceAlongSpline, Rail.VisualizeEnterSide, DeltaTime, Speed, bShouldExit, ExitSide);

			Time += DeltaTime;

			if(!bHasDrawnPoint && PointTime < Time)
			{
				bHasDrawnPoint = true;
				const FTransform SplineTransform = Rail.Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
				Visualizer.DrawWireSphere(SplineTransform.Location, 39, FLinearColor::Green, 3);

				if(Rail.bInterpTowardsTargetSpeed)
				{
					const FPinballTargetSpeedData TargetSpeedData = Rail.GetTargetSpeedData(DistanceAlongSpline, Rail.VisualizeEnterSide);
					const float TargetSpeed = TargetSpeedData.TargetSpeed;
					Visualizer.DrawWorldString(f"TargetSpeed: {Math::RoundToInt(TargetSpeed)}", SplineTransform.Location, FLinearColor::Green, 1);
				}
			}

			if(bShouldExit)
				break;
		}
	}
#endif
};