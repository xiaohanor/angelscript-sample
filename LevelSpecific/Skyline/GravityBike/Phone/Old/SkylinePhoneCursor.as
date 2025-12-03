/**
 * A purely visual representation of the cursor
 */
UCLASS(Abstract)
class ASkylinePhoneCursor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BorderRoot;

	UPROPERTY(DefaultComponent, Attach = BorderRoot)
	UStaticMeshComponent BorderMeshComp;

	UPROPERTY(DefaultComponent)
	USceneComponent CenterRoot;

	UPROPERTY(DefaultComponent, Attach = CenterRoot)
	UStaticMeshComponent CenterMeshComp;

	bool bIsHolding = false;
	float ScaleAlpha = 0;
	float StartHoldTime = -1;

	UFUNCTION(BlueprintEvent)
	void BP_OnTap() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnRelease() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GetGameTimeSince(StartHoldTime) < 0.05)
		{
			ScaleAlpha = Math::FInterpTo(ScaleAlpha, 2.0, DeltaSeconds, 100);
		}
		else if(bIsHolding)
		{
			ScaleAlpha = Math::FInterpTo(ScaleAlpha, 1.0, DeltaSeconds, 20);
		}
		else
		{
			ScaleAlpha = Math::FInterpTo(ScaleAlpha, 0, DeltaSeconds, 30);
		}

		const float BorderScale = Math::Lerp(1, 1.7, ScaleAlpha);
		BorderRoot.SetRelativeScale3D(FVector(BorderScale, BorderScale, 1.0));

		const float CenterScale = Math::Lerp(0.8, 1.3, ScaleAlpha);
		CenterRoot.SetRelativeScale3D(FVector(CenterScale, CenterScale, 1.0));
	}

	UFUNCTION()
	private void HandleClickPressed()
	{
		bIsHolding = true;
		StartHoldTime = Time::GameTimeSeconds;
		BP_OnTap();
	}

	UFUNCTION()
	private void HandleClickReleased()
	{
		bIsHolding = false;
		BP_OnRelease();
	}
};