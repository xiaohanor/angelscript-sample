asset HackableGearsSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UHackableGearsMioHackingCapability);
	Capabilities.Add(UHackableGearsSideScrollerCapability);
	Capabilities.Add(UHackableGearsSplineLockCapability);
	Capabilities.Add(UHackableGearsZoeFullscreenCapability);
};

/**
 * The conditions for the Gears section in the level BP were complicated.
 * This Manager has a bunch of capabilities for the different states of the HackableGears section.
 */
UCLASS(NotBlueprintable)
class AHackableGearsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(HackableGearsSheet);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly, Category = "Mio")
	AHackableWaterGear HackableWaterGear;

	UPROPERTY(EditInstanceOnly, Category = "Mio")
	ASplineFollowCameraActor SplineFollowCameraActor;

	UPROPERTY(EditInstanceOnly, Category = "Mio")
	ASplineFollowCameraActor SplineBlendCameraActor;

	UPROPERTY(EditAnywhere)
	FText TutorialText;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	APlayerTrigger ZoeTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	APlayerTrigger ZoeStartTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	APlayerTrigger SplineLockTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	APlayerTrigger OperationTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	APlayerTrigger RemoveTutorialTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	ASplineActor SplineLockSplineActor;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	ARespawnPoint SplineLockRespawnPoint;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	ARespawnPoint OperationRespawnPoint;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	AFocusCameraActor SplineLockFocusCameraActor;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	TArray<AHackableWaterGearWheel> HackableWheelsOnlyMagnetizedWhileInSideScroller;

	UPROPERTY(EditInstanceOnly, Category = "Zoe")
	AMagnetDroneRotatingArm TransitionToOperationRotatingArm;

	/**
	 * Have we exited the end of this section?
	 */
	UPROPERTY(BlueprintReadWrite)
	bool bFinished = false;

	UPROPERTY(BlueprintReadWrite)
	bool bSideScrollerActive = false;
	bool bSplineLocked = false;

	bool bTutorialFinished;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		RemoveTutorialTrigger.OnActorBeginOverlap.AddUFunction(this,n"DisableTutorial");
		
		DisableWaterGearWheels();
	}

	UFUNCTION()
	private void DisableTutorial(AActor OverlappedActor, AActor OtherActor)
	{
		if(Cast<AHazePlayerCharacter>(OtherActor) == Game::Zoe)
		{
			Timer::SetTimer(this,n"RemoveTutorial",1);
			bTutorialFinished = true;
		}
	}

	UFUNCTION()
	void AddTutorial()
	{
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Rotate_CW;
		TutorialPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_LeftRight;
		TutorialPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
		TutorialPrompt.Text = TutorialText;
		
		Game::Zoe.ShowTutorialPrompt(TutorialPrompt, this);

		if(bTutorialFinished)
			Timer::SetTimer(this,n"RemoveTutorial",3);

	}

	UFUNCTION()
	private void RemoveTutorial()
	{
		Game::Zoe.RemoveTutorialPromptByInstigator(this);
	}

	void EnableWaterGearWheels()
	{
		for(auto HackableWheel : HackableWheelsOnlyMagnetizedWhileInSideScroller)
		{
			if(HackableWheel == nullptr)
				continue;

			HackableWheel.EnableGear(HackableWheel);
		}
	}

	void DisableWaterGearWheels()
	{
		for(auto HackableWheel : HackableWheelsOnlyMagnetizedWhileInSideScroller)
		{
			if(HackableWheel == nullptr)
				continue;

			HackableWheel.DisableGear(HackableWheel);
		}
	}
};