class UShootEmUpPlayerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AShootEmUpShip> ShipClass;
	AShootEmUpShip CurrentShip;

	UPROPERTY()
	TSubclassOf<AShootEmUpProjectile> ProjectileClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentShip = SpawnActor(ShipClass);
	}
}