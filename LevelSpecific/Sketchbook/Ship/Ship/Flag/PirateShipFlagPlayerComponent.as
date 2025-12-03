enum EPirateShipFlagType
{
	None,
	Pirate,
	Aimar,
	Hazelight,
}

UCLASS(Abstract)
class UPirateShipFlagPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TMap<EPirateShipFlagType, UMaterialInterface> FlagMaterials;

	EPirateShipFlagType CarriedFlag;
};