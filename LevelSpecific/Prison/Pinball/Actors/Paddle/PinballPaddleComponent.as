enum EPinballPaddleTransformType
{
	Top,
	CurrentTransform,
	Bottom
};

struct FPinballPaddleAutoAimTargetData
{
	UPROPERTY(EditAnywhere)
	AHazeActor Actor;

	UPROPERTY(EditAnywhere)
	private FVector2D Offset;

	UPROPERTY(EditAnywhere)
	bool bOverrideImpulse = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bOverrideImpulse", EditConditionHides))
	float Impulse = 3000;

	bool IsValid() const
	{
		if(Actor == nullptr)
			return false;

		auto AutoAimComp = GetAutoAimComp();
		if(AutoAimComp == nullptr)
			return false;

		if(!AutoAimComp.IsAutoAimEnabled())
			return false;

		return true;
	}

	UPinballAutoAimComponent GetAutoAimComp() const
	{
		if(Actor == nullptr)
			return nullptr;

		return UPinballAutoAimComponent::Get(Actor);
	}

	FVector GetAutoAimTargetLocation() const
	{
		auto AutoAimComp = GetAutoAimComp();
		if(AutoAimComp == nullptr)
			return Actor.ActorLocation;

		return AutoAimComp.WorldLocation + FVector(0, Offset.X, Offset.Y);
	}

	FVector GetDirectionToAutoAimFrom(FVector From) const
	{
		return (GetAutoAimTargetLocation() - From).GetSafeNormal();
	}
};

struct FPinballPaddleLaunchSettings
{
	UPROPERTY(EditAnywhere, Category = "Angle")
	bool bUseLaunchDirectionOverAngle = true;

	UPROPERTY(EditAnywhere, Category = "Angle")
	FRuntimeFloatCurve LaunchDirectionOverAngle;

	UPROPERTY(EditAnywhere, Category = "Angle")
	bool bUseLaunchDirectionOverLength = true;

	UPROPERTY(EditAnywhere, Category = "Angle")
	FRuntimeFloatCurve LaunchDirectionOverLength;

	UPROPERTY(EditAnywhere, Category = "Angle|Back")
	bool bCopyTopLaunchDirectionOverAngleCurve = true;

	UPROPERTY(EditAnywhere, Category = "Angle|Back")
	FRuntimeFloatCurve LaunchDirectionOverAngleBack;

	UPROPERTY(EditAnywhere, Category = "Angle|Back")
	bool bCopyTopLaunchDirectionOverLengthCurve = true;

	UPROPERTY(EditAnywhere, Category = "Angle|Back")
	FRuntimeFloatCurve LaunchDirectionOverLengthBack;

	UPROPERTY(EditAnywhere, Category = "Force")
	float PaddleImpulse = 2800.0;

	UPROPERTY(EditAnywhere, Category = "Force")
	FRuntimeFloatCurve ForceOverLengthMultiplier;

	UPROPERTY(EditAnywhere, Category = "Force|Back")
	float PaddleImpulseBack = 2800.0;

	UPROPERTY(EditAnywhere, Category = "Force|Back")
	bool bCopyTopForceOverLengthMultiplier = true;

	UPROPERTY(EditAnywhere, Category = "Force|Back")
	FRuntimeFloatCurve ForceOverLengthMultiplierBack;

	const FRuntimeFloatCurve& GetForceOverLengthCurve(bool bTop) const
	{
		if(bTop || bCopyTopForceOverLengthMultiplier)
			return ForceOverLengthMultiplier;
		else
			return ForceOverLengthMultiplierBack;
	}

	const FRuntimeFloatCurve& GetLaunchDirectionOverLengthCurve(bool bTop) const
	{
		if(bTop || bCopyTopLaunchDirectionOverLengthCurve)
			return LaunchDirectionOverLength;
		else
			return LaunchDirectionOverLengthBack;
	}

