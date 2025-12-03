event void FOnBombPlacedInContainer();
class ABombTossBombContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh2;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BombMesh;
	default BombMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY()
	FOnBombPlacedInContainer OnBombPlacedInContainer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		BombMesh.SetHiddenInGame(false);
		OnBombPlacedInContainer.Broadcast();
		InteractionComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AHazePlayerCharacter PlayerHoldingBomb = nullptr;

		for(auto Player : Game::GetPlayers())
		{
			if(UGameShowArenaBombTossPlayerComponent::Get(Player).bHoldingBomb)
				PlayerHoldingBomb = Player;
		}

		if(PlayerHoldingBomb == nullptr)
		{
			for(auto Player : Game::GetPlayers())
				InteractionComp.DisableForPlayer(Player, this);
			return;
		}

		InteractionComp.EnableForPlayer(PlayerHoldingBomb, this);
		InteractionComp.DisableForPlayer(PlayerHoldingBomb.OtherPlayer, this);		
	}
}