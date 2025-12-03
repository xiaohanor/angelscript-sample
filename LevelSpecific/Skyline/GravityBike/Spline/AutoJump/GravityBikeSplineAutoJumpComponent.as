UCLASS(NotBlueprintable, NotPlaceable)
class UGravityBikeSplineAutoJumpComponent : UActorComponent
{
	private AGravityBikeSplineAutoJumpTarget Target = nullptr;

	const float STEERING_ADJUST_SPEED = 50;

	void SetTarget(AGravityBikeSplineAutoJumpTarget InTarget)
	{
		check(Target == nullptr);
		Target = InTarget;
	}

	bool HasTarget() const
	{
		return Target != nullptr;
	}

	FTraversalTrajectory PlotTrajectory(FVector InitialLocation, FVector InitialVelocity, FVector WorldUp, float Gravity) const
	{
		if(!ensure(HasTarget()))
			return FTraversalTrajectory();

		const FVector InitialHorizontalVelocity = InitialVelocity.VectorPlaneProject(WorldUp);

		const FVector ClosestPointOnTrajectory = Math::ClosestPointOnInfiniteLine(InitialLocation, InitialLocation + InitialHorizontalVelocity, Target.ActorLocation);
		const FVector TargetLocation = Math::ClosestPointOnLine(Target.GetLeftEdgeLocation(), Target.GetRightEdgeLocation(), ClosestPointOnTrajectory);

		//const FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(InitialLocation, TargetLocation, Gravity, InitialHorizontalVelocity.Size(), WorldUp);

		const FVector HighestPoint = Trajectory::TrajectoryHighestPoint(InitialLocation, InitialVelocity, Gravity, WorldUp);
		const float Height = FPlane(InitialLocation, WorldUp).PlaneDot(HighestPoint);

		const FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(InitialLocation, TargetLocation, Gravity, Height, -1, WorldUp);

		FTraversalTrajectory OutTrajectory;
		OutTrajectory.LaunchLocation = InitialLocation;
		OutTrajectory.LaunchVelocity = LaunchVelocity;
		OutTrajectory.Gravity = WorldUp * -Gravity;
		OutTrajectory.LandLocation = TargetLocation;
		OutTrajectory.LandArea = Target;

		return OutTrajectory;
	}

	void AdjustTrajectory(FTraversalTrajectory OriginalTrajectory, FTraversalTrajectory& AutoJumpTrajectory, FVector BikeForward, FVector WorldUp) const
	{
		FVector RelativeBikeForward = Target.ActorTransform.InverseTransformVectorNoScale(BikeForward);
		RelativeBikeForward = RelativeBikeForward.GetSafeNormal2D(FVector::UpVector);

		float LandDistance = GetTargetDistance(AutoJumpTrajectory.LandLocation);
		LandDistance += RelativeBikeForward.Y * STEERING_ADJUST_SPEED;

		AutoJumpTrajectory.LandLocation = GetLocationFromTargetDistance(LandDistance);

		const FVector HighestPoint = Trajectory::TrajectoryHighestPoint(OriginalTrajectory.LaunchLocation, OriginalTrajectory.LaunchVelocity, OriginalTrajectory.Gravity.Size(), WorldUp);
		const float Height = FPlane(OriginalTrajectory.LaunchLocation, WorldUp).PlaneDot(HighestPoint);

		AutoJumpTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(AutoJumpTrajectory.LaunchLocation, AutoJumpTrajectory.LandLocation, AutoJumpTrajectory.Gravity.Size(), Height, -1, WorldUp);
	}

	float GetTargetDistance(FVector Location) const
	{
		return Target.ActorTransform.InverseTransformPositionNoScale(Location).Y;
	}

	FVector GetLocationFromTargetDistance(float TargetDistance) const
	{
		const float ClampedTargetDistance = Math::Clamp(TargetDistance, Target.Width * -0.5, Target.Width * 0.5);
		return Target.ActorTransform.TransformPositionNoScale(FVector(0, ClampedTargetDistance, 0));
	}

	void Reset()
	{
		Target = nullptr;
	}
};