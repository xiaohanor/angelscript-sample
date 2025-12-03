class ASkylinePoleThrowElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AKineticMovingActor MovingActor;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MovingActor.IsMovingBackward()|| MovingActor.IsMovingForward())
			ForceFeedback::PlayWorldForceFeedback(ForceFeedback, MovingActor.ActorLocation, false, this, 300, 400, 1.0, 0.15, EHazeSelectPlayer::Both);

		
	}
};