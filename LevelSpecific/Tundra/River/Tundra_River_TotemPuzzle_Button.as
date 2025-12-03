event void FTotemPuzzleButtonEvent();

UCLASS(Abstract)
class ATundra_River_TotemPuzzle_Button : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	UStaticMeshComponent ButtonMeshComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent SlamComp;

	FTotemPuzzleButtonEvent ButtonSlammedEvent;

	UPROPERTY()
	FHazeTimeLike TL_Slam;

	UPROPERTY(EditInstanceOnly)
	ATundra_River_TotemPuzzle_TreeControl TreeControl;

	bool bEnabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SlamComp.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		TL_Slam.BindUpdate(this, n"TL_Slam_Update");
		TreeControl.PuzzleIsSolved.AddUFunction(this, n"PuzzleSolved");
	}

	UFUNCTION()
	private void PuzzleSolved()
	{
		bEnabled = false;
	}

	UFUNCTION()
	private void TL_Slam_Update(float CurrentValue)
	{
		float Height = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(0, -30), CurrentValue);
		MoveRoot.SetRelativeLocation(FVector(0, 0, Height));
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType,
	                          FVector PlayerLocation)
	{
		if(!bEnabled)
			return;

		TL_Slam.PlayFromStart();
		ButtonSlammedEvent.Broadcast();
	}
};
