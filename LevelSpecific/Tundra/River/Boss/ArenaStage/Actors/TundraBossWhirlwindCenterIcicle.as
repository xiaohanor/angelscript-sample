class ATundraBossWhirlwindCenterIcicle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FHazeTimeLike IcicleAppearTimelike;
	default IcicleAppearTimelike.Duration = 0.5;
	UPROPERTY()
	FHazeTimeLike IcicleDisappearTimelike;
	default IcicleDisappearTimelike.Duration = 4;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		IcicleAppearTimelike.BindUpdate(this, n"IcicleAppearTimelikeUpdate");
		IcicleDisappearTimelike.BindUpdate(this, n"IcicleDisappearTimelikeUpdate");
		IcicleDisappearTimelike.BindFinished(this, n"IcicleDisappearTimelikeFinished");
		MeshRoot.SetRelativeLocation(FVector(0, 0, -3000));
	}

	UFUNCTION()
	void ShowCenterIcicle()
	{
		SetActorHiddenInGame(false);
		IcicleAppearTimelike.PlayFromStart();
	}

	UFUNCTION()
	void HideCenterIcicle()
	{
		IcicleDisappearTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void IcicleDisappearTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(0, 0, -3000), CurrentValue));
	}

	UFUNCTION()
	private void IcicleDisappearTimelikeFinished()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	private void IcicleAppearTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector(0, 0, -3000), FVector::ZeroVector, CurrentValue));
	}
};