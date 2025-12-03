class USplitTraversalPushableMushroomPushCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	UPlayerMovementComponent PlayerMoveComp;

	ASplitTraversalPushableMushroom PushableMushroom;
	UHazeMovementComponent MoveComp;
	UFloatingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		PushableMushroom = Cast<ASplitTraversalPushableMushroom>(ActiveInteraction.Owner);
		MoveComp = UHazeMovementComponent::Get(PushableMushroom);
		MoveData = MoveComp.SetupFloatingMovementData();

		Player.ApplyCameraSettings(PushableMushroom.CameraSettings, 2.0, this, EHazeCameraPriority::VeryHigh);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToComponent(PushableMushroom.InteractionComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.ClearCameraSettingsByInstigator(this, 2.0);

		if(HasControl() && PushableMushroom.bIsMoving)
			CrumbStopMoving();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasMovedThisFrame())
			return;

		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			MoveData.ApplyFloatingHeightThisFrame(10);

			const FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			const FVector MoveInputXY = FVector(MoveInput.Y, MoveInput.X, 0);

			const FVector Forward = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			const FRotator Rotation = FRotator::MakeFromX(Forward);
			const FVector Move = Rotation.RotateVector(MoveInputXY) * PushableMushroom.PushForce;

			FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
			ApplyFriction(HorizontalVelocity, DeltaTime);
			MoveData.AddHorizontalVelocity(HorizontalVelocity);

			PushableMushroom.VFXRoot.SetWorldRotation(HorizontalVelocity.GetSafeNormal().Rotation());

			MoveData.AddOwnerVerticalVelocity();
			MoveData.AddGravityAcceleration();

			if(Move.Size() > 0)
			{
				PushableMushroom.TargetRotation = Move.Rotation();
			}

			PushableMushroom.WheelPushForce = Move.Size();

			MoveData.AddAcceleration(Move);

			if (Move.Size() > SMALL_NUMBER && !PushableMushroom.bIsMoving)
				CrumbStartMoving();

			if (Move.Size() < SMALL_NUMBER && PushableMushroom.bIsMoving)
				CrumbStopMoving();
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);

		if(Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"BoxPush", this);
		}
	}

	private void ApplyFriction(FVector& Velocity, float DeltaTime) const
	{
		float IntegratedFriction = Math::Exp(-PushableMushroom.Friction);
		Velocity *= Math::Pow(IntegratedFriction, DeltaTime);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartMoving()
	{
		PushableMushroom.bIsMoving = true;

		PushableMushroom.MushroomPushVFXComp.Activate();
		USplitTraversalPushableMushroomEventHandler::Trigger_OnStartMoving(PushableMushroom);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStopMoving()
	{
		PushableMushroom.bIsMoving = false;
		PushableMushroom.VelocityOnStoppedMoving = PushableMushroom.ActorVelocity;

		PushableMushroom.MushroomPushVFXComp.Deactivate();
		USplitTraversalPushableMushroomEventHandler::Trigger_OnStopMoving(PushableMushroom);
	}
};