class AGoatDevourGoatActor : AGenericGoat
{
	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	USceneComponent UpperHeadRoot;

	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	USceneComponent LowerHeadRoot;

	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	USceneComponent MouthComp;

	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	UNiagaraComponent SuckEffectComp;

	bool bMouthOpen = false;

	float UpperHeadRot = 0.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float UpperHeadTargetRot = bMouthOpen ? 60.0 : 0.0;
		UpperHeadRot = Math::FInterpTo(UpperHeadRot, UpperHeadTargetRot, DeltaTime, 10.0);
		UpperHeadRoot.SetRelativeRotation(FRotator(UpperHeadRot, 0.0, 0.0));
	}

	void OpenMouth()
	{
		if (bMouthOpen)
			return;

		bMouthOpen = true;
		SuckEffectComp.Activate(true);
	}

	void CloseMouth()
	{
		if (!bMouthOpen)
			return;

		bMouthOpen = false;
		SuckEffectComp.Deactivate();
	}
}