class UMoonMarketPolymorphMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;

	UMoonMarketShapeshiftComponent ShapeshiftComp;
	UWitchPlayerMushroomBounceComponent BounceComp;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;
	
	FHazeAcceleratedVector MoveAcceleration;
	
	float GroundContactTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		BounceComp = UWitchPlayerMushroomBounceComponent::GetOrCreate(Player);
		ShapeshiftComp = UMoonMarketShapeshiftComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;
		
		if(!ShapeshiftComp.IsShapeshiftActive())
			return false;

		if(ShapeshiftComp.ShapeData.bUseCustomMovement)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ShapeshiftComp.IsShapeshiftActive())
			return true;

		if(ShapeshiftComp.ShapeData.bUseCustomMovement)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilitiesExcluding(PlayerMovementTags::CoreMovement, n"MoonMarketPolymorph", this);
		GroundContactTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{		
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;

		if(BounceComp.HasBouncedLastFrame())
		{
			UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(ShapeshiftComp.ShapeshiftShape.CurrentShape, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
			UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(Owner, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));

			ShapeshiftComp.GetShape().SetAnimTrigger(n"Bounce");
			ShapeshiftComp.GetShape().SetAnimTrigger(n"Jump");
		}
		
		if(HasControl())
		{
			if (MoveComp.HasGroundContact())
				GroundContactTime += DeltaTime;
			else
				GroundContactTime = 0;

			//BOUNCE
			if(ShapeshiftComp.ShapeData.bCanBounce)
			{
				if(!MoveComp.MovementInput.IsNearlyZero()  && MoveComp.HasGroundContact() && !MoveComp.HasImpulse() && GroundContactTime > 0.05)
				{
					Player.PlayForceFeedback(ForceFeedback::Default_Light_Tap, this);
					Player.AddMovementImpulse(FVector::UpVector * ShapeshiftComp.ShapeData.JumpStrength);
					CrumbSetAnimTrigger(n"Bounce");
				}
			}

			//JUMP
			if(ShapeshiftComp.ShapeData.bCanJump && WasActionStarted(ActionNames::MovementJump) && MoveComp.HasGroundContact())
			{
				Player.AddMovementImpulse(FVector::UpVector * ShapeshiftComp.ShapeData.JumpStrength);
				CrumbSetAnimTrigger(n"Jump");
			}
		}

		//HORIZONTAL MOVEMENT
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				MoveAcceleration.AccelerateTo(MovementInput.GetSafeNormal() * MovementInput.Size(), 0.2, DeltaTime);
				float Speed = ShapeshiftComp.ShapeData.MoveSpeed;
				Movement.AddHorizontalVelocity(MoveAcceleration.Value * Speed);
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
				Movement.AddPendingImpulses();
				HandleRotation(DeltaTime);
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			if(!MoveComp.HasGroundContact())
				Movement.RequestFallingForThisFrame();

			MoveComp.ApplyMove(Movement);
		}
	}

	
	void HandleRotation(float DeltaTime)
	{
		TOptional<FQuat> TargetRotation;

		if(!MoveComp.HorizontalVelocity.IsNearlyZero() && !MoveComp.HasWallContact())
			TargetRotation.Set(MoveComp.HorizontalVelocity.ToOrientationQuat());
		
		if(!TargetRotation.IsSet())
			return;

		Movement.SetRotation(Math::QInterpConstantTo(Player.GetActorQuat(), TargetRotation.Value, DeltaTime, 360));
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetAnimTrigger(FName TriggerName)
	{
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(ShapeshiftComp.ShapeshiftShape.CurrentShape, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(Owner, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));

		ShapeshiftComp.GetShape().SetAnimTrigger(TriggerName);
	}
};