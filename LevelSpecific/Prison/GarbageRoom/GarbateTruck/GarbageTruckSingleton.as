class UGarbageTruckSingleton : UHazeSingleton
{
	UPROPERTY(BlueprintReadOnly)
	bool bTransformsSaved = false;

	FTransform MioTransform;
	FTransform ZoeTransform;
}