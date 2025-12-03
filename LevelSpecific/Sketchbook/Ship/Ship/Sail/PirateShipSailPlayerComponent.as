UCLASS(Abstract)
class UPirateShipSailPlayerComponent : UActorComponent
{
	APirateShipSail Sail;
	UInteractionComponent InteractionComp;
	bool bIsUnrolling;
};