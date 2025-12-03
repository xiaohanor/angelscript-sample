UCLASS(Abstract)
class UTundraPlayerFairyComponent : UTundraPlayerShapeBaseComponent
{
	access ReadOnly = private, * (readonly), UTundraPlayerFairyLeapActiveCapability, UTundraPlayerFairyLeapCapability;
	default ShapeType = ETundraShapeshiftShape::Small;

	UPROPERTY(Category = "Settings")
	TSubclassOf<ATundraPlayerFairyActor> FairyActorClass;

	UPROPERTY(Category = "Settings")
	UTundraPlayerFairySettings SettingsOverride;

	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "Settings")
	UPlayerPoleClimbSettings PoleClimbSettings;

	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsInLeap;

	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsInMoveSpline;

	UPROPERTY(Category = "Settings")
	UPlayerFloorMotionSettings FloorMotionSettings;

	UPROPERTY(Category = "Settings")
	UPlayerFloorSlowdownSettings FloorSlowdownSettings;

	UPROPERTY(Category = "Settings")
	UPlayerCrouchSettings CrouchSettings;

	UPROPERTY(Category = "Settings")
	UTundraPlayerFairySettings OutOfBoundsFairySettings;

	UPROPERTY(Category = "Settings")
	TSubclassOf<ATundraFairyMoveSplineSwitchTargetableActor> SwitchTargetableActorClass;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	UForceFeedbackEffect JumpForceFeedback;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	UForceFeedbackEffect LeapForceFeedback;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> LoopingMoveSplineCameraShake;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	UForceFeedbackEffect LoopingMoveSplineForceFeedback;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> ExitMoveSplineCameraShake;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	UForceFeedbackEffect ExitMoveSplineForceFeedback;

	bool bIsActive = false;

	// Leap stuff
	bool bIsLeaping = false;
	access:ReadOnly int AmountOfLeaps = 0;
	access:ReadOnly bool bResetLeapSession = true;
	float LeapSessionDuration = 0.0;
	float TimeOfLastLeap = -100.0;
	float HeightOfLastLeap = 0.0;
	float HeightOfLeapSession = 0.0;
	float HighestHeightOfLeapSession = 0.0;
	float LastLeapSessionHeight = 0.0;
	float TargetSidewaysLeapOffset;
	bool bFairyLeapAfterShapeshifting = false;
	uint FrameOfLeap = MAX_uint32;
	bool bSwitchingSpline = false;
	FVector LeapAirControlVelocity;
	FVector LeapDirection;
	FVector LeapAdditionalVelocity;
	FVector LeapVerticalVelocity;
	TArray<FInstigator> OutOfBoundsLeapInstigators;

	// Wind current stuff
	ATundraWindCurrentSpline CurrentWindCurrent;
	FVector WindCurrentTargetLocation;

	// Move spline stuff
	bool bIsOnMoveSpline = false;
	ATundraFairyMoveSpline CurrentMoveSpline;
	float CurrentSplineDistance;
	UTundraFairyMoveSplineSwitchTargetableComponent FocusedSwitchMoveSplineTargetable;
	FVector CurrentSplineLocation;

	UTundraPlayerFairySettings CurrentFairySettings;

	UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
	ATundraPlayerFairyActor FairyActor;

	UPlayerMovementComponent MoveComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerSwingComponent SwingComponent;
	UPlayerWallRunComponent WallRunComp;

	// Leap temporal log categories
	const FString LeapGeneralCategory = "1#Leap";
	const FString LeapSessionCategory = "3#Leap Session Height Window";
	const FString LeapSidewaysDeltaCategory = "5#Leap Sideways Delta";

	float CurrentMaxHeightLossSpeed;
	FRuntimeFloatCurve CurrentLeapHeightLossCurve;
	float CurrentLeapHeightLossCurveDuration;
	int CurrentFairySettingsModificationID;
	TOptional<float> TimeOfModifiedFairySettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(SettingsOverride != nullptr)
			Player.ApplyDefaultSettings(SettingsOverride);

		CurrentFairySettings = UTundraPlayerFairySettings::GetSettings(Player);

		if(FairyActorClass != nullptr)
		{
			FairyActor = SpawnActor(FairyActorClass, bDeferredSpawn = true);
			FairyActor.Player = Player;
			FinishSpawningActor(FairyActor);
			FairyActor.MakeNetworked(this, n"_FairyActor");

			FairyActor.AttachToComponent(Player.Mesh);
			FairyActor.ActorRelativeTransform = FTransform::Identity;
			Player.Mesh.LinkMeshComponentToLocomotionRequests(FairyActor.Mesh);
			FairyActor.Mesh.SetOverrideRootMotionReceiverComponent(Player.RootComponent);
			FairyActor.AddActorDisable(ShapeshiftingComp);
			Outline::ApplyOutlineOnActor(FairyActor, Game::Mio, Outline::GetMioOutlineAsset(), this, EInstigatePriority::Level);

			UPlayerRenderingSettingsComponent::GetOrCreate(Player).AdditionalSubsurfaceMeshes.Add(FairyActor.Mesh);
		}
	}

	void SnapFairyLeapHeightLossSpeed()
	{
		CurrentMaxHeightLossSpeed = CurrentFairySettings.MaxHeightLossSpeed;
		CurrentLeapHeightLossCurve = CurrentFairySettings.HeightLossOverTimeCurve;
		CurrentLeapHeightLossCurveDuration = CurrentFairySettings.HeightLossOverTimeCurveDuration;
		CurrentFairySettingsModificationID = CurrentFairySettings.GetModificationId();
		TimeOfModifiedFairySettings.Reset();
	}

	void AddOutOfBoundsLeapInstigator(FInstigator Instigator)
	{
		bool bWasOutOfBounds = IsOutOfBoundsLeaping();
		OutOfBoundsLeapInstigators.AddUnique(Instigator);
		if(IsOutOfBoundsLeaping() && !bWasOutOfBounds)
		{
			Player.ApplySettings(OutOfBoundsFairySettings, this);
		}
	}

	void RemoveOutOfBoundsLeapInstigator(FInstigator Instigator)
	{
		bool bWasOutOfBounds = IsOutOfBoundsLeaping();
		OutOfBoundsLeapInstigators.RemoveSingleSwap(Instigator);
		if(!IsOutOfBoundsLeaping() && bWasOutOfBounds)
		{
			Player.ClearSettingsWithAsset(OutOfBoundsFairySettings, this);
		}
	}

	bool IsOutOfBoundsLeaping() const
	{
		return OutOfBoundsLeapInstigators.Num() > 0;
	}

	AHazeCharacter GetShapeActor() const override
	{
		return FairyActor;
	}

	UHazeCharacterSkeletalMeshComponent GetShapeMesh() const override
	{
		return FairyActor.Mesh;
	}

	FVector2D GetShapeCollisionSize() const override
	{
		return TundraShapeshiftingStatics::FairyCollisionSize;
	}

	void GetMaterialTintColors(FLinearColor &PlayerColor, FLinearColor &ShapeColor) const override
	{
		auto Settings = UTundraPlayerFairySettings::GetSettings(Player);
		PlayerColor = Settings.MorphPlayerTint;
		ShapeColor = Settings.MorphShapeTint;
	}

	float GetShapeGravityAmount() const override
	{
		return ShapeshiftingComp.OriginalPlayerGravityAmount;
	}

	float GetShapeTerminalVelocity() const override
	{
		return ShapeshiftingComp.OriginalPlayerTerminalVelocity;
	}

	float GetShapePoleClimbMaxHeightOffset() const override
	{
		return PoleClimbSettings.MaxHeightOffset;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ShouldResetLeap())
			ResetLeap();

		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value(f"{LeapGeneralCategory};Reset Leap Session", bResetLeapSession);
		TemporalLog.Value(f"{LeapGeneralCategory};Leap Session Duration", bResetLeapSession ? 0.0 : LeapSessionDuration);
	}

	float GetCurrentHeightLossSpeed()
	{
		const float LerpDuration = 1.0;

		float LeapHeightLossCurveDuration = CurrentLeapHeightLossCurveDuration;
		float MaxHeightLossSpeed = CurrentMaxHeightLossSpeed;

		if(CurrentFairySettings.GetModificationId() != CurrentFairySettingsModificationID)
		{
			if(!TimeOfModifiedFairySettings.IsSet())
				TimeOfModifiedFairySettings.Set(Time::GetGameTimeSeconds());

			float TimeSince = Time::GetGameTimeSince(TimeOfModifiedFairySettings.Value);
			float Alpha = Math::Saturate(TimeSince / LerpDuration);
			if(Math::IsNearlyEqual(Alpha, 1.0))
			{
				Alpha = 1.0;
				SnapFairyLeapHeightLossSpeed();
				LeapHeightLossCurveDuration = CurrentLeapHeightLossCurveDuration;
				MaxHeightLossSpeed = CurrentMaxHeightLossSpeed;
			}
			else
			{
				LeapHeightLossCurveDuration = Math::Lerp(CurrentLeapHeightLossCurveDuration, CurrentFairySettings.HeightLossOverTimeCurveDuration, Alpha);
				MaxHeightLossSpeed = Math::Lerp(CurrentMaxHeightLossSpeed, CurrentFairySettings.MaxHeightLossSpeed, Alpha);
			}
		}

		float CurveAlpha = Math::Saturate(LeapSessionDuration / LeapHeightLossCurveDuration);
		float CurveValue = CurrentLeapHeightLossCurve.GetFloatValue(CurveAlpha);
		if(TimeOfModifiedFairySettings.IsSet())
		{
			float TimeSince = Time::GetGameTimeSince(TimeOfModifiedFairySettings.Value);
			float Alpha = Math::Saturate(TimeSince / LerpDuration);
			float NewCurveValue = CurrentFairySettings.HeightLossOverTimeCurve.GetFloatValue(CurveAlpha);
			CurveValue = Math::Lerp(CurveValue, NewCurveValue, Alpha);
		}
		return CurveValue * MaxHeightLossSpeed;
	}

	bool ShouldResetLeap()
	{
		// Some of these components are sometimes created after this one so they might be null in BeginPlay, so we need to get them here.
		if(MoveComp == nullptr)
			MoveComp = UPlayerMovementComponent::Get(Player);

		if(GrappleComp == nullptr)
			GrappleComp = UPlayerGrappleComponent::Get(Player);

		if(PoleClimbComp == nullptr)
			PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);

		if(TreeGuardianComp == nullptr)
			TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);

		if(SwingComponent == nullptr)
			SwingComponent = UPlayerSwingComponent::Get(Player);

		if(WallRunComp == nullptr)
			WallRunComp = UPlayerWallRunComponent::Get(Player);

		if(AmountOfLeaps == 0 && bResetLeapSession)
			return false;

		if(MoveComp.HasGroundContact())
			return true;

		if(GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleEnter)
			return true;

		if(PoleClimbComp.State == EPlayerPoleClimbState::Climbing)
			return true;

		if(Player.IsPlayerDead())
			return true;

		if(SwingComponent.HasActivateSwingPoint())
			return true;

		if(TreeGuardianComp.CurrentRangedGrapplePoint != nullptr)
			return true;

		if(WallRunComp.State != EPlayerWallRunState::None)
			return true;

		return false;
	}

	void ResetLeap()
	{
		AmountOfLeaps = 0;
		bResetLeapSession = true;
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	float GetAccelerationWithDrag(float DeltaTime, float DragFactor, float MaxSpeed, float DragExponent = 1.0) const
	{
		const float IntegratedDragFactor = Math::Exp(-DragFactor);
		const float NewSpeed = MaxSpeed * Math::Pow(IntegratedDragFactor, DeltaTime);
		float Drag = Math::Abs(NewSpeed - MaxSpeed);

		// Optional, to make the drag more exponential. Might feel nicer
		if(DragExponent > 1.0 + KINDA_SMALL_NUMBER)
			Drag = Math::Pow(Drag, DragExponent);

		return Drag / DeltaTime;
	}

	float GetAirFrictionValue()
	{
		UTundraPlayerFairySettings Settings = UTundraPlayerFairySettings::GetSettings(Cast<AHazePlayerCharacter>(Owner));
		return Settings.HorizontalAirFriction;
	}

	float GetCurrentMeshHeightOffset() property
	{
		return Cast<AHazePlayerCharacter>(Owner).Mesh.RelativeLocation.Z;
	}

	void TemporalLogLeapStuff()
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		// Debug general leap info
		{
			TemporalLog.Value(f"{LeapGeneralCategory};Leaped This Frame", FrameOfLeap == Time::FrameNumber);
			TemporalLog.DirectionalArrow(f"{LeapGeneralCategory};Leap Additional Velocity", Player.ActorLocation, LeapAdditionalVelocity);
		}

		// Debug draw leap session height window
		{
			const float LineLength = 100.0;
			const FVector OriginBottom = FVector(Player.ActorLocation.X, Player.ActorLocation.Y, HeightOfLeapSession);
			const FVector BottomStart = OriginBottom - Player.ActorForwardVector * LineLength * 0.5;
			const FVector BottomEnd = OriginBottom + Player.ActorForwardVector * LineLength * 0.5;
			const FVector MaxHeightGainOffset = Player.ActorUpVector * CurrentFairySettings.MaxHeightGain;
			const FVector LowHeightOffset = -Player.ActorUpVector * CurrentFairySettings.LowHeightBeforeLosingHeight;

			const float CurrentHeightLossCurveAlpha = Math::Min(LeapSessionDuration / CurrentFairySettings.HeightLossOverTimeCurveDuration, 1.0);
			const float CurrentHeightLossSpeed = GetCurrentHeightLossSpeed();

			TemporalLog.Value(f"{LeapSessionCategory};Leap Session Height", HeightOfLeapSession);
			TemporalLog.Value(f"{LeapSessionCategory};Leap Session Highest Height", HighestHeightOfLeapSession);
			TemporalLog.Value(f"{LeapSessionCategory};Last Leap Session Height", LastLeapSessionHeight);
			TemporalLog.Value(f"{LeapSessionCategory};Height Loss Speed", CurrentHeightLossSpeed);
			TemporalLog.Value(f"{LeapSessionCategory};Height Loss Alpha", CurrentHeightLossCurveAlpha);
			TemporalLog.Line(f"{LeapSessionCategory};Leap Session Height Line", BottomStart, BottomEnd, Color = FLinearColor::Red);
			TemporalLog.Line(f"{LeapSessionCategory};Low Height Line", BottomStart + LowHeightOffset, BottomEnd + LowHeightOffset, Color = FLinearColor::Yellow);
			TemporalLog.Line(f"{LeapSessionCategory};Max Height Gain Line", BottomStart + MaxHeightGainOffset, BottomEnd + MaxHeightGainOffset, Color = FLinearColor::Green);
		}

		// Debug sideways delta
		{
			const float LineLength = 100.0;
			const FVector CenterStart = Player.ActorLocation - Player.ActorForwardVector * LineLength * 0.5;
			const FVector CenterEnd = Player.ActorLocation + Player.ActorForwardVector * LineLength * 0.5;
			const FVector ActualOffset = Player.ActorRightVector * FairyActor.Mesh.RelativeLocation.Y;
			const FVector TargetOffset = Player.ActorRightVector * TargetSidewaysLeapOffset;

			TemporalLog.Line(f"{LeapSidewaysDeltaCategory};Base Line", CenterStart, CenterEnd, Color = FLinearColor::Red);
			TemporalLog.Line(f"{LeapSidewaysDeltaCategory};Current Sideways Offset", CenterStart + ActualOffset, CenterEnd + ActualOffset, Color = FLinearColor::LucBlue);
			TemporalLog.Line(f"{LeapSidewaysDeltaCategory};Target Sideways Offset", CenterStart + TargetOffset, CenterEnd + TargetOffset, Color = FLinearColor::Green);
		}
	}
}