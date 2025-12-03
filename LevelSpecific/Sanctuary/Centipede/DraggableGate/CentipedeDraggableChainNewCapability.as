struct FCentipedeDraggableChainNewCapabilityActivationParams
{
	UCentipedeDraggableChainComponent DraggableChainComp;
	UFauxPhysicsTranslateComponent ChainTranslateComp;
}

class UCentipedeDraggableChainNewCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default DebugCategory = CentipedeTags::Centipede;
	default CapabilityTags.Add(CentipedeTags::Centipede);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	FCentipedeDraggableChainNewCapabilityActivationParams Params;
	UPlayerCentipedeDraggableChainComponent PlayerDraggableChainComp;
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComp;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerMovementComponent MovementComponent;

	FHazeAcceleratedQuat AcceleratedForward;
	FHazeAcceleratedFloat AccRetractSpeed;
	FHazeAcceleratedFloat AccCentiSpeed;

	USteppingMovementData MoveData;

	float SmoothTPDuration = 0.1;
	FVector PlayerStartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		PlayerDraggableChainComp = UPlayerCentipedeDraggableChainComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeDraggableChainNewCapabilityActivationParams& ActivationParams) const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (PlayerDraggableChainComp.DraggableChainComp == nullptr)
			return false;

		ActivationParams.DraggableChainComp = PlayerDraggableChainComp.DraggableChainComp;
		ActivationParams.ChainTranslateComp = Cast<UFauxPhysicsTranslateComponent>(PlayerDraggableChainComp.DraggableChainComp.AttachParent);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (PlayerDraggableChainComp.DraggableChainComp == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCentipedeDraggableChainNewCapabilityActivationParams ActivationParams)
	{
		PlayerDraggableChainComp.DraggableChainComp = ActivationParams.DraggableChainComp;
		Params = ActivationParams;		
		Params.DraggableChainComp.SetIsDragged(true);
		ADraggableGateActor Gate = Cast<ADraggableGateActor>(Params.DraggableChainComp.Owner);

		AccRetractSpeed.SnapTo(0.0);
		FVector PlayerLocation = Params.DraggableChainComp.WorldLocation + (Params.DraggableChainComp.ForwardVector * Centipede::PlayerMeshMandibleOffset);
		AccCentiSpeed.SnapTo(0.0);

		PlayerLocation.Z = Player.ActorLocation.Z;
		PlayerStartLocation = PlayerLocation;
		FRotator StartRotation = FRotator::MakeFromXZ(-Params.DraggableChainComp.ForwardVector, FVector::UpVector);
		AcceleratedForward.SnapTo(StartRotation.Quaternion());
		Player.SmoothTeleportActor(PlayerLocation, StartRotation, this, SmoothTPDuration);

		FSanctuaryCentipedeGateChainGrabbedData Data;
		Data.Player = Player;
		UPlayerCentipedeDraggableChainComponent OtherPlayerDraggableChainComp = UPlayerCentipedeDraggableChainComponent::Get(Player.OtherPlayer);
		Data.bOtherPlayerIsHoldingChain = OtherPlayerDraggableChainComp.DraggableChainComp != nullptr;
		UCentipedeEventHandler::Trigger_OnGateChainGrabbed(Player, Data);
		UCentipedeEventHandler::Trigger_OnGateChainGrabbed(Gate, Data);
		UCentipedeEventHandler::Trigger_OnGateChainGrabbed(CentipedeComponent.Centipede, Data);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ADraggableGateActor Gate = Cast<ADraggableGateActor>(Params.DraggableChainComp.Owner);
		FSanctuaryCentipedeGateChainReleasedData Data;

		Data.Player = Player;
		Data.ProgressWhenReleased = Params.DraggableChainComp.DraggedAlpha;
		UPlayerCentipedeDraggableChainComponent OtherPlayerDraggableChainComp = UPlayerCentipedeDraggableChainComponent::Get(Player.OtherPlayer);
		Data.bOtherPlayerIsHoldingChain = OtherPlayerDraggableChainComp.DraggableChainComp != nullptr;
		UCentipedeEventHandler::Trigger_OnGateChainReleased(Player, Data);
		UCentipedeEventHandler::Trigger_OnGateChainReleased(Gate, Data);
		UCentipedeEventHandler::Trigger_OnGateChainReleased(CentipedeComponent.Centipede, Data);
		Params.DraggableChainComp.SetIsDragged(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				HandleControlMovement(DeltaTime);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}
			MovementComponent.ApplyMove(MoveData);
		}

		if (ActiveDuration < SmoothTPDuration)
			return;

		FVector PlayerMandibleLocation = Player.ActorLocation + (Player.ActorForwardVector * Centipede::PlayerMeshMandibleOffset);
		FVector Delta = PlayerMandibleLocation - Params.DraggableChainComp.WorldLocation;
		Delta.Z = 0.0;
		Params.ChainTranslateComp.ApplyMovement(FVector(), Delta);
		
		if (SanctuaryCentipedeDevToggles::Draw::Biting.IsEnabled())
		{
			Debug::DrawDebugSphere(PlayerMandibleLocation, 100.0, 12, Player.GetPlayerUIColor(), 5.0, 0.0, true);
			Debug::DrawDebugCoordinateSystem(Params.DraggableChainComp.WorldLocation, Params.DraggableChainComp.WorldRotation, 300.0, 5.0, 0.0, true);
		}
	}

	private void HandleControlMovement(float DeltaTime)
	{
		if (SanctuaryCentipedeDevToggles::Draw::Biting.IsEnabled())
			Debug::DrawDebugString(Player.ActorLocation, "Chain Bite Drag", ColorDebug::Lavender);

		if (ActiveDuration < SmoothTPDuration)
			return;

		const FVector MoveInput = CentipedeComponent.GetMovementInput();
		FVector DeltaMovement = FVector();

		float DegreesCone = 20.0;
		// FVector DraggingVelocity = MoveInput.ConstrainToCone(Params.ChainTranslateComp.ForwardVector, Math::DegreesToRadians(DegreesCone) * 0.5);
		FVector ConstrainedMove = MoveInput.ConstrainToDirection(Params.ChainTranslateComp.ForwardVector);
		float SpeedAlpha = 1.0 - Math::Clamp(Math::DotToDegrees(ConstrainedMove.GetSafeNormal().DotProduct(Params.ChainTranslateComp.ForwardVector)) / DegreesCone, 0.0, 1.0);

		const float MaxAllowedLengthDiff = 300.0;
		const float DistanceFromConstraint = Math::Clamp(Params.ChainTranslateComp.RelativeLocation.X - Params.ChainTranslateComp.MinX, 0.0, 1.0);
		float RetractForceAlpha = Params.DraggableChainComp.ChainsDiffLength / MaxAllowedLengthDiff;
		float TargetSpeed = SpeedAlpha - (RetractForceAlpha * DistanceFromConstraint);
		if (DistanceFromConstraint < KINDA_SMALL_NUMBER && RetractForceAlpha > 1.0 - KINDA_SMALL_NUMBER)
			TargetSpeed = 0.0;
		if (Params.DraggableChainComp.bImpossible)
			TargetSpeed *= 1.0 - Math::Saturate(Params.ChainTranslateComp.RelativeLocation.X / Params.ChainTranslateComp.MaxX);

		AccCentiSpeed.AccelerateTo(TargetSpeed * 300.0, 0.5, DeltaTime);

		float MaxMoveMultiplier = Params.DraggableChainComp.bIsCapped ? 0.0 : 1.0; 
		// Debug::DrawDebugString(Player.ActorLocation, "" +  Params.ChainTranslateComp.RelativeLocation.X);
		FVector DraggingVelocity = ConstrainedMove * MaxMoveMultiplier * AccCentiSpeed.Value;
		// DraggingVelocity += Params.ChainTranslateComp.ForwardVector * -1.0 * 350.0 * RetractForceAlpha;

		if (SanctuaryCentipedeDevToggles::Draw::Biting.IsEnabled())
		{
			Debug::DrawDebugCone(Params.ChainTranslateComp.WorldLocation, Params.ChainTranslateComp.ForwardVector, 100.0, DegreesCone, DegreesCone);
		}

		if (LavaIntoleranceComp == nullptr)
			LavaIntoleranceComp = UCentipedeLavaIntoleranceComponent::GetOrCreate(CentipedeComponent.Centipede);

		bool bDragging = LavaIntoleranceComp.Health.Value >= 1.0 - KINDA_SMALL_NUMBER && MoveInput.Size() > 0.5 && ConstrainedMove.DotProduct(Params.ChainTranslateComp.ForwardVector) > 0.0;
		if (bDragging)
			MoveDragTheChain(DeltaTime, DraggingVelocity);
		else
			MoveDraggedAlong(DeltaTime);

		MoveData.AddGravityAcceleration();

		if (SanctuaryCentipedeDevToggles::Draw::Biting.IsEnabled())
		{
			Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + Params.ChainTranslateComp.ForwardVector * 1000.0, ColorDebug::Cyan, 15.0, 0.0, true);
			Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + DeltaMovement.GetSafeNormal() * 500.0, ColorDebug::Magenta, 5.0, 0.0, true);
		}
	}

	void MoveDragTheChain(float DeltaTime, FVector DraggingVelocity)
	{
		if (SanctuaryCentipedeDevToggles::Draw::Biting.IsEnabled())
			Debug::DrawDebugString(Player.ActorLocation, "\n\nDragging!", ColorDebug::Eggblue);

		AccRetractSpeed.SnapTo(0.0);
		FVector DeltaMovement = DraggingVelocity * DeltaTime;
		if (Params.DraggableChainComp.bIsCapped)
			DeltaMovement = FVector();

		DeltaMovement.Z = 0.0;
		MoveData.AddDelta(DeltaMovement);

		// Rotation
		{
			// AcceleratedForward.AccelerateTo(FRotator::MakeFromXZ(-DeltaMovement.GetSafeNormal(), FVector::UpVector).Quaternion(), 0.5, DeltaTime);
			AcceleratedForward.AccelerateTo(FRotator::MakeFromXZ(-Params.ChainTranslateComp.ForwardVector, FVector::UpVector).Quaternion(), 0.5, DeltaTime);
			MoveData.SetRotation(AcceleratedForward.Value);
		}
	}

	void MoveDraggedAlong(float DeltaTime)
	{
		if (SanctuaryCentipedeDevToggles::Draw::Biting.IsEnabled())
			Debug::DrawDebugString(Player.ActorLocation, "\n\nDragged along", ColorDebug::Lavender);

		Params.DraggableChainComp.ControlApplyRetractingForce(Player, DeltaTime);
		FVector DesiredPlayerLocation = Params.DraggableChainComp.WorldLocation + (Params.DraggableChainComp.ForwardVector * Centipede::PlayerMeshMandibleOffset);
		FVector DeltaMovement = DesiredPlayerLocation - Player.ActorLocation;

		DeltaMovement.Z = 0.0;
		MoveData.AddDelta(DeltaMovement);

		// Rotation
		{
			FVector TargetForward = Player.ActorForwardVector;
			TargetForward = -Params.ChainTranslateComp.ForwardVector;
			AcceleratedForward.AccelerateTo(FRotator::MakeFromXZ(TargetForward, FVector::UpVector).Quaternion(), 0.5, DeltaTime);
			MoveData.SetRotation(AcceleratedForward.Value);
		}
	}
};