event void FOnSolarFlareShieldsCollected();

class ASolarFlareTriggerShieldEventManager : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareShieldsCollected OnSolarFlareShieldsCollected;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	TPerPlayer<ASolarFlareCollectTriggerShield> CollectShieldInteractions;

	UPROPERTY(EditAnywhere)
	ASolarFlareBasicCoverRaisable RaisableCover;

	int Count;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollectShieldInteractions[0].OnSolarFlareTriggerShieldCollected.AddUFunction(this, n"OnSolarFlareTriggerShieldCollected");
		CollectShieldInteractions[1].OnSolarFlareTriggerShieldCollected.AddUFunction(this, n"OnSolarFlareTriggerShieldCollected");
	}

	UFUNCTION()
	private void OnSolarFlareTriggerShieldCollected()
	{
		Count++;

		if (Count >= 2)
		{
			RaisableCover.ActivateCover();
			OnSolarFlareShieldsCollected.Broadcast();
		}
	}
};