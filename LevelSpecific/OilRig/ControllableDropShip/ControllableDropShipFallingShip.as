UCLASS(Abstract)
class AControllableDropShipFallingShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShipRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DropTimeLike;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector EndLocation;

	UPROPERTY(EditAnywhere)
	bool bPreviewEnd = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEnd)
			ShipRoot.SetRelativeLocation(EndLocation);
		else
			ShipRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DropTimeLike.BindUpdate(this, n"UpdateDrop");
	}

	UFUNCTION()
	private void UpdateDrop(float CurValue)
	{
		FVector Loc = Math::Lerp(FVector::ZeroVector, EndLocation, CurValue);
		ShipRoot.SetRelativeLocation(Loc);
	}
}