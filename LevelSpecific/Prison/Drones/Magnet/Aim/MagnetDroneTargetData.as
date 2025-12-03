namespace FMagnetDroneTargetData
{
	FMagnetDroneTargetData MakeFromAutoAim(UMagnetDroneAutoAimComponent AutoAimTarget, FVector TargetPoint)
	{
		FMagnetDroneTargetData TargetData;
		TargetData.AutoAimComp_Internal = AutoAimTarget;
		if(TargetData.AutoAimComp_Internal == nullptr)
			return TargetData;

		bool bHasFoundComponent = false;
		TargetData.SocketComp_Internal = Cast<UDroneMagneticSocketComponent>(TargetData.AutoAimComp_Internal);
		if(TargetData.SocketComp_Internal != nullptr)
			bHasFoundComponent = true;

		if(!bHasFoundComponent)
		{
			TargetData.SurfaceComp_Internal = UDroneMagneticSurfaceComponent::Get(TargetData.AutoAimComp_Internal.Owner);
			if(TargetData.SurfaceComp_Internal != nullptr)
				bHasFoundComponent = true;
		}

		if(!ensure(bHasFoundComponent))
			return TargetData;

        TargetData.TargetComp_Internal = TargetData.AutoAimComp_Internal;

		TargetData.RelativeLocation = TargetData.TargetComp_Internal.WorldTransform.InverseTransformPositionNoScale(TargetPoint);
		TargetData.RelativeImpactNormal = TargetData.TargetComp_Internal.WorldTransform.InverseTransformVectorNoScale(AutoAimTarget.ForwardVector);

		TargetData.bValid = true;
		return TargetData;
	}

	FMagnetDroneTargetData MakeFromHit(
		FHitResult Hit,
		bool bInvalidIfHasAutoAim,
		bool bIgnoreSockets)
	{
		if(!Hit.bBlockingHit)
			return FMagnetDroneTargetData();

		return CreateTargetData(
			Hit.Component,
			Hit.ImpactPoint,
			Hit.Distance,
			bInvalidIfHasAutoAim,
			bIgnoreSockets
		);
	}

	FMagnetDroneTargetData MakeFromComponentAndLocation(
		UPrimitiveComponent Component,
		FVector ImpactPoint,
		float Distance)
	{
		return CreateTargetData(
			Component,
			ImpactPoint,
			Distance,
			false,
			false
		);
	}

	FMagnetDroneTargetData CreateTargetData(
		UPrimitiveComponent InComponent,
		FVector InImpactPoint,
		float InDistance,
		bool bInInvalidIfHasAutoAim,
		bool bIgnoreSockets)
	{
		FMagnetDroneTargetData TargetData;

		if(InComponent == nullptr)
			return TargetData;

		TArray<UMagnetDroneAutoAimComponent> AutoAimComponents;
		InComponent.Owner.GetComponentsByClass(AutoAimComponents);

		if(!AutoAimComponents.IsEmpty() && bInInvalidIfHasAutoAim)
		{
			// If the target has auto aim, then we should have gotten it through auto aiming instead!
			return TargetData;
		}

		float ClosestDistance = BIG_NUMBER;
		UMagnetDroneAutoAimComponent ClosestAutoAimComp = nullptr;

		for(auto AutoAimComp_It : AutoAimComponents)
		{
			if(bIgnoreSockets)
			{
				if(AutoAimComp_It.IsA(UDroneMagneticSocketComponent))
					continue;
			}

			if(ClosestAutoAimComp == nullptr)
			{
				ClosestDistance = AutoAimComp_It.DistanceFromPoint(InImpactPoint);
				ClosestAutoAimComp = AutoAimComp_It;
			}
			else
			{
				float Distance = AutoAimComp_It.DistanceFromPoint(InImpactPoint);
				if(Distance < ClosestDistance)
				{
					ClosestDistance = Distance;
					ClosestAutoAimComp = AutoAimComp_It;
				}
			}
		}

		if(ClosestAutoAimComp == nullptr)
		{
			// We are not inside any auto aims!
			// This is currently always a requirement
			return TargetData;
		}

		TargetData.AutoAimComp_Internal = ClosestAutoAimComp;
		TargetData.TargetComp_Internal = TargetData.AutoAimComp_Internal;

		TargetData.SocketComp_Internal = Cast<UDroneMagneticSocketComponent>(TargetData.AutoAimComp_Internal);
		if(TargetData.SocketComp_Internal != nullptr)
		{
			TargetData.RelativeLocation = FVector::ZeroVector;
			TargetData.RelativeImpactNormal = FVector::ForwardVector;

			// We found a valid socket
			TargetData.bValid = true;
			return TargetData;
		}

		TargetData.SurfaceComp_Internal = UDroneMagneticSurfaceComponent::Get(InComponent.Owner);
		if(TargetData.SurfaceComp_Internal != nullptr)
		{
			if(InDistance > TargetData.SurfaceComp_Internal.MaxTargetDistance)
				return TargetData;

			TargetData.RelativeLocation = TargetData.TargetComp_Internal.WorldTransform.InverseTransformPositionNoScale(TargetData.AutoAimComp_Internal.GetClosestPointTo(InImpactPoint));
			TargetData.RelativeImpactNormal = TargetData.TargetComp_Internal.WorldTransform.InverseTransformVectorNoScale(TargetData.AutoAimComp_Internal.ForwardVector);
			
			// We found a valid surface
			TargetData.bValid = true;
			return TargetData;
		}

		// Invalid
		return TargetData;
	}
}


