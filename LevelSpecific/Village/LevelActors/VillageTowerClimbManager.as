class AVillageTowerClimbManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	TArray<APlayerTrigger> PlayerTriggers;

	// Don't look
	UFUNCTION()
	void DisableDanger()
	{
		// for (AHazePlayerCharacter Player : Game::GetPlayers())
		// {
		// 	TArray<UActorComponent> PlayerComps = Player.GetComponentsByClass(UPrimitiveComponent);
		// 	for (UActorComponent Comp : PlayerComps)
		// 	{	
		// 		UPrimitiveComponent PrimComp = Cast<UPrimitiveComponent>(Comp);
		// 		if (PrimComp != nullptr)
		// 			PrimComp.SetCollisionResponseToChannel(ECollisionChannel::Trigger, ECollisionResponse::ECR_Ignore);
		// 	}
		// }

		for (APlayerTrigger Trigger : PlayerTriggers)
		{
			Trigger.DisablePlayerTrigger(this);
		}
	}
}