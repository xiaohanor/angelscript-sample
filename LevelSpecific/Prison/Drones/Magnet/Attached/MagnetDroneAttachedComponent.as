/**
 * Data passed through in the Attachment event
 */
struct FMagnetDroneAttachmentParams
{
	UPROPERTY()
	FMagnetDroneAttractionStartedParams AttractionStartedParams;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector Normal;

	UPROPERTY()
	USceneComponent AttachToComponent;
};

struct FMagnetDroneMoveToNewSurfaceData
{
	UPrimitiveComponent Component;

	FVector Location;
	FVector Normal;
	
	FVector ImpactPoint;
	FVector ImpactNormal;

	FMagnetDroneMoveToNewSurfaceData(FMovementHitResult InNewSurfaceHit)
	{
		Component = InNewSurfaceHit.Component;

		Location = InNewSurfaceHit.Location;
		Normal = InNewSurfaceHit.Normal;

		ImpactPoint = InNewSurfaceHit.ImpactPoint;
		ImpactNormal = InNewSurfaceHit.ImpactNormal;
	}
};

namespace MagnetDroneTags
{
	const FName BlockedWhileAttached = n"BlockedWhileAttached";
	const FName BlockedWhileAttachedSurface = n"BlockedWhileAttachedSurface";
	const FName BlockedWhileAttachedSocket = n"BlockedWhileAttachedSocket";
}

UCLASS(Abstract)
class UMagnetDroneAttachedComponent : UActorComponent
{
	access AttachTo = private, UMagnetDroneAttractionModesCapability, UMagnetDroneAttachToSurfaceCapability, UMagnetDroneAttachToSocketCapability, UMagnetDroneAttachToSurfaceFromChainJumpCapability, UPinballMagnetAttractionModesCapability;

	UPROPERTY(EditDefaultsOnly)
	private UMagnetDroneAttachedSettings DefaultSettings;

	private AHazePlayerCharacter Player;
	private UMagnetDroneComponent DroneComp;
	private UPlayerMovementComponent MoveComp;

	UMagnetDroneAttachedSettings Settings;

	FMagnetDroneAttachedData AttachedData;
	FInstigator AttachedInstigator;

	FMagnetDroneAttachedData PreviousAttachment;
	private uint DetachedFrame = 0;
	private float DetachTime = -1;
	private uint ForceDetachedFromSocketWithJumpFrame = 0;
	private FVector ForceDetachedFromSocketWithJumpDirection;
	private float ForceDetachedFromSocketWithJumpImpulseMultiplier = 1.0;
	private bool bForceDetachedFromSocketIgnoreOverlappingComponents = false;

	UCameraShakeBase ShakeInstance_Attached;
	UCameraShakeBase ShakeInstance_Detached;

	uint LastInputFrame = 0;
	FVector PreviousForward;
	FVector2D PreviousMoveInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DroneComp = UMagnetDroneComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		Player.ApplyDefaultSettings(DefaultSettings);
		Settings = UMagnetDroneAttachedSettings::GetSettings(Player);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneAttachedComponent");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		AttachedData.LogToTemporalLog(TemporalLog, "Attached Data");

