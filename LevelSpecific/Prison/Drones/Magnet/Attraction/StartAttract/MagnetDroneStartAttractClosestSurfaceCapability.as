struct FMagnetDroneAttractToClosestSurfaceActivateParams
{
	FMagnetDroneTargetData TargetData;
}

class UMagnetDroneStartAttractClosestSurfaceCapability : UHazePlayerCapability
{
	// We just sync with a CrumbFunction instead to save a crumb when deactivating
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileChainJumping);

	default TickGroup = MagnetDrone::StartAttractTickGroup;
	default TickGroupOrder = MagnetDrone::StartAttractTickGroupOrder;
	default TickGroupSubPlacement = 120;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttractAimComponent AttractAimComp;
	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttractAimComp = UMagnetDroneAttractAimComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneAttractToClosestSurfaceActivateParams& Params) const
	{
		if(!HasControl())
			return false;

		if(!AttractionComp.Settings.bAttachToClosestSurfaceIfNoTargetAndNoGround)
			return false;

		if(!AttractionComp.IsInputtingAttract())
			return false;

		if(AttractionComp.IsAttracting())
			return false;

		if(AttractionComp.HasSetStartAttractTargetThisFrame())
			return false;

		if(AttachedComp.WasRecentlyMagneticallyAttached())
			return false;

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::PlayerAiming, n"MagnetDroneAttachToClosestSurface");
		Settings.UseSphereShape(AttractionComp.Settings.ClosestSurfaceOverlapRadius);
		FOverlapResultArray Overlaps = Settings.QueryOverlaps(Player.ActorLocation);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(AttractionComp).Page("StartAttractClosestSurface");
		TemporalLog.OverlapResults("MagnetDroneAttachToClosestSurface", Overlaps);
#endif

		if(Overlaps.Num() == 0)
			return false;

		TSet<AActor> TestedActors;

		int ClosestIndex = -1;
		FVector ClosestPoint;
		FVector ClosestNormal;
		float ClosestDistance = BIG_NUMBER;

		for(int i = 0; i < Overlaps.Num(); i++)
		{
			auto Overlap = Overlaps.OverlapResults[i];

			if(TestedActors.Contains(Overlap.Actor))
				continue;

			TestedActors.Add(Overlap.Actor);

			FVector Location = FVector::ZeroVector;
			FVector Normal = FVector::ZeroVector;
			float Distance = 0;
			if(!GetClosestValidLocation(Overlaps.Location, Overlap.Actor, Location, Normal, Distance))
				continue;

			if(Distance > ClosestDistance)
				continue;

			ClosestIndex = i;
			ClosestPoint = Location;
			ClosestNormal = Normal;
			ClosestDistance = Distance;

			TestedActors.Add(Overlap.Actor);
		}

		if(ClosestIndex < 0)
			return false;

		auto ClosestOverlap = Overlaps.OverlapResults[ClosestIndex];

		const FMagnetDroneTargetData TargetData = FMagnetDroneTargetData::MakeFromComponentAndLocation(
			ClosestOverlap.Component,
			ClosestPoint,
			ClosestDistance
		);

		if(!TargetData.IsValidTarget())
			return false;

		// Sweep to find obstructions
		FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
		if(!Player.ActorLocation.Equals(ClosestPoint))
		{
			FHitResult Hit = TraceSettings.QueryTraceSingle(Player.ActorLocation, ClosestPoint);

			if(Hit.IsValidBlockingHit())
			{
				// We hit some other actor!
				if(Hit.Actor != ClosestOverlap.Actor)
					return false;

				// If the normal is not matching, this is probably not the target surface
				if(!Hit.Normal.Equals(ClosestNormal, 0.1))
					return false;

				// We hit too far away from the auto aim point
				if(Hit.ImpactPoint.Distance(ClosestPoint) > MagnetDrone::Radius)
					return false;
			}
			else
			{
				return false;
			}
		}

		Params.TargetData = TargetData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneAttractToClosestSurfaceActivateParams Params)
	{
		CrumbStartAttractTarget(Params);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttractTarget(FMagnetDroneAttractToClosestSurfaceActivateParams Params)
	{
		AttractionComp.SetStartAttractTarget(Params.TargetData, EMagnetDroneStartAttractionInstigator::ClosestSurface);
	}

	bool GetClosestValidLocation(FVector Point, AActor Actor, FVector& OutClosestLocation, FVector& OutNormal ,float& OutDistance) const
	{
		bool bIsValid = false;
		FVector ClosestLocation;
		FVector ClosestNormal;
		float ClosestDistance = BIG_NUMBER;

		TArray<UMagnetDroneAutoAimComponent> AutoAimComponents;
		Actor.GetComponentsByClass(AutoAimComponents);

		for(auto AutoAimComp_It : AutoAimComponents)
		{
			FVector Location = AutoAimComp_It.GetClosestPointTo(Point);
			float Distance = Point.Distance(Location);
			if(Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestLocation = Location;
				ClosestNormal = AutoAimComp_It.ForwardVector;
				bIsValid = true;
			}
		}

		// for(const auto& Zone : MagneticZones)
		// {
		// 	switch(Zone.GetZoneType())
		// 	{
		// 		case EMagnetDroneZoneType::FallOffIfOutside:
		// 		{
		// 			bHadFallOffIfOutsideZone = true;
		// 			const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
		// 			if (DistanceFromPoint < KINDA_SMALL_NUMBER)
		// 				bIsInsideAtLeastOneZone = true;

		// 			break;
		// 		}

		// 		case EMagnetDroneZoneType::FallOffIfInside:
		// 		{
		// 			const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
		// 			if (DistanceFromPoint < KINDA_SMALL_NUMBER)
		// 				return false;

		// 			break;
		// 		}

		// 		case EMagnetDroneZoneType::ConstrainToWithin:
		// 		{
		// 			bHadConstrainToWithinZone = true;
		// 			const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
		// 			if (DistanceFromPoint < KINDA_SMALL_NUMBER)
		// 				bIsInsideAtLeastOneConstrainToWithinZone = true; 

		// 			break;
		// 		}

		// 		case EMagnetDroneZoneType::ConstrainToOutside:
		// 		{
		// 			const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
		// 			if (DistanceFromPoint < KINDA_SMALL_NUMBER)
		// 				return false;

		// 			break;
		// 		}
		// 	}
		// }

		OutClosestLocation = ClosestLocation;
		OutNormal = ClosestNormal;
		OutDistance = ClosestDistance;

		return bIsValid;
	}
}