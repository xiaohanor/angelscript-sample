struct FBabyDragonTailClimbFreeFormCapabilityActivation
{
	UPrimitiveComponent Component;
	FVector RelativeAttachPoint;
	FVector RelativeImpactNormal;
	FVector AttachmentOffset;
	TOptional<UBabyDragonTailClimbFreeFormTargetableComponent> TargetableComp;
}

/** Settings */
namespace BabyDragonTailClimbSettings
{
	const float MaxWallDistance = 165;

	const float AutoAimMovementSpeed = 10.0;

	const FHazeRange LaunchForce = FHazeRange(100, 1500); /* FHazeRange(100, 1650) */

	const float LaunchForceWindUpTime = 0.4;

	// If we can re trigger by holding the input, this is the time in relation to 'LaunchForce' before the re trigger happens
	const FHazeRange LaunchForceAutomaticReTriggerTime = FHazeRange(1, 2);

	// How long time until we start read the stick input
	// This should match the enter animation
	const float ActivationDelay = 0.2;
	// const float ActivationDelay = 0.5;

	// How long until we can trigger again after deactivating
	const float ReTriggerDelay = 0.4;

	// How much the camera should look up
	const float CameraPoiPitchAlpha = 0;

	// How much the camera should follow the input
	const float CameraPoiFollowInputAlpha = 1;

	// If true, and in inverted mode, you can also jump using the jump button
	const bool bAllowJumpForceUsingJumpButton = true;

	const bool bAutoWindup = true;

	const FRotator MaxCameraInputRotation = FRotator(35, 50, 0);

	const FRotator CameraTargetOffsetRotation = FRotator(-0, 0, 0);

	const float CameraStayDurationAfterInput = 0.5;

	const float CameraNoInputRotateBackDuration = 5.0;

	const float CameraInputRotateDuration = 1.0;

	const bool bAlwaysLaunch = true;

	const float AlwaysLaunchMinPercent = 0.59;
}

