class UIslandRedBlueForceFieldCollisionComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere)
	float AdditionalCollisionShapeTolerance = 0.0;

	UPROPERTY(EditAnywhere)
	bool bStayIgnoredWhenIgnoredOnce = false;

	UPrimitiveComponent PrimitivePhysicsComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto MoveComp = UHazeMovementComponent::Get(Owner);

		if(MoveComp == nullptr)
		{
			PrimitivePhysicsComponent = UPrimitiveComponent::Get(Owner);
			devCheck(PrimitivePhysicsComponent != nullptr && PrimitivePhysicsComponent.IsSimulatingPhysics(), "There is a force field collision component on an actor without a movement component and without a simulate physics primitive component. This is not supported!");
		}

		Register();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Unregister();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Register();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Unregister();
	}

	void Register()
	{
		if(PrimitivePhysicsComponent == nullptr)
		{
			RegisterMoveComp();
		}
		else
		{
			RegisterPhysicsComp();
		}
	}

	void Unregister()
	{
		if(PrimitivePhysicsComponent == nullptr)
		{
			UnregisterMoveComp();
		}
		else
		{
			UnregisterPhysicsComp();
		}
	}

	void RegisterMoveComp()
	{
		auto MoveComp = UHazeMovementComponent::Get(Owner);
		devCheck(MoveComp != nullptr, "A UIslandRedBlueForceFieldCollisionComponent exists on an actor without a movement component (this is only supported if bExperimentalGenerateProceduralCollisionMesh is true)");
		UIslandRedBlueForceFieldCollisionContainerComponent::GetOrCreate(Game::Mio).IgnoreCollisionMovementComponents.AddUnique(FIslandRedBlueForceFieldIgnoreCollisionMoveCompData(MoveComp, AdditionalCollisionShapeTolerance, bStayIgnoredWhenIgnoredOnce));
	}

	void UnregisterMoveComp()
	{
		auto MoveComp = UHazeMovementComponent::Get(Owner);
		if(MoveComp != nullptr)
		{
			auto Container = UIslandRedBlueForceFieldCollisionContainerComponent::GetOrCreate(Game::Mio);
			Container.IgnoreCollisionMovementComponents.RemoveSingleSwap(FIslandRedBlueForceFieldIgnoreCollisionMoveCompData(MoveComp));
			Container.OnUnregisterMovementComponent.Broadcast(MoveComp);
		}
	}

	void RegisterPhysicsComp()
	{
		UIslandRedBlueForceFieldCollisionContainerComponent::GetOrCreate(Game::Mio).PrimitivePhysicsComponents.AddUnique(PrimitivePhysicsComponent);
	}

	void UnregisterPhysicsComp()
	{
		UIslandRedBlueForceFieldCollisionContainerComponent::GetOrCreate(Game::Mio).PrimitivePhysicsComponents.RemoveSingleSwap(PrimitivePhysicsComponent);
	}
}