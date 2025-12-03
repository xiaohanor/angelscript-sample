class UArenaBossLaunchToPlatformUserComponent : UActorComponent
{
	bool bIsLaunched = false;
	FVector LaunchVelocity = FVector::ZeroVector;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	UForceFeedbackEffect LandFF;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LandCamShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	void Launch(FVector Target, float Height = 500.0)
	{
		LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, Target, MoveComp.GravityForce, Height, -1.0, Player.MovementWorldUp);
		bIsLaunched = true;
	}
};