	const FRuntimeFloatCurve& GetLaunchDirectionOverAngleCurve(bool bTop) const
	{
		if(bTop || bCopyTopLaunchDirectionOverAngleCurve)
			return LaunchDirectionOverAngle;
		else
			return LaunchDirectionOverAngleBack;
	}

	float GetPaddleImpulse(bool bTop) const
	{
		if(bTop)
			return PaddleImpulse;
		else
			return PaddleImpulseBack;
	}

#if EDITOR
	void CopyFromComponent(const UPinballPaddleComponent InPaddleComp)
	{
		bUseLaunchDirectionOverAngle = InPaddleComp.bUseLaunchDirectionOverAngle;
		LaunchDirectionOverAngle = InPaddleComp.LaunchDirectionOverAngle;
		bUseLaunchDirectionOverLength = InPaddleComp.bUseLaunchDirectionOverLength;
		LaunchDirectionOverLength = InPaddleComp.LaunchDirectionOverLength;
		bCopyTopLaunchDirectionOverAngleCurve = InPaddleComp.bCopyTopLaunchDirectionOverAngleCurve;
		LaunchDirectionOverAngleBack = InPaddleComp.LaunchDirectionOverAngleBack;
		bCopyTopLaunchDirectionOverLengthCurve = InPaddleComp.bCopyTopLaunchDirectionOverLengthCurve;
		LaunchDirectionOverLengthBack = InPaddleComp.LaunchDirectionOverLengthBack;
		PaddleImpulse = InPaddleComp.PaddleImpulse;
		ForceOverLengthMultiplier = InPaddleComp.ForceOverLengthMultiplier;
		PaddleImpulseBack = InPaddleComp.PaddleImpulseBack;
		bCopyTopForceOverLengthMultiplier = InPaddleComp.bCopyTopForceOverLengthMultiplier;
		ForceOverLengthMultiplierBack = InPaddleComp.ForceOverLengthMultiplierBack;
	}
#endif
};

UCLASS(NotBlueprintable, HideCategories = "ComponentTick Deprecated Rendering Disable Debug Activation Cooking Tags LOD AssetUserData Navigation")
class UPinballPaddleComponent : USceneComponent
{
	access Internal = private, APinballPaddle, UPinballPaddleComponentVisualizer;
	access Visualizer = private, UPinballPaddleComponentVisualizer;
	access LaunchSettings = private, FPinballPaddleLaunchSettings;

	UPROPERTY(EditAnywhere, Category = "Paddle")
	access:Internal bool bIsLeft;

	UPROPERTY(EditInstanceOnly, Category = "Paddle")
	access:Internal bool bAutoAim = true;

	UPROPERTY(EditInstanceOnly, Category = "Paddle")
	access:Internal TArray<FPinballPaddleAutoAimTargetData> AutoAimTargets;

	UPROPERTY(EditAnywhere, Category = "Paddle", Meta = (ClampMin = "1", ClampMax = "1000"))
	access:Internal float PaddleLength = 335.0;

	UPROPERTY(EditAnywhere, Category = "Paddle", Meta = (ClampMin = "1", ClampMax = "100"))
	access:Internal float TipRadius = 25.0;

	UPROPERTY(EditAnywhere, Category = "Paddle", Meta = (ClampMin = "1", ClampMax = "100"))
	access:Internal float PivotRadius = 40.5;

	UPROPERTY(EditAnywhere, Category = "Paddle")
	access:Internal float StartExtraSweepDistance = -20;

	UPROPERTY(EditAnywhere, Category = "Paddle")
	access:Internal float EndExtraSweepDistance = 10;

	UPROPERTY(EditAnywhere, Category = "Paddle")
	access:Internal bool bAllowTipHits = false;

	UPROPERTY(EditAnywhere, Category = "Paddle|Squish")
	access:Internal bool bSquishPlayerIfUnder = false;

	UPROPERTY(EditAnywhere, Category = "Paddle|Squish", Meta = (EditCondition = "bSquishPlayerIfUnder"))
	access:Internal float SquishAngle = 60;

