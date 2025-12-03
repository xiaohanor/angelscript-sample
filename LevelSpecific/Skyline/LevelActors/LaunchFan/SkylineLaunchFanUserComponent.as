class USkylineLaunchFanUserComponent : UActorComponent
{
	bool bIsLaunched = false;
	FVector LaunchVelocity = FVector::ZeroVector;
	FVector LaunchLocation = FVector::ZeroVector;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	void Launch(FVector Location, FVector Target, float Height = 2000.0)
	{
		LaunchLocation = Location;
		LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, Target, MoveComp.GravityForce, Height, -1.0, Player.MovementWorldUp);
		bIsLaunched = true;
	}
};