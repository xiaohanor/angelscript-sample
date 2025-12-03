/**
 * Target data used when magnetically attached
 */
struct FMagnetDroneAttachedData
{
	private bool bValid = false;
	private uint AttachedFrame = 0;
	private bool bWasRecentlyAttached = false;
	private FVector InitialTargetLocation;
	private FVector InitialTargetImpactNormal;

	private USceneComponent AttachComp_Internal;
	private UDroneMagneticSurfaceComponent MagneticSurfaceComp_Internal;
	private UDroneMagneticSocketComponent MagneticSocketComp_Internal;

	bool bIsDetaching = false;

	FMagnetDroneAttachedData(const UHazeMovementComponent MoveComp, const UMagnetDroneAttachedComponent AttachedComp, FMagnetDroneTargetData InTargetData)
	{
		check(InTargetData.IsValidTarget());

		InitialTargetLocation = InTargetData.GetTargetLocation();
		InitialTargetImpactNormal = InTargetData.GetTargetImpactNormal();

		if(InTargetData.IsSocket())
		{
			MagneticSocketComp_Internal = Cast<UDroneMagneticSocketComponent>(InTargetData.GetAutoAimComp());
			AttachComp_Internal = MagneticSocketComp_Internal;
			check(MagneticSocketComp_Internal != nullptr);
		}
		else if(InTargetData.IsSurface())
		{
			MagneticSurfaceComp_Internal = InTargetData.GetSurfaceComp();
				
			// Trace towards the ground to prevent finding a new magnetic surface the first time we touch the ground,
			// which would cause a OnDetach and then OnAttach again.
			FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
			TraceSettings.IgnorePlayers();

			const FVector Start = MoveComp.Owner.ActorLocation;
			const FVector End = MoveComp.Owner.ActorLocation - InTargetData.GetTargetImpactNormal() * 50;
			const FHitResult HitResult = TraceSettings.QueryTraceSingle(Start, End);

#if !RELEASE
			FTemporalLog TemporalLog = TEMPORAL_LOG(AttachedComp);
			TemporalLog.HitResults("MagnetDroneAttachedData FindGround", HitResult, TraceSettings.Shape, FVector::ZeroVector, false);
#endif

			if(HitResult.bBlockingHit && HitResult.Actor == InTargetData.GetActor())
			{
				AttachComp_Internal = HitResult.Component;
				InitialTargetLocation = HitResult.ImpactPoint;
				InitialTargetImpactNormal = HitResult.ImpactNormal;
			}
			else
			{
				AttachComp_Internal = InTargetData.GetTargetComp();
			}
		}

		if(!ensure(AttachComp_Internal != nullptr))
			return;

		AttachedFrame = Time::FrameNumber;
		bValid = true;
	}

	FMagnetDroneAttachedData(FMovementHitResult InGroundImpact, bool bIsInitialAttachment)
	{
		check(MagnetDrone::IsImpactMagnetic(InGroundImpact, true));

		AttachComp_Internal = InGroundImpact.Component;
		MagneticSurfaceComp_Internal = UDroneMagneticSurfaceComponent::Get(InGroundImpact.Actor);
		MagneticSocketComp_Internal = nullptr;

		InitialTargetLocation = InGroundImpact.ImpactPoint;
		InitialTargetImpactNormal = InGroundImpact.ImpactNormal;

		if(bIsInitialAttachment)
			AttachedFrame = Time::FrameNumber;

		bValid = true;
	}

	FMagnetDroneAttachedData(FMagnetDroneMoveToNewSurfaceData InMoveToNewSurfaceData)
	{
		check(MagnetDrone::IsComponentMagnetic(InMoveToNewSurfaceData.Component, InMoveToNewSurfaceData.ImpactPoint, true));

		AttachComp_Internal = InMoveToNewSurfaceData.Component;
		MagneticSurfaceComp_Internal = UDroneMagneticSurfaceComponent::Get(InMoveToNewSurfaceData.Component.Owner);
		MagneticSocketComp_Internal = nullptr;

		InitialTargetLocation = InMoveToNewSurfaceData.ImpactPoint;
		InitialTargetImpactNormal = InMoveToNewSurfaceData.ImpactNormal;

		bValid = true;
	}

	bool IsValid() const
	{
		return bValid;
	}

