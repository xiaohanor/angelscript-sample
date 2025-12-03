
class UPlayerPoleClimbCancelCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);
	default CapabilityTags.Add(PlayerPoleClimbTags::PoleClimbCancel);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;

	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	USteppingMovementData Movement;

	APoleClimbActor PoleActor;

	//In order to not snap meshrotation awkwardly on angled poles we delay it one tick
	bool bTriggeredDelayedTransformReset = false;

	const float CancelDuration = 0.4;
	FVector CancelDirection = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;
		
		if(PoleClimbComp.Data.ActivePole == nullptr)
			return false;

		if(PoleClimbComp.GetState() != EPlayerPoleClimbState::Climbing)
			return false;

		if(PoleClimb::bUseAlternateClimbControls)
			return false;

		if(PoleClimbComp.Data.bPerformingTurnaround)
			return false;

		// When in 2D mode, holding down with the stick and should drop down instead of jump down
		if (PerspectiveModeComp.GetPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller)
		{
			if (WasActionStarted(ActionNames::MovementJump))
			{
				if (GetAttributeVector2D(AttributeVectorNames::MovementRaw).DotProduct(FVector2D(-1, 0)) > 0.8)
				{
					return true;
				}
			}
		}

		// Cancel always drops from the pole
		if(IsActioning(ActionNames::Cancel))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsOnWalkableGround())
			return true;

		if(ActiveDuration >= CancelDuration)
			return true;
	
		if(PoleClimbComp.Data.State != EPlayerPoleClimbState::Cancel)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::PoleClimb, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		//Store Pole since we are detaching via StopClimbing()
		PoleActor = PoleClimbComp.Data.ActivePole;

		CancelDirection = PoleClimbComp.GetPoleToPlayerVector();
		FVector OutwardsVelocity = CancelDirection * PoleClimbComp.Settings.CancelOutwardsImpulse;

		FVector DownwardsVelocity = FVector::ZeroVector;

		float SpeedDot = (MoveComp.WorldUp.DotProduct(MoveComp.VerticalVelocity));
		if(SpeedDot < 0.0)
			DownwardsVelocity = MoveComp.WorldUp * SpeedDot;

		Player.SetActorVelocity(OutwardsVelocity + DownwardsVelocity);

		if(PoleClimbComp.Data.ActivePole != nullptr)
			PoleClimbComp.Data.ActivePole.OnCancel.Broadcast(Player, PoleClimbComp.Data.ActivePole, OutwardsVelocity.GetSafeNormal());

		//Detach from pole and clear data
		PoleClimbComp.StopClimbing();

		PoleClimbComp.SetState(EPlayerPoleClimbState::Cancel);
		PoleClimbComp.AnimData.bCancellingPoleClimb = true;

		UPlayerCoreMovementEffectHandler::Trigger_Pole_LetGo(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::PoleClimb, this);

		//Incase we somehow didnt clear our constraint override when applying the OffsetReset then clear it here.
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		//Cleanup capability and anim data
		PoleActor = nullptr;
		CancelDirection = FVector::ZeroVector;
		PoleClimbComp.SetState(EPlayerPoleClimbState::Inactive);
		PoleClimbComp.AnimData.bCancellingPoleClimb = false;

		bTriggeredDelayedTransformReset = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector VerticalVelocity = MoveComp.Velocity.ConstrainToDirection(MoveComp.WorldUp);
				FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);

				HorizontalVelocity -= HorizontalVelocity * 1.0 * DeltaTime;

				float GravityBlendIn = Math::Clamp(ActiveDuration / 0.2, 0.0, 1.0);
				
				VerticalVelocity -= MoveComp.WorldUp * 2075.0 * GravityBlendIn * DeltaTime;

				// Terminal Velocity
				if (VerticalVelocity.DotProduct(MoveComp.WorldUp) < - 4000.0)
					VerticalVelocity = VerticalVelocity.GetClampedToMaxSize(4000.0);

				Movement.AddVerticalVelocity(VerticalVelocity);
				Movement.AddHorizontalVelocity(HorizontalVelocity);

				FRotator TargetRot = FRotator::MakeFromXZ(CancelDirection, MoveComp.WorldUp);

				//We delay our offset freeze one frame to not have character snap when exiting on angled poles
				if(ActiveDuration == 0)
				{
					TargetRot = FRotator::MakeFromXZ(-Player.ActorForwardVector, Player.ActorUpVector);
				}
				else if(!bTriggeredDelayedTransformReset)
				{
					MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
					bTriggeredDelayedTransformReset = true;

					Player.RootOffsetComponent.FreezeRotationAndLerpBackToParent(n"PoleResetRotation", 0.2);
					Player.RootOffsetComponent.FreezeLocationAndLerpBackToParent(n"PoleResetLocation", 0.1);
				}	

				Movement.SetRotation(TargetRot);
				Movement.IgnoreSplineLockConstraint();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"PoleClimb");
		}
	}
}