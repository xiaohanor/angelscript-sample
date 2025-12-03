event void FGravityBikeSplineOnSplineChanged(AGravityBikeSplineActor OldSpline, AGravityBikeSplineActor NewSpline, bool bSnap);
event void FGravityBikeSplineOnHitImpactResponseComponent(UGravityBikeSplineImpactResponseComponent ResponseComp, FGravityBikeSplineOnImpactData ImpactData);

#if !RELEASE
namespace DevToggleGravityBikeSpline
{
	const FHazeDevToggleBool AutoThrottle;
	const FHazeDevToggleBool FreezeLocation;
};
#endif

struct FGravityBikeSplineAnimationData
{
	float Speed;
    float AngularSpeed;
	FRotator AngularVelocity;

	bool bIsThrottling;
    float Steering;

	float BoostAlpha;
    bool bIsBoosting;

    float RollAngle;
    float RollVelocity;

    float PitchAngle;
	float PitchVelocity;

	uint FloorImpactFrame;
	float FloorImpactImpulse;

	uint LeaveGroundFrame;
	uint JumpFrame;
}

struct FGravityBikeSplineInput
{
	access InputCapability = private, UGravityBikeSplineInputCapability;

	access:InputCapability
	float Steering = 0;

	access:InputCapability
	FGravityBikeSplineStickyThrottle Throttle;

	private UGravityBikeSplineSyncComponent SyncComp;

	void Initialize(UGravityBikeSplineSyncComponent InSyncComp)
	{
		SyncComp = InSyncComp;

		if(SyncComp.HasControl())
			Reset();
	}

	void ControlSetSteering(float InSteering)
	{
		check(SyncComp.HasControl());
		Steering = InSteering;
	}

	float GetSteering() const
	{
		if(SyncComp == nullptr || SyncComp.HasControl())
			return Steering;
		else
			return SyncComp.GetValue().Steering;
	}

	float GetStickyThrottle() const
	{
		if(SyncComp == nullptr || SyncComp.HasControl())
		{
			return Throttle.GetStickyThrottle();
		}
		else
		{
			return SyncComp.GetValue().StickyThrottle;
		}
	}

	float GetImmediateThrottle() const
	{
		if(SyncComp == nullptr || SyncComp.HasControl())
		{
			return Throttle.GetImmediateThrottle();
		}
		else
		{
			return SyncComp.GetValue().ImmediateThrottle;
		}
	}

	void Reset()
	{
		if(!SyncComp.HasControl())
			return;

		Throttle.Reset();
		SyncComp.ResetInput();
	}
}

enum EGravityBikeSplineSnapToTransformVelocityMode
{
	Keep,
	Zero,
	MaxSpeed,
}

UCLASS(Abstract, NotPlaceable)
class AGravityBikeSpline : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	access Resolver = private, UGravityBikeSplineMovementResolver;
	access Death = private, UGravityBikeSplineDriverDeathCapability;
	access AutoAim = private, UGravityBikeSplineAutoAimCapability, UGravityBikeSplineInputCapability;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Sphere;
	default Sphere.SphereRadius = 48;
	default Sphere.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default Sphere.CollisionProfileName = n"PlayerCharacter";
	default Sphere.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Sphere)
	UHazeOffsetComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh, AttachSocket = "Base")
	USceneComponent DriverAttachment;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh, AttachSocket = "Base")
	USceneComponent PassengerAttachment;

	UPROPERTY(DefaultComponent, Attach = "MeshPivot")
	UGravityBikeWheelComponent BackWheelComp;

	UPROPERTY(DefaultComponent, Attach = "MeshPivot")
	UGravityBikeWheelComponent FrontWheelComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UGravityBikeSplineSteeringCapability);

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent)
	USplineLockComponent SplineLockComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedActorPositionComp;
	default CrumbSyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default CrumbSyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineSyncComponent SyncComp;
	default SyncComp.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineSteeringComponent SteeringComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLogger;

	UPROPERTY(DefaultComponent)
	UMovementInstigatorLogComponent MovementLogComp;
