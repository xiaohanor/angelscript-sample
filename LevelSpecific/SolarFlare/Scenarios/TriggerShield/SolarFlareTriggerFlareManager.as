event void FOnSolarFlareTriggerShieldsCollected();

class ASolarFlareTriggerFlareManager : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareTriggerShieldsCollected OnSolarFlareTriggerShieldsCollected;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareCollectTriggerShield> TriggerShieldCollectables;

	int Collected = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ASolarFlareCollectTriggerShield Collectable : TriggerShieldCollectables)
			Collectable.OnSolarFlareTriggerShieldCollected.AddUFunction(this, n"OnSolarFlareTriggerShieldCollected");
	}

	UFUNCTION()
	private void OnSolarFlareTriggerShieldCollected()
	{
		Collected++;

		if (Collected >= 2)
			OnSolarFlareTriggerShieldsCollected.Broadcast();
	}
};