UCLASS(Abstract)
class UPirateShipTelescopePlayerComponent : UActorComponent
{
	bool bIsUsingTelescope = false;
	APirateShipTelescope Telescope = nullptr;
	bool bHasFocusedOnTarget = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPirateTelescopeWidget> WidgetClass;
};