#endif

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY()
	FGravityBikeSplineOnSplineChanged OnSplineChanged;

	private AHazePlayerCharacter Driver = nullptr;
	private AHazePlayerCharacter Passenger = nullptr;

	private AGravityBikeSplineActor Spline;
	TInstigated<UGravityBikeSplineCameraLookSplineComponent> CameraLookSplineComps;

	TInstigated<bool> IsAirborne;
	default IsAirborne.DefaultValue = false;
	FHazeAcceleratedQuat AccBikeUp;
	FHazeAcceleratedQuat AccGlobalUp;
	private FHazeAcceleratedQuat AccTurnReference;
	TArray<FInstigator> TurnReferenceDelayBlockers;
	FVector AngularVelocity = FVector::ZeroVector;

	FGravityBikeSplineInput Input;

	UPROPERTY(BlueprintReadOnly)
	float SplineBikePanningValue = 0;

	private uint AlignedWithWallFrame = 0;
	private float AlignedWithWallTime = -1;

	access:Death
	uint DeathFromWallHitFrame = 0;
	access:Death
	FHitResult DeathFromWallHitResult;

	UPROPERTY()
	FGravityBikeSplineOnHitImpactResponseComponent OnHitImpactResponseComponent;

	// Animation
	FGravityBikeSplineAnimationData AnimationData;

	TSet<FInstigator> ForceThrottle;
	TSet<FInstigator> BlockEnemyRifleFire;
	TSet<FInstigator> BlockEnemySlowRifleFire;

	TInstigated<float> MaxSpeedOverride;
	default MaxSpeedOverride.DefaultValue = 0;

	UGravityBikeSplineSettings Settings;

	TInstigated<FGravityBikeSplineAutoAimData> AutoAim;
	bool bIsAutoAiming;
	float AutoAimAlpha = 0;

	// InheritMovement
	FQuat LastInheritedComponentRotation;

#if !RELEASE
	TOptional<FVector> LockedLocation;
#endif

	private UGravityBikeSplineHoverComponent HoverComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(GravityBikeSpline::GetDriverPlayer());

		Settings = UGravityBikeSplineSettings::GetSettings(this);

		MoveComp.SetupShapeComponent(Sphere);

		if(AccBikeUp.Value.IsIdentity())
			AccBikeUp.SnapTo(ActorQuat);

		Input.Initialize(SyncComp);
		SyncComp.FillFromLocal(this);

		HoverComp = UGravityBikeSplineHoverComponent::Get(this);

		OnPreSequencerControl.AddUFunction(this, n"PreSequencerControl");
		OnPostSequencerControl.AddUFunction(this, n"PostSequencerControl");

#if !RELEASE
		DevToggleGravityBikeSpline::AutoThrottle.MakeVisible();
		DevToggleGravityBikeSpline::FreezeLocation.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsControlledByCutscene)
			return;


		// Sync spline position and speed to remote
		// Used in prediction on enemies
		SyncComp.FillFromLocal(this);

#if !RELEASE
		if(DevToggleGravityBikeSpline::FreezeLocation.IsEnabled())
		{
			if(!LockedLocation.IsSet())
				LockedLocation = ActorLocation;

			SetActorLocation(LockedLocation.Value);
		}
		else
		{
			LockedLocation.Reset();
		}
#endif
		AccGlobalUp.AccelerateTo(FQuat::MakeFromZX(GetGlobalWorldUp(), ActorForwardVector), 1, DeltaTime);

		if(IsTurnReferenceDelayBlocked())
		{
			AccTurnReference.AccelerateTo(FQuat::Identity, 1, DeltaTime);
		}

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		const FVector AboveBike = MeshPivot.WorldLocation + ActorUpVector * 150;

		TemporalLog
		.Value("Driver", Driver)
		.Value("Passenger", Passenger)
		.Value("Current Spline", Spline)

		.Value("CameraLookSpline;Component", CameraLookSplineComps.Get())
		.Value("CameraLookSpline;Instigator", CameraLookSplineComps.CurrentInstigator)
		.Value("CameraLookSpline;Priority", CameraLookSplineComps.CurrentPriority)

		.Value("Input;Input.Steering", Input.GetSteering())

		.Value("Overrides;ForceThrottle", !ForceThrottle.IsEmpty())
		.Value("Overrides;MaxSpeedOverride", MaxSpeedOverride.Get())

		.Value("Auto Aim;bIsAutoAiming", bIsAutoAiming)
		.Value("Auto Aim;bOnlyWhileAirborne", AutoAim.Get().bOnlyWhileAirborne)
		.Value("Auto Aim;AutoAimAlpha", AutoAimAlpha)

		.Value("Misc;IsAirborne.Get()", IsAirborne.Get())

		.DirectionalArrow("Misc;AccUpVector", AboveBike, AccBikeUp.Value.UpVector * 200, 5)
		.DirectionalArrow("Misc;AccGlobalUp", AboveBike, AccGlobalUp.Value.UpVector * 200, 5)
		.Rotation("Misc;AccTurnReference", AccTurnReference.Value, AboveBike, 500)
		;
