struct FTeenDragonKnockableObjectData
{
	ATeenDragonKnockableObject Object;
	//Not in use yet but probably needed?
	UPROPERTY()
	float ObjectLocationOffset = 400.0;
}

class UTeenDragonKnockObjectComponent : UActorComponent
{
	UPROPERTY()
	FHazePlaySlotAnimationParams AnimSequence;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	FTeenDragonKnockableObjectData ObjectData;

	bool bIsEating;

	void SetObjectToEat(FTeenDragonKnockableObjectData NewObjectData)
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