class UBabyDragonTailClimbFreeFormCapability: UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);		
	
	default CapabilityTags.Add(BabyDragon::BabyDragon);
	default CapabilityTags.Add(n"TailClimb");
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);

	default BlockExclusionTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 2;

	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	UTeleportingMovementData Movement;
	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	UHazeCharacterSkeletalMeshComponent Mesh;
	UHazeCrumbSyncedVectorComponent WantedLaunchDirection;
	UPlayerTargetablesComponent TargetableComp;

	FVector RelativeAttachPoint;
	FVector RelativeImpactNormal;

	TOptional<UBabyDragonTailClimbFreeFormTargetableComponent> CurrentTargetable;
	FVector RemainingOffsetToTargetable;

	FHazeAcceleratedFloat ForceAmount;
	bool bHasFoundWall = false;
	float PrevInputSize = 0;
	bool bHasActivatedInternally = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		TargetableComp = UPlayerTargetablesComponent::Get(Player);
		WantedLaunchDirection = UHazeCrumbSyncedVectorComponent::GetOrCreate(Player, n"TailDragonLaunchInput");
		Movement = MoveComp.SetupTeleportingMovementData();
		Mesh = Player.Mesh;
		
		// Added 
		#if !RELEASE
		{
			FHazeDevInputInfo Info;

			Info.Name = n"Swap what way to charge the climb";
			Info.Category = n"Dragon";
			Info.OnTriggered.BindUFunction(this, n"DebugToggleJumpMode");
			Info.bTriggerLocalOnly = true;

			Info.AddKey(EKeys::Gamepad_FaceButton_Bottom);
			Info.AddKey(EKeys::Q);

			Player.RegisterDevInput(Info);
		}
		#endif
	}

	UFUNCTION()
	void DebugToggleJumpMode()
	{
	#if !RELEASE
		DragonComp.bInvertTailClimbLaunchForce = !DragonComp.bInvertTailClimbLaunchForce;
		if(DragonComp.bInvertTailClimbLaunchForce)
			PrintToScreen("Tail jump force set to; INVERTED", 2, FLinearColor::Red);
		else 
			PrintToScreen("Tail jump force set to; NORMAL", 2, FLinearColor::Red);
	#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBabyDragonTailClimbFreeFormCapabilityActivation& ActivationParams) const
	{
		// if(DragonComp.NextAutomaticReTriggerTime <= 0)
		// {
		// 	if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, BabyDragonTailClimbSettings::ReTriggerDelay + 0.1))
		// 		return false;

		// 	if(DeactiveDuration < BabyDragonTailClimbSettings::ReTriggerDelay)
		// 		return false;
		// }
		// else
		// {
		// 	if(!IsActioning(ActionNames::PrimaryLevelAbility))
		// 		return false;
		// }

		if(DeactiveDuration < BabyDragonTailClimbSettings::ReTriggerDelay)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, BabyDragonTailClimbSettings::ReTriggerDelay + 0.1)
		&& !IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		auto WallTrace = Trace::InitFromMovementComponent(MoveComp);
		FHazeTraceShape VerticalTraceShape = FHazeTraceShape::MakeLine();
		WallTrace.UseShape(VerticalTraceShape);
		WallTrace.UseShapeWorldOffset(FVector::ZeroVector);

		auto TempLog = TEMPORAL_LOG(Player, "Baby Dragon Climb");
		//WallTrace.DebugDraw(2);
		
		// Trace for a climb able wall
		FVector TraceDirection = Player.ControlRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		if(TraceDirection.IsNearlyZero())
			TraceDirection = MoveComp.MovementInput.GetSafeNormal();
		if(TraceDirection.IsNearlyZero())
			TraceDirection = Player.ActorForwardVector;
		
		const float ShapeRadius = Player.CapsuleComponent.GetScaledCapsuleRadius();
		const float ShapeHalfHeight = Player.CapsuleComponent.GetCapsuleHalfHeight();
		
		float TraceLength = ShapeRadius;
		TraceLength += BabyDragonTailClimbSettings::MaxWallDistance + DragonComp.ClimbBonusTrace;
	
		FVector UpVelocity = (FVector::UpVector * Math::Clamp(MoveComp.VerticalVelocity.DotProduct(FVector::UpVector), 0, 100));

		FVector TraceFrom = Player.ActorLocation;

		bool bTargetableIsValid = false;
		auto PrimaryTarget = TargetableComp.GetPrimaryTarget(UBabyDragonTailClimbFreeFormTargetableComponent);
		auto ClimbTargetable = Cast<UBabyDragonTailClimbFreeFormTargetableComponent>(PrimaryTarget);
		if(ClimbTargetable != nullptr)
		{
			FHazeTraceSettings TraceToTargetable;
			TraceToTargetable.TraceWithPlayerProfile(Player);
			TraceToTargetable.IgnorePlayers();
			FHazeTraceShape TargetableTraceShape = FHazeTraceShape::MakeLine();
			TraceToTargetable.UseShape(TargetableTraceShape);
			auto Hit = TraceToTargetable.QueryTraceSingle(Player.ActorLocation, ClimbTargetable.WorldLocation);
			TempLog.HitResults("Targetable Trace", Hit, TargetableTraceShape);

			if(!Hit.bBlockingHit
			|| Hit.Component.HasTag(n"TailDragonClimbable"))
			{
				TraceFrom = ClimbTargetable.WorldLocation + ClimbTargetable.ForwardVector * 10.0;
				bTargetableIsValid = true;
			}
		}
		if(!bTargetableIsValid)
		{
			TraceFrom += FVector::UpVector * ShapeHalfHeight;
			if(MoveComp.IsOnAnyGround())
				TraceFrom += FVector::UpVector * ShapeHalfHeight;
			else
				TraceFrom += UpVelocity * BabyDragonTailClimbSettings::ActivationDelay * 0.01;
		}
		
		FVector TraceOffset = FVector::UpVector * -ShapeRadius;
		
		auto UpImpact = WallTrace.QueryTraceSingle(TraceFrom + TraceOffset, TraceFrom + TraceOffset + (TraceDirection * TraceLength));
		TempLog.HitResults("Up Impact", UpImpact, VerticalTraceShape);
		if(!IsValidClimbable(UpImpact))
			return false;

		auto DownImpact = WallTrace.QueryTraceSingle(TraceFrom - TraceOffset, TraceFrom - TraceOffset + (TraceDirection * TraceLength));
		TempLog.HitResults("Down Impact", DownImpact, VerticalTraceShape);
		if(!IsValidClimbable(DownImpact))
			return false;
		
		// On the sides we use a sphere so we don't miss small stuff
		FHazeTraceShape HorizontalTraceShape = FHazeTraceShape::MakeSphere(ShapeRadius);
		WallTrace.UseShape(HorizontalTraceShape);
		
		TraceOffset = Player.ActorRightVector * ShapeRadius;
		auto RightImpact = WallTrace.QueryTraceSingle(TraceFrom + TraceOffset, TraceFrom + TraceOffset + (TraceDirection * TraceLength));
		TempLog.HitResults("Right Impact", RightImpact, HorizontalTraceShape);
		bool bRightIsValid = IsValidClimbable(RightImpact);
		
		TraceOffset = -Player.ActorRightVector * ShapeRadius;
		auto LeftImpact = WallTrace.QueryTraceSingle(TraceFrom + TraceOffset, TraceFrom + TraceOffset + (TraceDirection * TraceLength));
		TempLog.HitResults("Left Impact", LeftImpact, HorizontalTraceShape);
		bool bLeftIsValid = IsValidClimbable(LeftImpact);

		FVector ImpactLocation = UpImpact.ImpactPoint;
		if(bRightIsValid && bLeftIsValid)
		{
			FVector Offset = FVector::ZeroVector;
			Offset += (RightImpact.ImpactPoint - UpImpact.ImpactPoint);
			Offset += (LeftImpact.ImpactPoint - UpImpact.ImpactPoint);
			Offset /= 2;
			ImpactLocation += Offset;
		}
		else if(bRightIsValid)
		{
			ImpactLocation += Player.ActorRightVector * ShapeRadius;
		}
		else if(bLeftIsValid)
		{
			ImpactLocation += -Player.ActorRightVector * ShapeRadius;
		}

		
		if(ClimbTargetable != nullptr)
		{
			ActivationParams.TargetableComp.Set(ClimbTargetable);
			FVector DeltaToTargetable = ClimbTargetable.WorldLocation - ImpactLocation;
			ImpactLocation += DeltaToTargetable.ConstrainToPlane(UpImpact.ImpactNormal);
		}

		TempLog.Sphere("Impact Location", ImpactLocation, 10, FLinearColor::Red, 2);

		ApplyImpactToActivation(UpImpact, ImpactLocation, ActivationParams);
		return true;
	}

	bool IsValidClimbable(FHitResult Impact) const
	{
		if(!Impact.IsValidBlockingHit())
			return false;

		if(!Impact.Component.HasTag(ComponentTags::TailDragonClimbable))
			return false;

		return true;
	}

	void ApplyImpactToActivation(FHitResult Impact, FVector ImpactLocation, FBabyDragonTailClimbFreeFormCapabilityActivation& ActivationParams) const
	{
		ActivationParams.Component = Impact.Component;
		ActivationParams.RelativeAttachPoint = Impact.Component.WorldTransform.InverseTransformPosition(ImpactLocation);
		ActivationParams.RelativeImpactNormal = Impact.Component.WorldTransform.InverseTransformVectorNoScale(Impact.ImpactNormal);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(DragonComp.AttachmentComponent == nullptr)
			return true;

		if(WasActionStartedDuringTime(ActionNames::Cancel, BabyDragonTailClimbSettings::ActivationDelay))
			return true;

		
		// if(ActiveDuration > BabyDragonTailClimbSettings::ActivationDelay && bHasActivatedInternally)
		// {
		// 	if(!bHasFoundWall)
		// 		return true;

		// 	if(DragonComp.bTriggerLaunchForce)
		// 		return true;

		// 	// If we release the input and have no jump force,
		// 	// we fall of
		// 	// Else, we launch, even if we didn't flip the stick
		// 	if(DragonComp.bInvertTailClimbLaunchForce 
		// 	&& !IsActioning(ActionNames::PrimaryLevelAbility) 
		// 	&& ForceAmount.Value <= KINDA_SMALL_NUMBER)
		// 		return true;
		// }

		if(ActiveDuration > BabyDragonTailClimbSettings::ActivationDelay && bHasActivatedInternally)
		{
			if(!bHasFoundWall)
				return true;

			if(DragonComp.bTriggerLaunchForce)
				return true;

			if(WasActionStartedDuringTime(ActionNames::Cancel, BabyDragonTailClimbSettings::ActivationDelay))
				return true;
			
			// If we release the input and have no jump force,
			// we fall of
			// Else, we launch, even if we didn't flip the stick
			if(DragonComp.bInvertTailClimbLaunchForce 
			&& !IsActioning(ActionNames::PrimaryLevelAbility) 
			&& ForceAmount.Value <= KINDA_SMALL_NUMBER)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBabyDragonTailClimbFreeFormCapabilityActivation ActivationParams)
	{	
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, n"TailClimb", this);
		Player.BlockCapabilities(n"ContextualMoves", this);

		Player.PlayForceFeedback(DragonComp.ClimbAttachRumble, false, false, this);

		Player.ApplyCameraSettings(DragonComp.ClimbCameraSettings, 0, this, SubPriority = 60);
		Player.ApplyBlendToCurrentView(1);

		DragonComp.AttachmentComponent = ActivationParams.Component;
		RelativeAttachPoint = ActivationParams.RelativeAttachPoint;
		RelativeImpactNormal = ActivationParams.RelativeImpactNormal;
		DragonComp.ClimbLaunchForce = FVector::ZeroVector;
		DragonComp.AttachNormal = ActivationParams.Component.WorldTransform.TransformVectorNoScale(ActivationParams.RelativeImpactNormal);

		FVector WorldAttachLocation = ActivationParams.Component.WorldTransform.TransformPosition(ActivationParams.RelativeAttachPoint);

		auto ResponseComp = UBabyDragonTailClimbFreeFormResponseComponent::Get(ActivationParams.Component.Owner);
		if(ResponseComp != nullptr)
		{
			if(!ResponseComp.bIsPrimitiveParentExclusive
			|| ResponseComp.AttachmentWasOnParent(ActivationParams.Component))
			{
				FBabyDragonTailClimbFreeFormAttachParams Params;
				Params.AttachComponent = ActivationParams.Component;
				Params.WorldAttachLocation = WorldAttachLocation;
				Params.AttachNormal = ActivationParams.Component.WorldTransform.TransformVectorNoScale(ActivationParams.RelativeImpactNormal);
				ResponseComp.OnTailAttached.Broadcast(Params);
			}
		}

		bHasActivatedInternally = false;
		DragonComp.bClimbReachedPoint = true;
		DragonComp.bTriggerLaunchForce = false;

		FBabyDragonTailClimbFreeFormOnTailAttachedParams AttachParams;
		AttachParams.TailAttachLocation = DragonComp.BabyDragon.Mesh.GetSocketLocation(n"Tail10");
		UBabyDragonTailClimbFreeFormEventHandler::Trigger_OnTailAttached(Player, AttachParams);
		UBabyDragonTailClimbFreeFormEventHandler::Trigger_OnTailAttached(DragonComp.BabyDragon, AttachParams);
		
		DragonComp.ApplyClimbState(ETailBabyDragonClimbState::Enter, this, EInstigatePriority::Normal);
		MoveComp.VerticalAttachmentOffset.Apply(Player.CapsuleComponent.ScaledCapsuleHalfHeight * 1.25, this);
		MoveComp.FollowComponentMovement(DragonComp.AttachmentComponent, this, EMovementFollowComponentType::Teleport);
		MoveComp.ApplyCustomMovementStatus(n"WallClimb", this);

		CurrentTargetable = ActivationParams.TargetableComp;

		if(BabyDragonTailClimbSettings::bAlwaysLaunch)
			ForceAmount.SnapTo(BabyDragonTailClimbSettings::AlwaysLaunchMinPercent);
		else
			ForceAmount.SnapTo(0);

		Player.ResetAirDashUsage();
		Player.ResetAirJumpUsage();

		DragonComp.bUseClimbingCamera = true;
		auto CameraToggleComp = UBabyDragonTailClimbFreeFormCameraToggleComponent::Get(DragonComp.AttachmentComponent.Owner);
		if(CameraToggleComp != nullptr
		&& !CameraToggleComp.bToggleOn) 
			DragonComp.bUseClimbingCamera = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!DragonComp.bInvertTailClimbLaunchForce)
			Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);

		Player.StopForceFeedback(this);

		DragonComp.ClearClimbStateInstigator(this);
		MoveComp.ClearCustomMovementStatus(this);

		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(n"ContextualMoves", this);

		auto ResponseComp = UBabyDragonTailClimbFreeFormResponseComponent::Get(DragonComp.AttachmentComponent.Owner);
		if(ResponseComp != nullptr)
		{
			if(!ResponseComp.bIsPrimitiveParentExclusive
			|| ResponseComp.AttachmentWasOnParent(DragonComp.AttachmentComponent))
			{
				FBabyDragonTailClimbFreeFormReleasedParams Params;
				Params.AttachComponent = DragonComp.AttachmentComponent;
				Params.WorldAttachLocation = DragonComp.AttachmentComponent.WorldTransform.TransformPosition(RelativeAttachPoint);
				Params.AttachNormal = DragonComp.AttachmentComponent.WorldTransform.TransformVectorNoScale(RelativeImpactNormal);
				ResponseComp.OnTailReleased.Broadcast(Params);
			}
		}

		DragonComp.bClimbReachedPoint = false;

		if(BabyDragonTailClimbSettings::bAlwaysLaunch
		&& !IsActioning(ActionNames::PrimaryLevelAbility))
			DragonComp.bTriggerLaunchForce = true;

		MoveComp.UnFollowComponentMovement(this);
		MoveComp.VerticalAttachmentOffset.Clear(this);
		Player.ClearCameraSettingsByInstigator(this, 0.75);
		Player.ApplyBlendToCurrentView(1);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);

		if (DragonComp.BabyDragon != nullptr)
		{
			FBabyDragonTailClimbFreeFormOnTailReleasedParams ReleasedParams;
			ReleasedParams.TailReleaseLocation = DragonComp.BabyDragon.Mesh.GetSocketLocation(n"Tail10");
			UBabyDragonTailClimbFreeFormEventHandler::Trigger_OnTailReleased(Player, ReleasedParams);
			UBabyDragonTailClimbFreeFormEventHandler::Trigger_OnTailReleased(DragonComp.BabyDragon, ReleasedParams);
		}


		bHasFoundWall = false;
		PrevInputSize = 0;

		const bool bWasCanceled = WasActionStartedDuringTime(ActionNames::Cancel, BabyDragonTailClimbSettings::ActivationDelay);
		if(bWasCanceled)
			DragonComp.PreviousClimbLaunchForce = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(MoveComp.IsOnWalkableGround())
			DragonComp.bUseClimbingCamera = false;

		TEMPORAL_LOG(Player, "Baby Dragon Climb")
			.Value("Has Found Wall", bHasFoundWall)
			.Value("Has Activated Internally", bHasActivatedInternally)
			.Value("Trigger Launch Force", DragonComp.bTriggerLaunchForce)
			.DirectionalArrow("Launch Force", Player.ActorLocation, DragonComp.ClimbLaunchForce, 20, 100, FLinearColor::Red)
		;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateMovement(DeltaTime);

		if(bHasFoundWall)
		{
			if(ActiveDuration > BabyDragonTailClimbSettings::ActivationDelay * 0.5 && DragonComp.ClimbState == ETailBabyDragonClimbState::Enter)
				DragonComp.ApplyClimbState(ETailBabyDragonClimbState::Hang, this, EInstigatePriority::Normal);
			
			if(HasControl())
			{
				UpdateControlInput(DeltaTime);
			}
			else
			{
				UpdateRemoteInput(DeltaTime);
			}
		}

		if(Mesh.CanRequestLocomotion())
		{
			Mesh.RequestLocomotion(n"BackpackDragonClimbing", this);
			DragonComp.RequestBabyDragonLocomotion(n"BackpackDragonClimbing");
		}
	}

	void UpdateControlInput(float DeltaTime)
	{
		if(!bHasActivatedInternally 
		&& ActiveDuration > BabyDragonTailClimbSettings::ActivationDelay)
		{
			bHasActivatedInternally = true;
		}

		FVector ImpactNormal = DragonComp.AttachmentComponent.WorldTransform.TransformVectorNoScale(RelativeImpactNormal);

		if(ActiveDuration > BabyDragonTailClimbSettings::ActivationDelay && bHasFoundWall)
		{
			FVector TargetFacingDirection = -ImpactNormal;
			FQuat TargetRotation = FQuat::MakeFromX(TargetFacingDirection);

			float InputSize = 0;

			// Update launch
			if(BabyDragonTailClimbSettings::bAutoWindup)
			{
				FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
				InputSize = 1;
				float RightAmount = Math::EaseOut(0, 0.3, Math::Abs(RawInput.X), 2) * Math::Sign(RawInput.X);

				RightAmount = -RightAmount;
				
				const float UpAmount = -Math::Lerp(0, 1, 1 - Math::Pow(Math::Abs(RightAmount), 2));
				WantedLaunchDirection.Value = TargetRotation.RotateVector(FVector(0, RightAmount, UpAmount).GetSafeNormal());
			}
			else
			{
				FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
				InputSize = RawInput.Size();
				const float UpAmount = Math::EaseOut(Math::Abs(RawInput.X) * 0.3, 1, Math::Abs(RawInput.Y), 3) * Math::Sign(RawInput.Y);
				const float RightAmount = Math::EaseOut(0, 0.3, Math::Abs(RawInput.X), 2) * Math::Sign(RawInput.X);
				WantedLaunchDirection.Value = TargetRotation.RotateVector(FVector(0, RightAmount, UpAmount).GetSafeNormal());
			}

			if(InputSize > PrevInputSize * 0.66 || BabyDragonTailClimbSettings::bAutoWindup)
			{
				PrevInputSize = InputSize;

				UpdateLaunchDirection(DeltaTime, InputSize, WantedLaunchDirection.Value);
	
				// DEBUG
				//Debug::DrawDebugDirectionArrow(Player.ActorCenterLocation, DragonComp.ClimbLaunchForce, DragonComp.ClimbLaunchForce.Size() * 0.1, LineColor = FLinearColor::Red);
			}
			else if(PrevInputSize > 0.3)
			{
				DragonComp.bTriggerLaunchForce = true;
			}
			
			// If we release the hold wall, but we have input force,
			// we jump instead
			if(DragonComp.bInvertTailClimbLaunchForce 
				&& !IsActioning(ActionNames::PrimaryLevelAbility)
				&& (ForceAmount.Value > KINDA_SMALL_NUMBER || BabyDragonTailClimbSettings::bAlwaysLaunch) )
			{
				DragonComp.bTriggerLaunchForce = true;
			}

			if(DragonComp.bInvertTailClimbLaunchForce
			&& BabyDragonTailClimbSettings::bAllowJumpForceUsingJumpButton
			&& WasActionStarted(ActionNames::MovementJump))
			{	
				FVector FinalLaunchDirection = WantedLaunchDirection.Value;
				if(FinalLaunchDirection.IsNearlyZero())
					FinalLaunchDirection = FVector::UpVector;
				else
					FinalLaunchDirection = -FinalLaunchDirection;

				ForceAmount.SnapTo(1);
				DragonComp.ClimbLaunchForce = FinalLaunchDirection * BabyDragonTailClimbSettings::LaunchForce.Lerp(ForceAmount.Value);
				DragonComp.bTriggerLaunchForce = true;
			}
		}
	}

	void UpdateRemoteInput(float DeltaTime)
	{
		if(ActiveDuration > BabyDragonTailClimbSettings::ActivationDelay && bHasFoundWall)
		{
			FVector LaunchDirection = WantedLaunchDirection.Value;
			UpdateLaunchDirection(DeltaTime, LaunchDirection.Size(), LaunchDirection);
		}
	}

	void UpdateLaunchDirection(float DeltaTime, float InputSize, FVector Direction)
	{
		if(BabyDragonTailClimbSettings::bAlwaysLaunch)
		{	
			FVector LaunchDirection = Direction;
			if(Direction.IsNearlyZero())
				LaunchDirection = FVector::UpVector;
			ForceAmount.AccelerateTo(InputSize, BabyDragonTailClimbSettings::LaunchForceWindUpTime, DeltaTime);
			DragonComp.ClimbLaunchForce = -LaunchDirection * BabyDragonTailClimbSettings::LaunchForce.Lerp(ForceAmount.Value);
		}
		// You have to pull the stick down to launch up
		if(DragonComp.bInvertTailClimbLaunchForce)
		{
			if(!Direction.IsNearlyZero() && Direction.DotProduct(FVector::UpVector) < 0)
			{
				ForceAmount.AccelerateTo(InputSize, BabyDragonTailClimbSettings::LaunchForceWindUpTime, DeltaTime);
				DragonComp.ClimbLaunchForce = -Direction * BabyDragonTailClimbSettings::LaunchForce.Lerp(ForceAmount.Value);
			}
			else
			{
				ForceAmount.SnapTo(0);
				DragonComp.ClimbLaunchForce = FVector::ZeroVector;
			}
		}
		// You have to pull the stick up to launch up
		else
		{
			if(!Direction.IsNearlyZero() && Direction.DotProduct(FVector::UpVector) > 0)
			{
				ForceAmount.AccelerateTo(InputSize, BabyDragonTailClimbSettings::LaunchForceWindUpTime, DeltaTime);
				DragonComp.ClimbLaunchForce = Direction * BabyDragonTailClimbSettings::LaunchForce.Lerp(ForceAmount.Value);
			}
			else
			{
				ForceAmount.SnapTo(0);
				DragonComp.ClimbLaunchForce = FVector::ZeroVector;
			}
		}
	}


	void UpdateMovement(float DeltaTime)
	{
		if(HasControl())
		{
			if(MoveComp.PrepareMove(Movement))
			{
				if(!bHasFoundWall)
				{	
					FVector ImpactNormal = DragonComp.AttachmentComponent.WorldTransform.TransformVectorNoScale(RelativeImpactNormal);
					
					FVector	AttachPoint = DragonComp.AttachmentComponent.WorldTransform.TransformPosition(RelativeAttachPoint);
					FVector TargetPoint = AttachPoint + ImpactNormal * Player.CapsuleComponent.CapsuleRadius;

					TEMPORAL_LOG(Player, "Baby Dragon Climb")
						.Sphere("Attach Point", AttachPoint, 20, FLinearColor::Blue, 2)
					;

					DragonComp.bClimbReachedPoint = true;
					DragonComp.ApplyClimbState(ETailBabyDragonClimbState::Enter, this, EInstigatePriority::Normal);

					FVector InterpedLocation = Math::VInterpConstantTo(Player.ActorCenterLocation, TargetPoint, DeltaTime, 1000);
					Movement.AddDeltaWithCustomVelocity(InterpedLocation - Player.ActorCenterLocation, FVector::ZeroVector);

					FVector TargetFacingDirection = -ImpactNormal;
					FQuat TargetRotation = FQuat::MakeFromX(TargetFacingDirection);
					Movement.SetRotation(TargetRotation);

					MoveComp.ApplyMove(Movement);

					if(Player.ActorCenterLocation.Equals(TargetPoint, 5))
					{
						CrumbTriggerWallImpact();
					}
				}
				else
				{
					if(!RemainingOffsetToTargetable.IsNearlyZero())
					{
						FVector DeltaTowardsTargetable = RemainingOffsetToTargetable;
						RemainingOffsetToTargetable = Math::VInterpTo(RemainingOffsetToTargetable, FVector::ZeroVector, DeltaTime, BabyDragonTailClimbSettings::AutoAimMovementSpeed);
						DeltaTowardsTargetable = RemainingOffsetToTargetable - DeltaTowardsTargetable;
						Movement.AddDelta(DeltaTowardsTargetable);
						TEMPORAL_LOG(Player, "Baby Dragon Climb")
							.DirectionalArrow("Initial Offset to Targetable", Player.ActorLocation, RemainingOffsetToTargetable, 10, 40, FLinearColor::Red)
						;
					}
					MoveComp.ApplyMove(Movement);
				}
			}
		}

		// Remote
		else
		{
			if(MoveComp.PrepareMove(Movement))
			{
				Movement.ApplyCrumbSyncedAirMovement();
				MoveComp.ApplyMove(Movement);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerWallImpact()
	{
		bHasFoundWall = true;

		if(CurrentTargetable.IsSet())
		{
			auto Targetable = CurrentTargetable.Value;
			RemainingOffsetToTargetable = Player.ActorCenterLocation - Targetable.WorldLocation;
			FVector ImpactNormal = DragonComp.AttachmentComponent.WorldTransform.TransformVectorNoScale(RelativeImpactNormal);
			RemainingOffsetToTargetable = RemainingOffsetToTargetable.ConstrainToPlane(ImpactNormal);
		}
		else
			RemainingOffsetToTargetable = FVector::ZeroVector;
	}
};