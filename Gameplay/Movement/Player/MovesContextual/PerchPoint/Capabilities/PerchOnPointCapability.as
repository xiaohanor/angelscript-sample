
class UPerchOnPointCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointPerch);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 44;
	default TickGroupSubPlacement = 10;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPerchOnPointActivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(PerchComp.Data.ActivePerchPoint == nullptr)
			return false;

        if(PerchComp.Data.ActivePerchPoint.bHasConnectedSpline)
            return false;

		Params.ActivatedOnData = PerchComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPerchOnPointDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
		{
			if(PerchComp.Data.State == EPlayerPerchState::JumpTo)
				Params.DeactivationType = EPerchOnPointDeactivationTypes::JumpTo;
			else if(PerchComp.Data.bJumpingOff)
				Params.DeactivationType = EPerchOnPointDeactivationTypes::JumpOff;
			else
				Params.DeactivationType = EPerchOnPointDeactivationTypes::Interrupted;

			return true;
		}

		if(PerchComp.Data.ActivePerchPoint.IsDisabled() || PerchComp.Data.ActivePerchPoint.IsDisabledForPlayer(Player))
		{
			Params.DeactivationType = EPerchOnPointDeactivationTypes::Disabled;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPerchOnPointActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::Perch, this);

		//Make sure our data is replicated
		PerchComp.Data = ActivationParams.ActivatedOnData;
		MoveComp.FollowComponentMovement(PerchComp.Data.ActivePerchPoint, this);
		
		//Assign our state after Data has been set (If we got teleported here then previous data would overwrite with inactive state)
		PerchComp.SetState(EPlayerPerchState::PerchingOnPoint);
		MoveComp.ApplyCustomMovementStatus(n"Perching", this);

		if (PerchComp.Data.ActivePerchPoint.PerchCameraSetting != nullptr)
		{
			if (PerspectiveModeComp.IsCameraBehaviorEnabled())
				Player.ApplyCameraSettings(PerchComp.Data.ActivePerchPoint.PerchCameraSetting, 2.0, this, SubPriority = 44);
		}
		
		if (PerchComp.Data.ActivePerchPoint.PerchSettings != nullptr)
			Player.ApplySettings(PerchComp.Data.ActivePerchPoint.PerchSettings, this);

		//Set our landing velocity for ABP to read
		PerchComp.Data.PerchLandingVerticalVelocity = MoveComp.VerticalVelocity;
		PerchComp.Data.PerchLandingHorizontalVelocity = MoveComp.HorizontalVelocity;

		//Reset Move Usage
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		if(!IsBlocked() && PerchComp.Data.ActivePerchPoint.bShouldCameraFollowPointRotation)
			Player.ApplyCameraUsesMovementFollowDeltaRotation(this);

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Started(Player);

		//Broadcast Started perching event
		PerchComp.Data.ActivePerchPoint.OnPlayerStartedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPerchOnPointDeactivationParams Params)
	{
		Player.ClearCameraUsesMovementFollowDeltaRotation(this);
		Player.UnblockCapabilities(BlockedWhileIn::Perch, this);
		MoveComp.ClearCustomMovementStatus(this);
		MoveComp.UnFollowComponentMovement(this);

		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);

		switch(Params.DeactivationType)
		{
			case EPerchOnPointDeactivationTypes::Disabled:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;

			//[AL] - StoppedPerchingEvent is fired in jumpoff capability as it should already have stopped perching = our Current perchPoint has been cleared.
			case EPerchOnPointDeactivationTypes::JumpOff:
				PerchComp.StopPerching();
				break;

			case EPerchOnPointDeactivationTypes::Interrupted:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;

			case EPerchOnPointDeactivationTypes::JumpTo:
				PerchComp.StopPerching();
				break;

			default:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;
		}

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MoveInput = MoveComp.MovementInput;

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector NewDir = MoveInput;
				float RotRate = Player.ActorRightVector.DotProduct(NewDir);
				if(RotRate < 0)
					RotRate = -1;
				else
					RotRate = 1;

				if(NewDir.IsNearlyZero() || NewDir.DotProduct(Player.ActorForwardVector) > 0.999)
				{
					NewDir = Player.ActorForwardVector;
					RotRate = 0;
				}

				PerchComp.Data.RotRate = RotRate;
				FRotator Rot = Math::RInterpConstantTo(Player.ActorRotation, NewDir.Rotation(), DeltaTime, 250.0);
				Movement.SetRotation(Rot);
				Movement.IgnoreSplineLockConstraint();
			
				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(
					PerchComp.Data.ActivePerchPoint.WorldLocation, FVector::ZeroVector
				);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Perch");
		}

		Player.SetBlendSpaceValues(MoveInput.X, MoveInput.Y);
	}
}

struct FPerchOnPointActivationParams
{
	FPerchData ActivatedOnData;
}

struct FPerchOnPointDeactivationParams
{
	EPerchOnPointDeactivationTypes DeactivationType;
}

enum EPerchOnPointDeactivationTypes
{
	None,
	Disabled,
	JumpOff,
	JumpTo,
	Interrupted
}