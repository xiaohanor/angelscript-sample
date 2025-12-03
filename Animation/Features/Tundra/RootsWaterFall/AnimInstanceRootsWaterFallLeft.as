UCLASS(Abstract)
class UAnimInstanceRootsWaterFallLeft : UAnimInstance
{
	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	FTransform TipTransform;

	ATundra_River_WaterslideRocks WaterslideRocks;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(OwningComponent == nullptr)
			return;

		WaterslideRocks = Cast<ATundra_River_WaterslideRocks>(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if(WaterslideRocks == nullptr)
			WaterslideRocks = Cast<ATundra_River_WaterslideRocks>(OwningComponent.Owner);

		if(WaterslideRocks == nullptr)
			return;

		FTransform Transform = FTransform::Identity;
		FVector LocalOffset = WaterslideRocks.LeftRootsMesh.WorldTransform.InverseTransformPosition(WaterslideRocks.LeftRootsMeshTipPoint.WorldLocation);

		Transform.Location = FVector(LocalOffset.Z, LocalOffset.Y, -LocalOffset.X);
		Transform.Rotation = FQuat::Identity;
		TipTransform = Transform;
	}
}