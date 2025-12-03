class APrisonNosediveHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HatchRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenHatchTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenHatchTimeLike.BindUpdate(this, n"UpdateOpenHatch");
		OpenHatchTimeLike.BindFinished(this, n"FinishOpenHatch");
	}

	UFUNCTION()
	void OpenHatch()
	{
		OpenHatchTimeLike.Play();
	}

	UFUNCTION()
	void CloseHatch()
	{
		OpenHatchTimeLike.Reverse();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenHatch(float CurValue)
	{
		float Rot = Math::Lerp(0.0, 70.0, CurValue);
		HatchRoot.SetRelativeRotation(FRotator(0.0, 0.0, Rot));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenHatch()
	{

	}
}