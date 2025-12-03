class UIslandRedBlueSidescrollerAssaultCapability : UHazePlayerCapability
{
	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UIslandRedBlueSidescrollerAssaultSettings SidescrollerAssaultSettings;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		SidescrollerAssaultSettings = UIslandRedBlueSidescrollerAssaultSettings::GetSettings(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::SidescrollerAssault)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::SidescrollerAssault)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Add any model attachments here
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Remove any model attachments here
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(SidescrollerAssaultSettings.bClampMaxConeWidth && SidescrollerAssaultSettings.bDebugDrawMaxConeWidth)
		{
			if(!AimComp.HasAiming2DConstraint())
				return;

			FAimingResult AimTarget = WeaponUserComponent.GetAimTarget();
			float MaxWidthExtents = SidescrollerAssaultSettings.MaxConeWidth / 2.0;
			// Trig formula tan(x) = o / a. Rearranged to a = o / tan(x)
			float ReferenceDistance = MaxWidthExtents / Math::Tan(Math::DegreesToRadians(SidescrollerAssaultSettings.ConeMaxDegreeOffset));
			float StartDistance = ReferenceDistance - SidescrollerAssaultSettings.MaxConeWidthSmoothingExtents;
			float EndDistance = ReferenceDistance + SidescrollerAssaultSettings.MaxConeWidthSmoothingExtents;
			FVector Normal = AimComp.Get2DConstraintPlaneNormal();
			Debug::DrawDebugArc(SidescrollerAssaultSettings.ConeMaxDegreeOffset * 2.0, AimTarget.AimOrigin, ReferenceDistance, AimTarget.AimDirection, FLinearColor::Red, 5.0, Normal);
			Debug::DrawDebugArc(SidescrollerAssaultSettings.ConeMaxDegreeOffset * 2.0, AimTarget.AimOrigin, StartDistance , AimTarget.AimDirection, FLinearColor::Green, 5.0, Normal, 16, 0.0, false);
			Debug::DrawDebugArc(SidescrollerAssaultSettings.ConeMaxDegreeOffset * 2.0, AimTarget.AimOrigin, EndDistance , AimTarget.AimDirection, FLinearColor::Green, 5.0, Normal, 16, 0.0, false);

			FVector Dir1 = AimTarget.AimDirection.RotateAngleAxis(SidescrollerAssaultSettings.ConeMaxDegreeOffset, Normal);
			FVector Dir2 = AimTarget.AimDirection.RotateAngleAxis(-SidescrollerAssaultSettings.ConeMaxDegreeOffset, Normal);

			FVector Point1 = AimTarget.AimOrigin + Dir1 * ReferenceDistance;
			FVector Point2 = AimTarget.AimOrigin + Dir2 * ReferenceDistance;

			const float Distance = 200.0;
			Debug::DrawDebugLine(Point1, Point1 + AimTarget.AimDirection * Distance, FLinearColor::Red, 5.0);
			Debug::DrawDebugLine(Point2, Point2 + AimTarget.AimDirection * Distance, FLinearColor::Red, 5.0);

			const float Speed = 2.0;
			float TimeAlpha = (Math::Sin(Time::GetGameTimeSeconds() * Speed) + 1.0) / 2.0;
			float CurrentBezierAngle = Math::Lerp(-SidescrollerAssaultSettings.ConeMaxDegreeOffset, SidescrollerAssaultSettings.ConeMaxDegreeOffset, TimeAlpha);
			FVector CurrentBezierDirection = AimTarget.AimDirection.RotateAngleAxis(CurrentBezierAngle, Normal);

			FVector Origin = AimTarget.AimOrigin;
			FVector LastStraightPoint = AimTarget.AimOrigin + CurrentBezierDirection * StartDistance;
			FVector BezierControlPoint = LastStraightPoint + CurrentBezierDirection * SidescrollerAssaultSettings.MaxConeWidthSmoothingExtents;
			FVector BezierEndPoint = BezierControlPoint + AimTarget.AimDirection * SidescrollerAssaultSettings.MaxConeWidthSmoothingExtents;

			Debug::DrawDebugLine(Origin, LastStraightPoint, FLinearColor::Yellow, 5.0);
			Debug::DrawDebugPoint(LastStraightPoint, 3.0, FLinearColor::Purple, 0.0, true);
			Debug::DrawDebugPoint(BezierControlPoint, 3.0, FLinearColor::LucBlue, 0.0, true);
			Debug::DrawDebugPoint(BezierEndPoint, 3.0, FLinearColor::DPink, 0.0, true);

			BezierCurve::DebugDraw_1CP(LastStraightPoint, BezierControlPoint, BezierEndPoint, FLinearColor::Yellow, 5.0, 0.0, 500);
			Debug::DrawDebugLine(BezierEndPoint, BezierEndPoint + AimTarget.AimDirection * (Distance - SidescrollerAssaultSettings.MaxConeWidthSmoothingExtents), FLinearColor::Yellow, 5.0);
		}

		auto Target = TargetablesComp.GetPrimaryTarget(UIslandRedBlueTargetableComponent);

		if(Target != nullptr && ShouldUseHoming() &&  SidescrollerAssaultSettings.bDebugDrawHomingTargets)
		{
			Debug::DrawDebugPoint(Target.WorldLocation, 50.0, Player.IsMio() ? FLinearColor::Red : FLinearColor::LucBlue);
		}
	}
#endif

	bool ShouldUseHoming() const
	{
		EAimingConstraintType2D Type = AimComp.GetCurrentAimingConstraintType();
		switch(Type)
		{
			case EAimingConstraintType2D::Spline:
			{
				return SidescrollerAssaultSettings.bUseHomingInSidescroller;
			}
			case EAimingConstraintType2D::Plane:
			{
				return SidescrollerAssaultSettings.bUseHomingInTopDown;
			}
			default:
				return true;
		}
	}
}