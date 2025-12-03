class ATeenDragonEatableObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;
	default InteractComp.FocusShape.SphereRadius = 800.0;
	FMoveToParams MoveToParams;
	default MoveToParams.Type = EMoveToType::NoMovement;
	default InteractComp.MovementSettings = MoveToParams;

	UPROPERTY()
	UNiagaraSystem EatEffect;

	UPROPERTY()
	FTeenDragonEatingData EatableObjectData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EatableObjectData.Object = this;
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		if (Player.IsInAir())
			return;

		InteractionComponent.Disable(this);
		auto EatComp = UTeenDragonEatingComponent::Get(Player);
		EatComp.SetObjectToEat(EatableObjectData);
		OnObjectEatStarted(Player);
	}

	UFUNCTION(BlueprintEvent)
	void OnObjectEatStarted(AHazePlayerCharacter Player) {}

	void EatObject()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(EatEffect, ActorLocation, ActorRotation);
		AddActorDisable(this);
	}
};