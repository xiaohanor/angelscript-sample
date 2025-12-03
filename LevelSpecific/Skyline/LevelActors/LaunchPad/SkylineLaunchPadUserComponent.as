class USkylineLaunchPadUserComponent : UActorComponent
{
	bool bIsLaunched = false;
	bool bOnlyDeactivateOnGrounded = false;
	FVector LaunchVelocity = FVector::ZeroVector;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	void Launch(FVector Target, float Height = 2000.0, bool bSetOnlyDeactivateOnGrounded = false)
	{
		LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, Target, MoveComp.GravityForce, Height, -1.0, Player.MovementWorldUp);
		bIsLaunched = true;
		bOnlyDeactivateOnGrounded = bSetOnlyDeactivateOnGrounded;
	}
};