class AYarnMoonMarketCat : AMoonMarketCat
{
	UPROPERTY(EditAnywhere)
	bool bUseSillyRotations = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		InteractComp.Disable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_PlaySillyRotations() {}
	
	UFUNCTION()
	void StopSillyRotations() 
	{
		BP_StopSillyRotations();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StopSillyRotations() {}
};