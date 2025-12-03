struct FSketchbookArrowHitData
{
    FSketchbookArrowHitData(FHitResult Hit)
    {
        Component = Hit.Component;
        ImpactNormal = Hit.ImpactNormal;
        ImpactPoint = Hit.ImpactPoint;
		BoneName = Hit.BoneName;
    }

    UPROPERTY()
	UPrimitiveComponent Component;

    UPROPERTY()
	FVector ImpactNormal;

    UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FName BoneName;
}