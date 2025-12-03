class ULadderPlayerMeshOrientationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 26;
	default TickGroupSubPlacement = 5;	
	default DebugCategory = n"Movement";

	UPlayerLadderComponent LadderComp;
	UPlayerMovementComponent MoveComp;

	float LerpInDuration = 0.1;

	ALadder CurrentLadder;

	/* Should each capability set mesh location/Rotation rather then dedicated capability? (AL - For upcoming rework of ladderclimb)
	 * Cleanup jumping off mesh snapping, preferably we want mesh orientation to lerp back in from jump off rotation
	 * 
	 * Other Todos for rework
	 * Falling into ladder can lerp you back up a bit (account for or find next ping below player when entering with downwards velocity)
	 * Tracing for target location for ExitOnTop (Exiting on tilting train can cause issues, seems to rely on a depenetration solve to get roughly correct location depending on tilt which is really scary)
	 */

	UFUNCTION(BlueprintOverride)	
	void Setup()
	{
		LadderComp = UPlayerLadderComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;

		// if(!LadderComp.IsClimbing())
		// 	return false;

		// return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FLadderMeshOrientationDeactivationParams& Params) const
	{
		if(LadderComp.IsClimbing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentLadder = LadderComp.Data.ActiveLadder;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FLadderMeshOrientationDeactivationParams DeactivationParams)
	{
		if(LadderComp.State != EPlayerLadderState::JumpOut && LadderComp.State != EPlayerLadderState::LetGo && LadderComp.State != EPlayerLadderState::ExitOnBottom)
			Player.MeshOffsetComponent.ResetOffsetWithLerp(FInstigator(this).WithName(n"LadderRotation"), 0.5);
		else
			Player.MeshOffsetComponent.ClearOffset(FInstigator(this).WithName(n"LadderRotation"));

		// Player.MeshOffsetComponent.ResetOffsetWithLerp(FInstigator(this).WithName(n"LadderOffset"), 0.25);

		CurrentLadder = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat Rotation = FQuat::MakeFromXZ(CurrentLadder.ActorForwardVector, CurrentLadder.ActorUpVector);

		Player.MeshOffsetComponent.LerpToRotation(FInstigator(this).WithName(n"LadderRotation"), Rotation, LerpInDuration);

		// if(ActiveDuration <= LerpInDuration)
		// 	Player.MeshOffsetComponent.LerpToLocation(FInstigator(this).WithName(n"LadderOffset"), Player.ActorLocation + (LadderComp.Data.ActiveLadder.ActorForwardVector * 20), LerpInDuration);
		// else
		// 	Player.MeshOffsetComponent.SnapToLocation(FInstigator(this).WithName(n"LadderOffset"), Player.ActorLocation + (LadderComp.Data.ActiveLadder.ActorForwardVector * 20));
	}
};

struct FLadderMeshOrientationDeactivationParams
{
	EPlayerLadderState DeactivationState;
}