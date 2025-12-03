/**
 * Optional capability that makes the 2D mouse aiming only directional,
 * instead of having a cursor on screen.
 */
class UAimingMouseDirectionalOnlyInputCapability2D : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 99;

	UPlayerAimingComponent AimComp;
	
	FVector2D CursorDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AimComp.HasAiming2DConstraint())
			return false;

		if (Player.IsUsingGamepad())
			return false;

		if (!HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AimComp.HasAiming2DConstraint())
			return true;

		if (Player.IsUsingGamepad())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"MouseCursorInput", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAimingRayOverride(this);
		Owner.UnblockCapabilities(n"MouseCursorInput", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector2D InputVector = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

		float HorizSensitivity = Player.GetSensitivity(EHazeSensitivityType::MouseYaw);
		float VertSensitivity = Player.GetSensitivity(EHazeSensitivityType::MousePitch);

		CursorDirection.X += InputVector.X * HorizSensitivity * DeltaTime;
		CursorDirection.X = Math::Clamp(CursorDirection.X, -1.0, 1.0);

		CursorDirection.Y += InputVector.Y * VertSensitivity * DeltaTime;
		CursorDirection.Y = Math::Clamp(CursorDirection.Y, -1.0, 1.0);

		// Find point at which we intersect the aiming plane
		const FVector AimCenter = AimComp.Get2DAimingCenter();
		const FVector PlaneNormal = AimComp.Get2DConstraintPlaneNormal();

		FVector2D NormalCursorDirection = CursorDirection.GetSafeNormal();

		FVector AimDirection;
		AimDirection += Player.ViewRotation.UpVector.ConstrainToPlane(PlaneNormal).GetSafeNormal() * NormalCursorDirection.Y;
		AimDirection += Player.ViewRotation.RightVector.ConstrainToPlane(PlaneNormal).GetSafeNormal() * NormalCursorDirection.X;
		AimDirection = AimDirection.GetSafeNormal();

		FAimingRay Ray;
		Ray.AimingMode = EAimingMode::Directional2DAim;
		Ray.Origin = AimCenter;
		Ray.Direction = AimDirection;
		Ray.ConstraintPlaneNormal = PlaneNormal;
		AimComp.ApplyAimingRayOverride(Ray, this);

#if !RELEASE
		ShowDebug(PlaneNormal, AimDirection);
#endif
	}

#if !RELEASE
	void ShowDebug(FVector Normal, FVector Direction)
	{
		if (Console::GetConsoleVariableInt("Haze.AutoAimDebug") == 0)
			return;

		if (!Player.HasControl())
			return;

		const FVector Origin = Player.ActorCenterLocation;
		Debug::DrawDebugLine(Origin, Origin + Direction * 200.0, FLinearColor::Blue, 5.0);
		Debug::DrawDebugArrow(Origin, Origin + Normal * 250.0, 250.0, FLinearColor::Yellow, 5.0);
		Debug::DrawDebugPlane(Origin, Normal, 250.0, 250.0, FLinearColor::Yellow, MaxNumSquares = 1);
	}
#endif
}