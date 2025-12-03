UCLASS(Abstract)
class AIslandEntranceFlyingDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float ScaleDuration = 1;

	UPROPERTY()
	FHazeTimeLike TL_DebrisScale;

	UPROPERTY()
	float ScaleAlpha = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TL_DebrisScale.BindUpdate(this, n"TL_DebrisScale_Update");

		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	private void TL_DebrisScale_Update(float CurrentValue)
	{
		ScaleAlpha = CurrentValue;
	}

	UFUNCTION(BlueprintCallable)
	void ActivateDebris()
	{
		SetActorHiddenInGame(false);

		TL_DebrisScale.PlayRate = 1.0 / ScaleDuration;
		TL_DebrisScale.PlayFromStart();
	}
};