	UPROPERTY(EditAnywhere, Category = "Paddle|Squish", Meta = (EditCondition = "bSquishPlayerIfUnder"))
	access:Internal float SquishDistance = 150;

	UPROPERTY(EditAnywhere, Category = "Rotation", Meta = (ClampMin = "1", ClampMax = "359"))
	access:Internal float UpAngleDiff = 50;

	UPROPERTY(EditAnywhere, Category = "Rotation")
	access:Internal float UpAcceleration = 1000;

	UPROPERTY(EditAnywhere, Category = "Rotation")
	access:Internal float FallAcceleration = 6250;

	UPROPERTY(EditAnywhere, Category = "Launch")
	private FPinballPaddleLaunchSettings LaunchSettings;

	UPROPERTY(EditAnywhere, Category = "Launch")
	private FPinballPaddleLaunchSettings BossBallLaunchSettings;

	UPROPERTY(EditAnywhere, Category = "Launce", AdvancedDisplay)
	private bool bHasCopiedLaunchSettings = false;

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Deprecated|Angle")
	access:LaunchSettings bool bUseLaunchDirectionOverAngle = true;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Angle", Meta = (EditCondition = "bUseLaunchDirectionOverAngle"))
	access:LaunchSettings FRuntimeFloatCurve LaunchDirectionOverAngle;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Angle")
	access:LaunchSettings bool bUseLaunchDirectionOverLength = true;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Angle", Meta = (EditCondition = "bUseLaunchDirectionOverLength"))
	access:LaunchSettings FRuntimeFloatCurve LaunchDirectionOverLength;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Angle|Back")
	access:LaunchSettings bool bCopyTopLaunchDirectionOverAngleCurve = true;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Angle|Back", Meta = (EditCondition = "!bCopyTopLaunchDirectionOverAngleCurve"))
	access:LaunchSettings FRuntimeFloatCurve LaunchDirectionOverAngleBack;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Angle|Back")
	access:LaunchSettings bool bCopyTopLaunchDirectionOverLengthCurve = true;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Angle|Back", Meta = (EditCondition = "!bCopyTopLaunchDirectionOverLengthCurve"))
	access:LaunchSettings FRuntimeFloatCurve LaunchDirectionOverLengthBack;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Force")
	access:LaunchSettings float PaddleImpulse = 2800.0;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Force")
	access:LaunchSettings FRuntimeFloatCurve ForceOverLengthMultiplier;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Force|Back")
	access:LaunchSettings float PaddleImpulseBack = 2800.0;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Force|Back")
	access:LaunchSettings bool bCopyTopForceOverLengthMultiplier = true;

	UPROPERTY(EditAnywhere, Category = "Deprecated|Force|Back", Meta = (EditCondition = "!bCopyTopForceOverLengthMultiplier"))
	access:LaunchSettings FRuntimeFloatCurve ForceOverLengthMultiplierBack;
#endif

