class ASkylineHighwayTankerTruckFF : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent FFRoot;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float FFFrequency = 8.0;
		float FFIntensity = 0.07;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(DeltaSeconds * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-DeltaSeconds * FFFrequency) * FFIntensity;
		

		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, ActorLocation, 300, 400, 1.0, EHazeSelectPlayer::Both, false);
	}

	};