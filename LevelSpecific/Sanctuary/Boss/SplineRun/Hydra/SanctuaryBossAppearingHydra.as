class ASanctuaryBossAppearingHydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;

	UPROPERTY()
	FHazeTimeLike AppearTimeLike;
	default AppearTimeLike.UseSmoothCurveZeroToOne();
	default AppearTimeLike.Duration = 3.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXComp;

	UPROPERTY()
	float AppearHeight = 10000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		AppearTimeLike.BindUpdate(this, n"AppearTimeLikeUpdate");
	}

	UFUNCTION()
	private void AppearTimeLikeUpdate(float CurrentValue)
	{
		HeadRoot.SetRelativeLocation(FVector::UpVector * CurrentValue * AppearHeight);
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);
		VFXComp.Activate();
		AppearTimeLike.Play();

		Timer::SetTimer(this, n"DeactivateVFX", 2.0);
	}

	UFUNCTION()
	private void DeactivateVFX()
	{
		VFXComp.Deactivate();
	}
};