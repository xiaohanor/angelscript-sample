class ASummitDebrisFallingPlatformBreakPOIManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(15));
#endif

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	UCameraPointOfInterestClearOnInputSettings InputSettings;

	TArray<AHazePlayerCharacter> POIPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void ApplyPlatformBreakPOI(AHazePlayerCharacter Player)
	{
		FHazePointOfInterestFocusTargetInfo Target;
		Target.SetFocusToActor(TargetActor);
		FApplyPointOfInterestSettings Settings;
		Settings.bBlockFindAtOtherPlayer = true;
		Settings.Duration = 1.5;
		Player.ApplyPointOfInterest(this, Target, Settings);
		POIPlayers.AddUnique(Player);
		Timer::SetTimer(this, n"ClearPOI", 1.5);
	}

	UFUNCTION()
	private void ClearPOI()
	{
		for (AHazePlayerCharacter Player : POIPlayers)
		{
			Player.ClearPointOfInterestByInstigator(this);
		}
		POIPlayers.Empty();
	}
};