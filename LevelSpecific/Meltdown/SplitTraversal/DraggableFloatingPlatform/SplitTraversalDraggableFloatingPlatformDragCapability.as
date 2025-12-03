class USplitTraversalDraggableFloatingPlatformDragCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	UPlayerMovementComponent MoveComp;

	ASplitTraversalDraggableFloatingPlatform DraggablePlatform;
	bool bMoving = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		DraggablePlatform = Cast<ASplitTraversalDraggableFloatingPlatform>(Params.Interaction.Owner);

		Player.ApplyCameraSettings(DraggablePlatform.CameraSettings, 2.0, this, EHazeCameraPriority::VeryHigh);
		Player.AttachToComponent(DraggablePlatform.InteractionComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		DraggablePlatform.TransferWeightComp.PlayerForce = 100.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.ClearCameraSettingsByInstigator(this, 2.0);

		if(bMoving)
			StopMoving();

		DraggablePlatform.TransferWeightComp.PlayerForce = 500.0;

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!DraggablePlatform.bBlockedMovement)
		{
			const FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			const FVector MoveInputXY = FVector(MoveInput.Y, MoveInput.X, 0);
			const FVector Forward = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			const FRotator Rotation = FRotator::MakeFromX(Forward);
			const FVector Move = Rotation.RotateVector(MoveInputXY) * DraggablePlatform.PushForce;
			
			FauxPhysics::ApplyFauxForceToParentsAt(DraggablePlatform.FantasyTranslateComp, DraggablePlatform.FantasyTranslateComp.WorldLocation, Move);

			if (Move.Size() > SMALL_NUMBER && !bMoving)
				StartMoving();

			if (Move.Size() < SMALL_NUMBER && bMoving)
				StopMoving();
		}

		if(Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"RaftSwim", this);
	}

	private void StartMoving()
	{
		if(bMoving)
			return;

		bMoving = true;
		USplitTraversalDraggableFloatingPlatformEventHandler::Trigger_StartMoving(DraggablePlatform);
	}

	private void StopMoving()
	{
		if(!bMoving)
			return;
		
		bMoving = false;
		USplitTraversalDraggableFloatingPlatformEventHandler::Trigger_StopMoving(DraggablePlatform);
	}
};