class UAdultDragonCircleStrafeMoveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonCircleStrafeComponent CircleStrafeComp;
	UCameraUserComponent CameraUserComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;

	ASummitAdultDragonCircleStrafeManager StrafeManager;

	FVector TargetOffset;
	FHazeAcceleratedVector AccOffset;
	FHazeAcceleratedVector AccUnclampedOffset;

	UAdultDragonCircleStrafeSettings StrafeSettings;
	const float CameraDeactivateBlendTime = 2.0;
	const float CameraActivationBlendTime = 5.0;
	const float UnclampedOffsetAccelerationDuration = 1.0;
	const float RotationSpeed = 4.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StrafeSettings = UAdultDragonCircleStrafeSettings::GetSettings(Player);

		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		CircleStrafeComp = UAdultDragonCircleStrafeComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(StrafeManager == nullptr)
			return false;

		if(StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::Circling)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if(StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::Circling)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Flying, this, EInstigatePriority::Normal);

		FTransform FollowTransform = GetFollowTransform();
		FVector BaseLocation = GetBaseLocation(FollowTransform);

		if(CircleStrafeComp.bSmoothenTransition)
		{
			FVector Location = Player.ActorLocation;

			FVector DeltaFromBase = Location - BaseLocation;
			float OffsetRight = DeltaFromBase.DotProduct(FollowTransform.Rotation.RightVector);
			OffsetRight = Math::Clamp(OffsetRight, -StrafeSettings.OffsetBoundaryRadius.X, StrafeSettings.OffsetBoundaryRadius.X);
			float OffsetUp = DeltaFromBase.DotProduct(FollowTransform.Rotation.UpVector); 
			OffsetUp = Math::Clamp(OffsetUp, -StrafeSettings.OffsetBoundaryRadius.X, StrafeSettings.OffsetBoundaryRadius.X);

			TargetOffset = FVector(0, OffsetRight, OffsetUp);
			AccOffset.SnapTo(TargetOffset);

			FVector RightOffset = FollowTransform.Rotation.RightVector * TargetOffset.Y;
			FVector UpOffset = FollowTransform.Rotation.UpVector * TargetOffset.Z;

			FVector TargetLocation = BaseLocation + RightOffset + UpOffset;
			FVector	StartUnclampedOffset = Location - TargetLocation;

			AccUnclampedOffset.SnapTo(StartUnclampedOffset);
			TEMPORAL_LOG(Player)
				.Sphere("Current Location", Location, 100, FLinearColor::Green, 20)
				.Sphere("Base Location", BaseLocation, 100, FLinearColor::Red, 20)
				.Arrow("New Offset", BaseLocation, TargetLocation, 50, 200, FLinearColor::DPink)
				.Arrow("Start Unclamped Offset", TargetLocation + StartUnclampedOffset, TargetLocation, 50, 200, FLinearColor::LucBlue)
			;
		}
		else
		{
			AccOffset.SnapTo(FVector::ZeroVector);
		}

		StrafeManager.ActivateCirclingCamera(Player);
		Player.ApplyBlendToCurrentView(CameraActivationBlendTime);

		MoveComp.FollowComponentMovement(StrafeManager.AttachmentRoot, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal);
		CircleStrafeComp.bSmoothenTransition = false;

		DragonComp.AimingInstigators.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);

		StrafeManager.DeactivateCirclingCamera(Player);
		Player.ApplyBlendToCurrentView(CameraDeactivateBlendTime);

		MoveComp.UnFollowComponentMovement(this);

		DragonComp.AimingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(StrafeManager == nullptr)
			StrafeManager = CircleStrafeComp.StrafeManager;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FTransform FollowTransform = GetFollowTransform();
				FVector BaseLocation = GetBaseLocation(FollowTransform);

				FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

				TargetOffset.Y += MovementInput.Y * StrafeSettings.OffsetSpeed * DeltaTime;
				TargetOffset.Y = Math::Clamp(TargetOffset.Y, -StrafeSettings.OffsetBoundaryRadius.X, StrafeSettings.OffsetBoundaryRadius.X);
				TargetOffset.Z += MovementInput.X * StrafeSettings.OffsetSpeed * DeltaTime;
				TargetOffset.Z = Math::Clamp(TargetOffset.Z, -StrafeSettings.OffsetBoundaryRadius.Y, StrafeSettings.OffsetBoundaryRadius.Y);

				AccOffset.AccelerateTo(TargetOffset, StrafeSettings.OffsetAccelerationDuration, DeltaTime);

				FVector RightOffset = FollowTransform.Rotation.RightVector * AccOffset.Value.Y;
				FVector UpOffset = FollowTransform.Rotation.UpVector * AccOffset.Value.Z;

				AccUnclampedOffset.AccelerateTo(FVector::ZeroVector, UnclampedOffsetAccelerationDuration, DeltaTime);
				FVector ClampedLocation = BaseLocation + RightOffset + UpOffset;
				FVector TargetLocation = ClampedLocation + AccUnclampedOffset.Value; 
				Movement.AddDelta(TargetLocation - Player.ActorLocation);

				FRotator TargetRotation;
				if(StrafeManager.bStrafingIsFlipped)
					TargetRotation = FRotator::MakeFromX(-FollowTransform.Rotation.RightVector);
				else
					TargetRotation = FRotator::MakeFromX(FollowTransform.Rotation.RightVector);

				FRotator NewRotation = Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, RotationSpeed);
				Movement.SetRotation(NewRotation);

				TEMPORAL_LOG(Player)
					.Box("Offset Boundary", BaseLocation, FVector(0, StrafeSettings.OffsetBoundaryRadius.X, StrafeSettings.OffsetBoundaryRadius.Y), FollowTransform.Rotator(), FLinearColor::Red, 50)
					.Sphere("Base Location", BaseLocation, 100, FLinearColor::Red, 20)
					.Arrow("Target Offset", BaseLocation, ClampedLocation, 50, 200, FLinearColor::DPink)
					.Arrow("Acc Unclamped Offset", ClampedLocation, TargetLocation, 50, 200, FLinearColor::LucBlue)
				;
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(AdultDragonLocomotionTags::AdultDragonFlying);
		}
	}

	FVector GetBaseLocation(FTransform FollowTransform) const
	{
		return (FollowTransform.Location + FollowTransform.Rotation.ForwardVector * (StrafeSettings.BaseForwardOffset + StrafeSettings.AdditionalForwardOffset));
	}
	
	FTransform GetFollowTransform() const
	{
		return CircleStrafeComp.StrafeManager.CirclingCamera.WorldTransform;
	}
};