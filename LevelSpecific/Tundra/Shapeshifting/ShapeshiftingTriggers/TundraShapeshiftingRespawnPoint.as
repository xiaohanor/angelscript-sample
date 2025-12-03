class ATundraShapeshiftingRespawnPoint : ARespawnPoint
{
	/* When respawning, this should be the shape that Zoe spawns as, if none, will keep its current shape */
	UPROPERTY(EditAnywhere, Category = "Respawn Point", meta = (EditCondition = "bCanZoeUse"))
	ETundraShapeshiftShape ShapeForZoe;

	/* When respawning, this should be the shape that Mio spawns as, if none, will keep its current shape */
	UPROPERTY(EditAnywhere, Category = "Respawn Point", meta = (EditCondition = "bCanMioUse"))
	ETundraShapeshiftShape ShapeForMio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnRespawnAtRespawnPoint.AddUFunction(this, n"OnRespawn");
		OnPlayerTeleportToRespawnPoint.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn(AHazePlayerCharacter Player)
	{
		if(Player.IsMio() && ShapeForMio != ETundraShapeshiftShape::None)
			Player.TundraSetPlayerShapeshiftingShape(ShapeForMio, false);
		else if(Player.IsZoe() && ShapeForZoe != ETundraShapeshiftShape::None)
			Player.TundraSetPlayerShapeshiftingShape(ShapeForZoe, false);
	}
}