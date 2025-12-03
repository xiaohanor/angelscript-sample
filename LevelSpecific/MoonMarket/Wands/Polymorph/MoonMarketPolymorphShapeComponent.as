class UMoonMarketPolymorphShapeComponent : UActorComponent
{
	UPROPERTY()
	FMoonMarketShapeshiftShapeData ShapeData;

	UPROPERTY()
	UHazeCapabilitySheet Sheet;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!ShapeData.bUseCustomMovement)
			ShapeData.bUseCustomMovement = Sheet != nullptr;
	}
};