
struct FActiveAiming
{
	UCrosshairWidget Crosshair;
	FInstigator Instigator;
	FAimingSettings Settings;
	FAimingResult CurrentTarget;
};

struct FAimingOverrideTarget
{
	USceneComponent AutoAimTarget;
	FVector AutoAimTargetPoint;
}

const FConsoleVariable CVar_DebugAimSensitivity("Haze.DebugAimSensitivity", 0);

class UPlayerAimingComponent : UActorComponent
{
	// Blend when aiming starts 
	UPROPERTY()
	float DefaultAimingCameraBlendIn;
	default DefaultAimingCameraBlendIn = 0.5;

	// Default crosshair widget
	UPROPERTY()
	TSubclassOf<UCrosshairWidget> DefaultCrosshairWidget;

	// Crosshair container widget
	UPROPERTY(AdvancedDisplay)
	TSubclassOf<UCrosshairContainer> DefaultCrosshairContainer;

	// Default settings for aiming for this player
	UPROPERTY(EditDefaultsOnly)
	private UPlayerAimingSettings DefaultAimingSettings;

	UPlayerAimingSettings PlayerAimingSettings;
	private AHazePlayerCharacter Player;
	private UPlayerTargetablesComponent TargetablesComp;
	private TArray<FActiveAiming> ActiveAiming;
	private TInstigated<FAimingConstraint2D> Constraint;
	private TInstigated<FAimingRay> OverrideAimingRay;
	private TInstigated<FAimingOverrideTarget> OverrideAimingTarget;
	private UCrosshairContainer CrosshairContainer;
	bool bIsUsingMouseAiming = false;

