
/**
 * Helper baseclass for objects that can be dissolved in acid.
 */
 UCLASS(Abstract)
class AAcidDissolvable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComponent;

	// How long does it need to be touching acid to dissolve
	UPROPERTY(EditAnywhere)
	float DissolveDuration = 1.0;

	private float DissolvePct = 0.0;
	private bool bFullyDissolved = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComponent.OnAcidTick.AddUFunction(this, n"OnAcidTick");
	}

	UFUNCTION(BlueprintEvent)
	void OnUpdateDissolvePercentage(float DissolvePercentage) {}

	UFUNCTION(BlueprintEvent)
	void OnFullyDissolved() {}

	UFUNCTION(CrumbFunction)
	private void CrumbFullyDissolved()
	{
		DissolvePct = 1.0;
		bFullyDissolved = true;

		OnUpdateDissolvePercentage(DissolvePct);
		OnFullyDissolved();
	}

	UFUNCTION()
	private void OnAcidTick(float DeltaTime)
	{
		if (bFullyDissolved)
			return;

		DissolvePct += DeltaTime / DissolveDuration;
		if (DissolvePct >= 1.0)
			CrumbFullyDissolved();
		else
			OnUpdateDissolvePercentage(DissolvePct);
	}
};