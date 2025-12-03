event void FOnMovedIntoByTeenDragon(FTeenDragonMovementImpactParams Params);

struct FTeenDragonMovementImpactParams
{
	UPROPERTY()
	UPrimitiveComponent ImpactedComponent;
	UPROPERTY()
	FVector ImpactLocation;
	UPROPERTY()
	FVector ImpactNormal;
	UPROPERTY()
	AHazePlayerCharacter PlayerInstigator;
	UPROPERTY()
	FVector VelocityTowardsImpact;
}

class UTeenDragonMovementResponseComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bGroundImpactValid = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bWallImpactValid = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bCeilingImpactValid = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bEnabled = true;

	// If true, this will only trigger events when the parent component is hit
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bIsPrimitiveParentExclusive = false;

	FOnMovedIntoByTeenDragon OnMovedInto;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bIsPrimitiveParentExclusive)
		{
			auto CompAttachParent = GetAttachParent();
			auto PrimitiveParent = Cast<UPrimitiveComponent>(CompAttachParent);
			devCheck(PrimitiveParent != nullptr, f"{this} on {Owner} is set to 'bIsPrimitiveParentExclusive' but its parent component is not a primitive");
		}
	}

	bool ImpactWasOnParent(UPrimitiveComponent ComponentHit) const 
	{
		auto PrimitiveParent = Cast<UPrimitiveComponent>(GetAttachParent());
		if(PrimitiveParent != nullptr && PrimitiveParent == ComponentHit)
			return true;

		return false;
	}
};