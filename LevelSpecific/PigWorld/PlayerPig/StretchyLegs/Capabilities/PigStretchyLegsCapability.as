struct FPigStretchyLegsCapabilityDeactivationParams
{
	bool bInterrupted = true;
}

class UPigStretchyLegsCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PigTags::SpecialAbility);
	default CapabilityTags.Add(n"Stretch");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default DebugCategory = PigTags::Pig;

	UPlayerPigStretchyLegsComponent StretchyLegsComponent;
	UPlayerMovementComponent MovementComponent;

	float OGCapsuleHalfHeight;
	float OGCameraVerticalOffset;

	bool bInterrupted;
	bool bTriggeredInterruptedFeedback;

	bool bMeshPhysicsDisabled;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StretchyLegsComponent = UPlayerPigStretchyLegsComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);

		OGCapsuleHalfHeight = Player.CapsuleComponent.CapsuleHalfHeight;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (!MovementComponent.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPigStretchyLegsCapabilityDeactivationParams& DeactivationParams) const
	{
		if (StretchyLegsComponent.bStretched && !IsActioning(ActionNames::PrimaryLevelAbility))
		{
			DeactivationParams.bInterrupted = false;
			return true;
		}

		if (ActiveDuration < Pig::StretchyLegs::StretchDuration)
			return false;

		if (bInterrupted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bTriggeredInterruptedFeedback = false;
		bMeshPhysicsDisabled = false;
		bInterrupted = false;
		StretchyLegsComponent.bStretching = true;
		StretchyLegsComponent.bEnterFailed = false;
		OGCameraVerticalOffset = UCameraSettings::GetSettings(Player).PivotOffset.Value.Z;

		float HeightUntilCeiling = HeightToCeiling(OGCapsuleHalfHeight) - OGCapsuleHalfHeight * 2.0;
		if (HeightUntilCeiling < Pig::StretchyLegs::MaxLength) 
		{
			bInterrupted = true;
			StretchyLegsComponent.bStretching = false;
			StretchyLegsComponent.bEnterFailed = true;
			StretchyLegsComponent.EnterFailHeight = HeightUntilCeiling + OGCapsuleHalfHeight;
			if(StretchyLegsComponent.ForceFeedback_Dizzy != nullptr)
				Player.PlayForceFeedback(StretchyLegsComponent.ForceFeedback_Dizzy, false, true, this);
		}
		else 
		{
			StretchyLegsComponent.OnPigStretched.Broadcast();
			UStretchyPigEffectEventHandler::Trigger_OnStretchStart(Owner);
			Player.ApplyCameraSettings(StretchyLegsComponent.StretchedCamSettings, 1.0, StretchyLegsComponent, EHazeCameraPriority::Medium, 1);

			Player.PlayForceFeedback(StretchyLegsComponent.StretchForceFeedback, false, true, this);
		}

		// block jump
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);

		// Swap mesh for springy pig
		StretchyLegsComponent.ApplySpringyMesh();

		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"Stretched", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FPigStretchyLegsCapabilityDeactivationParams DeactivationParams)
	{
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		float StretchFraction = Math::Saturate(ActiveDuration / Pig::StretchyLegs::StretchDuration);
		
		StretchyLegsComponent.bWasGrounded = MovementComponent.IsOnAnyGround();

		if (DeactivationParams.bInterrupted)
		{
			StretchyLegsComponent.ClearSpringyMesh();

			// Clear cam stuff if interrupted, otherwise clear in flip capability
			Player.ClearCameraSettingsByInstigator(StretchyLegsComponent, Pig::StretchyLegs::ClearBlendCameraSettingsDuration);
			UCameraSettings::GetSettings(Player).PivotOffset.Clear(StretchyLegsComponent, 0.0);

			UStretchyPigEffectEventHandler::Trigger_OnStretchInterrupted(Owner);
		}
		else
		{
			float HeightUntilCeiling = HeightToCeiling(OGCapsuleHalfHeight) - OGCapsuleHalfHeight;
			float VerticalOffset = GetStretchOffset(StretchFraction);
			if (HeightUntilCeiling < VerticalOffset)
				VerticalOffset = HeightUntilCeiling;

			// Disable mesh physics before teleporting, otherwise ears lose their literal shit
			UHazePhysicalAnimationComponent PhysicalAnimationComponent = UHazePhysicalAnimationComponent::Get(Owner);
			if (PhysicalAnimationComponent != nullptr)
			{
				PhysicalAnimationComponent.Disable(this, 0);
				bMeshPhysicsDisabled = true;
			}
		}

		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);

		Player.StopCameraShakeByInstigator(this, false);

		StretchyLegsComponent.bStretching = false;
		StretchyLegsComponent.bStretched = false;

		StretchyLegsComponent.bShouldFlip = !DeactivationParams.bInterrupted;
		if (Player.IsOnWalkableGround()) // might get swallowed by rolling hay bale ehh
			StretchyLegsComponent.bDizzy = DeactivationParams.bInterrupted;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			return;

		if (!bMeshPhysicsDisabled)
			return;

		// Reactivate mesh physics after mesh has been swapped back to normal by flip capability
		if (DeactiveDuration > 0.33)
		{
			UHazePhysicalAnimationComponent PhysicalAnimationComponent = UHazePhysicalAnimationComponent::Get(Owner);
			if (PhysicalAnimationComponent != nullptr)
			{
				UHazePhysicalAnimationComponent::Get(Owner).ClearDisable(this);
				bMeshPhysicsDisabled = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bInterrupted) // just wait for animation to finish before clearing mesh
		{
			HandleInterruptedFeedback();
			return; 
		} 

		// Stretch them legs
		if (StretchyLegsComponent.bStretching)
		{
			//Matches the animation duration
			float StretchAlpha = Math::Saturate(ActiveDuration / Pig::StretchyLegs::StretchDuration);

			//Matches how long it actually takes to reach the top in the animation (aka shorter than the full duration)
			float FullyStretchedAlpha = Math::Saturate(ActiveDuration/Pig::StretchyLegs::StretchFullyExtendedDuration);
			float Offset = GetStretchOffset(FullyStretchedAlpha) * 0.5;
			Player.CapsuleComponent.OverrideCapsuleHalfHeight(OGCapsuleHalfHeight + Offset, this, EInstigatePriority::High);

			// Update camera
			FVector CameraOffset = FVector::UpVector * FullyStretchedAlpha * ((Pig::StretchyLegs::MaxLength * Pig::StretchyLegs::CameraOffsetMultiplier));
			CameraOffset.Z += OGCameraVerticalOffset;
			UCameraSettings::GetSettings(Player).PivotOffset.Apply(CameraOffset, StretchyLegsComponent, Priority = EHazeCameraPriority::High);

			if (StretchAlpha >= 1.0)
			{
				StretchyLegsComponent.bStretching = false;
				StretchyLegsComponent.bStretched = true;

				Player.PlayCameraShake(StretchyLegsComponent.StretchedShake, this, 0.3);

				UStretchyPigEffectEventHandler::Trigger_OnFullyStretched(Owner);
			}
		}

		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"Stretched", this);
	}

	void HandleInterruptedFeedback() 
	{
		if (bTriggeredInterruptedFeedback)
			return;

		if (ActiveDuration > Pig::StretchyLegs::StretchDuration * 0.5) // arbitrary - trigger halfway in since we don't know animation progress
		{
			UStretchyPigEffectEventHandler::Trigger_OnDizzyStart(Owner);
			bTriggeredInterruptedFeedback = true;
		}
	}

	float GetStretchOffset(float StretchFraction) const
	{
		return Math::Pow(StretchFraction, 2.33) * Pig::StretchyLegs::MaxLength;
	}

	float HeightToCeiling(float CapsuleHalfHeight)
	{
		// Check if pig has any collisions above
		FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MovementComponent);
		Trace.UseCapsuleShape(MovementComponent.CollisionShape.Shape.CapsuleRadius, CapsuleHalfHeight);
		Trace.IgnorePlayers();
		Trace.SetTraceComplex(true);
		FVector Start = Player.ActorLocation + Trace.ShapeWorldOffset;
		FVector End = Player.ActorLocation + MovementComponent.WorldUp * (Pig::StretchyLegs::MaxLength + Trace.ShapeWorldOffset.Z); 
		FHitResult HitResult = Trace.QueryTraceSingle(Start, End);
		// DebugDrawTrace( Start + Trace.ShapeWorldOffset, End + Trace.ShapeWorldOffset, HitResult, CapsuleHalfHeight);

 		// Calculating distance manually because of shape offsets
		float DistanceToCeiling = HitResult.ImpactPoint.Z - Player.ActorLocation.Z;

		if (HitResult.bBlockingHit)
		{
			// Check if collision came from above
			if (HitResult.ImpactNormal.DotProduct(MovementComponent.WorldUp) < 0)
				return DistanceToCeiling;
		}
		return BIG_NUMBER;
	}

	void PlayForceFeedback()
	{
		// Tasty FF
		float Multiplier = Math::Saturate(MovementComponent.Velocity.Size() / UPigMovementSettings::GetSettings(Player).MoveSpeedMax);
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.1 * Multiplier;
		FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.1 * Multiplier;
		Player.SetFrameForceFeedback(FF);

		// Spread the joy
		float OtherPlayerIntensity = Math::Sin(ActiveDuration * 20) * 0.05 * Multiplier;
		ForceFeedback::PlayDirectionalWorldForceFeedbackForFrame(Player.ActorLocation, OtherPlayerIntensity, 180, 400, AffectedPlayers = EHazeSelectPlayer::Mio);
	}

	void DebugDrawTrace(FVector DrawLineStart, FVector DrawLineEnd, FHitResult HitResult, float CapsuleHalfHeight)
	{
		Debug::DrawDebugSphere(DrawLineStart, CapsuleHalfHeight, 12, FLinearColor::Green, 3, 5.0);
		Debug::DrawDebugSphere(DrawLineEnd, CapsuleHalfHeight, 12, FLinearColor::Green, 3, 5.0);
		Debug::DrawDebugLine(HitResult.ImpactPoint, HitResult.ImpactPoint + HitResult.ImpactNormal * 200.0, FLinearColor::Purple, 6, 5.0);
		Debug::DrawDebugLine(DrawLineStart, DrawLineEnd, FLinearColor::Yellow, 5, 7.0);
	}
}