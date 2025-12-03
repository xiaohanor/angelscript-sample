class UGravityBladeGrappleGravityAlignCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleGravityAlign);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 96;

	UGravityBladeGrappleUserComponent BladeComp;

	FVector TargetUpVector;
	FVector PreviousTargetUpVector;
	FVector RotationAxis;
	FHazeAcceleratedRotator UpRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeGrappleUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBladeGravityAlignSurface& Params) const
	{
		if (BladeComp.ActiveGrappleData.IsValid())
			return false;

		FGravityBladeGravityAlignSurface AlignSurface = BladeComp.QueryGravityAlignSurface();
		if (!AlignSurface.IsValid())
			return false;
		
		Params = AlignSurface;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BladeComp.ActiveGrappleData.IsValid())
			return true;

		if (!BladeComp.ActiveAlignSurface.IsValid())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FGravityBladeGravityAlignSurface& Params)
	{
		BladeComp.ActiveAlignSurface = Params;

		TargetUpVector = Params.SurfaceNormal;
		PreviousTargetUpVector = Player.MovementWorldUp;
		RotationAxis = FRotator(0.0, 0.0, 90.0).RotateVector(PreviousTargetUpVector).GetSafeNormal();
		
		UpRotation.Value = PreviousTargetUpVector.Rotation(); 
		UpRotation.Velocity = FRotator::ZeroRotator;

		Player.BlockCapabilities(CapabilityTags::CenterView, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::CenterView, this);

		bool bWasEjected = BladeComp.ActiveAlignSurface.WasEjected();
		if(bWasEjected)
			return;	// Handled by GravityBladeGrappleEject instead

		// if ((!BladeComp.ActiveGrappleData.IsValid() || !BladeComp.ActiveGrappleData.CanShiftGravity()))
		// 	Player.OverrideGravityDirection(-ClosestOrthogonalVector(TargetUpVector), Skyline::GravityProxy);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TEMP: Case where we don't want to exit shifting when we leave the surface
		if (BladeComp.AlignQueryDisablers.Num() == 0)
		{
			auto AlignSurface = BladeComp.QueryGravityAlignSurface();
			if (AlignSurface.IsValid() || BladeComp.ActiveAlignSurface.ShiftComponent == nullptr || !BladeComp.ActiveAlignSurface.ShiftComponent.bForceSticky)
				BladeComp.ActiveAlignSurface = AlignSurface;
		}

		if (!BladeComp.ActiveAlignSurface.IsValid())
			return;

		// Surface has no defined gravity direction, it's based on whatever
		//  normal the surface below us has
		if (BladeComp.ActiveAlignSurface.ShiftComponent.Type == EGravityBladeGravityShiftType::Surface)
		{
			TargetUpVector = BladeComp.ActiveAlignSurface.SurfaceNormal;
			UpRotation.AccelerateTo(TargetUpVector.Rotation(), .5, DeltaTime);

			if (Math::Abs(RotationAxis.DotProduct(TargetUpVector)) > .01)
				RotationAxis = TargetUpVector.CrossProduct(PreviousTargetUpVector).GetSafeNormal();

			const FVector CurrentUpVector = UpRotation.Value.Vector().ConstrainToPlane(RotationAxis).GetSafeNormal();
			Player.OverrideGravityDirection(-CurrentUpVector, Skyline::GravityProxy);
		}
		else
		{
			TargetUpVector = BladeComp.ActiveAlignSurface.ShiftComponent.GetShiftDirection(Player.ActorLocation);
			Player.OverrideGravityDirection(-TargetUpVector, Skyline::GravityProxy);
		}
	}

	// FVector ClosestOrthogonalVector(const FVector& Vector) const
	// {
	// 	FVector Orthogonal = Vector;
	// 	const FVector AbsVector = Vector.Abs;
	// 	if (AbsVector.X > AbsVector.Y && AbsVector.X > AbsVector.Z)
	// 		Orthogonal = FVector(Math::RoundToInt(Vector.X), 0.0, 0.0);
	// 	if (AbsVector.Y > AbsVector.X && AbsVector.Y > AbsVector.Z)
	// 		Orthogonal = FVector(0.0, Math::RoundToInt(Vector.Y), 0.0);
	// 	if (AbsVector.Z > AbsVector.X && AbsVector.Z > AbsVector.Y)
	// 		Orthogonal = FVector(0.0, 0.0, Math::RoundToInt(Vector.Z));
	// 	return Orthogonal;
	// }
}