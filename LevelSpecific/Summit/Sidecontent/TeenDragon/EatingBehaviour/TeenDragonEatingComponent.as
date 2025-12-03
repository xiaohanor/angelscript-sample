struct FTeenDragonEatingData
{
	ATeenDragonEatableObject Object;
	//Not in use yet but probably needed?
	UPROPERTY()
	float ObjectLocationOffset = 400.0;
}

class UTeenDragonEatingComponent : UActorComponent
{
	UPROPERTY()
	FHazePlaySlotAnimationParams AnimTail;

	UPROPERTY()
	FHazePlaySlotAnimationParams AnimAcid;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	FTeenDragonEatingData ObjectData;

	bool bIsEating;

	void SetObjectToEat(FTeenDragonEatingData NewObjectData)
	{
		bIsEating = true;
		ObjectData = NewObjectData;
	}

	bool ConsumeEatingCheck()
	{
		if (bIsEating)
		{
			bIsEating = false;
			return true;
		}

		return false;
	}
};