#endif
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return Sphere.WorldLocation;
	}

	void SetDriverAndPassenger(AHazePlayerCharacter InDriver, AHazePlayerCharacter InPassenger)
	{
		check(Driver == nullptr);
		check(Passenger == nullptr);

		Driver = InDriver;
		Passenger = InPassenger;

		auto PassengerComp = UGravityBikeSplinePassengerComponent::Get(Passenger);
		PassengerComp.GravityBike = this;
	}

	AHazePlayerCharacter GetDriver() const
	{
		if(Driver != nullptr)
			return Driver;

		return GravityBikeSpline::GetDriverPlayer();
	}

	AHazePlayerCharacter GetPassenger() const
	{
		if(Passenger != nullptr)
			return Passenger;

		return GravityBikeSpline::GetPassengerPlayer();
	}

	FTransform GetSpawnTransform(AGravityBikeSplineActor InSpline, FHitResult&out OutGroundHit) const
	{
		check(InSpline != nullptr);

		FHazeTraceSettings GroundTrace = Trace::InitFromPrimitiveComponent(Sphere);
		GroundTrace.IgnoreActor(this);
		GroundTrace.IgnorePlayers();

		FTransform SpawnTransform = InSpline.SplineComp.GetClosestSplineWorldTransformToWorldLocation(Driver.ActorLocation);

		OutGroundHit = GroundTrace.QueryTraceSingle(ActorLocation + SpawnTransform.Rotation.UpVector * 500, Game::Mio.ActorLocation + SpawnTransform.Rotation.UpVector * -5000);

#if !RELEASE
		TEMPORAL_LOG(this).HitResults("GetSpawnTransform GroundHit", OutGroundHit, GroundTrace.Shape, GroundTrace.ShapeWorldOffset);
#endif

		FVector Location;
		if(OutGroundHit.bBlockingHit)
		{
			Location = OutGroundHit.Location;
		}
		else
		{
			Location = Game::Mio.ActorLocation + SpawnTransform.Rotation.UpVector * 500;
		}

		SpawnTransform.SetLocation(Location);
		SpawnTransform.SetScale3D(FVector::OneVector);

		return SpawnTransform;
	}

	void SnapToTransform(FTransform Transform, EGravityBikeSplineSnapToTransformVelocityMode VelocityMode)
	{
		TeleportActor(Transform.Location, Transform.Rotator(), this);
		AccGlobalUp.SnapTo(GetSplineRotation());
		AccBikeUp.SnapTo(Transform.Rotation);
		SnapTurnReferenceRotation(GetActorQuat());

		MoveComp.Reset(false, AccGlobalUp.Value.UpVector, true);

		switch(VelocityMode)
		{
			case EGravityBikeSplineSnapToTransformVelocityMode::Keep:
				break;

			case EGravityBikeSplineSnapToTransformVelocityMode::Zero:
				SetActorVelocity(FVector::ZeroVector);
				break;

			case EGravityBikeSplineSnapToTransformVelocityMode::MaxSpeed:
				SetActorVelocity(ActorForwardVector * Settings.MaxSpeed);
				break;
		}
	}

	float GetSpeedAlpha(float Speed) const
	{
		return Math::Saturate(Speed / Settings.FastSpeedThreshold);
	}

	float GetForwardSpeed() const
	{
		return MoveComp.Velocity.DotProduct(ActorForwardVector);
	}

	void TurnBike(UGravityBikeSplineMovementData& Movement, float DeltaTime)
	{
		const FQuat SteerRelativeRotation = SteeringComp.GetTargetSteerRelativeRotation();

		if(!IsTurnReferenceDelayBlocked() && !SteerRelativeRotation.IsIdentity())
		{
			FQuat SplineRotation = GetSplineRotation();
			SplineRotation = FQuat::MakeFromZX(AccGlobalUp.Value.UpVector, SplineRotation.ForwardVector);

			const FQuat TargetRotation = SplineRotation * SteerRelativeRotation;

			const bool bTurningLeft = TargetRotation.ForwardVector.DotProduct(SplineRotation.RightVector) > 0;
			const bool bTurnReferenceShouldTurnLeft = AccTurnReference.Value.ForwardVector.DotProduct(TargetRotation.RightVector) < 0;

			float AppliedInterpSpeed = 0;

			if(bTurningLeft == bTurnReferenceShouldTurnLeft)
			{
				const float TurnReferenceError = AccTurnReference.Value.AngularDistance(SplineRotation);
				const float ExtraTurnRate = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(0, 2), TurnReferenceError);
				const float TurnReferenceInterpSpeed = SteerRelativeRotation.GetAngle() + ExtraTurnRate;
				AppliedInterpSpeed += TurnReferenceInterpSpeed;
				AccTurnReference.Value = Math::QInterpConstantTo(AccTurnReference.Value, SplineRotation, DeltaTime, TurnReferenceInterpSpeed);
			}

			if(IsAirborne.Get())
			{
				// Always interp while airborne, helps with some turns
				const float AirborneInterpSpeed = 1.0;
				float InterpSpeed = AirborneInterpSpeed - AppliedInterpSpeed;
				if(InterpSpeed > 0)
					AccTurnReference.Value = Math::QInterpConstantTo(AccTurnReference.Value, SplineRotation, DeltaTime, InterpSpeed);
			}
		}

		// Make sure up always faces the correct direction
		AccTurnReference.Value = FQuat::MakeFromZX(AccGlobalUp.Value.UpVector, AccTurnReference.Value.ForwardVector);

		FQuat TurnReference = GetTurnReferenceRotation();
		TurnReference = FQuat::MakeFromZX(AccBikeUp.Value.UpVector, TurnReference.ForwardVector);

		const FQuat NewRotation = FQuat::ApplyDelta(TurnReference, SteerRelativeRotation);

		Movement.SetRotation(NewRotation);

		FQuat DeltaRotation = FQuat::GetDelta(ActorQuat, NewRotation);

		FVector Axis = FVector::ZeroVector;
		float Angle = 0;
		DeltaRotation.ToAxisAndAngle(Axis, Angle);
		AngularVelocity = Axis * (Angle / DeltaTime);
	}

	FSplinePosition GetSplinePosition(float LeadAmount = 0) const
	{
		UHazeSplineComponent SplineComp = GetActiveSplineComponent();
		FSplinePosition SplinePosition = SplineComp.GetClosestSplinePositionToWorldLocation(ActorLocation);

		if(LeadAmount != 0)
			SplinePosition.Move(LeadAmount);

		return SplinePosition;
	}

	FTransform GetSplineTransform(float LeadAmount = 0) const
	{
		return GetSplinePosition(LeadAmount).WorldTransform;
	}

	FQuat GetSplineRotation(float LeadAmount = 0) const
	{
		return GetSplinePosition(LeadAmount).WorldRotation;
	}

	FVector GetSplineUp() const
	{
		return GetSplineRotation().UpVector;
	}

	FVector GetSplineForward() const
	{
		return GetSplineRotation().ForwardVector;
	}

	FVector GetSplineRight() const
	{
		return GetSplineRotation().RightVector;
	}

	float GetSideDistance(bool bAbsolute) const
	{
		FTransform SplineTransform = GetSplineTransform();
		const FVector Diff = ActorLocation - SplineTransform.Location;
		if(bAbsolute)
			return Math::Abs(Diff.DotProduct(SplineTransform.Rotation.RightVector));
		else
			return Diff.DotProduct(SplineTransform.Rotation.RightVector);
	}

	float GetSplineWidth() const
	{
		FTransform Transform = GetSplineTransform();
		float ScaleY = Transform.Scale3D.Y;
		return ScaleY * GetActiveSplineComponent().EditingSettings.VisualizeScale;
	}

	bool IsOutsideSplineWidth() const
	{
		const float SideDistance = GetSideDistance(true);
		const float Width = GetSplineWidth();
		return SideDistance > Width;
	}

	// Change the currently active spline
	UFUNCTION(BlueprintCallable)
	void SetSpline(AGravityBikeSplineActor InSpline, bool bSnap = false)
	{
		if(!ensure(InSpline != nullptr, "It is not allowed to unset the GravityBike spline!"))
			return;

		// Only allow changing to same if we are snapping
		if(!bSnap && InSpline == Spline)
			return;

		AGravityBikeSplineActor PreviousSpline = Spline;
		Spline = InSpline;

		// Remove the old splines settings
		if(PreviousSpline != nullptr)
		{
			if(PreviousSpline.bNoTurnReferenceDelay)
				TurnReferenceDelayBlockers.RemoveSingleSwap(PreviousSpline);

			if(Spline.bNoTurnReferenceDelay || PreviousSpline.bNoTurnReferenceDelay)
			{
				// Handle transitioning to or from a no reference delay spline
				auto OldSplineTransform = PreviousSpline.SplineComp.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
				auto NewSplineTransform = GetSplineTransform();
				FQuat Delta = OldSplineTransform.Rotation * NewSplineTransform.Rotation.Inverse();
				AccTurnReference.SnapTo(Delta);
			}
		}

		// Add new spline settings
		{
			CameraLookSplineComps.DefaultValue = Spline.CameraLookSplineComp;

			if(Spline.bNoTurnReferenceDelay)
			{
				TurnReferenceDelayBlockers.Add(Spline);
			}
		}

		// Broadcast the spline change
		OnSplineChanged.Broadcast(PreviousSpline, Spline, bSnap);

		if(PreviousSpline != Spline)
		{
			if(PreviousSpline != nullptr)
				PreviousSpline.OnLoseBeingCurrentSpline.Broadcast();
		
			Spline.OnBecomeCurrentSpline.Broadcast();
		}
	}

	UFUNCTION(BlueprintCallable)
	void StartAutoAim(FGravityBikeSplineAutoAimData AutoAimData, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		devCheck(Instigator != NAME_None, "No instigator supplied to StartAutoAim");
		AutoAim.Apply(AutoAimData, Instigator, Priority);
	}

	UFUNCTION(BlueprintCallable)
	void ClearAutoAim(FInstigator Instigator)
	{
		devCheck(Instigator != NAME_None, "No instigator supplied to StartAutoAim");
		AutoAim.Clear(Instigator);
	}

	AGravityBikeSplineActor GetActiveSplineActor() const 
	{
		return Spline;
	}

	UHazeSplineComponent GetActiveSplineComponent() const
	{
		return Spline.SplineComp;
	}

	UGravityBikeSplineCameraLookSplineComponent GetCameraLookSplineComponent() const
	{
		return CameraLookSplineComps.Get();
	}

	bool ShouldUseSplineForGravity() const
	{
		return Spline.bUseForGravityDirection;
	}

	bool IsSteering() const
	{
		if(Math::Abs(Input.GetSteering()) > 0.2)
			return true;

		return false;
	}

	FVector GetCameraDir() const
	{
		return Driver.ViewRotation.ForwardVector.VectorPlaneProject(ActorUpVector).GetSafeNormal();
	}

	float GetForwardAcceleration(float DeltaTime, float DragFactor, bool bUseThrottle)
	{
		float MaxSpeed = Settings.MaxSpeed;
		if(MaxSpeedOverride.Get() > KINDA_SMALL_NUMBER)
			MaxSpeed = MaxSpeedOverride.Get();

		if(bUseThrottle)
		{
			const float Throttle = IsBoosting() ? 1 : Input.GetStickyThrottle();
			MaxSpeed = Math::Lerp(Settings.MinimumSpeed, MaxSpeed, Throttle);
		}

		const float IntegratedDragFactor = Math::Exp(-DragFactor);
		const float NewSpeed = MaxSpeed * Math::Pow(IntegratedDragFactor, DeltaTime);
		const float Drag = Math::Abs(NewSpeed - MaxSpeed);
		
		return Drag / DeltaTime;
	}

	float GetMaxSpeed() const
	{
		if(MaxSpeedOverride.Get() > KINDA_SMALL_NUMBER)
			return MaxSpeedOverride.Get();

		return Settings.MaxSpeed;
	}

	FVector GetGlobalWorldUp() const
	{
		if(ShouldUseSplineForGravity())
			return GetSplineUp();
		else
			return FVector::UpVector;
	}

	FVector GetGravityDir() const
	{
		if(ShouldUseSplineForGravity())
		{
			return -GetSplineUp();
		}
		else
		{
			if(IsAirborne.Get())
				return -FVector::UpVector;

			return -MoveComp.WorldUp;
		}
	}

	access:Resolver
	void OnLanding(float LandingImpulse, FHitResult LandingHit)
	{
		if(!ensure(HasControl()))
			return;

#if !RELEASE
		TEMPORAL_LOG(this).Event("OnLanding");
#endif

		FGravityBikeSplineOnGroundImpactEventData EventData;
		EventData.Location = LandingHit.ImpactPoint;
		EventData.ImpactStrength = LandingImpulse;
		
		FPlane LandingGroundPlane = FPlane(LandingHit.ImpactPoint, LandingHit.ImpactNormal);

		CrumbOnLanding(LandingImpulse, EventData, LandingGroundPlane);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnLanding(float LandingImpulse, FGravityBikeSplineOnGroundImpactEventData EventData, FPlane LandingGroundPlane)
	{
		UGravityBikeSplineEventHandler::Trigger_OnGroundImpact(this, EventData);

		AnimationData.FloorImpactFrame = Time::FrameNumber;
		AnimationData.FloorImpactImpulse = LandingImpulse;

		if(Settings.bApplyPitchImpulseOnLanding)
			ApplyPitchImpulseOnLanding(LandingImpulse, LandingGroundPlane);
	}

	private void ApplyPitchImpulseOnLanding(float LandingImpulse, FPlane LandingGroundPlane)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("ApplyPitchImpulseOnLanding");
#endif

		if(LandingImpulse < Settings.LandingImpulseMinimumThreshold)
			return;

		// Too aligned
		// if(ActorRotation.UpVector.GetAngleDegreesTo(LandingHit.Normal) < Settings.LandingMinimumVerticalAngle)
		// 	return;

		FVector Impulse = ActorRightVector * Math::Clamp(LandingImpulse, Settings.LandingMinimumImpulse, Settings.LandingMaximumImpulse) * Settings.LandingImpulseMultiplier;

		bool bBackWheelFirst = LandingGroundPlane.PlaneDot(BackWheelComp.WorldLocation) < LandingGroundPlane.PlaneDot(FrontWheelComp.WorldLocation);

		if(bBackWheelFirst)
			Impulse *= -1;

		HoverComp.AddPitchImpulse(Impulse, false);
	}

	void OnLeaveGround()
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("OnLeaveGround");
#endif

		AnimationData.LeaveGroundFrame = Time::FrameNumber;
		UGravityBikeSplineEventHandler::Trigger_OnLeaveGround(this);
	}

	access:Resolver
	void BroadcastMovementImpacts(TArray<FGravityBikeSplineImpactResponseComponentAndData> Impacts)
	{
		if(!ensure(HasControl()))
			return;

		CrumbBroadcastMovementImpacts(Impacts);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBroadcastMovementImpacts(TArray<FGravityBikeSplineImpactResponseComponentAndData> Impacts)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event(f"BroadcastMovementImpacts: {Impacts.Num()} impacts");
#endif

		for(const FGravityBikeSplineImpactResponseComponentAndData& Impact : Impacts)
		{
			// Notify ourselves of the impact
			OnHitImpactResponseComponent.Broadcast(Impact.ResponseComp, Impact.ImpactData);

			// Notify the response component of the impact
			Impact.ResponseComp.OnImpact.Broadcast(this, Impact.ImpactData);
		}
	}

	access:Resolver
	void ApplyAlignWithWall(FVector AlignWithWallImpulse, FQuat AlignWithWallDeltaRotation)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("ApplyAlignWithWall");
