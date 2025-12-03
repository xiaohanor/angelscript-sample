
class UPlayerLadderHangCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderHang);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 26;
	default TickGroupSubPlacement = 1;	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;

	FVector TargetLocation;
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;

		if(LadderComp.Data.ActiveLadder.IsDisabled())
			return false;

		if (LadderComp.Data.bMoving)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!LadderComp.Data.bHanging)
			return true;

		if (WasActionStartedDuringTime(ActionNames::Cancel, 0.25))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.FollowComponentMovement(LadderComp.Data.ActiveLadder.RootComp, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Interaction);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		LadderComp.SetState(EPlayerLadderState::MH);
		LadderComp.Data.bHanging = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.UnFollowComponentMovement(this);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		LadderComp.Data.bHanging = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if (!HasControl())
				Movement.ApplyCrumbSyncedAirMovement();

			Movement.SetRotation(LadderComp.CalculatePlayerCapsuleRotation(LadderComp.Data.ActiveLadder));

			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}
};

