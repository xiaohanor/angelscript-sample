class USanctuarySnakeSplineFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SanctuarySnake");

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 98;
//	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	ASanctuarySnake Snake;

	USanctuarySnakeSettings Settings;

	USanctuarySnakeComponent SanctuarySnakeComponent;
	USanctuarySnakeSplineFollowComponent SplineFollowComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);
		SplineFollowComponent = USanctuarySnakeSplineFollowComponent::Get(Owner);
		Settings = USanctuarySnakeSettings::GetSettings(Owner);
		Snake = Cast<ASanctuarySnake>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SplineFollowComponent.bFollowSpline)
			return false;

		if (SplineFollowComponent.Spline == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SplineFollowComponent.bFollowSpline)
			return true;

		if (SplineFollowComponent.Spline == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"SanctuarySnakeHeadRotation", this);
		Owner.BlockCapabilities(n"SanctuarySnakeRiderMovement", this);
		Owner.BlockCapabilities(n"SanctuarySnakeFollowTarget", this);
		Owner.BlockCapabilities(n"SanctuarySnakeSelfCollision", this);
		Owner.BlockCapabilities(n"SanctuarySnakeBurrow", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"SanctuarySnakeHeadRotation", this);
		Owner.UnblockCapabilities(n"SanctuarySnakeRiderMovement", this);
		Owner.UnblockCapabilities(n"SanctuarySnakeFollowTarget", this);
		Owner.UnblockCapabilities(n"SanctuarySnakeSelfCollision", this);
		Owner.UnblockCapabilities(n"SanctuarySnakeBurrow", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SplineFollowComponent.Move(Settings.Acceleration * DeltaTime);

		FTransform TransformAtDistance = SplineFollowComponent.Transform;
		FVector Velocity = TransformAtDistance.Rotation.ForwardVector * Settings.Acceleration;
		Owner.SetActorLocationAndRotation(TransformAtDistance.Location, TransformAtDistance.Rotation);
		Snake.Pivot.SetWorldRotation(TransformAtDistance.Rotation);

		Print("Velocity: " + Velocity.Size(), 0.0, FLinearColor::Green);

		Owner.SetActorVelocity(Velocity);
		SanctuarySnakeComponent.WorldUp = Owner.ActorUpVector;
	}
};