	// When Zoe is further away than this, don't do any collision checks towards balls
	UPROPERTY(EditAnywhere, Category = "Optimization")
	access:Internal float PaddleCullDistance = 2500.0;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	access:Internal bool bSimulateHit = true;

	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	access:Visualizer bool bSimulateHitTop = true;

	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	access:Internal EPinballBallType SimulateBallType = EPinballBallType::Player;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (UIMin = "-1.0", UIMax = "1.0", EditCondition = "bSimulateHit", EditConditionHides))
	access:Visualizer float SimulatedInput = 0;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (EditCondition = "bSimulateHit", EditConditionHides))
	access:Visualizer float SimulationDuration = 1;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (EditCondition = "bSimulateHit", EditConditionHides))
	access:Visualizer float SimulatedPlayerDistance = 250;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (EditCondition = "bSimulateHit", EditConditionHides))
	access:Visualizer float SimulatedPlayerAngle = 20;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (EditCondition = "bSimulateHit", EditConditionHides))
	access:Internal bool bSimulationIgnoresAutoAim = false;

	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	access:Internal int SimulationFPS = 60;

	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	access:Internal bool bTestFramerateDependency = false;
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CopyLaunchSettings();
	}

	UFUNCTION(CallInEditor, Category = "Paddle")
	void CopyLaunchSettings()
	{
		if(bHasCopiedLaunchSettings)
			return;

		LaunchSettings.CopyFromComponent(this);
		bHasCopiedLaunchSettings = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		// Don't ever move the paddle component in the editor!
		SetRelativeTransform(FTransform::Identity);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if EDITOR
		if(!RelativeTransform.Equals(FTransform::Identity))
		{
			PrintError(f"Paddle attached to {Owner.Name} has a weird transform! PaddleComponent should have all 0 on the transform values!");
		}
#endif
	}

	const FPinballPaddleLaunchSettings& GetLaunchSettings(EPinballBallType BallType) const
	{
		switch(BallType)
		{
			case EPinballBallType::Player:
				return LaunchSettings;

			case EPinballBallType::BossBall:
				return BossBallLaunchSettings;
		}
	}

	float GetRelativeAngle(EPinballPaddleTransformType TransformType) const
	{
		switch(TransformType)
		{
			case EPinballPaddleTransformType::Top:
				return UpAngleDiff;

			case EPinballPaddleTransformType::CurrentTransform:
				return RelativeRotation.Pitch;

			case EPinballPaddleTransformType::Bottom:
				return 0;
		}
	}

	FQuat GetPaddleRelativeRotation(float Pitch) const
	{
		return FQuat(FVector::RightVector, Math::DegreesToRadians(-Pitch));
	}

	FQuat GetPaddleRelativeRotation(EPinballPaddleTransformType TransformType) const
	{
		return GetPaddleRelativeRotation(GetRelativeAngle(TransformType));
	}

	FTransform GetPaddleWorldTransform(float Pitch) const
	{
		const FQuat Rotation = AttachParent.WorldTransform.TransformRotation(GetPaddleRelativeRotation(Pitch));
		return FTransform(Rotation, WorldLocation);
	}

	// Tip

	float GetLengthFromPivotToTip() const
	{
		return PaddleLength + TipRadius;
	}

	// Center

	FVector GetCenterPivot() const
	{
		return GetPaddleWorldTransform(0).TransformPositionNoScale(FVector::ZeroVector);
	}

	FVector GetCenterTip(float Pitch) const
	{
		const FVector Forward = AttachParent.WorldTransform.TransformVector(GetPaddleRelativeRotation(Pitch).ForwardVector);
		return GetCenterPivot() + (Forward * PaddleLength);
	}

	// Top

	FVector GetTopPivot(float Pitch) const
	{
		const FVector Up = AttachParent.WorldTransform.TransformVector(GetPaddleRelativeRotation(Pitch).UpVector);
		return GetCenterPivot() + (Up * PivotRadius);
	}

	FVector GetTopTip(float Pitch) const
	{
		const FVector Up = AttachParent.WorldTransform.TransformVector(GetPaddleRelativeRotation(Pitch).UpVector);
		return GetCenterTip(Pitch) + (Up * TipRadius);
	}

	// Vector from TopPivot to TopTip
	FVector GetTopEdge(float Pitch) const
	{
		return GetTopTip(Pitch) - GetTopPivot(Pitch);
	}

	// Location between TopPivot and TopTip
	FVector GetTopEdgeCenter(float Pitch) const
	{
		return (GetTopTip(Pitch) + GetTopPivot(Pitch)) * 0.5;
	}

	private void GetTopPlane(float Pitch, bool bTop, FVector&out Origin, FVector&out Normal) const
	{
		const FVector Right = AttachParent.WorldTransform.TransformVector(GetPaddleRelativeRotation(Pitch).RightVector);
		Origin = GetTopEdgeCenter(Pitch);
		Normal = GetTopEdge(Pitch).CrossProduct(Right).GetSafeNormal();

		if(!bTop)
			Normal *= -1;
	}

	// Bot
	
	FVector GetBotPivot(float Pitch) const
	{
		const FVector Up = AttachParent.WorldTransform.TransformVector(GetPaddleRelativeRotation(Pitch).UpVector);
		return GetCenterPivot() - (Up * PivotRadius);
	}

	FVector GetBotTip(float Pitch) const
	{
		const FVector Up = AttachParent.WorldTransform.TransformVector(GetPaddleRelativeRotation(Pitch).UpVector);
		return GetCenterTip(Pitch) - (Up * PivotRadius);
	}

	// Vector from BotPivot to BotTip
	FVector GetBotEdge(float Pitch) const
	{
		return GetBotTip(Pitch) - GetBotPivot(Pitch);
	}

	// Location between BotPivot and BotTip
	FVector GetBotEdgeCenter(float Pitch) const
	{
		return (GetBotTip(Pitch) + GetBotPivot(Pitch)) * 0.5;
	}

	private void GetBotPlane(float Pitch, bool bTop, FVector&out Origin, FVector&out Normal) const
	{
		const FVector Right = AttachParent.WorldTransform.TransformVector(GetPaddleRelativeRotation(Pitch).RightVector);
		Origin = GetBotEdgeCenter(Pitch);
		Normal = GetBotEdge(Pitch).CrossProduct(Right).GetSafeNormal();

		if(!bTop)
			Normal *= -1;
	}

	// Misc

	void GetFrontPlane(float Angle, bool bTop, FVector&out Origin, FVector&out Normal) const
	{
		if(bTop)
			GetTopPlane(Angle, bTop, Origin, Normal);
		else
			GetBotPlane(Angle, bTop, Origin, Normal);
	}

	void GetBackPlane(float Angle, bool bTop, FVector&out Origin, FVector&out Normal) const
	{
		if(bTop)
			GetBotPlane(Angle, bTop, Origin, Normal);
		else
			GetTopPlane(Angle, bTop, Origin, Normal);
	}

	float GetPaddleWidthAtDistanceFromPivot(float Distance) const
	{
		if(Distance < 0)
			return PivotRadius;

		if(Distance > PaddleLength)
			return TipRadius;

		const float Alpha = Distance / PaddleLength;
		return Math::Lerp(PivotRadius, TipRadius, Alpha);
	}

	float GetPaddleLaunchSpeedAtDistanceFromPivot(EPinballBallType BallType, float Distance, bool bTop) const
	{
		if(Distance < 0)
			return 0;

		const FPinballPaddleLaunchSettings& Settings = GetLaunchSettings(BallType);

		const float Alpha = Math::Saturate(Distance / PaddleLength);
		const float Multiplier = Settings.GetForceOverLengthCurve(bTop).GetFloatValue(Alpha);
		const float LaunchSpeed = Settings.GetPaddleImpulse(bTop) * Multiplier;

		return LaunchSpeed;
	}

	float GetPaddlePositionAlpha() const
	{
		return Math::NormalizeToRange(RelativeRotation.Pitch, GetRelativeAngle(EPinballPaddleTransformType::Bottom), GetRelativeAngle(EPinballPaddleTransformType::Top));
	}

	FVector GetPaddleNormal(EPinballBallType BallType, float Distance, float Angle, bool bTop) const
	{
		float LaunchAngle = 0;

		const FPinballPaddleLaunchSettings& Settings = GetLaunchSettings(BallType);

		if(Settings.bUseLaunchDirectionOverLength)
		{
			const float Alpha = Math::Saturate(Distance / PaddleLength);
			LaunchAngle += Settings.GetLaunchDirectionOverLengthCurve(bTop).GetFloatValue(Alpha);
		}

		if(Settings.bUseLaunchDirectionOverAngle)
		{
			const float Alpha = Math::NormalizeToRange(Angle, GetRelativeAngle(EPinballPaddleTransformType::Bottom), GetRelativeAngle(EPinballPaddleTransformType::Top));
			LaunchAngle += Settings.GetLaunchDirectionOverAngleCurve(bTop).GetFloatValue(Alpha);
		}

		if(bIsLeft)
			LaunchAngle *= -1;

		if(!bTop)
			LaunchAngle *= -1;

		FQuat LaunchRotation = FQuat(-FVector::ForwardVector, Math::DegreesToRadians(LaunchAngle));

		if(bTop)
			return LaunchRotation.UpVector;
		else
			return -LaunchRotation.UpVector;
	}

	void DebugDraw() const
	{
		DrawPaddle(EPinballPaddleTransformType::Top, FLinearColor::Blue);
		DrawPaddle(EPinballPaddleTransformType::Bottom, FLinearColor::LucBlue);
		DrawPaddle(EPinballPaddleTransformType::CurrentTransform, FLinearColor::Black);
	}

	private void DrawPaddle(EPinballPaddleTransformType TransformType, FLinearColor Color) const
	{
		const FTransform PaddleTransform = GetPaddleWorldTransform(GetRelativeAngle(TransformType));

		// Draw Pivot
		Debug::DrawDebugArc(180, PaddleTransform.Location, PivotRadius, -PaddleTransform.Rotation.ForwardVector, Color, 3, PaddleTransform.Rotation.RightVector);

		// Draw Tip
		const FVector TipLocation = PaddleTransform.Location + PaddleTransform.Rotation.ForwardVector * PaddleLength;
		Debug::DrawDebugArc(180, TipLocation, TipRadius, PaddleTransform.Rotation.ForwardVector, Color, 3, PaddleTransform.Rotation.RightVector);

		// Draw lines
		const FVector LineStartUp = PaddleTransform.Location + PaddleTransform.Rotation.UpVector * PivotRadius;
		const FVector LineEndUp = TipLocation + PaddleTransform.Rotation.UpVector * TipRadius;
		Debug::DrawDebugLine(LineStartUp, LineEndUp, Color);

		const FVector LineStartDown = PaddleTransform.Location - PaddleTransform.Rotation.UpVector * PivotRadius;
		const FVector LineEndDown = TipLocation - PaddleTransform.Rotation.UpVector * TipRadius;
		Debug::DrawDebugLine(LineStartDown, LineEndDown, Color);
	}
};

