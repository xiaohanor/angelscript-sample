class ASolarFlareWallrunInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USolarFlareTargetableComponent Targetable;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY()
	bool bIsActivated;

	TPerPlayer<UPlayerTargetablesComponent> PlayerTargetables;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			PlayerTargetables[Player] = UPlayerTargetablesComponent::Get(Player);

		// ButtonInteraction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
	}

	void ActivateTargetableAction()
	{
		USolarFlareWallrunInteractionResponseComponent::Get(TargetActor).OnSolarFlareWallrunInteractionActivated.Broadcast();
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		// Interaction.Disable(this);
	}
}

class USolarFlareTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"Interaction";
	default bShowWhileDisabled = false;
	
	UPROPERTY()
	float MaxRange = 500;

	UPROPERTY()
	float VisibleRange = 1500;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, MaxRange);
		Targetable::ApplyVisibleRange(Query, VisibleRange);


		return true;
	}
}

struct FSolarFlareTargetableParams
{
	USolarFlareTargetableComponent ActivatedTargetable;
}