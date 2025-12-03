class USanctuarySnakeBurrowCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 101;
	default CapabilityTags.Add(n"SanctuarySnake");
	default CapabilityTags.Add(n"SanctuarySnakeBurrow");

	UHazeMovementComponent MovementComponent;
	USweepingMovementData Movement;

	USanctuarySnakeSettings Settings;

	USanctuarySnakeComponent SanctuarySnakeComponent;
	USanctuarySnakeSplineFollowComponent SplineFollowComponent;
	USanctuarySnakeBurrowComponent BurrowComponent;

	ASanctuarySnake Snake;

	FVector CustomWorldUp = FVector::UpVector;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();
		Settings = USanctuarySnakeSettings::GetSettings(Owner);

		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);
		BurrowComponent = USanctuarySnakeBurrowComponent::Get(Owner);
		SplineFollowComponent = USanctuarySnakeSplineFollowComponent::Get(Owner);

		Snake = Cast<ASanctuarySnake>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SanctuarySnakeComponent.bBurrow)
			return true;

		if(SanctuarySnakeComponent.bSelfCollision)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		int RndIndex = Math::RandRange(0, BurrowComponent.BurrowTargets.Num() - 1);

		BurrowComponent.BurrowTargets[RndIndex].SetActorLocationAndRotation(Owner.ActorLocation, FRotator::MakeFromZX(Owner.MovementWorldUp, Snake.Pivot.ForwardVector));
		Snake.FollowSpline(BurrowComponent.BurrowTargets[RndIndex]);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SanctuarySnakeComponent.bBurrow = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}