	bool CanAttach() const
	{
		if(!bValid)
			return false;

		if(AttachComp_Internal == nullptr)
			return false;

		if(IsSocket())
		{
			// If we are detaching, it could be because the component was disabled
			if(!bIsDetaching)
			{
				if(MagneticSocketComp_Internal.IsDisabledForPlayer(Drone::GetMagnetDronePlayer()))
					return false;
			}

			return true;
		}

		if(IsSurface())
		{
			return true;
		}

		return false;
	}

	bool AttachedThisFrame() const
	{
		return AttachedFrame == Time::FrameNumber;
	}

	bool AttachedThisOrLastFrame() const
	{
		return AttachedFrame >= Time::FrameNumber - 1;
	}

	bool WasRecentlyAttached() const
	{
		if(CanAttach())
			return false;

		return bWasRecentlyAttached;
	}

	bool ShouldImmediatelyDetach() const
	{
		if(IsSocket())
			return GetSocketComp().bImmediatelyDetach;
		else if(IsSurface())
			return GetSurfaceComp().bImmediatelyDetach;

		return false;
	}

	USceneComponent GetAttachComp() const
	{
		check(CanAttach());
		return AttachComp_Internal;
	}

	UDroneMagneticSurfaceComponent GetSurfaceComp() const
	{
		check(CanAttach());
		return MagneticSurfaceComp_Internal;
	}

	UDroneMagneticSocketComponent GetSocketComp() const
	{
		check(CanAttach());
		return MagneticSocketComp_Internal;
	}

	bool IsSocket() const
	{
		return MagneticSocketComp_Internal != nullptr;
	}

	FVector GetSocketNormal() const
	{
		check(IsSocket());
		return GetSocketComp().ForwardVector;
	}

	bool IsSurface() const
	{
		return MagneticSurfaceComp_Internal != nullptr;
	}

	EMagneticSurfaceComponentCameraType GetCameraType() const property
	{
		check(CanAttach());

		if(IsSocket())
		{
			if(MagneticSocketComp_Internal.bUseAutomaticWallCamera)
				return EMagneticSurfaceComponentCameraType::AutomaticWall;
			else
				return EMagneticSurfaceComponentCameraType::NoAutomaticWallCamera;
		}

		if(IsSurface())
		{
			return MagneticSurfaceComp_Internal.CameraType;
		}

		return EMagneticSurfaceComponentCameraType::AutomaticWall;
	}

	FVector GetInitialTargetLocation() const
	{
		return InitialTargetLocation;
	}

	FVector GetInitialTargetImpactNormal() const
	{
		return InitialTargetImpactNormal;
	}

	void Invalidate(FName DataName, FInstigator Instigator)
	{
		if(!bValid)
			return;

		bValid = false;
		bWasRecentlyAttached = true;

		//PrintWarning(f"Invalidated {DataName} by {Instigator}");
	}

	void ResetWasRecentlyAttached()
	{
		bWasRecentlyAttached = false;
	}

#if EDITOR
	void LogToTemporalLog(const FTemporalLog& TemporalLog, FString Category) const
	{
		TemporalLog.Value(f"{Category};Valid", bValid);
		TemporalLog.Value(f"{Category};Was Recently Attached", bWasRecentlyAttached);
		TemporalLog.Value(f"{Category};AttachedFrame", AttachedFrame);
		TemporalLog.Value(f"{Category};AttachedThisFrame", AttachedThisFrame());
		TemporalLog.Value(f"{Category};AttachedThisOrLastFrame", AttachedThisOrLastFrame());
		TemporalLog.Value(f"{Category};Can Attach", CanAttach());
		TemporalLog.Sphere(f"{Category};Initial Target Location", InitialTargetLocation, MagnetDrone::Radius);
		TemporalLog.DirectionalArrow(f"{Category};Initial Target Impact Normal", InitialTargetLocation, InitialTargetImpactNormal * 200);

		if(CanAttach())
		{
			if(IsSurface())
			{
				TemporalLog.Value(f"{Category};Surface;Actor", AttachComp_Internal.Owner);
				TemporalLog.Value(f"{Category};Surface;Component", AttachComp_Internal);
				TemporalLog.Value(f"{Category};Surface;Surface Component", GetSurfaceComp());
			}
			else if(IsSocket())
			{
				TemporalLog.Value(f"{Category};Socket;Actor", GetSocketComp().Owner);
				TemporalLog.Value(f"{Category};Socket;Component", GetSocketComp());
				TemporalLog.DirectionalArrow(f"{Category};Socket;Normal", GetSocketComp().WorldLocation, GetSocketNormal() * 200);
			}
		}
	}
#endif
}