		if(AttachedData.IsValid())
		{
			FString CalculatedWorldUpDebugString;
			FVector CalculatedWorldUp = CalculateWorldUp(CalculatedWorldUpDebugString);
			TemporalLog.DirectionalArrow("Calculated World Up", Player.ActorLocation, CalculatedWorldUp * 200);
			TemporalLog.Value("Calculated World Up Reason", CalculatedWorldUpDebugString);
		}
#endif
	}

	/*
	 *	Attach to the TargetData. Will invalidate the parameter TargetData.
	 */
	access:AttachTo
	void AttachToSurface(FMagnetDroneTargetData& InTargetData, FMagnetDroneAttractionStartedParams AttractionStartedParams, FInstigator Instigator)
	{
		check(InTargetData.IsValidTarget());
		check(InTargetData.IsSurface());

		// Create the initial attachment data, to be used while magnetically attached
		AttachedData = FMagnetDroneAttachedData(MoveComp, this, InTargetData);
		AttachedInstigator = Instigator;

		{
			FOnMagnetDroneAttachedParams AttachParams;
			AttachParams.Player = Player;
			AttachParams.Location = InTargetData.GetTargetLocation();
			AttachParams.Normal = InTargetData.GetTargetImpactNormal();
			AttachedData.GetSurfaceComp().OnMagnetDroneAttached.Broadcast(AttachParams);
		}

		// Invalidate the old TargetData, since we are no longer attracting towards it
		InTargetData.Invalidate(n"InTargetData AttachToSurface", Instigator);

		Player.StopAllCameraShakes(false);

		if(Settings.ShakeClass_Attached != nullptr)
		{
			ShakeInstance_Attached = Player.PlayCameraShake( Settings.ShakeClass_Attached.Get(), this);
		}

		{
			FMagnetDroneAttachmentParams AttachmentParams;
			AttachmentParams.AttractionStartedParams = AttractionStartedParams;
			AttachmentParams.Location = AttachedData.GetInitialTargetLocation();
			AttachmentParams.Normal = AttachedData.GetInitialTargetImpactNormal();
			AttachmentParams.AttachToComponent = AttachedData.GetAttachComp();

			UMagnetDroneEventHandler::Trigger_Attached(Player, AttachmentParams);
		}

		// Don't allow auto following while attached
		UMovementStandardSettings::SetAutoFollowGround(Player, EMovementAutoFollowGroundType::Never, this);

		if(!AttachedData.ShouldImmediatelyDetach())
			MoveComp.FollowComponentMovement(AttachedData.GetAttachComp(), this, EMovementFollowComponentType::ResolveCollision, EInstigatePriority::High);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Attach To Surface: {AttachedData.GetAttachComp().Owner}");
#endif

		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileAttached, this);
		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileAttachedSurface, this);
	}

	access:AttachTo
	void AttachToSocket(FMagnetDroneTargetData& InTargetData, FMagnetDroneAttractionStartedParams AttractionStartedParams, FInstigator Instigator)
	{
		check(InTargetData.IsValidTarget());
		check(InTargetData.IsSocket());

		// Create the initial attachment data, to be used while magnetically attached
		AttachedData = FMagnetDroneAttachedData(MoveComp, this, InTargetData);
		AttachedInstigator = Instigator;

		{
			FOnMagnetDroneAttachedParams AttachParams;
			AttachParams.Player = Player;
			AttachParams.Location = InTargetData.GetTargetLocation();
			AttachParams.Normal = InTargetData.GetTargetImpactNormal();
			AttachedData.GetSocketComp().OnMagnetDroneAttached.Broadcast(AttachParams);

		}
		// Invalidate the old TargetData, since we are no longer attracting towards it
		InTargetData.Invalidate(n"InTargetData AttachToSocket", Instigator);

		Player.ClearCameraSettingsByInstigator(this, 0.5);
		Player.StopAllCameraShakes(false);

		if(Settings.ShakeClass_Attached != nullptr)
		{
			ShakeInstance_Attached = Player.PlayCameraShake( Settings.ShakeClass_Attached.Get(), this);
		}

		{
			FMagnetDroneAttachmentParams AttachmentParams;
			AttachmentParams.AttractionStartedParams = AttractionStartedParams;
			AttachmentParams.Location = AttachedData.GetInitialTargetLocation();
			AttachmentParams.Normal = AttachedData.GetInitialTargetImpactNormal();
			AttachmentParams.AttachToComponent = AttachedData.GetAttachComp();
			
			UMagnetDroneEventHandler::Trigger_Attached(Player, AttachmentParams);
		}
		
		// Don't allow auto following while attached
		UMovementStandardSettings::SetAutoFollowGround(Player, EMovementAutoFollowGroundType::Never, this);

		if(!AttachedData.ShouldImmediatelyDetach())
			MoveComp.FollowComponentMovement(AttachedData.GetAttachComp(), this, EMovementFollowComponentType::ResolveCollision);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Attach To Socket: {AttachedData.GetAttachComp().Owner}");
#endif

		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileAttached, this);
		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileAttachedSocket, this);
	}

	/*
	 *	Attach to a new magnetic surface component. AttachedData must be valid before calling.
	 *  OnPlayerDetached will be broadcast on the previous attachment.
	 */
	void MoveToNewMagneticSurface(FMovementHitResult InGroundImpact, bool bCrumb)
	{
		check(HasControl());

		// FB TODO: Probably want to split this up for Pinball?
		if(bCrumb)
			CrumbMoveToNewMagneticSurface(FMagnetDroneMoveToNewSurfaceData(InGroundImpact));
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMoveToNewMagneticSurface(FMagnetDroneMoveToNewSurfaceData InMoveToNewSurfaceData)
	{
		check(AttachedData.CanAttach());

		auto NewAttachedData = FMagnetDroneAttachedData(InMoveToNewSurfaceData);
		check(NewAttachedData.IsValid());
		check(NewAttachedData.IsSurface());

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Move To New Magnetic Surface: (From: {AttachedData.GetAttachComp()}) (To: {NewAttachedData.GetAttachComp()})");
#endif

		bool bHasSameSurfaceComp = AttachedData.GetSurfaceComp() == NewAttachedData.GetSurfaceComp();

		// Only broadcast events if it is actually a new surface component
		if(!bHasSameSurfaceComp)
		{
			FOnMagnetDroneDetachedParams DetachParams;
			DetachParams.Player = Player;
			AttachedData.GetSurfaceComp().OnMagnetDroneDetached.Broadcast(DetachParams);

#if !RELEASE
			TemporalLog.Event(f"Move To New Magnetic Surface: Broadcast Detach to {AttachedData.GetSurfaceComp().Owner}");
#endif

			FOnMagnetDroneAttachedParams AttachParams;
			AttachParams.Player = Player;
			AttachParams.Location = InMoveToNewSurfaceData.Location;
			AttachParams.Normal = InMoveToNewSurfaceData.Normal;
			NewAttachedData.GetSurfaceComp().OnMagnetDroneAttached.Broadcast(AttachParams);

#if !RELEASE
			TemporalLog.Event(f"Move To New Magnetic Surface: Broadcast Attach to {NewAttachedData.GetSurfaceComp().Owner}");
#endif
		}

		// Replace our current attached data
		AttachedData = NewAttachedData;

		MoveComp.UnFollowComponentMovement(this);

		if(!AttachedData.ShouldImmediatelyDetach())
			MoveComp.FollowComponentMovement(AttachedData.GetAttachComp(), this, EMovementFollowComponentType::ResolveCollision);
	}

	void UpdateNewGroundContact(bool bCrumb)
	{
		check(HasControl());

		// If we are currently attached, and we have a new ground contact
		if(AttachedData.CanAttach() && MoveComp.GetGroundContact().Component != AttachedData.GetAttachComp())
		{
			if(MagnetDrone::IsImpactMagnetic(MoveComp.GroundContact, false))
			{
				// If our new ground contact is a new magnetic surface, attach to it instead.
				MoveToNewMagneticSurface(MoveComp.GetGroundContact(), bCrumb);
			}
			else
			{
				// If it's not magnetic, detach
				Detach(n"UpdateAutoDetach_NewGroundNotMagnetic");	
			}
		}
	}

	void Detach(FName DetachTag)
	{
		if(!AttachedData.IsValid())
			return;

		PreviousAttachment = AttachedData;
		
		AttachedData.bIsDetaching = true;

		FOnMagnetDroneDetachedParams DetachParams;
		DetachParams.Player = Player;

		if(AttachedData.IsSocket())
		{
			const UDroneMagneticSocketComponent SocketComp = AttachedData.GetSocketComp();
			SocketComp.OnMagnetDroneDetached.Broadcast(DetachParams);

			if(SocketComp.bJumpOnDetach)
			{
				ForceDetachedFromSocketWithJumpFrame = Time::FrameNumber;
				ForceDetachedFromSocketWithJumpDirection = AttachedData.GetSocketNormal();
				ForceDetachedFromSocketWithJumpImpulseMultiplier = SocketComp.JumpOnDetachImpulseMultiplier;
				bForceDetachedFromSocketIgnoreOverlappingComponents = SocketComp.bIgnoreOverlappingComponentsOnDetach;
			}

			Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileAttachedSocket, this);

			// When jumping out of a socket, we may want to ignore collision that we ignored while in the socket
			auto AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
			if(AttractionComp != nullptr)
			{
				TArray<AActor> ActorsToIgnoreWhileAttracting;
				ActorsToIgnoreWhileAttracting.Add(SocketComp.Owner);
				ActorsToIgnoreWhileAttracting.Append(SocketComp.IgnoredActors);
				AttractionComp.IgnoreActorsWhileAttracting(ActorsToIgnoreWhileAttracting, this);
			}
		}
		else if(AttachedData.IsSurface())
		{
			const UDroneMagneticSurfaceComponent SurfaceComp = AttachedData.GetSurfaceComp();
			SurfaceComp.OnMagnetDroneDetached.Broadcast(DetachParams);

			Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileAttachedSurface, this);
		}

		Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileAttached, this);
		
		// Prevent the current AttachedData from being used, now that we have detached
		AttachedData.Invalidate(n"AttachedData Detach", DetachTag);
		AttachedInstigator = nullptr;

		// Make sure that the TargetData is invalid
		//AttractionTargetData.Invalidate();

		Player.StopAllCameraShakes();

		if(Settings.ShakeClass_Detached != nullptr)
		{
			ShakeInstance_Detached = Player.PlayCameraShake( Settings.ShakeClass_Detached.Get(), this);
		}

		UMagnetDroneEventHandler::Trigger_Detached(Player);
		
		UMovementStandardSettings::ClearAutoFollowGround(Player, this);
		MoveComp.UnFollowComponentMovement(this);

		DetachedFrame = Time::FrameNumber;
		DetachTime = Time::GameTimeSeconds;

		AttachedData.bIsDetaching = false;

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Detached by {DetachTag}");
#endif
	}

	bool DetachedThisFrame() const
	{
		return DetachedFrame == Time::FrameNumber;
	}

	float GetDetachTime() const
	{
		return DetachTime;
	}

	bool ForceDetachedFromSocketWithJumpThisOrLastFrame() const
	{
		return ForceDetachedFromSocketWithJumpFrame >= Time::FrameNumber - 1;
	}

	const FVector& GetForceDetachJumpDirection() const
	{
		check(ForceDetachedFromSocketWithJumpThisOrLastFrame());
		return ForceDetachedFromSocketWithJumpDirection;
	}

	float GetForceDetachJumpImpulseMultiplier() const
	{
		check(ForceDetachedFromSocketWithJumpThisOrLastFrame());
		return ForceDetachedFromSocketWithJumpImpulseMultiplier;
	}

	bool GetForceDetachedFromSocketIgnoreOverlappingComponents() const
	{
		check(ForceDetachedFromSocketWithJumpThisOrLastFrame());
		return bForceDetachedFromSocketIgnoreOverlappingComponents;
	}

	TArray<UPrimitiveComponent> FindOverlappingComponents() const
	{
		TArray<UPrimitiveComponent> OverlappingComponents;

		FHazeTraceSettings TraceSettings = Trace::InitProfile(CollisionProfile::PlayerCharacter);
		TraceSettings.UseShape(MoveComp.CollisionShape);
		auto Overlaps = TraceSettings.QueryOverlaps(Player.ActorLocation);
		for(auto Overlap : Overlaps)
		{
			if(Overlap.bBlockingHit)
				OverlappingComponents.AddUnique(Overlap.Component);
		}

		return OverlappingComponents;
	}

	bool IsAttached() const
	{
		return AttachedData.CanAttach();
	}

	bool IsAttachedToActor(const AActor Actor) const
	{
		if(!AttachedData.CanAttach())
			return false;

		return AttachedData.GetAttachComp().Owner == Actor;
	}

	bool IsAttachedToSurface() const
	{
		if(!AttachedData.CanAttach())
			return false;

		return AttachedData.IsSurface();
	}

	bool IsAttachedToSocket() const
	{
		if(!AttachedData.CanAttach())
			return false;

		return AttachedData.IsSocket();
	}

	bool AttachedThisFrame() const
	{
		return AttachedData.AttachedThisFrame();
	}

	bool AttachedThisOrLastFrame() const
	{
		return AttachedData.AttachedThisOrLastFrame();
	}

	/**
	 * True when we have been attached, but are no longer, but we have not let go of the input yet.
	 * Will be set to false after a time delay, or if we stop holding the input, or if we get a new attachment.
	 */
	bool WasRecentlyMagneticallyAttached() const
	{
		return AttachedData.WasRecentlyAttached();
	}

	bool IsInputTopDown() const
	{
		if(!IsAttachedToSurface())
			return false;

		if(AttachedData.GetSurfaceComp().InputMethod != EMagnetDroneAttachedInputMethod::TopDown)
			return false;

		return true;
	}

	bool IsInputSideScrollerScreenspace() const
	{
		if(!IsAttachedToSurface())
			return false;

		if(AttachedData.GetSurfaceComp().InputMethod != EMagnetDroneAttachedInputMethod::SideScrollerScreenspace)
			return false;

		return true;
	}

	bool IsInputSeeSawScreenspace() const
	{
		if(!IsAttachedToSurface())
			return false;

		if(AttachedData.GetSurfaceComp().InputMethod != EMagnetDroneAttachedInputMethod::SeeSawScreenspace)
			return false;

		return true;
	}

	bool IsInputHarpoonGun() const
	{
		if(!IsAttachedToSurface())
			return false;

		return AttachedData.GetSurfaceComp().InputMethod == EMagnetDroneAttachedInputMethod::HarpoonGun;
	}

	bool IsInputCustom() const
	{
		if(!IsAttachedToSurface())
			return false;

		return AttachedData.GetSurfaceComp().InputMethod == EMagnetDroneAttachedInputMethod::Custom;
	}

	FVector GetCustomForwardVector(FVector WorldUp) const
	{
		check(IsInputCustom());
		return AttachedData.GetSurfaceComp().GetCustomAxis(WorldUp, AttachedData.GetSurfaceComp().CustomForwardAxis);
	}

	FVector GetCustomRightVector(FVector WorldUp) const
	{
		check(IsInputCustom());
		return AttachedData.GetSurfaceComp().GetCustomAxis(WorldUp, AttachedData.GetSurfaceComp().CustomRightAxis);
	}

	bool IsCameraAlignedWithSurface() const
	{
		if(!IsAttachedToSurface())
			return false;

		return AttachedData.GetSurfaceComp().CameraType == EMagneticSurfaceComponentCameraType::AlignWithSurface;
	}
	
	FVector CalculateWorldUp() const
	{
		FString OutDebugString;
		return CalculateWorldUp(OutDebugString);
	}

	FVector CalculateWorldUp(FString&out OutDebugString) const
	{
		if(AttachedThisOrLastFrame())
		{
			if(AttachedData.IsSurface())
			{
				OutDebugString = "Attached Initial Target Impact Normal";
				return AttachedData.GetInitialTargetImpactNormal();
			}
		}

		if(IsAttached() && AttachedData.IsSocket())
		{
			OutDebugString = "Attached Socket Normal";
			return AttachedData.GetSocketNormal();
		}

		if(MoveComp.HasWallContact() && MagnetDrone::IsImpactMagnetic(MoveComp.WallContact, true))
		{
			OutDebugString = "Attached Wall Contact Normal";
			return MoveComp.WallContact.Normal;
		}

		if(MoveComp.HasGroundContact() && MagnetDrone::IsImpactMagnetic(MoveComp.GroundContact, true))
		{
			OutDebugString = "Attached Ground Contact Normal";
			return MoveComp.GroundContact.Normal;
		}

		if(!MoveComp.WorldUp.IsZero())
		{
			OutDebugString = "MoveComp world up";
			return MoveComp.WorldUp;
		}

		OutDebugString = "Unhandled, Global Up";
		return FVector::UpVector;
	}

	FVector GetMagnetMoveInput(FVector2D InMovementRaw, FVector WorldUp)
	{
		check(IsAttached() && AttachedData.IsSurface(), "This function should only be used while magnetically attached to a surface!");

		if(InMovementRaw.IsNearlyZero())
		{
			PreviousForward = FVector::ZeroVector;
			return FVector::ZeroVector;
		}

		const FRotator ControlRotation = Player.GetControlRotation();

		FVector CurrentInput;
		FVector Forward;

		if(IsInputTopDown())
		{
			// Flat surface (or camera aligned)
			// Handle input along a relatively horizontal plane
			FVector Right = ControlRotation.RightVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

			// Base Forward on the Right vector, since Camera.Forward can point "backwards" relative to the player if the surface is slanted back
			Forward = Right.CrossProduct(FVector::UpVector).GetSafeNormal();
			
			CurrentInput = AdjustInput(Forward, Right, InMovementRaw);
		}
		else if(IsInputSideScrollerScreenspace())
		{
			// Use up as "forward"
			Forward = FVector::UpVector;
			FVector Right = ControlRotation.RightVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

			if(WorldUp.Z > 0)
				Right = -Right;

			// and project on surface
			Forward = Forward.VectorPlaneProject(WorldUp);
			Right = Right.VectorPlaneProject(WorldUp);

			CurrentInput = AdjustInput(Forward, Right, InMovementRaw);
		}
		else if(IsInputSeeSawScreenspace())
		{
			// Use up projected on the current surface as "forward"
			Forward = FVector::UpVector.VectorPlaneProject(WorldUp);

			// and use the surface tangent as right
			FVector Right = ControlRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal().CrossProduct(WorldUp);

			if(WorldUp.Z > 0)
				Right = -Right;

			CurrentInput = AdjustInput(Forward, Right, InMovementRaw);
		}
		else if(IsInputHarpoonGun())
		{
			// Use up projected on the current surface as "forward"
			Forward = ControlRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

			// and use the surface tangent as right
			FVector Right = ControlRotation.RightVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

			CurrentInput = AdjustInput(Forward, Right, InMovementRaw);
		}
		else if(IsInputCustom())
		{
			Forward = GetCustomForwardVector(WorldUp);
			FVector Right = GetCustomRightVector(WorldUp);

			CurrentInput = AdjustInput(Forward, Right, InMovementRaw);
		}
		else
		{
			CurrentInput = DefaultAttachedMovement(WorldUp, Forward, InMovementRaw);
		}

		CurrentInput = ConstrainToSpline(CurrentInput);

		LastInputFrame = Time::FrameNumber;
		PreviousForward = Forward;
		PreviousMoveInput = InMovementRaw;

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("Magnet Movement Input", CurrentInput);
#endif

		return CurrentInput;
	}

	private FVector DefaultAttachedMovement(FVector WorldUp, FVector& Forward, FVector2D InMovementRaw) const
	{
		const FRotator ControlRotation = Player.GetControlRotation();
		FVector Right;

		if(WorldUp.Z > 0.5 || IsCameraAlignedWithSurface())
		{
			// Flat surface (or camera aligned)
			// Handle input along a relatively horizontal plane
			Right = ControlRotation.RightVector.VectorPlaneProject(WorldUp).GetSafeNormal();

			// Base Forward on the Right vector, since Camera.Forward can point "backwards" relative to the player if the surface is slanted back
			Forward = Right.CrossProduct(WorldUp).GetSafeNormal();
		}
		else if(WorldUp.Z < -0.9)
		{
			// Upside down surface
			// Handle input along a relatively horizontal plane
			Right = ControlRotation.RightVector.VectorPlaneProject(WorldUp).GetSafeNormal();

			// Base Forward on the Right vector, since Camera.Forward can point "backwards" relative to the player if the surface is slanted back
			Forward = -Right.CrossProduct(WorldUp).GetSafeNormal();
		}
		else
		{
			FVector WallUp = FVector::UpVector.VectorPlaneProject(WorldUp).GetSafeNormal();
			Right = WorldUp.CrossProduct(WallUp).GetSafeNormal();

			// Handle input along a wall
			Forward = WallUp;
		}
		
		if(DroneComp.Settings.bUse2DTargeting && IsAttached())
		{
			// Flip input in 2D mode if the wall is facing away from the camera
			if(WorldUp.DotProduct(Player.ViewRotation.ForwardVector) > 0.3)
			{
				Forward = -Forward;
				Right = -Right;
			}
		}
		else
		{
			if(ShouldFlipDirection(InMovementRaw, Forward))
				Forward = -Forward;
		}

		return AdjustInput(Forward, Right, InMovementRaw);
	}

	bool ShouldFlipDirection(FVector2D InMovementRaw, FVector Forward) const
	{
		// If we were inputting last frame,
		if(LastInputFrame < Time::FrameNumber - 1)
			return false;

		// and the direction is now in the other direction
		if(Forward.DotProduct(PreviousForward) >= 0.0)
			return false;

		// and the stick input has not been flipped
		if(PreviousMoveInput.DotProduct(InMovementRaw) < MagnetDrone::StopFlipInputThreshold)
			return false;

		// flip it again to keep the same direction (relative to the camera)
		return true;
	}

	private FVector AdjustInput(FVector Forward, FVector Right, FVector2D InMovementRaw) const
	{
		// This math will make the x and y axis more oval, making it easier to make small adjustments,
		// but it will also making the diagonal directions be a bit skewed.
		FVector CurrentInput =
			(Forward * Math::Pow(InMovementRaw.X, 2.0) * Math::Sign(InMovementRaw.X)) +
			(Right * Math::Pow(InMovementRaw.Y, 2.0) * Math::Sign(InMovementRaw.Y));
		return CurrentInput.GetClampedToMaxSize(1) * InMovementRaw.Size();
	}

	private FVector ConstrainToSpline(FVector Input)
	{
		if(Player.IsPlayerMovementLockedToSpline())
		{
			auto SplineLockComp = UPlayerSplineLockComponent::Get(Player);
			return SplineLockComp.GetLockedMovementInput(Input);
		}

		return Input;
	}
};