struct FDentistToothGroundPoundStateActivateParams
{
	bool bIsAirGroundPound = false;
	UDentistGroundPoundAutoAimComponent AutoAimTarget;
};

struct FDentistToothGroundPoundStateDeactivateParams
{
	bool bFinished = false;
};

class UDentistToothGroundPoundStateCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(Dentist::Tags::GroundPound);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothGroundPoundComponent GroundPoundComp;
	UDentistToothDashComponent DashComp;
	UDentistToothJumpComponent JumpComp;

	UPlayerTargetablesComponent PlayerTargetablesComp;
	UPlayerMovementComponent MoveComp;

	bool bIsBlockingDash = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);
		DashComp = UDentistToothDashComponent::Get(Player);
		JumpComp = UDentistToothJumpComponent::Get(Player);

		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothGroundPoundStateActivateParams& Params) const
	{
		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if(GroundPoundComp.IsGroundPounding())
			return false;

		// if(MoveComp.IsInAir())
		// {
		// 	if(!GroundPoundComp.CanAirGroundPound())
		// 		return false;

		// 	Params.bIsAirGroundPound = true;
		// }
		Params.AutoAimTarget = PlayerTargetablesComp.GetPrimaryTarget(UDentistGroundPoundAutoAimComponent);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistToothGroundPoundStateDeactivateParams& Params) const
	{
		if(GroundPoundComp.AutoAimTarget != nullptr && GroundPoundComp.AutoAimTarget.IsDisabledForPlayer(Player))
		{
			Params.bFinished = false;
			return true;
		}

		if(GroundPoundComp.DesiredState == EDentistToothGroundPoundState::None)
		{
			Params.bFinished = true;
			return true;
		}

		if(GroundPoundComp.CurrentState == EDentistToothGroundPoundState::None)
		{
			Params.bFinished = true;
			return true;
		}

		if(GroundPoundComp.CurrentState == EDentistToothGroundPoundState::Recover)
		{
			Params.bFinished = true;
			return true;
		}

		if(!bIsBlockingDash)
		{
			if(DashComp.ShouldDash())
				return true;

			if(DashComp.IsDashing())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothGroundPoundStateActivateParams Params)
	{
		GroundPoundComp.StartGroundPound(Params.bIsAirGroundPound, Params.AutoAimTarget);

		JumpComp.ResetChainedJumpCount();

		bIsBlockingDash = true;
		Player.BlockCapabilities(Dentist::Tags::Dash, this);

		Player.BlockCapabilities(Dentist::Tags::BlockedWhileGroundPound, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistToothGroundPoundStateDeactivateParams Params)
	{
		GroundPoundComp.StopGroundPound(Params.bFinished);

		if(bIsBlockingDash)
		{
			Player.UnblockCapabilities(Dentist::Tags::Dash, this);
			bIsBlockingDash = false;
		}

		Player.UnblockCapabilities(Dentist::Tags::BlockedWhileGroundPound, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!PlayerComp.HasSetMeshRotationThisFrame())
		{
			// Reset mesh world rotation
			PlayerComp.SetMeshWorldRotation(Player.ActorQuat, this, Dentist::InterpVisualRotationDuration, DeltaTime);
		}

		if(bIsBlockingDash && ActiveDuration > GroundPoundComp.Settings.AnticipationBlockDashDuration)
		{
			Player.UnblockCapabilities(Dentist::Tags::Dash, this);
			bIsBlockingDash = false;
		}
	}
};