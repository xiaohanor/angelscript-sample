
class UPlayerPolevaultChargeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 11;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerPolevaultComponent PolevaultComp;
	USteppingMovementData Movement;

	FVector MiddleLoc;
	FVector EndLoc;
	FHazeRuntimeSpline Spline;
	float ChargeTimeTotal = 1.0;
	float ChargeTime;
	float MaxHeight = 150.0;
	float MaxLength = 1450.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PolevaultComp = UPlayerPolevaultComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if (!IsActioning(ActionNames::WeaponSecondary))
        	// return false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (!IsActioning(ActionNames::WeaponSecondary))
        // 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ChargeTime = 0.0;
		Player.ApplyCameraSettings(PolevaultComp.CamSettingCharge, 2, this, SubPriority = 54);
		Player.ApplySettings(PolevaultComp.MoveSettings, this);
		Player.BlockCapabilities(PlayerMovementTags::Sprint, this);
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 0.5);
		Player.ClearSettingsByInstigator(this);
		Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);
		PolevaultComp.StartLoc = Player.ActorLocation;
		PolevaultComp.MiddleLoc = MiddleLoc;
		PolevaultComp.EndLoc = EndLoc;
		PolevaultComp.bAnticipate = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ChargeTime += DeltaTime / 1.33;
		ChargeTime = Math::Clamp(ChargeTime, 0.0, 1.0);
		Spline = FHazeRuntimeSpline();

		EndLoc = Player.ActorLocation + Player.ActorForwardVector * (ChargeTime * MaxLength);
		MiddleLoc = Player.ActorLocation + Player.ActorForwardVector * (ChargeTime * (MaxLength * 0.66));
		MiddleLoc += FVector::UpVector * (MaxHeight * ChargeTime);
		MiddleLoc += FVector::UpVector * 150.0;
		Spline.AddPoint(Player.ActorLocation);
		Spline.AddPoint(MiddleLoc);
		Spline.AddPoint(EndLoc);
		
		PolevaultComp.DrawDebugSpline(Spline);
		Player.SetMovementFacingDirection(Player.ViewRotation.ForwardVector);
		
		// FHazePointOfInterest Poi;
		// Poi.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		// Poi.FocusTarget.WorldOffset = EndLoc;
		// Poi.Blend.BlendTime = 0.5;
		// Poi.Duration = 0.25;
		// Player.ApplyPointOfInterest(Poi, this);


		// if(MoveComp.PrepareMove(Movement))
		// {
		// 	if(HasControl())
		// 	{		

		// 		// Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Spline.GetDirectionAtDistance(DistAlongSpline) * Speed);
		// 		// Movement.SetRotation(Spline.GetDirectionAtDistance(DistAlongSpline).Rotation());
		// 		// Movement.OverrideStepDownAmountForThisFrame(0.0);
				
		// 	}

			
		// 	MoveComp.ApplyMove(Movement);
		// 	// Player.Mesh.RequestLocomotion(n"Grapple", this);
		// }

	}
};

