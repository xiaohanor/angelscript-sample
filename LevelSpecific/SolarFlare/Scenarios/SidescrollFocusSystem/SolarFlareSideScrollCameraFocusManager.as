class ASolarFlareSideScrollCameraFocusManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "S_SceneCaptureIcon";
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere, Category = "Setup : Splines")
	ASolarFlareSideScrollSplineActor ConveyerAreaSpline;

	UPROPERTY(EditAnywhere, Category = "Setup : Splines")
	ASolarFlareSideScrollSplineActor DoorAreaSpline;

	UPROPERTY(EditAnywhere, Category = "Setup : Splines")
	ASolarFlareSideScrollSplineActor PoleAreaSpline;

	UPROPERTY(EditAnywhere, Category = "Setup : EventActors")
	ASolarFlareSidescrollLift FirstLift;

	UPROPERTY(EditAnywhere, Category = "Setup : EventActors")
	APlayerTrigger PerchDoorTrigger;

	UPROPERTY(EditAnywhere, Category = "Setup : EventActors")
	ADoubleInteractionActor LiftInteract;

	UPROPERTY(EditAnywhere, Category = "Setup : EventActors")
	ASolarFlareBatteryLift BatteryLift;

	UPROPERTY(EditAnywhere, Category = "Setup : EventActors")
	ABothPlayerTrigger EndingTrigger;

	ASolarFlareSidescrollCameraFocusActor FocusTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FirstLift.OnSolarFlareSidescrollLiftCrash.AddUFunction(this, n"OnSolarFlareSidescrollLiftCrash");
		PerchDoorTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterPerchDoorArea");
		LiftInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		BatteryLift.OnSolarFlareBatteryLiftReachedTop.AddUFunction(this, n"OnSolarFlareBatteryLiftReachedTop");
		EndingTrigger.OnBothPlayersInside.AddUFunction(this, n"OnBothPlayersInside");
		
		FocusTarget = TListedActors<ASolarFlareSidescrollCameraFocusActor>().GetSingle();
	}

	UFUNCTION()
	void StartSidescrollCameraSegment(ASolarFlareSideScrollSplineActor TargetSpline)
	{
		FocusTarget.SetSpline(TargetSpline);		
		FocusTarget.ActivateFocusTarget();
	}

	UFUNCTION()
	private void OnSolarFlareSidescrollLiftCrash()
	{
		FocusTarget.SetSpline(ConveyerAreaSpline);
		FocusTarget.ActivateFocusTarget();
	}

	UFUNCTION()
	private void OnPlayerEnterPerchDoorArea(AHazePlayerCharacter Player)
	{
		FocusTarget.SetSpline(DoorAreaSpline);
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		FocusTarget.ClearSpline();
		FocusTarget.SetFocusTargetWorldOffset(FVector(-170,200,210));	
	}

	UFUNCTION()
	private void OnSolarFlareBatteryLiftReachedTop(bool bPlayerOnLift)
	{
		FocusTarget.SetFocusTargetWorldOffset(FVector(0,0,0));	
		FocusTarget.SetSpline(PoleAreaSpline);
	}

	UFUNCTION()
	private void OnBothPlayersInside()
	{
		FocusTarget.ClearSpline();
		FocusTarget.DeactivateFocusTarget();
	}
};