#if EDITOR
class UPinballPaddleComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPinballPaddleComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		const UPinballPaddleComponent PaddleComp = Cast<UPinballPaddleComponent>(Component);
		if(PaddleComp == nullptr)
			return;

		float TopAngle = PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Top);
		float BotAngle = PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Bottom);
		DrawPaddle(PaddleComp, FLinearColor::Blue, false, TopAngle);
		DrawPaddle(PaddleComp, FLinearColor::LucBlue, !PaddleComp.bSimulateHit, BotAngle);

		DrawCircle(PaddleComp.WorldLocation, PaddleComp.PaddleCullDistance, FLinearColor::Yellow, 3, FVector::ForwardVector);

		if(PaddleComp.bSimulateHit)
		{
			if(PaddleComp.bSquishPlayerIfUnder && !PaddleComp.bSimulateHitTop)
				DrawCircle(PaddleComp.WorldLocation, PaddleComp.SquishDistance, FLinearColor::Yellow, 1, FVector::ForwardVector);

			const APinballPaddle PaddleActor = Cast<APinballPaddle>(PaddleComp.Owner);
			if(PaddleActor != nullptr)
				SimulateHit(PaddleActor);
		}

		FVector TipLocation = PaddleComp.GetCenterTip(PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Bottom));

		Pinball::DrawAutoAims(this, TipLocation, PaddleComp.AutoAimTargets);
	}

	private void DrawPaddle(const UPinballPaddleComponent PaddleComp, FLinearColor Color, bool bDrawArrows, float Angle, bool bTop = true) const
	{
		FTransform PaddleTransform = PaddleComp.GetPaddleWorldTransform(Angle);

		// Draw Pivot
		DrawArc(PaddleTransform.Location, 180, PaddleComp.PivotRadius, -PaddleTransform.Rotation.ForwardVector, Color, 0, PaddleTransform.Rotation.RightVector);

		// Draw Tip
		FVector TipLocation = PaddleComp.GetCenterTip(Angle);
		DrawArc(TipLocation, 180, PaddleComp.TipRadius, PaddleTransform.Rotation.ForwardVector, Color, 0, PaddleTransform.Rotation.RightVector);

		// Draw lines
		const FVector LineStartUp = PaddleTransform.Location + PaddleTransform.Rotation.UpVector * PaddleComp.PivotRadius;
		const FVector LineEndUp = TipLocation + PaddleTransform.Rotation.UpVector * PaddleComp.TipRadius;
		DrawLine(LineStartUp, LineEndUp, Color);

		const FVector LineStartDown = PaddleTransform.Location - PaddleTransform.Rotation.UpVector * PaddleComp.PivotRadius;
		const FVector LineEndDown = TipLocation - PaddleTransform.Rotation.UpVector * PaddleComp.TipRadius;
		DrawLine(LineStartDown, LineEndDown, Color);

		if(bDrawArrows)
		{
            FVector ArrowsStart = PaddleComp.bSimulateHitTop ? LineStartUp : LineStartDown;
            FVector ArrowsEnd = PaddleComp.bSimulateHitTop ? LineEndUp : LineEndDown;

			const int Resolution = 20;
			for(int i = 0; i <= Resolution; i++)
			{ 
				const float Alpha = (i / float(Resolution));
				const float Distance = Alpha * PaddleComp.PaddleLength;

				const FVector Normal = PaddleComp.GetPaddleNormal(PaddleComp.SimulateBallType, Distance, Angle, PaddleComp.bSimulateHitTop);
				const FVector ArrowStart = Math::Lerp(ArrowsStart, ArrowsEnd, Alpha);
				float Force = PaddleComp.GetPaddleLaunchSpeedAtDistanceFromPivot(PaddleComp.SimulateBallType, Distance, bTop);
				DrawArrow(ArrowStart, ArrowStart + (Normal * Force * 0.1), Color, 5);
			}

			if(PaddleComp.bAllowTipHits)
			{
				const int TipResolution = 5;
				for(int i = 0; i <= TipResolution; i++)
				{ 
					const float Alpha = (i / float(TipResolution));
					float TipAngle = Alpha * (PI * 0.5);

					if(!bTop)
						TipAngle *= -1;

					FVector Normal = PaddleTransform.TransformRotation(FQuat(FVector::RightVector, TipAngle)).UpVector;

					if(!bTop)
						Normal *= -1;

					const FPinballPaddleLaunchSettings& Settings = PaddleComp.GetLaunchSettings(PaddleComp.SimulateBallType);
					const FVector ArrowStart = PaddleComp.GetCenterTip(Angle) + (Normal * PaddleComp.TipRadius);
					float Force = Settings.GetPaddleImpulse(bTop);
					DrawArrow(ArrowStart, ArrowStart + (Normal * Force * 0.1), FLinearColor::Yellow, 5);
				}
			}
		}
	}

	private void SimulateHit(const APinballPaddle PaddleActor)
	{
		const UPinballPaddleComponent PaddleComp = PaddleActor.PaddleComp;
		const bool bTop = PaddleComp.bSimulateHitTop;

		const FVector PlayerLocation = PaddleComp.AttachParent.WorldTransform.TransformPositionNoScale(GetSimulatedPlayerLocation(PaddleComp));
		const float  FlipperAngleTop = PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Top);
		const float FlipperAngleBottom = PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Bottom);

		const float FlipperAngleStart = bTop ? FlipperAngleBottom : FlipperAngleTop;
		const float FlipperAngleEnd = bTop ? FlipperAngleTop : FlipperAngleBottom;
		
		// // Back Start Plane
		// FVector Origin;
		// FVector Normal;
		// PaddleComp.GetFrontPlane(FlipperAngleStart, bTop, Origin, Normal);
		// DrawPlane(Origin - Normal * (PaddleComp.StartExtraSweepDistance), Normal, FLinearColor::Red);

		// // Front End Plane
		// PaddleComp.GetFrontPlane(FlipperAngleEnd, bTop, Origin, Normal);
		// DrawPlane(Origin + Normal * (PaddleComp.EndExtraSweepDistance), Normal, FLinearColor::Green);

		FPinballPaddleHitResult PaddleHitResult;
		if(!PaddleActor.SweepForBall(
			PaddleComp.SimulateBallType,
			PlayerLocation,
			MagnetDrone::Radius,
			FlipperAngleStart,
			FlipperAngleEnd,
			bTop,
			PaddleHitResult))
		{
			// No hit
			DrawWireSphere(PlayerLocation, 39, FLinearColor::Red, 3);
			return;
		}

		if(PaddleHitResult.bSquish)
		{
			DrawWireSphere(PlayerLocation, 39, FLinearColor::Yellow, 3);
			DrawWorldString("Squished!", PlayerLocation, FLinearColor::Yellow, 2);
			return;
		}

		DrawArrow(PlayerLocation, PlayerLocation + PaddleHitResult.LaunchDirection * 500, FLinearColor::Red, 20, 3, true);

		DrawPaddle(PaddleComp, FLinearColor::Green, true, PaddleHitResult.HitAngle, PaddleComp.bSimulateHitTop);

		FVector Impulse = PaddleActor.GetVelocityFromHit(PaddleComp.SimulateBallType, PlayerLocation, bTop, PaddleHitResult);

		DrawWireSphere(PlayerLocation, MagnetDrone::Radius, FLinearColor::Green, 3);
		DrawWorldString(f"Impulse: {Impulse.Size()}", PlayerLocation + FVector::UpVector * 50, FLinearColor::White);

		bool bHasAutoAim = PaddleHitResult.AutoAimTargetData.IsValid();
		FLinearColor DrawColor = bHasAutoAim ? FLinearColor::LucBlue : FLinearColor::Green;

		Pinball::AirMoveSimulation::VisualizePath(this, PlayerLocation, Impulse, PaddleActor.LauncherComp, PaddleComp.SimulatedInput, DrawColor, PaddleComp.SimulationDuration, 1.0 / PaddleComp.SimulationFPS);

		if(PaddleComp.bTestFramerateDependency)
		{
			const float DeltaTime = Math::GetMappedRangeValueClamped(FVector2D(-1, 1), FVector2D(0.005, 0.1), Math::Sin(Time::RealTimeSeconds));
			Log("Pinball Paddle DeltaTime:"+DeltaTime);
			Pinball::AirMoveSimulation::VisualizePath(this, PlayerLocation, Impulse, PaddleActor.LauncherComp, PaddleComp.SimulatedInput, FLinearColor::Red, PaddleComp.SimulationDuration, DeltaTime);
		}
	}

	FVector GetSimulatedPlayerLocation(const UPinballPaddleComponent PaddleComp) const
	{
		return FVector(0, 0, PaddleComp.PivotRadius) + FQuat(FVector::RightVector, Math::DegreesToRadians(-PaddleComp.SimulatedPlayerAngle)).ForwardVector * PaddleComp.SimulatedPlayerDistance;
	}

	private void DrawPlane(FVector Origin, FVector Normal, FLinearColor Color) const
	{
		DrawWireBox(Origin, FVector(0, 300, 0), FQuat::MakeFromZ(Normal), Color);
		DrawArrow(Origin, Origin + Normal * 100, Color);
	}
};
#endif