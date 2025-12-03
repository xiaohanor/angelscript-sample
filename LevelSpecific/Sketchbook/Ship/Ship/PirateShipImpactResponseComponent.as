event void FPirateShipOnImpact(FPirateShipOnImpactData Data);

struct FPirateShipOnImpactData
{
	UPROPERTY()
	FVector Impulse;
}

UCLASS(NotBlueprintable)
class UPirateShipImpactResponseComponent : UActorComponent
{
	UPROPERTY()
	FPirateShipOnImpact OnImpact;
};