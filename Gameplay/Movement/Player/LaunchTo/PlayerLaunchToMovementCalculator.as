struct FPlayerLaunchToMovementCalculator
{
	private FPlayerLaunchToParameters Params;

	private FVector InitialVelocity;
	private FVector InitialPosition;
	private FVector Gravity;

	private float StartTimeOffset = 0.0;

	void Start(AHazePlayerCharacter Player, FPlayerLaunchToParameters Parameters, float StartDeltaTime)
	{
		Params = Parameters;
		StartTimeOffset = StartDeltaTime;

		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
		Gravity = MoveComp.GetGravity();

		if (Params.Type == EPlayerLaunchToType::LaunchToPoint)
		{
			FVector Distance = Params.GetWorldTargetLocation() - Player.ActorLocation;

			FVector HorizontalDistance = Distance.ConstrainToPlane(MoveComp.WorldUp);
			float VerticalDistance = Distance.DotProduct(MoveComp.WorldUp);

			InitialVelocity = HorizontalDistance / Params.Duration;
			InitialVelocity += MoveComp.WorldUp * Trajectory::GetSpeedToReachTarget(VerticalDistance, Params.Duration, -MoveComp.GravityForce);

			if (Params.LaunchRelativeToComponent != nullptr)
			{
				InitialPosition = Params.LaunchRelativeToComponent.WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation);
				InitialVelocity = Params.LaunchRelativeToComponent.WorldTransform.InverseTransformVectorNoScale(InitialVelocity);
				Gravity = Params.LaunchRelativeToComponent.WorldTransform.InverseTransformVectorNoScale(Gravity);
			}
			else
			{
				InitialPosition = Player.ActorLocation;
			}
		}
		else if (Params.Type == EPlayerLaunchToType::LerpToPointWithCurve)
		{
			if (Params.LaunchRelativeToComponent != nullptr)
				InitialPosition = Params.LaunchRelativeToComponent.WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation);
			else
				InitialPosition = Player.ActorLocation;

			InitialVelocity = (Params.LaunchToLocation - InitialVelocity).GetSafeNormal();
		}
		else if (Params.Type == EPlayerLaunchToType::LaunchWithImpulse)
		{
			InitialVelocity = Params.LaunchImpulse;
			InitialPosition = Player.ActorLocation;
		}
	}

	FVector GetCurrentWorldLocation(float Time)
	{
		float TimeMoving = Time + StartTimeOffset;
		if (Params.Type == EPlayerLaunchToType::LaunchToPoint || Params.Type == EPlayerLaunchToType::LaunchWithImpulse)
			TimeMoving = Math::Min(TimeMoving, Params.Duration);
		TimeMoving = Math::Max(Time, 0.0);

		if (Params.Type == EPlayerLaunchToType::LerpToPointWithCurve)
		{
			float CurveAlpha = Time / Params.Duration;
			if (Params.LaunchCurve != nullptr)
				CurveAlpha = Params.LaunchCurve.GetFloatValue(CurveAlpha);
			else
				CurveAlpha = Curve::SmoothCurveZeroToOne.GetFloatValue(CurveAlpha);

			FVector WorldInitialLocation = InitialPosition;
			if (Params.LaunchRelativeToComponent != nullptr)
				WorldInitialLocation = Params.LaunchRelativeToComponent.WorldTransform.TransformPositionNoScale(WorldInitialLocation);
			FVector WorldTargetLocation = Params.GetWorldTargetLocation();
			return Math::Lerp(WorldInitialLocation, WorldTargetLocation, Math::Saturate(CurveAlpha));
		}
		else
		{
			FVector CurrentPosition =
				InitialPosition
				+ InitialVelocity * TimeMoving
				+ Gravity * Math::Square(TimeMoving) * 0.5;

			if (Params.Type == EPlayerLaunchToType::LaunchToPoint && Params.LaunchRelativeToComponent != nullptr)
				CurrentPosition = Params.LaunchRelativeToComponent.WorldTransform.TransformPositionNoScale(CurrentPosition);

			return CurrentPosition;
		}
	}

	FVector GetCurrentFrameWorldMovement(float FrameStartTime, float DeltaTime)
	{
		return GetCurrentWorldLocation(FrameStartTime - DeltaTime)
			- GetCurrentWorldLocation(FrameStartTime);
	}

	FVector GetCurrentWorldVelocity(float TimeMoving)
	{
		if (Params.Type == EPlayerLaunchToType::LerpToPointWithCurve)
		{
			float Step = 1.0 / 60.0;
			return GetCurrentFrameWorldMovement(TimeMoving, Step) / Step;
		}

		return InitialVelocity + Gravity * TimeMoving;
	}

	FQuat GetCurrentTargetRotation(float Time)
	{
		if (Params.Type == EPlayerLaunchToType::LaunchToPoint && Params.LaunchRelativeToComponent != nullptr)
			return FQuat::MakeFromZX(-Gravity, Params.LaunchRelativeToComponent.WorldTransform.TransformVectorNoScale(InitialVelocity));
		else
			return FQuat::MakeFromZX(-Gravity, InitialVelocity);
	}

	FVector GetExitVelocity()
	{
		if (Params.ExitVelocity.IsSet())
			return Params.ExitVelocity.GetValue();
		if (Params.Type == EPlayerLaunchToType::LerpToPointWithCurve)
			return GetCurrentWorldVelocity(Params.Duration - (1.0 / 60.0));
		return GetCurrentWorldVelocity(Params.Duration);
	}
}