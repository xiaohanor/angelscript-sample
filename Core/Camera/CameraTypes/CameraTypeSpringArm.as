#if TEST
//const FConsoleVariable CVar_SpringArmCollisionTest("Haze.SpringArmCollisionTest", 0);
const FConsoleVariable CVar_SpringArmForceIdealDistance("Haze.SpringArmForceIdealDistance", 0);
//const FConsoleVariable CVar_SpringArmForceMinTraceBlockedRange("Haze.SpringArmForceMinTraceBlockedRange", 0);
#endif

//const FConsoleVariable CVar_SpringArmUsePrediction("Haze.SpringArmUsePrediction", 0);

enum ECameraSpringArmCollisionResolveType
{
	MoveInCloser,
	PreferMoveUp,
	PreferPitchDown
}

enum ECameraCollisionType
{
	NoCollision,

	// The camera must stop at this collision
	HardCollision,

	// The camera can see through this collision
	SeeTroughCollision
}

struct FSpringArmObstruction
{
	FVector Front = FVector(BIG_NUMBER);
	FVector Back = FVector(BIG_NUMBER);
	FSpringArmObstruction(const FVector& Location)
	{
		Front = Location;
	}
}

struct FCameraUserValuesOverTime
{
	FInstigator Instigator;
	FTransform InitialTransform;
	float Time = 0;
	float TimeToTeach = 0;
	UCurveFloat AlphaModifier = nullptr;
	float LastAppliedAlpha = 0;

	float GetAlpha() const property
	{
		float FinalAlpha = Math::Min(Time / TimeToTeach, 1);
		if(AlphaModifier != nullptr)
			FinalAlpha = AlphaModifier.GetFloatValueNormalized(FinalAlpha);
		return FinalAlpha;
	}
}

struct FSpringArmAccelerationDurationData
{
	float Value;
	FHazeAcceleratedFloat AccMul;
	bool bIsLocked = false;
}



struct FSpringArmUserData
{
	FVector PreviousPivotLocation;
	FVector PreviousViewLocation;
	FHazeAcceleratedRotator PreviousDesiredLocalRotation;

	FSpringArmAccelerationDurationData PivotAccelerationDurationX;
	FSpringArmAccelerationDurationData PivotAccelerationDurationY;
	FSpringArmAccelerationDurationData PivotAccelerationDurationZ;
	
	FHazeAcceleratedVector MaxPivotLag;
	FVector AccPivotWorldVelocity;

	FHazeAcceleratedFloat PivotAccelerationLerpAlphaX;
	FHazeAcceleratedFloat PivotAccelerationLerpAlphaY;
	FHazeAcceleratedFloat PivotAccelerationLerpAlphaZ;

	FHazeAcceleratedFloat InheritedMovementVelocityLerpAlpha;

	float TargetArmLengthIdealDistance = 0;
	FHazeAcceleratedFloat ArmLengthMultiplier;
	bool bAccelerateArmLength = false;
}

struct FSpringArmUserSettings
{
	float RotationSpeedOverride = -1;
	float ObstructedClearance = 0;

	bool bInheritMovement = false;
	float InheritMovementAccelerationTime = 0;
	float PivotOwnerRotationAccelerationDuration = 0;
	float ArmLengthAccelerationSpeed = 0.0;
	float VerticalBonusTraceDistance = 0;

	FVector ActorScale = FVector::OneVector;
	FVector ActorCollisionCenterLocation;
	float ActorCollisionRadius = 0;
	bool bHasView = false;
	FVector PivotVelocity = FVector::ZeroVector;
	FRotator ViewAngularVel = FRotator::ZeroRotator;
	//FRotator CurrentCameraRotation = FRotator::ZeroRotator;
	bool bIsUsingGamePad = true;
	bool bUseCameraTrace = false;
	bool bUseCameraTunnelTrace = false;
	FVector PivotTraceOriginOffset;

	UCurveFloat CameraOffsetOwnerSpaceByPitchCurve = nullptr;
	UCurveFloat CameraOffsetByPitchCurve = nullptr;
	UCurveFloat PivotHeightByPitchCurve = nullptr;
	UCurveFloat IdealDistanceByPitchCurve = nullptr;
	UCurveFloat PivotLagMaxMultiplierByPitchCurve = nullptr;

	FVector PivotAccelerationDurationAlphaTarget = FVector::OneVector;
	float PivotAccelerationDurationAlphaDuration = 0;
	float ArmLengthAccelerationDuration = 0;
	float ScreenHeight = 0;
}

struct FSpringArmUpdateAlphaData
{
	float Duration = 0;
	FVector Target = FVector::OneVector;
	uint AddedFrame = 0;

	FInstigator Instigator;
	EInstigatePriority Priority = EInstigatePriority::Low;
}

struct FSpringArmTraceResult
{
	ECameraCollisionType ImpactType = ECameraCollisionType::NoCollision;
	FHitResult Impact;
	FHitResult TunnelImpact;

	FVector ImpactOffset;

	bool HasHardCollision() const
	{
		return ImpactType == ECameraCollisionType::HardCollision;
	}

	bool HasSeeTroughCollision() const
	{
		return ImpactType == ECameraCollisionType::SeeTroughCollision;
	}
}

/**
 * 
 */
#if EDITOR
class USpringArmCameraVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USpringArmCamera;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Camera = Cast<USpringArmCamera>(Component);
		Camera.VisualizeCameraEditorPreviewLocation(this);
	}
}
#endif

/**
 * 
 */
UCLASS(NotBlueprintable)
class USpringArmCamera : UHazeCameraComponent
{
	default CameraUpdaterType = UCameraSpringArmUpdater;
	default bHasSpringArmSettings = true;
	default bWantsCameraInput = true;

	/** Should only be used if you want the camera to turn different than the user has specified in the settings menu */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationSpeedOverride = -1;

	/**	When obstructed, camera needs to be at least this far away from the other side of the obstruction 
	or it will be moved to the near side of the obstruction.  */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float ObstructedClearance = 64.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector PivotTraceOriginOffset;

	private TArray<FSpringArmUpdateAlphaData> PivotAxisUpdateAlpha;
	// We must have a default value
	default PivotAxisUpdateAlpha.Add(FSpringArmUpdateAlphaData());
	private int PivotUpdateAlphaIndex = 0;

	void AddPivotAxisBlock(bool bXAxis, bool bYAxis, bool bZAxis, FInstigator Instigator, float Duration = 0, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		FVector TargetValue = FVector::OneVector;
		if(bXAxis)
			TargetValue.X = 0;
		if(bYAxis)
			TargetValue.Y = 0;
		if(bZAxis)
			TargetValue.Z = 0;
		
		int FoundIndex = -1;
		for(int i = 0; i < PivotAxisUpdateAlpha.Num(); ++i)
		{
			if(PivotAxisUpdateAlpha[i].Instigator == Instigator)
			{
				FoundIndex = i;
				break;
			}
		}

		if(FoundIndex < 0)
		{
			FSpringArmUpdateAlphaData NewIndex;
			NewIndex.Instigator = Instigator;
			PivotAxisUpdateAlpha.Add(NewIndex);
			FoundIndex = PivotAxisUpdateAlpha.Num() - 1;
		}

		FSpringArmUpdateAlphaData& IndexValue = PivotAxisUpdateAlpha[FoundIndex];
		IndexValue.Priority = Priority;
		IndexValue.AddedFrame = Time::FrameNumber;
		IndexValue.Target = TargetValue;
		IndexValue.Duration = Duration;

		PivotUpdateAlphaIndex = FindPivotUpdateAlphaIndex();
	}

