namespace FauxPhysics::Calculation
{
	const FConsoleVariable CVar_DropAllRemoteImpacts(
		"Haze.FauxPhysics.DropAllRemoteImpacts",
		0,
		"Pretend all impact messages from faux physics are dropped. Good to test if the level still works.");

	FVector QuatToVec(FQuat Quat)
	{
		return Quat.RotationAxis * Quat.Angle;
	}

	FQuat VecToQuat_Precise(FVector Vec)
	{
		float VecSize = Vec.Size();
		if (VecSize == 0)
			return FQuat();
		return FQuat(Vec.UnsafeNormal, VecSize);
	}

	FQuat VecToQuat(FVector Vec)
	{
		return FQuat(Vec.SafeNormal, Vec.Size());
	}

	float CalculateBoundRadiusForChildren(USceneComponent Root)
	{
		// First calculate the summed box extents of all primitive children
		FBox SumBox = FBox(Root.WorldLocation, Root.WorldLocation);

		TArray<USceneComponent> Children;
		Root.GetChildrenComponents(true, Children);

		for(auto Child : Children)
		{
			auto AsPrimitive = Cast<UPrimitiveComponent>(Child);
			if (AsPrimitive != nullptr)
			{
				FVector BoxCenter = AsPrimitive.GetBoundsOrigin();
				FVector BoxExtents = AsPrimitive.GetBoundsExtent();

				SumBox += FBox(BoxCenter - BoxExtents, BoxCenter + BoxExtents);
			}
		}

		// Then turn that into a radius
		float CenterOffset = (SumBox.Center - Root.WorldLocation).Size();
		float ExtentSize = SumBox.Extent.Size();

		return CenterOffset + ExtentSize;
	}

	// NOTE: This is FAKE (or Faux) calculations.
	// Instead of mass calculation, we use the radius of the bounds to
	//	approximate how much mass is being moved.
	//
	// But, it works and looks OK. :)
	//
	// This same math is used for both Forces and Impulses
	FVector LinearToAngular(FVector Origin, float BoundRadius, FVector VecOrigin, FVector Vec)
	{
		if (BoundRadius == 0.0)
		{
			devError("Converting linear to angular forces on an object with 0 bound radius.\nI'm sorry you have to see this but can you poke Emil? :(");
			return FVector::ZeroVector;
		}

		FVector Offset = VecOrigin - Origin;
		// DIVISION BY ZERO NOOOO
		if (Offset.IsNearlyZero())
		{
			return FVector::ZeroVector;
		}

		float OffsetLength = Offset.Size();

		// Now! The calculations here are to figure out how fast we should rotate to make point (VecOrigin) move at (Vec) speed.
		// This would assume 100% of the linear force gets transferred into that one point.

		// First step is to inverse the offset
		float InverseSize = 1.0 / OffsetLength;
		FVector InverseOffset = Offset.SafeNormal * InverseSize;

		// Next is a cross product, turning a linear translation into an angular rotation around an axis
		FVector Angular = InverseOffset.CrossProduct(Vec);

		// Next, we scale this angular velocity with how far away from the rotation origin we are
		// Essentialy, closer to origin = less force, futher from origin = bigger force
		float OffsetBoundsAlpha = OffsetLength / BoundRadius;
		return Angular * OffsetBoundsAlpha;
	}

	FVector ApplyFriction(FVector Velocity, float Friction, float DeltaTime)
	{
		FVector NewVelocity = Velocity;
		if (Friction > SMALL_NUMBER)
		{
			float IntegratedFriction = Math::Exp(-Friction);
			NewVelocity *= Math::Pow(IntegratedFriction, DeltaTime);
		}

		return NewVelocity;
	}
	float ApplyFriction(float Velocity, float Friction, float DeltaTime)
	{
		float NewVelocity = Velocity;
		if (Friction > SMALL_NUMBER)
		{
			float IntegratedFriction = Math::Exp(-Friction);
			NewVelocity *= Math::Pow(IntegratedFriction, DeltaTime);
		}

		return NewVelocity;
	}

	FVector GetArbitraryPerpendicular(FVector Direction)
	{
		return Math::GetSafePerpendicular(Direction, FVector(-25.2, 15.5, 85.1));
	}
}