	/**
	 * Start aiming with the specified instigator and settings.
	 */
	void StartAiming(FInstigator Instigator, FAimingSettings Settings)
	{
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];
			if (Aim.Instigator == Instigator)
			{
				devError(f"Already started aiming with instigator {Instigator}");
				return;
			}
		}

		FActiveAiming Aim;
		Aim.Instigator = Instigator;
		Aim.Settings = Settings;
		Aim.CurrentTarget = CalculateAim(Aim.Settings);

		if (Settings.bShowCrosshair)
		{
			for (auto& OtherAiming : ActiveAiming)
				OtherAiming.Crosshair = nullptr;

			TSubclassOf<UCrosshairWidget> WidgetType = Settings.OverrideCrosshairWidget;
			if (!WidgetType.IsValid())
				WidgetType = DefaultCrosshairWidget;

			CrosshairContainer.CreateCrosshair(WidgetType);
			CrosshairContainer.LingerDuration = Settings.CrosshairLingerDuration;
			CrosshairContainer.bCrosshairFollowsTarget = Aim.Settings.bCrosshairFollowsTarget;
			Aim.Crosshair = CrosshairContainer.Crosshair;

			if(Settings.bOverrideSnapOffsetPitch)
				UCameraUserSettings::SetSnapOffset(Player, FRotator(Settings.SnapOffsetPitch, 0, 0), Instigator, EHazeSettingsPriority::Gameplay);
		}

		if (Settings.bApplyAimingSensitivity)
		{
			auto CameraUser = UCameraUserComponent::Get(Player);
			CameraUser.SetAiming(Instigator);
		}

		ActiveAiming.Add(Aim);
	}

	/**
	 * Stop any aiming that was active with the specified instigator.
	 */
	void StopAiming(FInstigator Instigator)
	{
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];
			if (Aim.Instigator == Instigator)
			{
				if (Aim.Crosshair != nullptr)
				{
					CrosshairContainer.RemoveCrosshair(Aim.Crosshair);
					UCameraUserSettings::ClearSnapOffset(Player, Instigator);
				}

				if (Aim.Settings.bApplyAimingSensitivity)
				{
					auto CameraUser = UCameraUserComponent::Get(Player);
					CameraUser.ClearAiming(Instigator);
				}

				ActiveAiming.RemoveAt(i);
				return;
			}
		}

		devError(f"Stopped aiming but aiming with instigator {Instigator} is not active");
	}

	/**
	 * Causes the camera to take on the sensitivity of aiming mode.
	 */
	void ApplyAimingSensitivity(FInstigator Instigator)
	{
		auto CameraUser = UCameraUserComponent::Get(Player);
		CameraUser.SetAiming(Instigator);
	}

	/**
	 * Stops the camera from taking on the sensitivity of aiming mode.
	 */
	void ClearAimingSensitivity(FInstigator Instigator)
	{
		auto CameraUser = UCameraUserComponent::Get(Player);
		CameraUser.ClearAiming(Instigator);
	}

	/**
	 * Sets bCrosshairFollowsTarget on CrosshairContainer.
	 */
	void SetCrosshairFollowsTarget(FInstigator Instigator, bool bCrosshairFollowsTarget)
	{
		if(!IsAiming(Instigator))
			return;

		if(CrosshairContainer != nullptr)
			CrosshairContainer.bCrosshairFollowsTarget = bCrosshairFollowsTarget;
	}

	/**
	 * Whether aiming is active with this instigator.
	 */
	bool IsAiming(FInstigator Instigator) const
	{
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];
			if (Aim.Instigator == Instigator)
				return true;
		}

		return false;
	}

	bool IsAiming() const
	{
		return ActiveAiming.Num() > 0;
	}

	/**
	 * Whether the instigator's active aiming is using auto aim.
	 */
	bool IsUsingAutoAim(FInstigator Instigator) const
	{
		devCheck(IsAiming(Instigator), "The given instigator has not started aiming!");
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];
			if (Aim.Instigator == Instigator)
				return Aim.Settings.bUseAutoAim;
		}

		return false;
	}

	/**
	 * Get the aiming target for the started aim with the specified instigator.
	 */
	FAimingResult GetAimingTarget(FInstigator Instigator) const
	{
		// See if we already have this aim listed
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];
			if (Aim.Instigator == Instigator)
				return Aim.CurrentTarget;
		}

		devError(f"Tried to retrieve aiming target for instigator {Instigator} but aiming was not started.");
		return FAimingResult();
	}

	/**
	 * Get the crosshair widget that is being used for the aiming target with the specified instigator.
	 */
	UCrosshairWidget GetCrosshairWidget(FInstigator Instigator) const
	{
		// See if we already have this aim listed
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];
			if (Aim.Instigator == Instigator)
				return Aim.Crosshair;
		}

		return nullptr;
	}

	/**
	 * Get the current alpha fade of the crosshair widget with the specified instigator.
	 */
	float GetCrosshairFadeAlpha() const
	{
		// See if we already have this aim listed
		if (CrosshairContainer == nullptr)
			return 0.0;
		if (CrosshairContainer.Crosshair == nullptr)
			return 0.0;
		if (!CrosshairContainer.Crosshair.IsVisible())
			return 0.0;
		return CrosshairContainer.Crosshair.GetRenderOpacity();
	}

	/**
	 * Override the ray that the player should use for tracing aim.
	 */
	void ApplyAimingRayOverride(FAimingRay Ray, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		OverrideAimingRay.Apply(Ray, Instigator, Priority);
	}

	/**
	 * Clear a previously instigated override for the player's aiming ray.
	 */
	void ClearAimingRayOverride(FInstigator Instigator)
	{
		OverrideAimingRay.Clear(Instigator);
	}

	/**
	 * Override the final target that the player should be aiming at.
	 */
	void ApplyAimingTargetOverride(FAimingOverrideTarget OverrideTarget, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		OverrideAimingTarget.Apply(OverrideTarget, Instigator, Priority);
	}

	/**
	 * Clear a previously instigated override for the player's aiming target.
	 */
	void ClearAimingTargetOverride(FInstigator Instigator)
	{
		OverrideAimingTarget.Clear(Instigator);
	}

	/**
	 * Whether we are currently overriding the final aiming target.
	 */
	bool HasAimingTargetOverride() const
	{
		return !OverrideAimingTarget.IsDefaultValue();
	}

	/**
	 * Get the current ray that is being used to trace aim.
	 */
	FAimingRay GetPlayerAimingRay() const
	{
		FAimingRay Ray;
		if (OverrideAimingRay.IsDefaultValue())
		{
			if (SceneView::IsFullScreen() && Player != SceneView::GetFullScreenPlayer())
			{
				Ray.Origin = Player.ViewLocation;
				Ray.Direction = Player.ViewRotation.ForwardVector;
			}
			else
			{
				SceneView::DeprojectScreenToWorld_Relative(
					Player, FVector2D(0.5, 0.5) + PlayerAimingSettings.ScreenSpaceAimOffset,
					Ray.Origin, Ray.Direction,
				);
			}
		}
		else
		{
			Ray = OverrideAimingRay.Get();
		}

		return Ray;
	}

	// ==============
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerAimingSettings = UPlayerAimingSettings::GetSettings(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);

		if (DefaultAimingSettings != nullptr)
			Player.ApplyDefaultSettings(DefaultAimingSettings);

		CrosshairContainer = Cast<UCrosshairContainer>(
			Widget::AddFullscreenWidget(DefaultCrosshairContainer, EHazeWidgetLayer::Crosshair)
		);
		CrosshairContainer.OverrideWidgetPlayer(Player);
		CrosshairContainer.AimComp = this;
		CrosshairContainer.CrosshairScreenPosition = FVector2D(0.5, 0.5) + PlayerAimingSettings.ScreenSpaceAimOffset;
	}

	void UpdateAiming()
	{
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];

			// Calculate aim for this frame
			Aim.CurrentTarget = CalculateAim(Aim.Settings);

			// Update crosshair
			if (Aim.Crosshair != nullptr)
			{
				CrosshairContainer.CurrentTarget = Aim.CurrentTarget;
				CrosshairContainer.Crosshair2DSettings = Aim.Settings.Crosshair2DSettings;
				CrosshairContainer.AimCenterPosition = Player.ActorCenterLocation + Player.ActorRotation.RotateVector(Aim.Settings.Crosshair2DSettings.DirectionOffset);
			}
		}

		CrosshairContainer.CrosshairScreenPosition = FVector2D(0.5, 0.5) + PlayerAimingSettings.ScreenSpaceAimOffset;
		TargetablesComp.CurrentAimingRay = GetPlayerAimingRay();
		TargetablesComp.UpdateTargeting();

