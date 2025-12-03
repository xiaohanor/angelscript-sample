namespace MagnetDrone
{
    bool IsComponentMagnetic(const UPrimitiveComponent InComponent, FVector Location, bool bIgnoreConstraints)
    {
        if(InComponent == nullptr)
            return false;

        auto SurfaceComp = UDroneMagneticSurfaceComponent::Get(InComponent.Owner);
		if(SurfaceComp == nullptr)
			return false;

		if(!SurfaceComp.IsValidMagneticLocation(Location, bIgnoreConstraints))
			return false;

        return true;
    }

    bool IsImpactMagnetic(FMovementHitResult Impact, bool bIgnoreConstraints)
    {
        return IsComponentMagnetic(Impact.Component, Impact.Location, bIgnoreConstraints);
    }

    bool IsHitMagnetic(FHitResult Hit, bool bIgnoreConstraints)
    {
        return IsComponentMagnetic(Hit.Component, Hit.Location, bIgnoreConstraints);
    }

	EMagnetDroneIntendedTargetResult WasImpactIntendedTarget(
		FHitResult Hit,
		FVector Location,
		FVector Velocity,
		FMagnetDroneTargetData& PendingTargetData)
	{
		// Sockets are not hittable, so they may be missed.
		// If we are targeting a socket, check if the sweep hit intersects the socket sphere first.
		if(PendingTargetData.IsSocket())
		{
			const float DistToTargetSq = Hit.Location.DistSquared(PendingTargetData.GetSocketComp().WorldLocation);
			if(DistToTargetSq < Math::Square(MagnetDrone::Radius * 2.0))
				return EMagnetDroneIntendedTargetResult::Finish;
		}

		const FVector ToTarget = PendingTargetData.GetTargetLocation() - Location;

		// We will soon move away from this contact, no need to check it
		if(ToTarget.DotProduct(Hit.Normal) > 0)
			return EMagnetDroneIntendedTargetResult::Continue;

		if(MagnetDrone::IsHitMagnetic(Hit, false))
		{
			// We hit something magnetic
			// Change target to this new surface!
			PendingTargetData = FMagnetDroneTargetData::MakeFromHit(Hit, false, false);

			if(PendingTargetData.IsValidTarget())
				return EMagnetDroneIntendedTargetResult::Finish;
			else
				return EMagnetDroneIntendedTargetResult::Invalidate;
		}
		else
		{
			// We hit something that is not magnetic

			// Check if our current velocity is pointing into the surface
			{
				FVector AttractDir = Velocity;
				if(AttractDir.IsNearlyZero())
				{
					FVector FakeAttractDir = PendingTargetData.GetTargetLocation() - Location;
					AttractDir = FakeAttractDir.GetSafeNormal();
				}
				else
				{
					AttractDir.Normalize();
				}

				float Angle = AttractDir.GetAngleDegreesTo(-Hit.Normal);
				if(Angle < MagnetDrone::SlideAngleThreshold)
				{
					// Can't slide along it :c
					return EMagnetDroneIntendedTargetResult::Invalidate;
				}
			}

			// Check if the direction for the target is pointing into the surface
			// i.e there is probably a wall between us
			{
				float Angle = ToTarget.GetAngleDegreesTo(-Hit.Normal);
				if(Angle < MagnetDrone::SlideAngleThreshold)
					return EMagnetDroneIntendedTargetResult::Invalidate;
			}

			// Slide!
			return EMagnetDroneIntendedTargetResult::Continue;
		}
	}
}