	void RemovePivotAxisBlock(FInstigator Instigator, float Duration = 0)
	{
		int FoundIndex = -1;
		for(int i = PivotAxisUpdateAlpha.Num() - 1; i >= 0; --i)
		{
			if(PivotAxisUpdateAlpha[i].Instigator == Instigator)
			{
				FoundIndex = i;
				PivotAxisUpdateAlpha.RemoveAtSwap(i);
				break;
			}
		}

		if(FoundIndex < 0)
			return;

		PivotUpdateAlphaIndex = FindPivotUpdateAlphaIndex();
		PivotAxisUpdateAlpha[PivotUpdateAlphaIndex].Duration = Duration;
	}

	private int FindPivotUpdateAlphaIndex() const
	{
		if(PivotAxisUpdateAlpha.Num() == 1)
			return 0;

		EInstigatePriority HighestPriority = EInstigatePriority::Low;
		uint HighestFrameNumber = 0;

		int FoundIndex = -1;
		for(int i = 0; i < PivotAxisUpdateAlpha.Num(); ++i)
		{
			if(PivotAxisUpdateAlpha[i].Priority > HighestPriority)
			{
				FoundIndex = i;
				HighestPriority = PivotAxisUpdateAlpha[i].Priority;
				HighestFrameNumber = PivotAxisUpdateAlpha[i].AddedFrame;
			}
			else if(PivotAxisUpdateAlpha[i].Priority == HighestPriority
				&& PivotAxisUpdateAlpha[i].AddedFrame > HighestFrameNumber)
			{
				FoundIndex = i;
				HighestFrameNumber = PivotAxisUpdateAlpha[i].AddedFrame;
			}
		}

		return FoundIndex;
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto SpringArmData = Cast<UCameraSpringArmUpdater>(CameraData);

		FSpringArmUserSettings& UserData = SpringArmData.UserSettings;
		UserData.RotationSpeedOverride = RotationSpeedOverride;
		UserData.ObstructedClearance = ObstructedClearance;
		UserData.PivotTraceOriginOffset = PivotTraceOriginOffset;

		#if EDITOR
		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			FTransform ViewTransform;
			float EditorFOV = 70;
			GetEditorPreviewTransform(ViewTransform, EditorFOV);
			//UserData.CurrentCameraRotation = ViewTransform.Rotator();

			FSpringArmUserData& SpringArmDataSettings = SpringArmData.SpringArmData;
			SpringArmDataSettings.PivotAccelerationDurationX.AccMul.SnapTo(1);
			SpringArmDataSettings.PivotAccelerationDurationY.AccMul.SnapTo(1);
			SpringArmDataSettings.PivotAccelerationDurationZ.AccMul.SnapTo(1);
		}
		else
		#endif
		{
			auto User = Cast<UCameraUserComponent>(HazeUser);

			auto HazeOwner = Cast<AHazeActor>(HazeUser.Owner);
			UserData.ActorScale = HazeOwner.ActorScale3D;
			UserData.bIsUsingGamePad = HazeUser.IsUsingGamepad();
			UserData.ViewAngularVel = HazeUser.GetViewAngularVelocity();
			UserData.PivotVelocity = HazeUser.GetOwnerRawLastFrameTranslationVelocity();
			UserData.bHasView = HazeUser.HasAnyViewSize();

			auto Collision = UShapeComponent::Get(HazeOwner);
			UserData.ActorCollisionCenterLocation = Collision.WorldLocation;
			UserData.ActorCollisionRadius = (Collision.GetBoundsOrigin() - CameraTransform.UserLocation).Size();
			
			auto InheritMovementSettings = UCameraInheritMovementSettings::GetSettings(HazeOwner);

			UserData.bInheritMovement = InheritMovementSettings.bInheritMovement;
			UserData.InheritMovementAccelerationTime = InheritMovementSettings.InheritMovementAccelerationTime;
			
			auto UserSettings = UCameraUserSettings::GetSettings(HazeOwner);
			UserData.PivotOwnerRotationAccelerationDuration = UserSettings.PivotOwnerRotationAccelerationDuration;
			UserData.CameraOffsetOwnerSpaceByPitchCurve = UserSettings.CameraOffsetOwnerSpaceByPitchCurve;
			UserData.CameraOffsetByPitchCurve = UserSettings.CameraOffsetByPitchCurve;
			UserData.PivotHeightByPitchCurve = UserSettings.PivotHeightByPitchCurve;
			UserData.IdealDistanceByPitchCurve = UserSettings.IdealDistanceByPitchCurve;
			UserData.PivotLagMaxMultiplierByPitchCurve = UserSettings.PivotLagMaxMultiplierByPitchCurve;
			UserData.PivotAccelerationDurationAlphaTarget = PivotAxisUpdateAlpha[PivotUpdateAlphaIndex].Target;
			UserData.PivotAccelerationDurationAlphaDuration = PivotAxisUpdateAlpha[PivotUpdateAlphaIndex].Duration;
			UserData.ArmLengthAccelerationSpeed = UserSettings.ExtensionDurationAfterBlock;
			UserData.bUseCameraTrace = UserSettings.bAllowCameraTrace;
			UserData.bUseCameraTunnelTrace = UserSettings.bAllowCameraTunnelTrace;

			FSpringArmUserData& SpringArmDataSettings = SpringArmData.SpringArmData;
			if(CameraData.FunctionType == EHazeCameraFunctionType::SnapWithReset)
			{
				// We don't follow movement the first frame.
				UserData.bInheritMovement = false;
				SpringArmDataSettings.bAccelerateArmLength = false;
				SpringArmDataSettings.PivotAccelerationDurationX.AccMul.SnapTo(1);
				SpringArmDataSettings.PivotAccelerationDurationY.AccMul.SnapTo(1);
				SpringArmDataSettings.PivotAccelerationDurationZ.AccMul.SnapTo(1);
			}

			// Camera assist
			auto Assist = UCameraAssistComponent::Get(User.Owner);
			if(Assist != nullptr)
			{
				SpringArmData.AssistSettings = Assist.ActiveAssistSettings;
			}
		}
	}	

	FBox GenerateNearPlaneCollisionBox(AHazePlayerCharacter Player) const
	{
		FVector TempDir;

		FVector WorldTopLeft = FVector::ZeroVector;
		SceneView::DeprojectScreenToWorld_Relative(Player, FVector2D(0,0), WorldTopLeft, TempDir);
	
		FVector WorldTopRight = FVector::ZeroVector;
		SceneView::DeprojectScreenToWorld_Relative(Player, FVector2D(1,0), WorldTopRight, TempDir);

		FVector WorldBottomLeft = FVector::ZeroVector;
		SceneView::DeprojectScreenToWorld_Relative(Player, FVector2D(0,1), WorldBottomLeft, TempDir);
	
		FRotator MakeRotation = FRotator::MakeFromYZ(WorldTopRight - WorldTopLeft, WorldTopLeft - WorldBottomLeft);

		WorldBottomLeft = MakeRotation.UnrotateVector(WorldBottomLeft);
		WorldTopRight = MakeRotation.UnrotateVector(WorldTopRight);

		return FBox(WorldBottomLeft, WorldTopRight);
	}
}