#if TEST
		if (CVar_DebugAimSensitivity.GetBool())
		{
			auto CameraUser = UCameraUserComponent::Get(Player);
			if (CameraUser.IsAiming())
				PrintToScreenScaled(f"Aiming Sensitivity Active: {Player.Player :n}", 0.0, Player.GetPlayerDebugColor(), 3.0);
		}
#endif

#if EDITOR
		TemporalLogAiming();
#endif
	}

	private FAimingResult CalculateAim(FAimingSettings Settings)
	{
		FAimingResult Result;
		Result.Ray = GetPlayerAimingRay();
		Result.AimOrigin = Result.Ray.Origin;
		Result.AimDirection = Result.Ray.Direction;

		// Tell the targetables what aim ray to use
		if (Settings.OverrideAutoAimTarget.IsValid())
			TargetablesComp.OverrideTargetableAimRay(Settings.OverrideAutoAimTarget, Result.Ray);
		else
			TargetablesComp.OverrideTargetableAimRay(n"AutoAim", Result.Ray);

		// Apply any overrides that are changing what we are aiming at
		if (!OverrideAimingTarget.IsDefaultValue())
		{
			FAimingOverrideTarget OverrideTarget = OverrideAimingTarget.Get();
			Result.AutoAimTarget = OverrideTarget.AutoAimTarget;
			Result.AutoAimTargetPoint = OverrideTarget.AutoAimTargetPoint;
			Result.AimDirection = (Result.AutoAimTargetPoint - Result.AimOrigin).GetSafeNormal();

			return Result;
		}

		// Check for auto-aim
		if (Settings.bUseAutoAim)
		{
			UTargetableComponent PrimaryTarget;
			if (Settings.OverrideAutoAimTarget.IsValid())
				PrimaryTarget = TargetablesComp.GetPrimaryTarget(Settings.OverrideAutoAimTarget);
			else
				PrimaryTarget = TargetablesComp.GetPrimaryTargetForCategory(n"AutoAim");

			// If we have a primary auto-aim target, set the aim to point at that
			if (PrimaryTarget != nullptr)
			{
				Result.AutoAimTarget = PrimaryTarget;
				Result.AutoAimTargetPoint = PrimaryTarget.WorldLocation;

				auto AutoAimTarget = Cast<UAutoAimTargetComponent>(PrimaryTarget);
				if (AutoAimTarget != nullptr)
					Result.AutoAimTargetPoint = AutoAimTarget.GetAutoAimTargetPointForRay(Result.Ray);

				Result.AimDirection = (Result.AutoAimTargetPoint - Result.AimOrigin).GetSafeNormal();
			}
		}

		return Result;
	}

	/**
	 * Enables aiming by plane where the origin is the player's center and the normal is supplied.
	 * Constraint is added by priority, where the highest priority determines the active aiming plane.
	 */
	void ApplyAiming2DPlaneConstraint(FVector Normal,
		FInstigator Instigator,
		EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		FAimingConstraint2D NewConstraint;
		NewConstraint.Type = EAimingConstraintType2D::Plane;
		NewConstraint.Normal = Normal.GetSafeNormal();
		Constraint.Apply(NewConstraint, Instigator, Priority);
	}

	/**
	 * Enables aiming by plane where the origin is the player's center and the normal is supplied.
	 * Constraint is added by priority, where the highest priority determines the active aiming plane.
	 */
	void ApplyAiming2DCameraPlaneConstraint(FInstigator Instigator,
		EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		FAimingConstraint2D NewConstraint;
		NewConstraint.Type = EAimingConstraintType2D::CameraPlane;
		Constraint.Apply(NewConstraint, Instigator, Priority);
	}

	/**
	 * Enables aiming by spline, plane is defined by player's origin and closest spline right vector.
	 * Results in sidescroller-like aiming when movement is also locked to spline.
	 * Constraint is added by priority, where the highest priority determines the active aiming plane.
	 */
	void ApplyAiming2DSplineConstraint(UHazeSplineComponent SplineComponent,
		FInstigator Instigator,
		EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		if (!devEnsure(SplineComponent != nullptr, "Spline component was invalid."))
			return;

		FAimingConstraint2D NewConstraint;
		NewConstraint.Type = EAimingConstraintType2D::Spline;
		NewConstraint.SplineComponent = SplineComponent;
		Constraint.Apply(NewConstraint, Instigator, Priority);
	}

	/**
	 * Removes constraint by instigator, 2D aiming is disabled when no constraints remain.
	 */
	void ClearAiming2DConstraint(FInstigator Instigator)
	{
		Constraint.Clear(Instigator);
	}

	/**
	 * Whether 2D aiming has been enabled by any instigator.
	 * Retrieving aiming target is invalid if this is false, as there is no plane to adhere to.
	 */
	bool HasAiming2DConstraint() const
	{
		return (!Constraint.IsDefaultValue());
	}

	/**
	 * Returns the active constraint's plane normal.
	 * This is only valid if aiming is enabled.
	 */
	FVector Get2DConstraintPlaneNormal() const
	{
		const auto& ActiveConstraint = Constraint.Get();

		switch (ActiveConstraint.Type)
		{
			case EAimingConstraintType2D::Plane:
			{
				return ActiveConstraint.Normal;
			}
			case EAimingConstraintType2D::Spline:
			{
				return GetSplinePlaneNormal(ActiveConstraint);
			}
			case EAimingConstraintType2D::CameraPlane:
			{
				FVector PlayerWorldUp = Player.MovementWorldUp;
				FVector ViewForward = Player.ViewRotation.ForwardVector;

				if (PlayerWorldUp.AngularDistance(ViewForward) > 0.25 * PI)
				{
					return ViewForward.ConstrainToPlane(PlayerWorldUp).GetSafeNormal();
				}
				else
				{
					return PlayerWorldUp;
				}
			}
			case EAimingConstraintType2D::None:
				devError(f"Trying to get constraint normal, but we're not currently constrained.");
				return FVector::ZeroVector;
		}
	}

	/**
	 * Returns the forward of the closest transform on the spline to the player
	 */
	FVector Get2DConstraintSplineForward() const
	{
		const auto& ActiveConstraint = Constraint.Get();
		devCheck(ActiveConstraint.Type == EAimingConstraintType2D::Spline, "Can't get the spline forward since the current 2D constraint is not a spline constraint");

		FTransform SplineTransform = ActiveConstraint.SplineComponent.GetClosestSplineWorldTransformToWorldLocation(Player.ActorLocation);
		return SplineTransform.Rotation.ForwardVector;
	}

	/**
	 * Returns the spline the aiming is 2D constrained to.
	 */
	UHazeSplineComponent Get2DConstraintSpline() const
	{
		const auto& ActiveConstraint = Constraint.Get();
		devCheck(ActiveConstraint.Type == EAimingConstraintType2D::Spline, "Can't get the spline forward since the current 2D constraint is not a spline constraint");

		return ActiveConstraint.SplineComponent;
	}

	/**
	 * Returns the current active aiming constraint type
	 */
	EAimingConstraintType2D GetCurrentAimingConstraintType()
	{
		const auto& ActiveConstraint = Constraint.Get();
		return ActiveConstraint.Type;
	}

	FVector Get2DAimingCenter() const
	{
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];
			return Player.ActorCenterLocation + Player.ActorRotation.RotateVector(Aim.Settings.Crosshair2DSettings.DirectionOffset);
		}

		return Player.ActorCenterLocation;
	}

	FAiming2DCrosshairSettings Get2DAimingSettings() const
	{
		for (int i = ActiveAiming.Num() - 1; i >= 0; --i)
		{
			auto& Aim = ActiveAiming[i];
			return Aim.Settings.Crosshair2DSettings;
		}

		return FAiming2DCrosshairSettings();
	}

	private FVector GetSplinePlaneNormal(const FAimingConstraint2D& WithConstraint) const
	{
		const FSplinePosition SplinePosition = WithConstraint.SplineComponent
			.GetPlaneConstrainedClosestSplinePositionToWorldLocation(
				Player.ActorLocation, 
				Player.MovementWorldUp
			);

		const FTransform Transform = SplinePosition.WorldTransform;
		const FVector RightVector = Transform.Rotation.RightVector;

		return RightVector;
	}

