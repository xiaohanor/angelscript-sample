
class UMoveToSmoothTeleportCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");

	default DebugCategory = n"MoveTo";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 20;

	UMoveToComponent MoveToComp;
	FActiveMoveTo MoveTo;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveToComp = UMoveToComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FActiveMoveTo& Params) const
	{
		return MoveToComp.CanActivateMoveTo(EMoveToType::SmoothTeleport, Params);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FActiveMoveTo Params)
	{
		MoveTo = Params;
		MoveToComp.ActivateMoveTo(MoveTo);
		ApplySmoothTeleport(Owner, Params.Params, Params.Destination);
		MoveToComp.FinishMoveTo(MoveTo);
	}
};

void ApplySmoothTeleport(AHazeActor Actor, FMoveToParams Params, FMoveToDestination Destination)
{
	UHazeOffsetComponent OffsetComp;
	auto Player = Cast<AHazePlayerCharacter>(Actor);
	if (Player != nullptr)
	{
		OffsetComp = Player.GetRootOffsetComponent();
	}
	else
	{
		auto Character = Cast<AHazeCharacter>(Actor);
		if (Character != nullptr)
			OffsetComp = Character.MeshOffsetComponent;
	}

	if (OffsetComp != nullptr)
	{
		if (Destination.Component != nullptr)
			OffsetComp.FreezeRelativeTransformAndLerpBackToParent(n"MoveToSmoothTeleport", Destination.Component, 0.2);
		else
			OffsetComp.FreezeTransformAndLerpBackToParent(n"MoveToSmoothTeleport", 0.2);
	}

	Actor.ActorTransform = Destination.CalculateDestination(Actor.ActorTransform, Params);
	Actor.SetActorVelocity(FVector::ZeroVector);
	Actor.ResetMovement();
}