/**
 * 
 */
UCLASS(NotBlueprintable)
class UCameraSpringArmUpdater : UHazeCameraUpdater
{
	FSpringArmUserData SpringArmData;
	FSpringArmUserSettings UserSettings;

	FCameraAssistSettingsData AssistSettings;
	FHazeActiveCameraAssistData AssistData;

	#if TEST
	TArray<FVector> OffsetPositions;
	default OffsetPositions.SetNumZeroed(5);
	FVector ArmDirection = FVector::ZeroVector;
	#endif

	UFUNCTION(BlueprintOverride)
	protected void Copy(const UHazeCameraUpdater SourceBase)
	{
		auto Source = Cast<UCameraSpringArmUpdater>(SourceBase);
		SpringArmData = Source.SpringArmData;
		UserSettings = Source.UserSettings;
		// AssistType = Source.AssistType;
		// PreviousAssistType = Source.PreviousAssistType;
		AssistSettings = Source.AssistSettings;
		AssistData = Source.AssistData;
	}

	UFUNCTION(BlueprintOverride)
	protected void OnCameraSnap(FHazeCameraTransform& OutResult)
	{
		// To avoid initial pivot lag when camera is snapped, match pivot velocity with owner velocity
		SpringArmData.AccPivotWorldVelocity = UserSettings.PivotVelocity;
		AssistData = FHazeActiveCameraAssistData();

		// During snaps we start at where we want to be
		UpdatePivotLag(0);
		UpdateInheritedMovementVelocity(0, OutResult);
		UpdateViewRotation(0, OutResult);
		UpdatePivotLocation(0, OutResult);
		UpdateViewLocation(false, 0, OutResult);	
		
	}
	
	UFUNCTION(BlueprintOverride)
	protected void OnCameraUpdate(float DeltaTime, FHazeCameraTransform& OutResult)
	{
		UpdatePivotLag(DeltaTime);
		UpdateInheritedMovementVelocity(DeltaTime, OutResult);
		UpdateAssist(DeltaTime, OutResult);
		UpdateViewRotation(DeltaTime, OutResult);
		UpdatePivotLocation(DeltaTime, OutResult);
		UpdateViewLocation(UserSettings.bHasView, DeltaTime, OutResult);
	}

	UFUNCTION(BlueprintOverride)
	protected void DebugLogUpdater()
	{
	#if !RELEASE
		FVector From = OffsetPositions[0];
		FVector To = From + OffsetPositions[1];
		TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryUpdater};PivotOffset:", From, OffsetPositions[1], Color = FLinearColor::Red);
		
