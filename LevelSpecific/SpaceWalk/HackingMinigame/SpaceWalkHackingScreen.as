event void FonHackInitilazed();

class ASpaceWalkHackingScreen : AHazeActor
{	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Screen;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent HackCam;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent OverviewCam;

	UPROPERTY(EditAnywhere)
	ASpaceWalkEscapeDropshipFinal EscapeShip;

	bool bZoeLockedIn;
	bool bMioLockedIn;

	UPROPERTY()
	FonHackInitilazed HackStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
//		EscapeShip.BothHacking.AddUFunction(this, n"BothHacking");

//		EscapeShip.GameOver.AddUFunction(this, n"GameOver");
	}
	
	UFUNCTION()
	private void GameOver()
	{
		DisableUI();
	}

	UFUNCTION()
	private void BothHacking()
	{
		ShowUI();
		ApplyHackCam();
		ApplyOverviewCam();
	}

	UFUNCTION(BlueprintEvent)
	void ShowUI()
	{

	}

	UFUNCTION(BlueprintEvent)
	void DisableUI()
	{
		
	}

	UFUNCTION(BlueprintCallable)
	void ApplyHackCam()
	{
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Fast);
		UHazeCameraComponent Camera = HackCam;
		Game::Zoe.ActivateCamera(Camera, 4.0, this);
		HackStarted.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void ApplyOverviewCam()
	{
		UHazeCameraComponent Camera = OverviewCam;
		Game::Mio.ActivateCamera(Camera, 4.0, this);
		HackStarted.Broadcast();
	}
};