/**
 * Target data used when attracting.
 */
struct FMagnetDroneTargetData
{
	access Internal = private, FMagnetDroneTargetData;

	access:Internal bool bValid = false;

	// The targeted scene component. Can be an auto aim or a primitive. Used as reference frame.
    access:Internal USceneComponent TargetComp_Internal;

	access:Internal UMagnetDroneAutoAimComponent AutoAimComp_Internal;
	access:Internal UDroneMagneticSocketComponent SocketComp_Internal;
	access:Internal UDroneMagneticSurfaceComponent SurfaceComp_Internal;

	access:Internal FVector RelativeLocation;
	access:Internal FVector RelativeImpactNormal;

	access:Internal bool bAbsoluteLocation;

#if EDITOR
	access:Internal FName InvalidateDataName;
	access:Internal FInstigator InvalidateInstigator;
#endif

	bool IsValidTarget() const
	{
		if(!bValid)
			return false;

		if(!IsValid(TargetComp_Internal))
			return false;

		if(!IsValid(AutoAimComp_Internal))
			return false;

		// We can't read these values on the Magnet Drone remote, because they may mismatch with the control side
		if(Drone::MagnetDronePlayer.HasControl())
		{
			if(AutoAimComp_Internal.IsDisabledForPlayer(Drone::GetMagnetDronePlayer()))
				return false;

			if(!AutoAimComp_Internal.bIsAutoAimEnabled)
				return false;
		}

		return true;
	}

	bool HasAutoAimTarget() const
	{
		return AutoAimComp_Internal != nullptr;
	}

	UMagnetDroneAutoAimComponent GetAutoAimComp() const
	{
		check(IsValidTarget());
		return AutoAimComp_Internal;
	}

	UDroneMagneticSocketComponent GetSocketComp() const
	{
		check(IsSocket());
		return Cast<UDroneMagneticSocketComponent>(AutoAimComp_Internal);
	}

	USceneComponent GetTargetComp() const
	{
		check(IsValidTarget());
		return TargetComp_Internal;
	}

	UDroneMagneticSurfaceComponent GetSurfaceComp() const
	{
		check(IsSurface());
		return SurfaceComp_Internal;
	}

	AActor GetActor() const
	{
		check(IsValidTarget());
		return TargetComp_Internal.GetOwner();
	}

	bool IsSocket() const
	{
		return SocketComp_Internal != nullptr;
	}

	bool IsSurface() const
	{
		return SurfaceComp_Internal != nullptr;
	}

