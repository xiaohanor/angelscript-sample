class ACorkScrewCameraManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	APropLine PropLine;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor Camera;

	UBattlefieldLoopComponent LoopComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LoopComp = UBattlefieldLoopComponent::Get(PropLine);
		LoopComp.OnPlayerEnteredLoop.AddUFunction(this, n"OnPlayerEnteredLoop");
		LoopComp.OnPlayerExitedLoop.AddUFunction(this, n"OnPlayerExitedLoop");
	}

	UFUNCTION()
	private void OnPlayerEnteredLoop(AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(Camera, 2.5, this);
	}

	UFUNCTION()
	private void OnPlayerExitedLoop(AHazePlayerCharacter Player)
	{
		Player.DeactivateCameraByInstigator(this, 2.5);
	}
};