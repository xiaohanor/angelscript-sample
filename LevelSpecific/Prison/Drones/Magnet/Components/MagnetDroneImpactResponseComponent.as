event void FMagnetDroneOnImpact(FMagnetDroneOnImpactData Data);

struct FMagnetDroneImpactResponseComponentAndData
{
	UPROPERTY()
	UMagnetDroneImpactResponseComponent ResponseComp;

	UPROPERTY()
	FMagnetDroneOnImpactData ImpactData;
}

struct FMagnetDroneOnImpactData
{
	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	UPrimitiveComponent Component;

	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;
}

UCLASS(NotBlueprintable)
class UMagnetDroneImpactResponseComponent : UActorComponent
{
	// Should this actor be ignored for the following traces during this frames move?
	UPROPERTY(EditAnywhere)
	bool bIgnoreAfterImpact = true;

	UPROPERTY()
	FMagnetDroneOnImpact OnImpact;
};