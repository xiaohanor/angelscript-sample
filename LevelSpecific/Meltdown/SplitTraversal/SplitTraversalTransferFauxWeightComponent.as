class USplitTraversalTransferFauxWeightComponent : UFauxPhysicsPlayerWeightComponent
{
	UPROPERTY(EditAnywhere)
	bool bUseSpecifiedTargetWorld = true;

	// Apply player weight force from this component to this actor in the other world as well
	UPROPERTY(EditAnywhere, meta = (EditCondition="!bUseSpecifiedTargetWorld", EditConditionHides))
	AHazeActor TransferToActor;

	// Apply player weight force from this component to owner in specified world
	UPROPERTY(EditAnywhere, meta = (EditCondition="bUseSpecifiedTargetWorld", EditConditionHides))
	EHazeWorldLinkLevel FauxPhysicsLevel;

	void ApplyPlayerWeight(AHazePlayerCharacter Player) override
	{
		if (!bUseSpecifiedTargetWorld)
			Super::ApplyPlayerWeight(Player);

		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();


		if (bUseSpecifiedTargetWorld)
		{
			FauxPhysics::ApplyFauxForceToActorAt(
			Owner,
			Manager.Position_Convert(
				Player.ActorLocation,
				Manager.GetSplitForPlayer(Player),
				FauxPhysicsLevel,
			),
			-Player.MovementWorldUp * PlayerForce);
		}

		else
		{
			FauxPhysics::ApplyFauxForceToActorAt(
			TransferToActor,
			Manager.Position_Convert(
				Player.ActorLocation,
				Manager.GetSplitForPlayer(Player),
				Manager.GetOtherSplit(Manager.GetSplitForPlayer(Player)),
			),
			-Player.MovementWorldUp * PlayerForce);
		}	
	}
};