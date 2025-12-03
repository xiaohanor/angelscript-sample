event void FOnSolarFlareControlRoomInteractionComplete();

class AControlRoomInteractionManager : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareControlRoomInteractionComplete OnSolarFlareControlRoomInteractionComplete; 

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(3.0));
#endif

	UPROPERTY(EditAnywhere)
	AThreeShotInteractionActor LeftInteraction;

	UPROPERTY(EditAnywhere)
	AThreeShotInteractionActor RightInteraction;

	ASolarFlareVOManager VOManager;

	TPerPlayer<bool> bPlayerEngaged;

	bool bHaveBroadcasted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VOManager = TListedActors<ASolarFlareVOManager>().GetSingle();
		LeftInteraction.Interaction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		LeftInteraction.Interaction.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		RightInteraction.Interaction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		RightInteraction.Interaction.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		bPlayerEngaged[Player] = true;

		if (!bPlayerEngaged[Player] || !bPlayerEngaged[Player.OtherPlayer])
		{
			if (!bHaveBroadcasted)
				VOManager.TriggerDoubleInteractStarted(Player);
		}

		if (bPlayerEngaged[Player] && bPlayerEngaged[Player.OtherPlayer] && !bHaveBroadcasted)
		{
			VOManager.TriggerDoubleInteractCompleted();
			bHaveBroadcasted = true;
			
			//TODO Cancel players out manually somehow
			LeftInteraction.Interaction.KickAnyPlayerOutOfInteraction();
			RightInteraction.Interaction.KickAnyPlayerOutOfInteraction();
			LeftInteraction.AddActorDisable(this);
			RightInteraction.AddActorDisable(this);
			OnSolarFlareControlRoomInteractionComplete.Broadcast();
		}
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		bPlayerEngaged[Player] = false;
	}
};