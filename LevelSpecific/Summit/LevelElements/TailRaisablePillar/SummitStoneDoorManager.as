class ASummitStoneDoorManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10));
#endif

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor KineticActor;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> CameraShakeStart;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> CameraShakeEnd;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> CameraShakeLooping;

	UPROPERTY(EditInstanceOnly)
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditInstanceOnly)
	UForceFeedbackEffect RumbleFinish;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KineticActor.OnStartForward.AddUFunction(this, n"OnStartForward");
		KineticActor.OnReachedForward.AddUFunction(this, n"OnReachedForward");
	}

	UFUNCTION()
	private void OnStartForward()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(CameraShakeStart, this);
			Player.PlayCameraShake(CameraShakeLooping, Player);
			Player.PlayForceFeedback(Rumble, true, true, this, 0.4);
		}
	}

	UFUNCTION()
	private void OnReachedForward()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(CameraShakeEnd, this);
			Player.StopForceFeedback(this);
			Player.PlayForceFeedback(RumbleFinish, false, true, this);
			Player.StopCameraShakeByInstigator(Player);
		}
	}
};