event void FOnGoldGiantBreak(FVector ImpactDirection, float ImpulseAmount);

class UGoldGiantBreakResponseComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> CameraShake;

	FOnGoldGiantBreak OnBreakGiantObject;

	bool bIsBroken;

	TArray<FInstigator> Disablers;

	void BreakGiant(FVector ImpactDirection, float ImpulseAmount)
	{
		if (Disablers.Num() > 0)
			return;

		if (bIsBroken)
			return;

		bIsBroken = true;
		OnBreakGiantObject.Broadcast(ImpactDirection, ImpulseAmount);

		Game::Mio.PlayCameraShake(CameraShake, this, 2.0);
		Game::Zoe.PlayCameraShake(CameraShake, this, 2.0);
	}

	void AddDisabler(FInstigator Disabler)
	{
		Disablers.AddUnique(Disabler);
	}

	void RemoveDisabler(FInstigator Disabler)
	{
		Disablers.Remove(Disabler);
	}

	bool IsBreakDisabled()
	{
		return Disablers.Num() > 0;
	}

} 