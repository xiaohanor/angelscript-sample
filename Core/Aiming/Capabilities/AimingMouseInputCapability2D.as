class UAimingMouseInputCapability2D : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default CapabilityTags.Add(n"MouseCursorInput");

	UPlayerAimingComponent AimComp;
	UPlayerAimingComponent OtherPlayerAimComp;
	UPlayerAimingSettings AimSettings;
	
	FVector2D CursorUV;

	int ActiveSensitivitySetting = -1;
	int ActiveCursorSetting = -1;
	FQuat AimRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		OtherPlayerAimComp = UPlayerAimingComponent::Get(Player.OtherPlayer);
		AimSettings = UPlayerAimingSettings::GetSettings(Player);
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

		if (OtherPlayerAimComp.bIsUsingMouseAiming)
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
		AimComp.bIsUsingMouseAiming = true;
		CursorUV = FVector2D(0.5, 0.5);
		ActiveSensitivitySetting = -1;
		ActiveCursorSetting = -1;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.bIsUsingMouseAiming = false;
		AimComp.ClearAimingRayOverride(this);
		Widget::SetUseMouseCursor(this, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Aim2DSettings::CVar_UseSystemCursor.GetInt() != 0 || Aim2DSettings::CVar_UseSystemSensitivity.GetInt() != 0)
		{
			UHazeViewPoint ViewPoint;

			if (SceneView::IsFullScreen())
				ViewPoint = SceneView::GetFullScreenPlayer().GetViewPoint();
			else
				ViewPoint = Player.GetViewPoint();

			Widget::GetRelativeMouseCursorPosition(ViewPoint, CursorUV);
		}
		else
		{
			const FVector2D Resolution = (SceneView::IsFullScreen() ? 
				SceneView::GetFullViewportResolution() : 
				SceneView::GetPlayerViewResolution(Player));
				
			const FVector2D InputVector = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
			const FVector2D InputUV = (InputVector / Resolution);

			float YawSensitivity = Player.GetSensitivity(EHazeSensitivityType::AimYaw) * Player.GetSensitivity(EHazeSensitivityType::MouseYaw);
			float PitchSensitivity = Player.GetSensitivity(EHazeSensitivityType::AimPitch) * Player.GetSensitivity(EHazeSensitivityType::MousePitch);
			CursorUV.X = Math::Clamp(CursorUV.X + InputUV.X * YawSensitivity * 30.0, 0.0, 1.0);
			CursorUV.Y = Math::Clamp(CursorUV.Y - InputUV.Y * PitchSensitivity * 30.0, 0.0, 1.0);
		}

		if (ActiveCursorSetting != Aim2DSettings::CVar_UseSystemCursor.GetInt() || ActiveSensitivitySetting != Aim2DSettings::CVar_UseSystemSensitivity.GetInt())
		{
			ActiveCursorSetting = Aim2DSettings::CVar_UseSystemCursor.GetInt();
			ActiveSensitivitySetting = Aim2DSettings::CVar_UseSystemSensitivity.GetInt();

			Widget::SetUseMouseCursor(
				Instigator = this,
				bTrackMouseCursor = (ActiveCursorSetting != 0 || ActiveSensitivitySetting != 0),
				bVisibleMouseCursor = (ActiveCursorSetting != 0),
				bLockedMouseCursor = true,
				Priority = EInstigatePriority::Low,
			);
		}

		// Get cursor world location/direction relative to player view
		FVector CursorOrigin;
		FVector CursorDirection;
		SceneView::DeprojectScreenToWorld_Relative(Player, 
			CursorUV,
			CursorOrigin,
			CursorDirection
		);

		// Find point at which we intersect the aiming plane
		const FVector AimCenter = AimComp.Get2DAimingCenter();
		const FVector PlaneNormal = AimComp.Get2DConstraintPlaneNormal();
		const FVector CursorPlanePoint = Math::LinePlaneIntersection(
			CursorOrigin, 
			CursorDirection * MAX_flt, 
			AimCenter, 
			PlaneNormal
		);

		const FVector AimDirection = (CursorPlanePoint - AimCenter).GetSafeNormal();
		FQuat TargetAimRotation = FQuat::MakeFromXY(PlaneNormal, AimDirection);

		// Snap if we just activated
		if(ActiveDuration == 0.0)
			AimRotation = TargetAimRotation;
		else
			AimRotation = Math::QInterpTo(AimRotation, TargetAimRotation, DeltaTime, AimSettings.AimingCursor2DRayInterpSpeed);

		FAimingRay Ray;
		Ray.AimingMode = EAimingMode::Cursor2DAim;
		Ray.Origin = AimCenter;
		Ray.Direction = AimRotation.RightVector;
		Ray.ConstraintPlaneNormal = PlaneNormal;
		Ray.CursorPosition = CursorUV;
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