class ABattlefieldFootCrushedTank : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UFUNCTION()
	void CrushTank()
	{
		FOnBattlefieldTankCrushParams Params;
		Params.Location = ActorLocation;
		UBattlefieldFootCrushedTankEffectHandler::Trigger_CrushTank(this, Params);
	}
}