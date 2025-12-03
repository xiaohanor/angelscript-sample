class ASkylineInnerCityCrane : AHazeActor
{
	
	UPROPERTY(DefaultComponent,RootComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UThreeShotInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent)
	UInnerCityCraneComponent InputComp;

	UPROPERTY(EditAnywhere)
	float Force = 2000;

	bool bIsControllingCrane = false;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent CameraAnim;

	
	FTutorialPrompt PromptWidget;
	default PromptWidget.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
	default PromptWidget.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_LeftRight;
	default PromptWidget.Text = NSLOCTEXT("AdultDragonTutorial", "MovePrompt", "Move");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		
		bIsControllingCrane = false;
		Player.DeactivateCameraByInstigator(InteractionComponent, -1.0);
		Player.RemoveTutorialPromptByInstigator(InteractionComponent);
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		bIsControllingCrane = true;
		PlaySlotAnimation();
		Player.ActivateCamera(CameraAnim, 2.0, InteractionComponent, EHazeCameraPriority::High);
		Player.ShowTutorialPrompt(PromptWidget, InteractionComponent);
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsControllingCrane)
		{
			ForceComp.Force = FVector::ForwardVector * (Force * InputComp.GetXInput()); 
			
		}
	}
};