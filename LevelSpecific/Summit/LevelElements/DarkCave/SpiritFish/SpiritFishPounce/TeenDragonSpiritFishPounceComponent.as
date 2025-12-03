struct FTeenDragonSpiritFishPounceData
{
	FVector EndLocation;
	float Height;
	ADarkCaveSpiritFish Fish;

	FTeenDragonSpiritFishPounceData(FVector NewEndLoc, float NewHeight, ADarkCaveSpiritFish NewFish)
	{
	 	EndLocation = NewEndLoc;
	 	Height = NewHeight;
	 	Fish = NewFish;		
	} 
}

class UTeenDragonSpiritFishPounceComponent : UActorComponent
{
	FTeenDragonSpiritFishPounceData Data;

	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionFeatureBase LocomotionFeatureTail;
	
	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionFeatureBase LocomotionFeatureAcid;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UTargetableWidget> Widget;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	private bool bCanPounce;
	bool bIsPouncing;

	void ActivatePounce(FTeenDragonSpiritFishPounceData NewData)
	{
		Data = NewData;
		bCanPounce = true;
	}

	bool ConsumeCanPounce()
	{
		if (bCanPounce)
		{
			bCanPounce = false;
			return true;
		}
		
		return false;
	}
};