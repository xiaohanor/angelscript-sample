struct FFoliageDetectionData
{
	UPROPERTY()
	bool bIsOverlappingFoliage;
	UPROPERTY()
	EFoliageDetectionType Type;
	UPROPERTY()
	UPhysicalMaterialAudioAsset MaterialOverride = nullptr;
};

UCLASS(Abstract)
class UFoliageDetectionEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FoliageOverlapEvent(FFoliageDetectionData Data)
	{
	}
};