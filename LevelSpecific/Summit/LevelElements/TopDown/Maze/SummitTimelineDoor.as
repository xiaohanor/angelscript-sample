class ASummitTimelineDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StartPosRoot;

	UPROPERTY(DefaultComponent, Attach = StartPosRoot)
	UStaticMeshComponent StartPosMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndPosRoot;

	UPROPERTY(DefaultComponent, Attach = EndPosRoot)
	UStaticMeshComponent EndPosMesh;

	FVector StartPos;
	FVector TargetPos;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DoorAnim;
	default DoorAnim.Duration = 0.5;
	default DoorAnim.Curve.AddDefaultKey(0,0);
	default DoorAnim.Curve.AddDefaultKey(0.5,1);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPos = StartPosRoot.RelativeLocation;
		TargetPos = EndPosRoot.RelativeLocation;

		DoorAnim.BindUpdate(this,n"OnUpdate");
		EndPosMesh.SetVisibility(false);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		StartPosRoot.RelativeLocation = Math::Lerp(StartPos,TargetPos, Alpha);
	}

	UFUNCTION()
	void PlayFunction()
	{
		DoorAnim.Play();
	}

	UFUNCTION()
	void ReverseFunction()
	{
		DoorAnim.Reverse();
	}
}