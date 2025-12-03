class AIslandOverseerCombatIntroFixPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(5.0);

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;
#endif

	UFUNCTION()
	void ResetPlayersOutsideArena(ARespawnPoint RespawnPoint)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(ActorForwardVector.DotProduct(Player.ActorLocation - ActorLocation) > 0)
				Player.TeleportToRespawnPoint(RespawnPoint, this, true);
		}
	}
}