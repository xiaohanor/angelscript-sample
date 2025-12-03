class USummitMioFakeFlyingComponent : UActorComponent
{
	FHazeRuntimeSpline RuntimeSpline;
	bool bIsFakeFlying = false;
	float FlySpeed = 1800;

	FVector FlightDirection;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void FlyTowardsPoint(FVector TargetPoint)
	{
		FVector Velocity = Trajectory::CalculateVelocityForPathWithHeight(Owner.ActorLocation, TargetPoint, 2385, 0);
		FPlayerLaunchToParameters LaunchParams;
		LaunchParams.Duration = 3;
		LaunchParams.LaunchImpulse = Velocity;
		LaunchParams.Type = EPlayerLaunchToType::LaunchWithImpulse;
		Player.LaunchPlayerTo(this, LaunchParams);
		FlightDirection = (TargetPoint - Owner.ActorLocation).GetSafeNormal2D();
		bIsFakeFlying = true;
		Timer::SetTimer(this, n"OnTimerTimeout", 3);
	}

	UFUNCTION()
	private void OnTimerTimeout()
	{
		bIsFakeFlying = false;
	}
};