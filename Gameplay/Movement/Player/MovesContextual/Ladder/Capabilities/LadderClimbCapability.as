class UPlayerLadderClimbCapability : UHazePlayerCapability
{
	/*
	 *	TopMost capability Handling any constant logic or one of behavior that should trigger on ladderclimb
	 * 	- Following ladder movement / Resetting move usages / Camera settings / etc
	 */

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerLadderComponent LadderComp;

	ALadder CurrentLadder;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		LadderComp = UPlayerLadderComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!LadderComp.IsClimbing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!LadderComp.IsClimbing())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		Player.BlockCapabilities(PlayerMovementTags::UnwalkableSlide, this);
		Player.BlockCapabilities(n"ContextualMoves", this);
		Player.BlockCapabilities(PlayerMovementTags::Grapple, this);
		Player.BlockCapabilities(PlayerMovementTags::Swing, this);

		CurrentLadder = LadderComp.Data.ActiveLadder;
		MoveComp.FollowComponentMovement(CurrentLadder.RootComp, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Interaction);
		
		//Apply our cam settings with LadderComp as instigator to allow JumpOut to snap clear clamps on activation
		//If we clear were to only clear the clamps here then it will be 1 frame late and would snap due to jump out capsule getting rotated
		if(LadderComp.GetState() == EPlayerLadderState::EnterFromTop)
			Player.ApplyCameraSettings(CurrentLadder.CameraSetting, 1, LadderComp, SubPriority = 25);
		else
			Player.ApplyCameraSettings(CurrentLadder.CameraSetting, 2, LadderComp, SubPriority = 25);

		Player.ResetWallScrambleUsage();
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Start(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		Player.UnblockCapabilities(PlayerMovementTags::UnwalkableSlide, this);
		Player.UnblockCapabilities(n"ContextualMoves", this);
		Player.UnblockCapabilities(PlayerMovementTags::Grapple, this);
		Player.UnblockCapabilities(PlayerMovementTags::Swing, this);

		MoveComp.UnFollowComponentMovement(this);
		Player.ClearCameraSettingsByInstigator(this, 3);

		if(LadderComp.IsClimbing())
		{
			LadderComp.SetState(EPlayerLadderState::Inactive);
			LadderComp.DeactivateLadderClimb();
		}

		//Clear our camera settings
		Player.ClearCameraSettingsByInstigator(LadderComp);

		CurrentLadder = nullptr;

		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Stop(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
};