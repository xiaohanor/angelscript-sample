class AIslandWalkerHatchPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = DestinationComp)
	UIslandWalkerSwimmingObstacleComponent ObstacleAvoidanceComp;
	default ObstacleAvoidanceComp.AvoidanceRadius = 800.0;

	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerRef;

	FVector TargetLocation;

	bool bIsActivated;
	float TravelDuration = 1.0;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 2.5;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetLocation = DestinationComp.GetWorldLocation();
	}

	UFUNCTION()
	void MoveToLandLocation()
	{
		TeleportActor(TargetLocation, FRotator(0,0,0), this, false);
	}
	
};