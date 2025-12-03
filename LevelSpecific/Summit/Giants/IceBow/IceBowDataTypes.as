enum EIceBowArrowType
{
	Ice,
	Blizzard,
	Rope,
	Wind
}

struct FIceArrowHitData
{
    FIceArrowHitData(FHitResult Hit)
    {
        Component = Hit.Component;
        ImpactNormal = Hit.ImpactNormal;
        ImpactPoint = Hit.ImpactPoint;
    }

    UPROPERTY()
	UPrimitiveComponent Component;

    UPROPERTY()
	FVector ImpactNormal;

    UPROPERTY()
	FVector ImpactPoint;
}

struct FWindArrowHitData
{
    FWindArrowHitData(FHitResult Hit)
    {
        Component = Hit.Component;
        ImpactNormal = Hit.ImpactNormal;
        ImpactPoint = Hit.ImpactPoint;
    }

    UPROPERTY()
	UPrimitiveComponent Component;

    UPROPERTY()
	FVector ImpactNormal;

    UPROPERTY()
	FVector ImpactPoint;
}

struct FBlizzardArrowHitData
{
    FBlizzardArrowHitData(FHitResult Hit)
    {
        Component = Hit.Component;
        ImpactNormal = Hit.ImpactNormal;
        ImpactPoint = Hit.ImpactPoint;
    }

    UPROPERTY()
	UPrimitiveComponent Component;

    UPROPERTY()
	FVector ImpactNormal;

    UPROPERTY()
	FVector ImpactPoint;
}

struct FRopeArrowHitData
{
    FRopeArrowHitData(FHitResult Hit)
    {
        Component = Hit.Component;
        ImpactNormal = Hit.ImpactNormal;
        ImpactPoint = Hit.ImpactPoint;
    }

    UPROPERTY()
	UPrimitiveComponent Component;

    UPROPERTY()
	FVector ImpactNormal;

    UPROPERTY()
	FVector ImpactPoint;
}