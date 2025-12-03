struct FOnSlidingDiscCollidedParams
{
	FOnSlidingDiscCollidedParams(float AnImpactStrength, UPhysicalMaterial AnAudioPhysMaterial)
	{
		ImpactStrength = AnImpactStrength;
		AudioPhysMaterial = AnAudioPhysMaterial;
	}

	UPROPERTY(BlueprintReadOnly)
	float ImpactStrength;
	
	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterial AudioPhysMaterial;
}


struct FOnSlidingDiscLandedParams
{
	FOnSlidingDiscLandedParams(float AnImpactStrength, UPhysicalMaterial AnAudioPhysMaterial)
	{
		ImpactStrength = AnImpactStrength;
		AudioPhysMaterial = AnAudioPhysMaterial;
	}

	UPROPERTY(BlueprintReadOnly)
	float ImpactStrength;

	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterial AudioPhysMaterial;
}

UCLASS(Abstract)
class USlidingDiscEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCollisionImpact(FOnSlidingDiscCollidedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanded(FOnSlidingDiscLandedParams Params)
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHydra()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAirborne()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiscDestroyed()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEatenByHydra()
	{
	}

};