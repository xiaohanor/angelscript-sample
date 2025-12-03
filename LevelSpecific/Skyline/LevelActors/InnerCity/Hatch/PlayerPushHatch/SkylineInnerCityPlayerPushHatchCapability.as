
// this whole capability is basically a hack so we don't stop swimming while doing Buttonmash / Stickspin :)

class USkylineInnerCityPlayerPushHatchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swimming);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 20;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerSwimmingComponent SwimmingComp;
	USkylineInnerCityPlayerPushHatchComponent PushHatchComp;

	bool bWasPushing = false;

	FVector Direction;

	FRotator OGRotation;
	FHazeAcceleratedFloat AccSpinDirection;
	FHazeAcceleratedFloat AccFakeSpinVelocity;
	FHazeAcceleratedRotator AccRotator;
	FHazeAcceleratedVector AccPushOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
		PushHatchComp = USkylineInnerCityPlayerPushHatchComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!SwimmingComp.IsSwimming())
			return false;

		if (!PushHatchComp.bActive)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!SwimmingComp.IsSwimming())
			return true;

		if (!PushHatchComp.bActive)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);

		Player.SmoothTeleportActor(GetHandleLocation(), Player.ActorRotation, this, 0.2);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this, EInstigatePriority::High);
		OGRotation = Player.ActorRotation;
		AccRotator.SnapTo(OGRotation);
	}

	FVector GetHandleLocation() const
	{
		return Player.IsZoe() ? PushHatchComp.Hatch.ZoeHatchLocation.WorldLocation : PushHatchComp.Hatch.MioHatchLocation.WorldLocation; 
	}

	FRotator GetHandleRotation() const
	{
		return Player.IsZoe() ? PushHatchComp.Hatch.ZoeHatchLocation.WorldRotation : PushHatchComp.Hatch.MioHatchLocation.WorldRotation; 
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector CustomUp = MoveComp.WorldUp;
		if (MoveComp.PrepareMove(Movement, CustomUp))
		{
			if(HasControl())
			{
				auto SpinState = Player.GetStickSpinState(PushHatchComp.Hatch);
				if (Math::Abs(SpinState.SpinVelocity) > Math::Abs(AccFakeSpinVelocity.Value))
					AccFakeSpinVelocity.SnapTo(SpinState.SpinVelocity);
				AccFakeSpinVelocity.AccelerateTo(0.0, 3.0, DeltaTime);

				float Treshold = 1.0;
				FLinearColor Colrings = FLinearColor::White;
				float SpinTarget = 0.0;
				if (AccFakeSpinVelocity.Value > Treshold)
				{
					SpinTarget = 1.0;
					Colrings = ColorDebug::Ruby;
				}
				if (AccFakeSpinVelocity.Value < -Treshold)
				{
					SpinTarget = -1.0;
					Colrings = ColorDebug::Leaf;
				}

				// Debug::DrawDebugString(Player.ActorCenterLocation, "" + AccFakeSpinVelocity.Value, Colrings);
				AccSpinDirection.AccelerateTo(SpinTarget, 1.0, DeltaTime);
				// FRotator NewRotation = OGRotation;
				// float AsAlpha = AccSpinDirection.Value * 0.5 + 0.5;
				// NewRotation.Roll += Math::Lerp(-45.0, 45.0, AsAlpha);

				FVector FacingPushDirection = -PushHatchComp.Hatch.ActorForwardVector;
				FacingPushDirection -= GetHandleRotation().ForwardVector * SpinTarget;
				FVector SlightlyOutwards = (GetHandleLocation() - PushHatchComp.Hatch.ActorLocation).GetSafeNormal();
				FacingPushDirection -= SlightlyOutwards * 0.7;

				// Debug::DrawDebugLine(GetHandleLocation(), GetHandleLocation()+ FacingPushDirection * 200.0, ColorDebug::Lavender, 1.0);
				// Debug::DrawDebugLine(Player.ActorCenterLocation,Player.ActorCenterLocation + CustomUp * 200.0, ColorDebug::Cyan);

				FVector Delta = GetHandleLocation() - Player.ActorCenterLocation;
				AccPushOffset.AccelerateTo(GetHandleRotation().ForwardVector * SpinTarget * 20.0, 1.0, DeltaTime);
				Delta += AccPushOffset.Value;
				Movement.AddDelta(Delta);

				AccRotator.AccelerateTo(FRotator::MakeFromZX(CustomUp, FacingPushDirection.GetSafeNormal()), 0.63, DeltaTime);
				Movement.SetRotation(AccRotator.Value);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"UnderwaterSwimming", this);
		}
	}
}