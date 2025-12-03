class ADentistBossCupManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;
#endif

	UPROPERTY(DefaultComponent)
	USceneComponent LeftCupRoot;
	default LeftCupRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent)
	USceneComponent MiddleCupRoot;
	default MiddleCupRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent)
	USceneComponent RightCupRoot;
	default RightCupRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftSwapperRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent RightSwapperRoot;


	UPROPERTY(DefaultComponent)
	UHazeCameraComponent PlayerCaughtCamera;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	TOptional<ADentistBossToolCup> ChosenCup;
	AHazePlayerCharacter PlayerInCup;
	
	bool bChoseCorrectly = false;
	bool bCupSortingFinished = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector MiddleToLeftDelta = LeftCupRoot.WorldLocation - MiddleCupRoot.WorldLocation;
		LeftSwapperRoot.WorldLocation = MiddleCupRoot.WorldLocation + MiddleToLeftDelta * 0.5;

		FVector MiddleToRightDelta = RightCupRoot.WorldLocation - MiddleCupRoot.WorldLocation;
		RightSwapperRoot.WorldLocation = MiddleCupRoot.WorldLocation + MiddleToRightDelta * 0.5;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugCylinder(LeftCupRoot.WorldLocation, LeftCupRoot.WorldLocation + FVector::UpVector * 500, 300, 12, FLinearColor::White, 20);
		Debug::DrawDebugCylinder(MiddleCupRoot.WorldLocation, MiddleCupRoot.WorldLocation + FVector::UpVector * 500, 300, 12, FLinearColor::White, 20);
		Debug::DrawDebugCylinder(RightCupRoot.WorldLocation, RightCupRoot.WorldLocation + FVector::UpVector * 500, 300, 12, FLinearColor::White, 20);
	}
#endif
};