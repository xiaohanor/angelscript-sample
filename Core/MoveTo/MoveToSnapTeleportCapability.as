
class UMoveToSnapTeleportCapability : UHazeCapability
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
		return MoveToComp.CanActivateMoveTo(EMoveToType::SnapTeleport, Params);
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

		FTransform Transform = MoveTo.Destination.CalculateDestination(Owner.ActorTransform, MoveTo.Params);
		Owner.TeleportActor(Transform.Location, Transform.Rotator(), this);

		MoveToComp.FinishMoveTo(MoveTo);
	}
};