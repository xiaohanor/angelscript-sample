UCLASS(Abstract)
class AControllableDropShipEnemyShipSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AControllableDropShipEnemyShip> ShipClass;
}