		From = To;	
		To = From + OffsetPositions[2];
		TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryUpdater};WorldPivotOffset:", From, OffsetPositions[2], Color = FLinearColor::Yellow);

		From = To;
		const FVector ArmOffset = (ArmDirection * SpringArmData.TargetArmLengthIdealDistance * SpringArmData.ArmLengthMultiplier.Value);
		To = From + ArmOffset;
		TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryUpdater};ArmOffset:", From, ArmOffset, Color = FLinearColor::Blue);

		From = To;	
		To = From + OffsetPositions[3];
		TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryUpdater};OwnerSpaceOffset:", From, OffsetPositions[3], Color = FLinearColor::DPink);

		From = To;	
		To = From + OffsetPositions[4];
		TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryUpdater};CameraOffset:", From, OffsetPositions[4], Color = FLinearColor::Green);

		if(AssistSettings.AssistType != nullptr)
		{
			TemporalLog.Value(f"{CameraDebug::CategoryUpdater};Assist:", AssistSettings.AssistType);
		}
	#endif
	}

	protected void UpdateViewRotation(float DeltaTime, FHazeCameraTransform& OutResult)
	{
		// Add rotation delta from inherited movement
		OutResult.AddLocalDesiredDeltaRotation(OutResult.UserMovementRotationDelta);

		//const FRotator CurrentRotation = UserSettings.CurrentCameraRotation;
		FRotator NewRot = GetFinalWorldRotation(OutResult.WorldDesiredRotation, DeltaTime);
		OutResult.ViewRotation = NewRot;
	}

	protected FRotator GetFinalWorldRotation(FRotator To, float DeltaTime)
	{
		const FRotator CurrentLocalRotation = ClampLocalRotation(SpringArmData.PreviousDesiredLocalRotation.Value);
		const FRotator ClampedTargetRotation = ClampLocalRotation(WorldToLocalRotation(To));

		// We never lerp the spring-arm when using mouse input
		if(DeltaTime < SMALL_NUMBER || !UserSettings.bIsUsingGamePad)
		{
			SpringArmData.PreviousDesiredLocalRotation.SnapTo(ClampedTargetRotation);
			FRotator FinalRotation = LocalToWorldRotation(ClampedTargetRotation);
			return FinalRotation;
		}
		
		float Duration = UserSettings.RotationSpeedOverride;
		if(Duration > 0)
			Duration = 1.0 / Duration;
		else if(Math::Abs(Duration) < KINDA_SMALL_NUMBER)
			return LocalToWorldRotation(CurrentLocalRotation);
		else
			Duration = 1.0/240.0; // 240 fps

		SpringArmData.PreviousDesiredLocalRotation.AccelerateTo(ClampedTargetRotation, Duration, DeltaTime);
		FRotator FinalRotation = SpringArmData.PreviousDesiredLocalRotation.Value;
		FinalRotation = LocalToWorldRotation(FinalRotation);
		return FinalRotation;


		// OLD WAY!
		// I am keeping it until I am sure the new way works

		// float Speed = Math::Max(UserSettings.RotationSpeedOverride, 0);

		// // TODO: Use acceleration instead of interpolation
		// // Substepping to reduce twitches
		// FRotator Rot = From;
		// const float SubStepDuration = 1.0/240.0; // 240 fps
		// float SubsteppedTime = 0.0;
		// for (; SubsteppedTime < DeltaTime - SubStepDuration; SubsteppedTime += SubStepDuration)
		// {
		// 	Rot = Math::RInterpTo(Rot, To, SubStepDuration, Speed);
		// 	Rot = ClampWorldRotation(Rot);
		// } 

		// if (DeltaTime - SubsteppedTime > 0.0)
		// {
		// 	Rot = Math::RInterpTo(Rot, To, DeltaTime - SubsteppedTime, Speed);
		// 	Rot = ClampWorldRotation(Rot);
		// }

		// return Rot;
	}

	protected void UpdatePivotLag(float DeltaTime)
	{
		// Accelerate pivot lag acceleration duration, but snap to negative in either axis
		{
			const FVector DurationTarget = CameraSettings.PivotLagAccelerationDuration;
		
			UpdateAccelerationDuration(SpringArmData.PivotAccelerationDurationX, DurationTarget.X, DeltaTime);
			UpdateAccelerationDuration(SpringArmData.PivotAccelerationDurationY, DurationTarget.Y, DeltaTime);
			UpdateAccelerationDuration(SpringArmData.PivotAccelerationDurationZ, DurationTarget.Z, DeltaTime);
		}

		// Accelerate the pivot alpha to the target.
		// The pivot alpha allows us to make the pivot location stay at the previous location
		{
			const FVector DurationTarget = UserSettings.PivotAccelerationDurationAlphaTarget;
			UpdateAccelerationAlpha(SpringArmData.PivotAccelerationLerpAlphaX, DurationTarget.X, DeltaTime);
			UpdateAccelerationAlpha(SpringArmData.PivotAccelerationLerpAlphaY, DurationTarget.Y, DeltaTime);
			UpdateAccelerationAlpha(SpringArmData.PivotAccelerationLerpAlphaZ, DurationTarget.Z, DeltaTime);
		}

		// Accelerate pivot maximum lag when decreasing, snap when increasing
		const FVector PivotLagMax = GetPivotLagMaxSettingsValue();
		SpringArmData.MaxPivotLag.AccelerateTo(PivotLagMax, 0.5, DeltaTime);			
		
		SnapPivotLagMax(PivotLagMax.X, SpringArmData.MaxPivotLag.Value.X, SpringArmData.MaxPivotLag.Velocity.X);
		SnapPivotLagMax(PivotLagMax.Y, SpringArmData.MaxPivotLag.Value.Y, SpringArmData.MaxPivotLag.Velocity.Y);
		SnapPivotLagMax(PivotLagMax.Z, SpringArmData.MaxPivotLag.Value.Z, SpringArmData.MaxPivotLag.Velocity.Z);
	}

	protected FVector GetPivotLagMaxSettingsValue() const
	{
		FVector CurrentValue = CameraSettings.PivotLagMax;
		CurrentValue *= GetCurveValue(UserSettings.PivotLagMaxMultiplierByPitchCurve, LocalPitch, 1.0);
		CurrentValue *= CameraSettings.PivotLagMaxMultiplier;
		return CurrentValue;
	}

	void UpdateInheritedMovementVelocity(float DeltaTime, const FHazeCameraTransform& OutResult)
	{
		if (Math::IsNearlyZero(DeltaTime))
		{
			SpringArmData.InheritedMovementVelocityLerpAlpha.SnapTo(0);
		}
		else
		{
			float Target = OutResult.UserMovementDelta.IsNearlyZero() ? 0.0 : 1.0;
			SpringArmData.InheritedMovementVelocityLerpAlpha.AccelerateToWithStop(Target, UserSettings.InheritMovementAccelerationTime, DeltaTime, 0.01);
		}
	}

	protected void UpdatePivotLocation(float DeltaTime, FHazeCameraTransform& OutResult)
	{
		// We now use the view rotation instead instead of the actor rotation for pivot lag
		// since that will reduce the amount of wobbliness when the player turns
		// and make it easier to tweak the lag max value since X now is in the cameras forward.
		// We ignore the modifiers so we get a smooth offset only based on the camera rotation
		const FRotator HorizontalViewRotation = FRotator::MakeFromZX(OutResult.PivotRotation.UpVector, OutResult.ViewRotation.ForwardVector);
		const FTransform OwnerTransform = FTransform(HorizontalViewRotation, OutResult.PivotLocation);
		const FVector OriginalPivot = OutResult.PivotTransform.TransformPosition(UserSettings.PivotTraceOriginOffset);

		#if TEST
		OffsetPositions[0] = OriginalPivot;
		#endif
		
		const float ExtraPivotHeight = GetCurveValue(UserSettings.PivotHeightByPitchCurve, LocalPitch, 0) * CameraSettings.PivotHeightByPitchCurveAlpha;
		const FVector LocalPivotOffset = CameraSettings.PivotOffset + FVector(0.0, 0.0, ExtraPivotHeight);
		const FVector WorldPivotOffset = CameraSettings.WorldPivotOffset;

		FVector LocalTarget = OwnerTransform.InverseTransformPosition(OutResult.PivotTransform.Location);
		LocalTarget += LocalPivotOffset + OwnerTransform.InverseTransformVector(WorldPivotOffset);

		bool bPivotObstructed = false;
		FHitResult PivotObstruction;
		FVector WorldTarget = OwnerTransform.TransformPosition(LocalTarget);

		if(CameraTraceParams.IsCollisionEnabled() && CameraTraceParams.bCheckPivotObstruction)
		{
			// Check if the camera can move from the owner to the pivot, if not, move the pivot to the obstruction location
			// This prevents the pivot from being placed above ceilings in cases where the player can move below the ceiling while the pivot is above
			// TODO: We might only need this while a sphere placed on the pivot is not fully inside the owner collider
			if(!UserSettings.ActorCollisionCenterLocation.Equals(WorldTarget))
			{
				PivotObstruction = CameraTraceParams.QueryTraceSingle(UserSettings.ActorCollisionCenterLocation, WorldTarget, n"PivotObstruction");
				if(PivotObstruction.bBlockingHit)
				{
					if(PivotObstruction.Distance > 0)
						WorldTarget = Math::Lerp(PivotObstruction.TraceStart, PivotObstruction.Location, Math::Max(PivotObstruction.Distance - 1, 0) / PivotObstruction.Distance);
					else
						WorldTarget = PivotObstruction.Location;

					LocalTarget = OwnerTransform.InverseTransformPosition(WorldTarget);
					bPivotObstructed = true;
				}
			}
		}

		FVector LocalPivotVelocity = OwnerTransform.InverseTransformVector(SpringArmData.AccPivotWorldVelocity);
		FVector PreviousLocalPivotLocation = OwnerTransform.InverseTransformPosition(SpringArmData.PreviousPivotLocation);

		// Update pivot axes separately since we might have separate lag acceleration duration and max difference
		FVector UpdatedPivotLoc = LocalTarget;
		UpdatedPivotLoc.X = UpdatePivotAxis(LocalTarget.X, PreviousLocalPivotLocation.X, SpringArmData.PivotAccelerationLerpAlphaX.Value, DeltaTime, SpringArmData.PivotAccelerationDurationX, LocalPivotVelocity.X);
		UpdatedPivotLoc.Y = UpdatePivotAxis(LocalTarget.Y, PreviousLocalPivotLocation.Y, SpringArmData.PivotAccelerationLerpAlphaY.Value, DeltaTime, SpringArmData.PivotAccelerationDurationY, LocalPivotVelocity.Y);
		UpdatedPivotLoc.Z = UpdatePivotAxis(LocalTarget.Z, PreviousLocalPivotLocation.Z, SpringArmData.PivotAccelerationLerpAlphaZ.Value, DeltaTime, SpringArmData.PivotAccelerationDurationZ, LocalPivotVelocity.Z);

		// Inherit movement velocity
		if (UserSettings.bInheritMovement)
		{
			FVector RelativeUserMovementDelta = OwnerTransform.InverseTransformVector(OutResult.UserMovementDelta);
			FVector Target = LocalTarget + RelativeUserMovementDelta * DeltaTime;

			FSpringArmAccelerationDurationData Acceleration();
			Acceleration.Value = UserSettings.InheritMovementAccelerationTime * (1.0 - SpringArmData.InheritedMovementVelocityLerpAlpha.Value);
			UpdatedPivotLoc.X = UpdatePivotAxis(Target.X, UpdatedPivotLoc.X, SpringArmData.InheritedMovementVelocityLerpAlpha.Value, DeltaTime, Acceleration, LocalPivotVelocity.X);
			UpdatedPivotLoc.Y = UpdatePivotAxis(Target.Y, UpdatedPivotLoc.Y, SpringArmData.InheritedMovementVelocityLerpAlpha.Value, DeltaTime, Acceleration, LocalPivotVelocity.Y);
			UpdatedPivotLoc.Z = UpdatePivotAxis(Target.Z, UpdatedPivotLoc.Z, SpringArmData.InheritedMovementVelocityLerpAlpha.Value, DeltaTime, Acceleration, LocalPivotVelocity.Z);
		}

		UpdatedPivotLoc = GetClampedToMaxLag(UpdatedPivotLoc, LocalTarget, SpringArmData.MaxPivotLag.Value);

		SpringArmData.AccPivotWorldVelocity = OwnerTransform.TransformVector(LocalPivotVelocity);
		OutResult.PivotLocation = OwnerTransform.TransformPosition(UpdatedPivotLoc);

		if(bPivotObstructed)
		{
			// If the pivot was obstructed, snap the lag pivot to the hit plane, to prevent the pivot slowly moving through the collision
			SpringArmData.AccPivotWorldVelocity = SpringArmData.AccPivotWorldVelocity.VectorPlaneProject(PivotObstruction.Normal);
			OutResult.PivotLocation = OutResult.PivotLocation.PointPlaneProject(WorldTarget, PivotObstruction.Normal);
		}

		if(CameraTraceParams.IsCollisionEnabled())
		{
			// If we are using collision, pivot needs to be at least
			// the trace shapes radius from the ground
			// or we will always hit the ground when tracing
			const FVector UpVector = OutResult.UserRotation.UpVector;
			const float VerticalOffset = (OutResult.PivotLocation - OriginalPivot).DotProduct(UpVector);
			if(VerticalOffset <= CameraTraceParams.ProbeSize)
			{
				FVector TraceFrom = OriginalPivot + WorldPivotOffset + (UpVector * (CameraTraceParams.ProbeSize + 1));
				if(!TraceFrom.Equals(OutResult.PivotLocation))
				{
					auto TraceResult = CameraTraceParams.QueryTraceSingle(TraceFrom, OutResult.PivotLocation, n"PivotValidationLocation");
					if(TraceResult.IsValidBlockingHit())
						OutResult.PivotLocation = TraceResult.Location + TraceResult.ImpactNormal;
				}
			}

			// FVector HighestPivotPoint = OriginalPivot + (UpVector * (CameraTraceParams.ProbeSize + 0.125));
			// HighestPivotPoint = Math::Lerp(OutResult.PivotLocation, HighestPivotPoint, SpringArmData.PivotGroundedZOffset.Value);
			// const FVector DeltaToWanted = (HighestPivotPoint - OutResult.PivotLocation);
			// const float OffsetAmount = DeltaToWanted.DotProduct(UpVector);
			// OutResult.PivotLocation += UpVector * Math::Max(OffsetAmount, 0);

			// If the pivot is not at the pivot target location, sweep to make sure that the camera can reach the pivot
			if(CameraTraceParams.bCheckPivotObstruction && !WorldTarget.Equals(OutResult.PivotLocation) && !UserSettings.ActorCollisionCenterLocation.Equals(OutResult.PivotLocation))
			{
				auto TraceResult = CameraTraceParams.QueryTraceSingle(UserSettings.ActorCollisionCenterLocation, OutResult.PivotLocation, n"PivotLagObstruction");
				if(TraceResult.bBlockingHit)
				{
					if(TraceResult.Distance > 0)
						OutResult.PivotLocation = Math::Lerp(TraceResult.TraceStart, TraceResult.Location, Math::Max(TraceResult.Distance - 1, 0) / TraceResult.Distance);
					else
						OutResult.PivotLocation = TraceResult.Location;
				}
			}
		}

		SpringArmData.PreviousPivotLocation = OutResult.PivotLocation;

		#if TEST
		OffsetPositions[1] = OutResult.PivotLocation - OffsetPositions[0];
		OffsetPositions[2] = OwnerTransform.InverseTransformVector(WorldPivotOffset);
		
		const FVector DrawOffset = OffsetPositions[1].VectorPlaneProject(YawAxis);
		OffsetPositions[0] += DrawOffset;
		OffsetPositions[1] -= DrawOffset;
		#endif
	}

	protected float UpdatePivotAxis(float Target, float Previous, float Alpha, float DeltaTime, FSpringArmAccelerationDurationData AccDuration, float& InOutVelocity) const
	{
		if(DeltaTime <= 0)
			return Target;

		//float NewLoc = Previous;
		if(AccDuration.bIsLocked || Alpha < SMALL_NUMBER)
		{
			InOutVelocity = 0.0;
			return Previous;
		}
		if (AccDuration.Value < SMALL_NUMBER)
		{
			// No Lag
			InOutVelocity = 0.0;
			return Target;
		}
		else
		{
			// Apply Lag
			FHazeAcceleratedFloat AccPivotLoc;
			AccPivotLoc.SnapTo(Previous, InOutVelocity);
			float FinalTarget = Math::Lerp(Previous, Target, Alpha);
			float NewLoc = AccPivotLoc.AccelerateTo(FinalTarget, AccDuration.Value + AccDuration.AccMul.Value, DeltaTime);
			InOutVelocity = AccPivotLoc.Velocity;
			return NewLoc;
		}
	}

	protected FVector GetClampedToMaxLag(const FVector& PivotLoc, const FVector& TargetLoc, const FVector& MaxLag) const
	{
		FVector ClampedLoc = PivotLoc;
		FVector ToTarget = TargetLoc - PivotLoc;

		// Clamp to elliptical cylinder around target location. For free flying owner it might be nicer to use a spheroid, investigate.
		// Note we don't want to clamp each axis separately (i.e. clamping to within a cuboid) or we can get glitches when owner turns and moves the corners.

		// Clamp x and y if outside cylinder base
		if (Math::IsNearlyZero(MaxLag.X) || Math::IsNearlyZero(MaxLag.Y) || Math::IsNearlyZero(ToTarget.X) || Math::IsNearlyZero(ToTarget.Y))
		{
			// Might as well clamp to rectangle if either radius or direction axes are zero (and it avoids some divide by zero issues)
			if (Math::Abs(ToTarget.X) > MaxLag.X)
				ClampedLoc.X = TargetLoc.X - Math::Sign(ToTarget.X) * MaxLag.X;
			if (Math::Abs(ToTarget.Y) > MaxLag.Y)
				ClampedLoc.Y = TargetLoc.Y - Math::Sign(ToTarget.Y) * MaxLag.Y;
		}
		else if (ToTarget.SizeSquared2D() > Math::Min(MaxLag.X, MaxLag.Y))
		{
			// We might be outside ellipse, check properly
			float RadiusXSqr = Math::Square(MaxLag.X);
			float RadiusYSqr = Math::Square(MaxLag.Y);
			float Inclination = ToTarget.Y / ToTarget.X;
			float Discriminant = RadiusXSqr * RadiusYSqr / (RadiusYSqr + (RadiusXSqr * Math::Square(Inclination)));
			if (Discriminant < Math::Square(ToTarget.X))
			{
				// Clamp to where ToTarget line intersects with ellipse around target location
				float IntersectX = Math::Sign(ToTarget.X) * Math::Sqrt(Discriminant);
				float IntersectY = IntersectX * Inclination;
				ClampedLoc.X = TargetLoc.X - IntersectX;
				ClampedLoc.Y = TargetLoc.Y - IntersectY;
			}
		}

		// Clamp height if above/below cylinder
		if (Math::Abs(ToTarget.Z) > MaxLag.Z)
			ClampedLoc.Z = TargetLoc.Z - Math::Sign(ToTarget.Z) * MaxLag.Z;

		//DebugPrintMaxLag(PivotLoc, ClampedLoc, MaxLag);
		return ClampedLoc;
	}

	protected FVector GetTargetSpringArmLocation(FHazeCameraTransform CameraTransform, float TargetIdealDistance)
	{
		FRotator CurrentRotation = CameraTransform.ViewRotation;
		FVector ForwardDir = CurrentRotation.Vector();
		FVector TargetLoc = CameraTransform.PivotLocation - (ForwardDir * TargetIdealDistance);
		return TargetLoc;
	}

	protected FVector CalculateCameraTargetLocation(FHazeCameraTransform CameraTransform, FVector SpringArmLocation, float OffsetFactor)
	{
		FRotator CurrentRotation = CameraTransform.ViewRotation;

 		FVector OwnerSpaceOffset = CameraTransform.PivotRotation.RotateVector(CameraSettings.CameraOffsetOwnerSpace);
 		OwnerSpaceOffset *= GetCurveValue(UserSettings.CameraOffsetOwnerSpaceByPitchCurve, LocalPitch, 1);

		const FVector CameraTargetOffset = CameraSettings.CameraOffset;
		FVector CameraOffset = CurrentRotation.RotateVector(FVector(0.0, CameraTargetOffset.Y, CameraTargetOffset.Z));
		CameraOffset *= Math::Lerp(1, GetCurveValue(UserSettings.CameraOffsetByPitchCurve, LocalPitch, 1), CameraSettings.CameraOffsetByPitchCurveAlpha);

		FVector ForwardDir = CurrentRotation.Vector();
		//FVector TargetPivotLoc = CameraTransform.PivotLocation - (ForwardDir * TargetIdealDistance);
		FVector OffsetAmount = (CameraOffset + OwnerSpaceOffset) * OffsetFactor;
		FVector TargetCameraLoc = SpringArmLocation + OffsetAmount;

		#if TEST
		ArmDirection = -ForwardDir;
		OffsetPositions[3] = OwnerSpaceOffset;
		OffsetPositions[4] = CameraOffset;
		#endif

		return TargetCameraLoc;
	}

	
	protected void UpdateViewLocation(bool bCheckCollision, float DeltaTime, FHazeCameraTransform& OutResult)
 	{
		SpringArmData.TargetArmLengthIdealDistance = GetIdealDistanceTarget(CameraSettings.CameraOffset.X);
		FVector SpringArmLocation = GetTargetSpringArmLocation(OutResult, SpringArmData.TargetArmLengthIdealDistance);
		const FVector TargetCameraLoc = CalculateCameraTargetLocation(OutResult, SpringArmLocation, 1);

		// No collision check so place the camera here
		if(!bCheckCollision || !CameraTraceParams.IsCollisionEnabled())
		{
			OutResult.ViewLocation = TargetCameraLoc;
			SpringArmData.PreviousViewLocation = TargetCameraLoc;
			SpringArmData.bAccelerateArmLength = false;
			SpringArmData.ArmLengthMultiplier.SnapTo(1);
			return;
		}

		{
			//const float TargetDistance = OutResult.PivotLocation.Distance(TargetCameraLoc);
			if(DeltaTime > 0 && SpringArmData.bAccelerateArmLength)
			{
				float NewValue = SpringArmData.ArmLengthMultiplier.AccelerateTo(1, UserSettings.ArmLengthAccelerationSpeed, DeltaTime);
				SpringArmData.bAccelerateArmLength = Math::Abs(NewValue - 1) > KINDA_SMALL_NUMBER;
			}
			else
			{
				SpringArmData.ArmLengthMultiplier.SnapTo(1, UserSettings.ArmLengthAccelerationSpeed);
			}
		}

		// Don't check collision within min distance
		FVector MinOffset = FVector::ZeroVector;
		if (CameraSettings.MinDistance > 0.0 && TargetCameraLoc.DistSquared(OutResult.PivotLocation) >= 0)
			MinOffset = (TargetCameraLoc - OutResult.PivotLocation).GetSafeNormal() * CameraSettings.MinDistance;

		FVector TraceFrom = OutResult.PivotLocation + MinOffset;
		FVector TraceTo = SpringArmLocation + OutResult.ModifiedViewLocationDelta;

		// Check collision towards the target pivot location so we won't clip ground with lagging pivot.
		// Note that this will cause lag to lessen when obstructed.
        // TODO: When camera is blocked you might get some twitches, since blocked range needs to be tweaked accordingly. Fix!	
		//bool bApplyPreviousArmLength = true;
		FSpringArmTraceResult CameraHitResult = QuerySpringArmLocation(OutResult, TraceFrom, TraceTo, n"01");
		if (CameraHitResult.HasHardCollision())
		{
			//float NewArmDistance = OutResult.PivotLocation.Distance(Obstruction.Location);
			//float CurrentArmDistance = SpringArmData.TargetArmLengthIdealDistance * SpringArmData.ArmLengthMultiplier.Value;
			//if(NewArmDistance <= CurrentArmDistance - KINDA_SMALL_NUMBER)
			if(CameraHitResult.Impact.Time <= SpringArmData.ArmLengthMultiplier.Value - KINDA_SMALL_NUMBER)
			{
				SpringArmData.ArmLengthMultiplier.SnapTo(CameraHitResult.Impact.Time);
				SpringArmData.bAccelerateArmLength = true;
			}

			if (!CameraHitResult.ImpactOffset.IsZero())
			{
				SpringArmData.bAccelerateArmLength = true;
			}
		}

		//float ArmAlpha = Math::Min(SpringArmData.ArmLength.Value / TargetIdealDistance, 1);
		float ArmAlpha = SpringArmData.ArmLengthMultiplier.Value;
		float OffsetAlpha = Math::Lerp(CameraSettings.CameraOffsetBlockedFactor, 1, ArmAlpha);
		float CurrentArmDistance = SpringArmData.TargetArmLengthIdealDistance * SpringArmData.ArmLengthMultiplier.Value;
		SpringArmLocation = GetTargetSpringArmLocation(OutResult, CurrentArmDistance) + CameraHitResult.ImpactOffset;

		// Camera modifiers don't handle any collisions, counteract this by removing a chunk
		// from the original delta if there were collisions caused by impulses or shakes
		if (TrimCameraModifiersDelta(SpringArmLocation, OutResult, CameraHitResult.Impact))
			SpringArmData.bAccelerateArmLength = false;

		FVector FinalLocation = CalculateCameraTargetLocation(OutResult, SpringArmLocation, OffsetAlpha);

		// If the final location is not the same as the spring arm location,
		// we need to validate the last trace as well.
		if(!FinalLocation.Equals(SpringArmLocation))
		{
			if(CameraHitResult.HasSeeTroughCollision())
			{
				FVector TunnelTraceStartLocation = CameraHitResult.TunnelImpact.Location;
				TunnelTraceStartLocation += (FinalLocation - TraceFrom).GetSafeNormal();
				CameraHitResult = QuerySpringArmLocation(OutResult, TunnelTraceStartLocation, FinalLocation, n"02");
			}
			else
			{
				// Perform new trace from pivot to final final location (including camera offsets)
				// Tyko, why the fuck didn't you do this?
				CameraHitResult = QuerySpringArmLocation(OutResult, TraceFrom, FinalLocation, n"02");
			}

			if (CameraHitResult.HasHardCollision())
			{
				FinalLocation = CameraHitResult.Impact.Location;
			}
		}

		OutResult.ViewLocation = FinalLocation;
		SpringArmData.PreviousViewLocation = FinalLocation;
 	}

	protected float GetIdealDistanceTarget(float CameraOffsetX) const
	{
		float IdealDist = CameraSettings.IdealDistance;
		float IdealDistanceMultiplier = Math::Lerp(1, GetCurveValue(UserSettings.IdealDistanceByPitchCurve, LocalPitch, 1), CameraSettings.IdealDistanceByPitchCurveAlpha);
		IdealDist *= IdealDistanceMultiplier;
		IdealDist -= CameraOffsetX;
		IdealDist = Math::Max(IdealDist, CameraSettings.MinDistance);
#if TEST
		float ForceIdealDistance = CVar_SpringArmForceIdealDistance.Float;
		if (ForceIdealDistance > 1.0)
			return ForceIdealDistance;
#endif
		return IdealDist;
	
	}

	// Negative target values means that the pivot will no longer move.
	// But we can't lerp the value to a negative value, since there will then be some time
	// where the value is close to 0 and then the pivot will snap.
	// So when inserting negative values, we lerp to 0 and lock the value.
	protected void UpdateAccelerationDuration(FSpringArmAccelerationDurationData& Index, float Target, float DeltaTime) const
	{
		if(Target < 0)
		{
			if(DeltaTime > 0)
			Index.Value = 0;
			Index.bIsLocked = true;

			// We will lerp back from 60 sec to 0 over 0.5 sec.
			// This is just an arbitrary value since we need to lerp back from a very high value to make it smooth
			Index.AccMul.SnapTo(60); 
		}
		else
		{
			if(DeltaTime > 0)
				Index.AccMul.AccelerateTo(0, 0.5, DeltaTime);
			else
				Index.AccMul.SnapTo(0);

			Index.Value = Target;

			// When the values is guaranteed to start lerping in again,
			// we remove the lock
			if(Index.bIsLocked && Index.Value > KINDA_SMALL_NUMBER * 4)
				Index.bIsLocked = false;
		}
	}

	
	protected void SnapPivotLagMax(float Target, float& Value, float& Velocity) const
	{
		// snap when increasing
		if (Target <= Value)
			return;
		Value = Target;
		Velocity = 0.0;
	}

	private float GetCurveValue(UCurveFloat Curve, float Time, float DefaultValue) const
	{
		if(Curve == nullptr)
			return DefaultValue;

		return Curve.GetFloatValue(Time);
	}

	private float UpdateAccelerationAlpha(FHazeAcceleratedFloat& Value, float Target, float DeltaTime)
	{
		if(Target < Value.Value)
		{
			Value.SnapTo(Target);
			return Target;

		}
		else
		{
			const float Duration = UserSettings.PivotAccelerationDurationAlphaDuration;
			Value.AccelerateTo(Target, Duration, DeltaTime);
			return Value.Value;
		}
	}

	protected ECameraCollisionType GetCollisionType(FVector PivotLocation, FHitResult Obstruction) const
	{
		// Only camera blockers can obstruct
		if (!Obstruction.bBlockingHit)
			return ECameraCollisionType::NoCollision;

		if ((Obstruction.Component != nullptr))
		{
			// Components with the always blocking tag will obviously do that
			if(Obstruction.Component.HasTag(ComponentTags::AlwaysBlockCamera))
				return ECameraCollisionType::HardCollision;
			
			// We ignore hide on camera overlaps since the overlap capability will take care of that
			if(Obstruction.Component.HasTag(ComponentTags::HideOnCameraOverlap))
				return ECameraCollisionType::NoCollision; 

			// Also ignore this overlap hide tag
			if(Obstruction.Component.HasTag(ComponentTags::HideIndividualComponentOnCameraOverlap))
				return ECameraCollisionType::NoCollision; 
		}

		// BSP always obstruct
		if (Obstruction.Actor == nullptr)
			return ECameraCollisionType::HardCollision;
		
		// If the impact normal is on the opposite side of the yaw axis, we can't see through it
		if (YawAxis.DotProduct(Obstruction.Normal) <= 0.0)
			return ECameraCollisionType::HardCollision;

		const FVector ToObstruction = Obstruction.Location - PivotLocation;

		// Any surface we hit whose normal points towards camera is a hard hit (giggity)
		if (Obstruction.Normal.DotProduct(ToObstruction) < 0.0)
			return ECameraCollisionType::HardCollision;

		// Any obstructions below player (in camera space) will count as always blocking, so we don't end up on the wrong side of the floor.
		if (YawAxis.DotProduct(ToObstruction) < 0.0)
			return ECameraCollisionType::HardCollision;
		
		// We should never be able so see through the landscape
		if(Obstruction.Actor.IsA(ALandscape))
			return ECameraCollisionType::HardCollision;

		return ECameraCollisionType::SeeTroughCollision;
	}

	protected FSpringArmTraceResult QuerySpringArmLocation(FHazeCameraTransform CameraTransform, FVector WantedStartLocation, FVector EndLocation, FName TraceType) const
	{
		FSpringArmTraceResult Out;

		// This camera don't want us to use camera collision
		if(!CameraTraceParams.bUseCollision)
			return Out;
		
		// Camera trace is blocked by the user
		if(!UserSettings.bUseCameraTrace)
			return Out;

		//FVector InternalOriginalPivotLocation = GetOriginalCameraTransform().PivotLocation;
		const float ScaledObstructedClearance = UserSettings.ObstructedClearance * UserSettings.ActorScale.Z;
		FVector PivotLocation = WantedStartLocation;

		// Check if the camera can move back
		FHitResultArray TraceResult;

		if(!PivotLocation.Equals(EndLocation))
			TraceResult = CameraTraceParams.QueryTraceMulti(PivotLocation, EndLocation, FName(f"01;{TraceType};FirstObstruction"));

		FHitResult HitResult;
		ECameraCollisionType CollisionType = ECameraCollisionType::NoCollision;

		for(auto It : TraceResult)
		{
			ECameraCollisionType NewCollisionType = GetCollisionType(PivotLocation, It);
			if(NewCollisionType == ECameraCollisionType::HardCollision)
			{
				CollisionType = NewCollisionType;
				HitResult = It;
				break;
			}
			else if(NewCollisionType == ECameraCollisionType::SeeTroughCollision
				&& CollisionType == ECameraCollisionType::NoCollision)
			{
				CollisionType = NewCollisionType;
				HitResult = It;
			}
		}

		// No collision. We are free to place the spring arm at the wanted location
		if(CollisionType == ECameraCollisionType::NoCollision)
		{
			return Out;
		}
		// We are inside something, force the camera in as much as possible
		// and ignore the rest of the tracing.
		// This should be solved by using correct trace settings
		// so we always start the camera trace inside the users collision
		else if(HitResult.bStartPenetrating)
		{
			Out.ImpactType = ECameraCollisionType::HardCollision;
			Out.Impact = HitResult;
			Out.TunnelImpact = HitResult;
		}

		// No tunneling allowed so we just use the first impact
		if(!UserSettings.bUseCameraTunnelTrace)
		{
			Out.Impact = HitResult;
			Out.TunnelImpact = HitResult;
			Out.ImpactType = CollisionType;
			if(Out.ImpactType == ECameraCollisionType::SeeTroughCollision)
				Out.ImpactType = ECameraCollisionType::HardCollision;
			return Out;
		}

		// Trace from the other side
		// Then compare the two impacts. If they are far apart, this is a thick solid wall
		// and we will not be able to place the camera behind it
		TraceResult = CameraTraceParams.QueryTraceMulti(EndLocation, PivotLocation, FName(f"02;{TraceType};Tunneling"));
		ECameraCollisionType TunnelImpactType = ECameraCollisionType::NoCollision;
		for(auto It : TraceResult)
		{
			ECameraCollisionType NewCollisionType = GetCollisionType(PivotLocation, It);
			if(NewCollisionType == ECameraCollisionType::HardCollision)
			{
				float TunnelImpactDistance = It.Location.Distance(HitResult.Location);

				// Hard blocking obstruction found too close to first obstruction
				if (TunnelImpactDistance > ScaledObstructedClearance)
				{	
					Out.TunnelImpact = It;
					TunnelImpactType = ECameraCollisionType::HardCollision;
					break;
				}
				else
				{
					// If we can pass trough, we save that location
					Out.TunnelImpact = It;
					TunnelImpactType = ECameraCollisionType::SeeTroughCollision;
				}
			}
			else if(TunnelImpactType == ECameraCollisionType::NoCollision)
			{
				Out.TunnelImpact = It;
				TunnelImpactType = ECameraCollisionType::SeeTroughCollision;
			}
		}

		// Last validation, it might be a thin object, but it can still be a long wall
		// so we need to check the side of the object to see if we can see the owner on the side
		// if so, we can ignore the collision
		if(TunnelImpactType == ECameraCollisionType::SeeTroughCollision)
		{
			FVector TunnelLocation = HitResult.Location;
			TunnelLocation -= HitResult.Normal * CameraTraceParams.ProbeSize;
			
			FVector SideDir = FVector::ZeroVector;
			if(HitResult.Normal.DotProductLinear(CameraTransform.ViewRotation.RightVector) > 0.8)
			{
				SideDir = HitResult.ImpactNormal;
			}
			else
			{
				SideDir = FRotator::MakeFromZX(YawAxis, HitResult.ImpactNormal).RightVector;
				FVector LeftPos = TunnelLocation - (SideDir * CameraTraceParams.ProbeSize * 2);
				FVector RightPos = TunnelLocation + (SideDir * CameraTraceParams.ProbeSize * 2);
				SideDir *= CameraTransform.UserLocation.DistSquared(LeftPos) < CameraTransform.UserLocation.DistSquared(RightPos) ? 1 : -1;
			}

			FVector TraceAmount = SideDir * ScaledObstructedClearance * 0.5;
			FHitResult RightSideImpact = CameraTraceParams.QueryTraceSingle(TunnelLocation + TraceAmount, TunnelLocation, FName(f"03;{TraceType};TunnelingSide"));

			if(RightSideImpact.bStartPenetrating)
			{
				TunnelImpactType = ECameraCollisionType::HardCollision;
			}
			else
			{
				TraceAmount = -SideDir * ScaledObstructedClearance * 0.5;
				FHitResult LeftSideImpact = CameraTraceParams.QueryTraceSingle(TunnelLocation + TraceAmount, TunnelLocation, FName(f"03;{TraceType};TunnelingSide"));
				if(LeftSideImpact.bStartPenetrating)
				{
					TunnelImpactType = ECameraCollisionType::HardCollision;
				}
			}
		}

		// Finalize the impact result
		Out.Impact = HitResult;
		Out.ImpactType = TunnelImpactType;
		if(Out.ImpactType == ECameraCollisionType::NoCollision && CollisionType == ECameraCollisionType::HardCollision)
		{
			Out.ImpactType = CollisionType;
			Out.TunnelImpact = HitResult;
		}
		else if(TunnelImpactType == ECameraCollisionType::NoCollision)
		{
			Out.TunnelImpact = HitResult;
		}

		return Out;
	}

	// Removes modifier translation information due to collisions
	protected bool TrimCameraModifiersDelta(FVector& OutVector, const FHazeCameraTransform& CameraTransform, const FHitResult& CameraHitResult)
	{
		if (CameraHitResult.bBlockingHit)
	 	{
			FVector Trim = (CameraHitResult.Location - OutVector).ConstrainToDirection(CameraTransform.ModifiedViewLocationDelta.GetSafeNormal());
			FVector Offset = CameraTransform.ModifiedViewLocationDelta - Trim;
			if (!Offset.IsNearlyZero())
			{
				OutVector -= Offset;
				return true;
			}
		}

		return false;
	}

	protected void UpdateAssist(float DeltaTime, FHazeCameraTransform& OutResult)
	{	
		if(AssistSettings.AssistType == nullptr)
		{
			// Clean data if we are not using any assists
			if (AssistData.IsDirty())
				AssistData = FHazeActiveCameraAssistData();

			return;
		}

		AssistSettings.AssistType.Apply(
			DeltaTime, 
			CameraSettings.ChaseAssistFactor, 
			AssistSettings, 
			AssistData, 
			OutResult);
	}
}


