class ASanctuaryCatapultRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotatingPivot;

	UPROPERTY(DefaultComponent)
	USceneComponent InteractPivot;

	UPROPERTY(EditAnywhere)
	float RotatingSpeedPlatform = 40.0;

	UPROPERTY(EditAnywhere)
	float RotatingSpeedPlayer = -50.0;

	UPROPERTY(EditAnywhere)
	ASanctuaryCatapult Catapult;

	UPROPERTY(DefaultComponent, Attach = InteractPivot)
	USanctuaryCatapultRotatorInteractionComponent InteractCompCounterClockwise;

	//UPROPERTY(DefaultComponent, Attach = InteractPivot)
	//USanctuaryCatapultRotatorInteractionComponent InteractCompClockWise;

	UPROPERTY(EditAnywhere)
	FButtonMashSettings MashSettings;
	default MashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default MashSettings.bAllowPlayerCancel = true;

	UPROPERTY()
	UAnimSequence IdleAnim;
	UPROPERTY()
	UAnimSequence PushAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if(InteractCompCounterClockwise.bPushing && InteractCompCounterClockwise.bInteracting)
		{
			Catapult.AddActorLocalRotation(FRotator(0.0, RotatingSpeedPlatform * DeltaSeconds, 0.0));
			//InteractPivot.AddLocalRotation(FRotator(0.0, RotatingSpeedPlayer * DeltaSeconds, 0.0));
		}

		/*if(InteractCompClockWise.bPushing && InteractCompClockWise.bInteracting)
		{
			Catapult.AddActorLocalRotation(FRotator(0.0, -RotatingSpeedPlatform * DeltaSeconds, 0.0));
			
			//InteractPivot.AddLocalRotation(FRotator(0.0, -RotatingSpeedPlayer * DeltaSeconds, 0.0));
		}*/
		
	}
};