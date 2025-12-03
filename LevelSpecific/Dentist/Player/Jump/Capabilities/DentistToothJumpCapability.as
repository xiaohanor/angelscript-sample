struct FDentistToothJumpActivateParams
{
	bool bRollJump = false;
}

struct FDentistToothJumpDeactivateParams
{
	bool bNatural = false;
};

class UDentistToothJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(Dentist::Tags::Jump);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileGroundPound);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileDash);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UDentistToothJumpComponent JumpComp;
	UDentistToothDashComponent DashComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpComp = UDentistToothJumpComponent::Get(Player);
		DashComp = UDentistToothDashComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothJumpActivateParams& Params) const
	{
		if(!JumpComp.ShouldJump())
			return false;

		Params.bRollJump = DashComp.IsLanding();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistToothJumpDeactivateParams& Params) const
	{
		if(MoveComp.IsOnWalkableGround())
		{
			Params.bNatural = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothJumpActivateParams Params)
	{
		JumpComp.ConsumeJumpInput();

		JumpComp.ApplyIsJumping(this);

		if(Params.bRollJump)
			JumpComp.SetJumpType(EDentistToothJump::FrontFlip);
		else
			JumpComp.IncrementChainedJumpCount();

		JumpComp.AddJumpImpulse(this);

		switch(JumpComp.GetJumpType())
		{
			case EDentistToothJump::None:
				check(false);
				break;
				
			case EDentistToothJump::Regular:
				UDentistToothEventHandler::Trigger_OnJump(Player);
				break;
				
			case EDentistToothJump::Swirl:
				UDentistToothEventHandler::Trigger_OnSwirlJump(Player);
				break;

			case EDentistToothJump::FrontFlip:
				UDentistToothEventHandler::Trigger_OnFrontFlipJump(Player);
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistToothJumpDeactivateParams Params)
	{
		JumpComp.ClearIsJumping(this);

		if(Params.bNatural)
			UDentistToothEventHandler::Trigger_OnJumpLanding(Player);
		else
			UDentistToothEventHandler::Trigger_OnJumpCanceled(Player);
	}
};