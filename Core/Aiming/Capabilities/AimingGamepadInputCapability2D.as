class UAimingGamepadInputCapability2D : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AimingGamepadInput2D");
	default TickGroup = EHazeTickGroup::Input;

	UPlayerAimingComponent AimComp;
	UPlayerAimingSettings AimSettings;

	FQuat OrthogonalOffset(FRotator(-90.0, 0.0, 0.0));
	float AimAngle;
	FQuat AimRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		AimSettings = UPlayerAimingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AimComp.HasAiming2DConstraint())
			return false;

		if (!Player.IsUsingGamepad())
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

		if (!Player.IsUsingGamepad())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAimingRayOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D InputVector = GetAttributeVector2D(n"GamepadRightStick_NoDeadZone");
		InputVector.Y *= -1.0;

		if(AimSettings.bGamepadAllowBothSticks)
		{
			InputVector += GetAttributeVector2D(n"GamepadLeftStick_NoDeadZone");
			InputVector = InputVector.GetClampedToMaxSize(1);
		}

		const FVector PlaneNormal = AimComp.Get2DConstraintPlaneNormal();
		const FVector AimCenter = AimComp.Get2DAimingCenter();

		const float Deadzone = 0.3;
		if (InputVector.Size() > Deadzone)
			AimAngle = Math::Atan2(InputVector.Y, InputVector.X);

		// Ensure the axis is relative to the player's view
		FVector RotationAxis = PlaneNormal;
		if (RotationAxis.DotProduct(Player.ViewRotation.Vector()) < 0.0)
			RotationAxis *= -1.0;

		// Cross against movement up as long as the rotation axis is not
		//  pointing in the same direction, otherwise we rotate it
		FVector CrossVector = Player.ViewRotation.UpVector;
		if (Math::Abs(RotationAxis.DotProduct(CrossVector)) > 0.99)
			CrossVector = (OrthogonalOffset * Player.ViewRotation.UpVector.ToOrientationQuat()).Vector();

		// Calculate rotation relative to world
		const FQuat LocalToWorld = FQuat::MakeFromZX(CrossVector, RotationAxis);
		const FQuat TargetAimRotation = FQuat(RotationAxis, AimAngle) * LocalToWorld;

		// Snap if we just activated
		if(ActiveDuration == 0.0)
			AimRotation = TargetAimRotation;
		else
			AimRotation = Math::QInterpTo(AimRotation, TargetAimRotation, DeltaTime, AimSettings.AimingGamepad2DRayInterpSpeed);

		// Right vector should now be pointing towards the input direction
		FVector AimDirection = AimRotation.RightVector;

		FAimingRay Ray;
		Ray.AimingMode = EAimingMode::Directional2DAim;
		Ray.Origin = AimCenter;
		Ray.Direction = AimDirection;
		Ray.ConstraintPlaneNormal = PlaneNormal;
		Ray.bIsGivingAimInput = InputVector.Size() >= 0.1;
		AimComp.ApplyAimingRayOverride(Ray, this);

#if !RELEASE
		ShowDebug(PlaneNormal, AimRotation);
#endif
	}

#if !RELEASE
	void ShowDebug(FVector Normal, FQuat Rotation)
	{
		if (Console::GetConsoleVariableInt("Haze.AutoAimDebug") == 0)
			return;

		if (!Player.HasControl())
			return;

		const FVector Origin = AimComp.Get2DAimingCenter();
		Debug::DrawDebugLine(Origin, Origin + Rotation.ForwardVector * 200.0, FLinearColor::Red, 5.0);
		Debug::DrawDebugLine(Origin, Origin + Rotation.UpVector * 200.0, FLinearColor::Green, 5.0);
		Debug::DrawDebugLine(Origin, Origin + Rotation.RightVector * 200.0, FLinearColor::Blue, 5.0);
		Debug::DrawDebugArrow(Origin, Origin + Normal * 250.0, 250.0, FLinearColor::Yellow, 5.0);
		Debug::DrawDebugPlane(Origin, Normal, 250.0, 250.0, FLinearColor::Yellow, MaxNumSquares = 1);
	}
#endif
}