#if EDITOR
	private void TemporalLogAiming() const
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(Player, "Aiming");

		const FString ActiveAimingCategory = "01#Active Aiming";
		TemporalLog.Value(f"{ActiveAimingCategory};Count", ActiveAiming.Num());
		for(int i = 0; i < ActiveAiming.Num(); i++)
		{
			FString Category = f"{ActiveAimingCategory};{ActiveAiming[i].Instigator}";
			TemporalLog.Value(f"{Category};Crosshair", ActiveAiming[i].Crosshair);

			TemporalLog.Value(f"{Category};Settings;bShowCrosshair", ActiveAiming[i].Settings.bShowCrosshair);
			TemporalLog.Value(f"{Category};Settings;bCrosshairFollowsTarget", ActiveAiming[i].Settings.bCrosshairFollowsTarget);
			TemporalLog.Value(f"{Category};Settings;OverrideCrosshairWidget", ActiveAiming[i].Settings.OverrideCrosshairWidget.Get());

			TemporalLog.Value(f"{Category};Settings;Crosshair2DSettings;CrosshairOffset2D", ActiveAiming[i].Settings.Crosshair2DSettings.CrosshairOffset2D);
			TemporalLog.Value(f"{Category};Settings;Crosshair2DSettings;DirectionOffset", ActiveAiming[i].Settings.Crosshair2DSettings.DirectionOffset);
			TemporalLog.Value(f"{Category};Settings;Crosshair2DSettings;DirectionalArrowSize", ActiveAiming[i].Settings.Crosshair2DSettings.DirectionalArrowSize);
			TemporalLog.Value(f"{Category};Settings;Crosshair2DSettings;bAutoFadeOut", ActiveAiming[i].Settings.Crosshair2DSettings.bAutoFadeOut);

			TemporalLog.Value(f"{Category};Settings;CrosshairLingerDuration", ActiveAiming[i].Settings.CrosshairLingerDuration);
			TemporalLog.Value(f"{Category};Settings;bUseAutoAim", ActiveAiming[i].Settings.bUseAutoAim);
			TemporalLog.Value(f"{Category};Settings;OverrideAutoAimTarget", ActiveAiming[i].Settings.OverrideAutoAimTarget.Get());
			TemporalLog.Value(f"{Category};Settings;bApplyAimingSensitivity", ActiveAiming[i].Settings.bApplyAimingSensitivity);

			TemporalLog.DirectionalArrow(f"{Category};CurrentTarget;Ray", ActiveAiming[i].CurrentTarget.Ray.Origin, ActiveAiming[i].CurrentTarget.Ray.Direction * 500);
			TemporalLog.DirectionalArrow(f"{Category};CurrentTarget;Aim", ActiveAiming[i].CurrentTarget.AimOrigin, ActiveAiming[i].CurrentTarget.AimDirection * 500);
			TemporalLog.Value(f"{Category};CurrentTarget;AutoAimTarget", ActiveAiming[i].CurrentTarget.AutoAimTarget);
			TemporalLog.Point(f"{Category};CurrentTarget;AutoAimTargetPoint", ActiveAiming[i].CurrentTarget.AutoAimTargetPoint);
		}

		const FString ConstraintCategory = "02#Constraint";
		if(Constraint.IsDefaultValue())
		{
			TemporalLog.Value(f"{ConstraintCategory};Constraint", "None");
		}
		else
		{
			FAimingConstraint2D Value = Constraint.Get();
			TemporalLog.Value(f"{ConstraintCategory};Type", Value.Type);
			TemporalLog.DirectionalArrow(f"{ConstraintCategory};Normal", Player.ActorCenterLocation, Value.Normal * 100);
			TemporalLog.Value(f"{ConstraintCategory};SplineComponent", Value.SplineComponent);

			TemporalLog.Value(f"{ConstraintCategory};Instigator", Constraint.CurrentInstigator);
			TemporalLog.Value(f"{ConstraintCategory};Priority", Constraint.CurrentPriority);
		}

		const FString Constraint2DCategory = "03#2D Constraint";
		TemporalLog.Value(f"{Constraint2DCategory};Has 2D Constraint", HasAiming2DConstraint());

		if(HasAiming2DConstraint())
			TemporalLog.Value(f"{Constraint2DCategory};Plane Normal", Get2DConstraintPlaneNormal());

		const FString OverrideAimingRayCategory = "04#Override Aiming Ray";
		if(OverrideAimingRay.IsDefaultValue())
		{
			TemporalLog.Value(f"{OverrideAimingRayCategory};Override Aiming Ray", "None");
		}
		else
		{
			FAimingRay Value = OverrideAimingRay.Get();
			TemporalLog.Value(f"{OverrideAimingRayCategory};Value;AimingMode", Value.AimingMode);
			TemporalLog.Point(f"{OverrideAimingRayCategory};Value;Origin", Value.Origin);
			TemporalLog.DirectionalArrow(f"{OverrideAimingRayCategory};Value;Direction", Value.Origin, Value.Direction * 100);
			TemporalLog.Value(f"{OverrideAimingRayCategory};Value;CursorPosition", Value.CursorPosition);
			TemporalLog.DirectionalArrow(f"{OverrideAimingRayCategory};Value;ConstraintPlaneNormal", Player.ActorLocation, Value.ConstraintPlaneNormal);
			TemporalLog.Value(f"{OverrideAimingRayCategory};Value;bIsGivingAimInput", Value.bIsGivingAimInput);
			TemporalLog.Value(f"{OverrideAimingRayCategory};Value;HasConstraintPlane", Value.HasConstraintPlane());

			TemporalLog.Value(f"{OverrideAimingRayCategory};Instigator", OverrideAimingRay.CurrentInstigator);
			TemporalLog.Value(f"{OverrideAimingRayCategory};Priority", OverrideAimingRay.CurrentPriority);
		}

		const FString OverrideAimingTargetCategory = "05#OverrideAimingTarget";
		if(OverrideAimingTarget.IsDefaultValue())
		{
			TemporalLog.Value(f"{OverrideAimingTargetCategory};Override Aiming Target", "None");
		}
		else
		{
			FAimingOverrideTarget Value = OverrideAimingTarget.Get();
			TemporalLog.Value(f"{OverrideAimingTargetCategory};Value;AutoAimTarget", Value.AutoAimTarget);
			TemporalLog.Point(f"{OverrideAimingTargetCategory};Value;AutoAimTargetPoint", Value.AutoAimTargetPoint);

			TemporalLog.Value(f"{OverrideAimingTargetCategory};Instigator", OverrideAimingTarget.CurrentInstigator);
			TemporalLog.Value(f"{OverrideAimingTargetCategory};Priority", OverrideAimingTarget.CurrentPriority);
		}
	}
#endif
};