	bool IsAttractingTargetSocket() const
    {
        if(!IsValidTarget())
            return false;

        return IsSocket();
    }

    bool IsAttractingTargetSurface() const
    {
        if(!IsValidTarget())
            return false;

        return IsSurface();
    }
	
	FVector GetTargetImpactNormal() const
	{
		check(IsValidTarget());
		if(bAbsoluteLocation)
			return RelativeImpactNormal;
		else
			return TargetComp_Internal.WorldTransform.TransformVectorNoScale(RelativeImpactNormal);
	}

	FVector GetTargetLocation() const
	{
		check(IsValidTarget());
		if(bAbsoluteLocation)
			return TargetComp_Internal.WorldLocation + RelativeLocation;
		else
			return TargetComp_Internal.WorldTransform.TransformPositionNoScale(RelativeLocation);
	}

	float GetMaxTargetDistance() const
	{
		if(HasAutoAimTarget())
		{
			if(IsSurface())
				return Math::Min(AutoAimComp_Internal.MaximumDistance, SurfaceComp_Internal.MaxTargetDistance);
			else
				return AutoAimComp_Internal.MaximumDistance;
		}
		else
		{
			if(IsSurface())
				return SurfaceComp_Internal.MaxTargetDistance;
			else
				return MagnetDrone::MaxTargetableDistance_Aim;
		}
	}

	float GetVisibleDistance() const
	{
		return GetMaxTargetDistance() + MagnetDrone::VisibleDistanceExtra_Aim;
	}

	bool ShouldAttractRelative() const
	{
		if(IsSurface())
			return GetSurfaceComp().bRelativeAttraction;
		else if(IsSocket())
			return GetSocketComp().bRelativeAttraction;

		return false;
	}


	void Invalidate(FName DataName, FInstigator Instigator)
	{
		if(!bValid)
			return;
		
		bValid = false;

#if EDITOR
		InvalidateDataName = DataName;
		InvalidateInstigator = Instigator;
#endif
	}

	bool opEquals(FMagnetDroneTargetData Other) const
	{
		if(bValid != Other.bValid)
			return false;

		if(TargetComp_Internal != Other.TargetComp_Internal)
			return false;

		if(SurfaceComp_Internal != Other.SurfaceComp_Internal)
			return false;

		if(AutoAimComp_Internal != Other.AutoAimComp_Internal)
			return false;

		if(!RelativeLocation.Equals(Other.RelativeLocation))
			return false;

		if(!RelativeImpactNormal.Equals(Other.RelativeImpactNormal))
			return false;

		if(bAbsoluteLocation != Other.bAbsoluteLocation)
			return false;

		return true;
	}

	void OverrideRelativeLocation(FVector InRelativeLocation)
	{
		check(IsValidTarget());
		RelativeLocation = InRelativeLocation;
	}

	void OverrideRelativeImpactNormal(FVector InRelativeImpactNormal)
	{
		check(IsValidTarget());
		RelativeImpactNormal = InRelativeImpactNormal;
	}

	void SetIsAbsoluteLocation(bool bAbsolute)
	{
		check(IsValidTarget());
		bAbsoluteLocation = bAbsolute;
	}

#if !RELEASE
	void LogToTemporalLog(FTemporalLog TemporalLog) const
	{
		TemporalLog.Value("IsValidTarget", IsValidTarget());
		if(IsValidTarget())
		{
			TemporalLog.Value("HasAutoAimTarget", HasAutoAimTarget());
			TemporalLog.Value("IsSocket", IsSocket());
			TemporalLog.Value("IsSurface", IsSurface());
			TemporalLog.Sphere("TargetLocation", GetTargetLocation(), MagnetDrone::Radius);
			TemporalLog.DirectionalArrow("TargetImpactNormal", GetTargetLocation(), GetTargetImpactNormal() * 200);
		}
		else
		{
#if EDITOR
			TemporalLog.Value("Invalidation Data Name", InvalidateDataName);
			TemporalLog.Value("Invalidation Instigator", InvalidateInstigator);
#endif
		}
	}
#endif
}