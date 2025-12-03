class UCentipedeDraggableChainCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default DebugCategory = CentipedeTags::Centipede;
	default CapabilityTags.Add(CentipedeTags::Centipede);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerCentipedeDraggableChainComponent PlayerDraggableChainComp;
	UCentipedeDraggableChainComponent DraggableChainComp;
	UPlayerMovementComponent MovementComponent;

	FHazeAcceleratedVector AcceleratedForward;
	FVector PlayerLastPosition;
	USteppingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		PlayerDraggableChainComp = UPlayerCentipedeDraggableChainComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerDraggableChainComp.DraggableChainComp == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerDraggableChainComp.DraggableChainComp == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DraggableChainComp = PlayerDraggableChainComp.DraggableChainComp;
		if (Player.HasControl())
			Player.BlockCapabilities(CentipedeTags::CentipedeMovement, this);
		AcceleratedForward.SnapTo(Player.ActorForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// DraggableChainComp.SetIsDragged(false, HasControl());
		if (Player.HasControl())
			Player.UnblockCapabilities(CentipedeTags::CentipedeMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Player.HasControl())
		{
			HandleRemoteTick(DeltaTime);
			return;
		}

		const FVector MoveInput = CentipedeComponent.MovementInput;
		const FVector MoveInputXY = FVector(MoveInput.Y, MoveInput.X, 0);
		const FVector Forward = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		const FRotator Rotation = FRotator::MakeFromX(Forward);
		const FVector Move = Rotation.RotateVector(MoveInputXY);
		
		// Debug::DrawDebugString(Player.ActorCenterLocation, "Moved " + Move, FLinearColor::White, 0.0, 1.0, true, FVector2D(0.5, 0.5), FVector2D(16.0, 16.0));
		// Debug::DrawDebugString(Player.ActorCenterLocation, "Dragged " + DraggableChainComp.GetIsDragged(), FLinearColor::Yellow, 0.0, 1.0, true, FVector2D(0.5, 0.5), -FVector2D(16.0, 16.0));

		// if (Move.Y < -0.5 && !DraggableChainComp.GetIsDragged())
		// 	DraggableChainComp.SetIsDragged(true, HasControl());
		// else if (Move.Y > -0.5 && DraggableChainComp.GetIsDragged())
		// 	DraggableChainComp.SetIsDragged(false, HasControl());

		//Calculate Player Transform
		
		FVector PlayerDesiredForward;

		FVector ChainForward = DraggableChainComp.WorldLocation + DraggableChainComp.ForwardVector * 2000.0;

		if (DraggableChainComp.GetIsDragged())
			PlayerDesiredForward = (Player.ActorLocation - Math::Lerp(Player.OtherPlayer.ActorLocation, ChainForward, 0.6)).GetSafeNormal();
		else
			PlayerDesiredForward = (Player.ActorLocation - Math::Lerp(Player.OtherPlayer.ActorLocation, ChainForward, 0.4)).GetSafeNormal();

		AcceleratedForward.AccelerateTo(PlayerDesiredForward * FVector(1.0, 1.0, 0.0), 1.0, DeltaTime);

		FVector PlayerForward = AcceleratedForward.Value;
		FVector PlayerLocation = DraggableChainComp.WorldLocation - (PlayerForward * Centipede::PlayerMeshMandibleOffset * 0.9);
		MoveTo(DeltaTime, PlayerLocation, PlayerForward.Rotation());
	}

	private void MoveTo(float DeltaTime, FVector PlayerLocation, FRotator PlayerRotation)
	{
		FVector FakeVelocity = FVector::ZeroVector;
		if (PlayerLastPosition.Size() > SMALL_NUMBER)
			FakeVelocity = (PlayerLocation - PlayerLastPosition) / DeltaTime;
		PlayerLastPosition = PlayerLocation;

		if (MovementComponent.PrepareMove(MoveData/*GetWorldUp(bOtherPlayerFalling)*/))
		{
			MoveData.AddVelocity(FakeVelocity);
			FVector VerticalVelocity = MovementComponent.Velocity.ConstrainToPlane(MovementComponent.GroundContact.Normal);
			VerticalVelocity -= MovementComponent.GroundContact.Normal * MovementComponent.GravityForce;
			MoveData.AddVerticalVelocity(VerticalVelocity);
			MoveData.SetRotation(PlayerRotation);
			MovementComponent.ApplyMove(MoveData);
		}
	}

	private void HandleRemoteTick(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData/*GetWorldUp(bOtherPlayerFalling)*/))
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
			MovementComponent.ApplyMove(MoveData);
		}
	}
};