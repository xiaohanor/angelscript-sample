class UMoonMarketBouncyBallBlasterPotionMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 0;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;
	UMoonMarketBouncyBallBlasterPotionComponent BallBlasterComp;

	FHazeAcceleratedFloat AccYaw;
	FHazeAcceleratedFloat AccPitch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		BallBlasterComp = UMoonMarketBouncyBallBlasterPotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BallBlasterComp.BallBlaster == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccYaw.SnapTo(0);
		AccPitch.SnapTo(0);
		Player.BlockCapabilitiesExcluding(PlayerMovementTags::CoreMovement, n"MoonMarketPolymorph", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;
		
		if(HasControl())
		{
			FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			const FVector2D NormalizedInput = MovementInput.GetSafeNormal();
			
			const FVector Forward = Player.GetCameraDesiredRotation().ForwardVector.VectorPlaneProject(FVector::UpVector);
			const FVector Right = Forward.CrossProduct(FVector::DownVector);

			Movement.AddHorizontalVelocity(Forward * NormalizedInput.Y * BallBlasterComp.MoveSpeed * DeltaTime);
			Movement.AddHorizontalVelocity(Right * NormalizedInput.X * BallBlasterComp.MoveSpeed * DeltaTime);

			float FrictionValue = 7;
			if(MoveComp.HasGroundContact())
				Movement.AddHorizontalVelocity(-MoveComp.HorizontalVelocity * (FrictionValue * DeltaTime));

			Movement.AddGravityAcceleration();
			Movement.AddOwnerVelocity();
			Movement.AddPendingImpulses();
			Movement.SetRotation(Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).Rotation());

			if(!MoveComp.HasGroundContact())
				Movement.RequestFallingForThisFrame();

		}
		else
		{
			if(MoveComp.HasGroundContact())
				Movement.ApplyCrumbSyncedGroundMovement();
			else
				Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);
	}
};