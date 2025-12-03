UCLASS(Abstract)
class AMaxSecurityLaserShaftSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.WorldScale3D = FVector(5);
#endif

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;

	UPROPERTY(EditAnywhere)
	float LoopInterval = 1.0;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserAudioVolume AudioVolume;

	float StartYaw;
	bool bFlipFlop;
	FHazeActionQueue ActionQueue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Everything in the laser shaft must be on the Zoe side, since she is the one that dies
		SetActorControlSide(Game::Zoe);

		StartYaw = ActorRotation.Yaw;

		ActionQueue.Initialize(this);
		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"OnNewLoop");
		ActionQueue.Duration(TimeLike.Duration, this, n"UpdateTimeLike");
		ActionQueue.Idle(LoopInterval);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueue.ScrubTo(Time::GetActorControlPredictedCrumbTrailTime(this));
	}

	UFUNCTION()
	private void OnNewLoop()
	{
		bFlipFlop = !bFlipFlop;

		if(bFlipFlop)
			AudioVolume.StartOnLasersMoveOut();
		else
			AudioVolume.StartOnLasersMoveIn();
	}

	UFUNCTION()
	private void UpdateTimeLike(float Alpha)
	{
		TimeLike.SetNewTime(Alpha * TimeLike.Duration);
		float Value = TimeLike.Value;

		float NewYaw = Math::Lerp(StartYaw, StartYaw + 180, Value);
		SetActorRotation(FRotator(0, NewYaw, 0));
	}
};