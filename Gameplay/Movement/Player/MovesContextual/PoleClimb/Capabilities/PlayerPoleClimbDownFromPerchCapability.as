class UPlayerPoleClimbDownFromPerchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);
	default CapabilityTags.Add(PlayerPoleClimbTags::PoleClimbEnterFromPerch);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	//Needs to tick before PerchOnPoint
	default TickGroupOrder = 16;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerPerchComponent PerchComp;

	FVector PoleRelativeTargetLocation;
	FVector PoleRelativeStartLocation;
	FRotator StartRot;
	FRotator TargetRot;
	APoleClimbActor Pole;

	bool bTranslationFinished;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerPerchToPoleClimbActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!PerchComp.IsCurrentlyPerching())
			return false;

		if (PerchComp.Data.bPerformingPerchTurnaround)
			return false;
		
		if (!WasActionStarted(ActionNames::Cancel))
			return false;
		
		APoleClimbActor PoleClimbActor = Cast<APoleClimbActor>(PerchComp.Data.ActivePerchPoint.Owner);
		if (PoleClimbActor == nullptr)
			return false;
		
		FPoleClimbEnterTestData TestData;
		if (!PoleClimbComp.TestForValidDropDown(TestData, PoleClimbActor))
			return false;
		
		Params.TestData = TestData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerPerchToPoleClimbDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (PoleClimbComp.Data.ActivePole == nullptr)
			return true;

		if (PoleClimbComp.Data.ActivePole.IsActorDisabled() || PoleClimbComp.Data.ActivePole.IsPoleDisabled())
			return true;

		if (bTranslationFinished)
		{
			Params.bMoveFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerPerchToPoleClimbActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::PoleClimb, this);

		bTranslationFinished = false;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Pole = Params.TestData.PoleActor;

		//Broadcast and clean up Perch
		PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
		PerchComp.StopPerching();

		PoleRelativeStartLocation = Player.ActorLocation;
		PoleRelativeTargetLocation = Pole.ActorLocation;
		PoleRelativeTargetLocation += (Pole.ActorUpVector * Params.TestData.ClimbDirectionSign) * (Params.TestData.MaxHeight);
		PoleRelativeTargetLocation += Player.ActorForwardVector * -PoleClimbComp.Settings.PlayerPoleHorizontalOffset;

		PoleRelativeStartLocation = Pole.ActorTransform.InverseTransformPosition(PoleRelativeStartLocation);
		PoleRelativeTargetLocation = Pole.ActorTransform.InverseTransformPosition(PoleRelativeTargetLocation);

		PoleClimbComp.AnimData.bClimbingDownFromPerchPoint = true;

		PoleClimbComp.StartClimbing(Params.TestData);
		PoleClimbComp.SetState(EPlayerPoleClimbState::EnterFromPerch);

		UPlayerCoreMovementEffectHandler::Trigger_Pole_ClimbDownFromPerchStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerPerchToPoleClimbDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::PoleClimb, this);
		
		PoleClimbComp.AnimData.bClimbingDownFromPerchPoint = false;

		if(!Params.bMoveFinished)
		{
			PoleClimbComp.SetState(EPlayerPoleClimbState::Inactive);
			PoleClimbComp.StopClimbing();
			return;
		}

		FVector PlayerToPole = Pole.ActorLocation - Player.ActorLocation;
		FVector ConstrainedHeightVector = PlayerToPole.ConstrainToDirection(Pole.ActorUpVector * PoleClimbComp.Data.ClimbDirectionSign);
		PoleClimbComp.Data.CurrentHeight = ConstrainedHeightVector.Size();

		PoleClimbComp.SetState(EPlayerPoleClimbState::Climbing);

		if(PoleClimbComp.Data.ActivePole != nullptr)
			PoleClimbComp.Data.ActivePole.OnEnteredFromPerch.Broadcast(Player, PoleClimbComp.Data.ActivePole);

		Player.PlayForceFeedback(PoleClimbComp.PerchFF, false, true, this);

		UPlayerCoreMovementEffectHandler::Trigger_Pole_ClimbDownFromPerchFinished(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TransformedStartPosition = Pole.ActorTransform.TransformPosition(PoleRelativeStartLocation);
		FVector TransformedTargetPosition = Pole.ActorTransform.TransformPosition(PoleRelativeTargetLocation);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				float Alpha = ActiveDuration / PoleClimbComp.Settings.ClimbDownFromPerchDuration;

				FVector NewLoc = Math::Lerp(TransformedStartPosition, TransformedTargetPosition, Alpha);
				FVector DeltaMove = NewLoc - Player.ActorLocation;
				FRotator NewRot = Player.ActorRotation;

				if(Alpha >= 1)
					bTranslationFinished = true;
				
				Movement.AddDeltaWithCustomVelocity(DeltaMove, FVector::ZeroVector);
				Movement.SetRotation(NewRot);
				Movement.IgnoreSplineLockConstraint();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"PoleClimb", this);
		}
	}
};

struct FPlayerPerchToPoleClimbActivationParams
{
	FPoleClimbEnterTestData TestData;
}

struct FPlayerPerchToPoleClimbDeactivationParams
{
	bool bMoveFinished = false;
}