#endif

		FVector PreRotationReflectionImpulse = AlignWithWallDeltaRotation.Inverse() * AlignWithWallImpulse;
		HoverComp.AddRotationalImpulse(PreRotationReflectionImpulse * 0.5);

		HoverComp.RelativeOffsetFromImpact += AlignWithWallDeltaRotation.Inverse().Rotator();

		if(IsTurnReferenceDelayBlocked())
			AccTurnReference.SnapTo(ActorQuat * GetSplineRotation().Inverse());
		else
			AccTurnReference.SnapTo(ActorQuat);

		SteeringComp.AccSteering.SnapTo(0);

		if(Driver == nullptr)
			return;

		AlignedWithWallFrame = Time::FrameNumber;
		AlignedWithWallTime = Time::GameTimeSeconds;
	}

	bool AlignedWithWallThisOrLastFrame() const
	{
		return AlignedWithWallFrame >= Time::FrameNumber - 1;
	}

	access:Resolver
	void ApplyDeathFromWall(uint InDeathFromWallHitFrame, FHitResult InDeathFromWallHitResult)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("ApplyDeathFromWall");
#endif

		DeathFromWallHitFrame = InDeathFromWallHitFrame;
		DeathFromWallHitResult = InDeathFromWallHitResult;
	}

	access:Death
	bool DeathFromWallThisFrame() const
	{
		return DeathFromWallHitFrame == Time::FrameNumber;
	}

	access:Death
	FHitResult GetDeathFromWallHitResult() const
	{
		check(DeathFromWallThisFrame());
		return DeathFromWallHitResult;
	}

	bool IsTurnReferenceDelayBlocked() const
	{
		return TurnReferenceDelayBlockers.Num() > 0;
	}

	FQuat GetTurnReferenceRotation() const
	{
		if(IsTurnReferenceDelayBlocked())
			return AccTurnReference.Value * GetSplineRotation();
		else
			return AccTurnReference.Value;
	}

	void SnapTurnReferenceRotation(FQuat InTurnReference)
	{
		if(IsTurnReferenceDelayBlocked())
		{
			FQuat SplineRotation = GetSplineRotation();
			FQuat Delta = InTurnReference * SplineRotation.Inverse();
			AccTurnReference.SnapTo(Delta);
		}
		else
		{
			AccTurnReference.SnapTo(InTurnReference);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentRollAmount() const
	{
		const float CurrentRoll = MeshPivot.RelativeRotation.Roll;
		const float NormalizedValue = CurrentRoll / HoverComp.Settings.MaxRoll;
		return Math::Clamp(NormalizedValue, -1, 1);
	}

	UFUNCTION(BlueprintCallable)
	float GetCurrentPitchAmount(float MaxPitch = 20) const
	{
		const FVector SplineUp = FQuat::MakeFromZX(GetSplineUp(), ActorForwardVector).UpVector;
		const FVector BikeUp = FQuat::MakeFromZX(AccBikeUp.Value.UpVector, ActorForwardVector).UpVector;
		float Angle = SplineUp.GetAngleDegreesTo(BikeUp);
		Angle *= Math::Sign(ActorForwardVector.DotProduct(SplineUp));
		const float NormalizedAngle = Angle / MaxPitch;
		return Math::Clamp(NormalizedAngle, -1, 1);
	}

	UFUNCTION(BlueprintPure)
	float GetStickyThrottle() const
	{
		return Input.GetStickyThrottle();
	}

	UFUNCTION(BlueprintPure)
	float GetImmediateThrottle() const
	{
		return Input.GetImmediateThrottle();
	}

	UFUNCTION()
	private void PreSequencerControl(FHazePreSequencerControlParams Params)
	{
		BlockCapabilities(CapabilityTags::Movement, this);
		BlockCapabilities(CapabilityTags::GameplayAction, this);
		BlockCapabilities(CapabilityTags::MovementInput, this);
		BlockCapabilities(CapabilityTags::BlockedByCutscene, this);
	}

	UFUNCTION()
	private void PostSequencerControl(FHazePostSequencerControlParams Params)
	{
		UnblockCapabilities(CapabilityTags::Movement, this);
		UnblockCapabilities(CapabilityTags::GameplayAction, this);
		UnblockCapabilities(CapabilityTags::MovementInput, this);
		UnblockCapabilities(CapabilityTags::BlockedByCutscene, this);
	}
}