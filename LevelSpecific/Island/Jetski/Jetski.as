#if !RELEASE
namespace DevTogglesJetski
{
	const FHazeDevToggleBool DisableFollowingDeath;
	const FHazeDevToggleBool PrintAnimationValues;
	const FHazeDevToggleBool DisableRubberbanding;
	const FHazeDevToggleBoolPerPlayer AutoKill;
};
#endif

enum EJetskiMovementState
{
	Air,
	Ground,
	Water,
	Underwater,
};

enum EJetskiUp
{
	Global,
	ActorUp,
	WorldUp,
	GroundNormal,
	GroundImpactNormal,
	WaterPlane,
	WaveNormal,
	Spline,
	Accelerated,
};

UCLASS(Abstract, HideCategories = "ActorTick Rendering Disable Cooking")
class AJetski : AHazeActor
{
	access Resolver = private, UJetskiMovementResolver;
	access Death = private, UJetskiDriverDeathCapability;
	access AnimInstance = private, UFeatureAnimInstanceJetski;

	UPROPERTY(DefaultComponent, RootComponent)
	private USphereComponent SphereComp;
	default SphereComp.SphereRadius = Jetski::Radius;

	UPROPERTY(DefaultComponent, Attach = SphereComp)
	UHazeOffsetComponent RootOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = RootOffsetComponent)
	UHazeOffsetComponent MeshOffset;

	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "Base")
	USceneComponent DriverAttachment;

	UPROPERTY(DefaultComponent, Attach = RootOffsetComponent)
	UDynamicWaterEffectDecalComponent WaterEffectDecalComp;

	UPROPERTY(DefaultComponent)
	protected UJetskiWaterPlaneComponent WaterPlaneComp;

	UPROPERTY(DefaultComponent)
	UJetskiBobbingComponent BobbingComponent;

	UPROPERTY(DefaultComponent)
	UJetskiCameraDataComponent CameraDataComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UJetskiMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UJetskiSyncComponent SyncComponent;
	default SyncComponent.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedMeshPivotRotationComp;
	default SyncedMeshPivotRotationComp.SyncRate = EHazeCrumbSyncRate::High;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UMovementInstigatorLogComponent MovementInstigatorLogComp;
#endif

	UPROPERTY()
	AHazePlayerCharacter Driver = nullptr;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance MioMat;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance ZoeMat;
	
	UPROPERTY(EditDefaultsOnly, Category = Audio)
	TArray<FSoundDefReference> MioSoundDefs;
	UPROPERTY(EditDefaultsOnly, Category = Audio)
	TArray<FSoundDefReference> ZoeSoundDefs;
	
	UPROPERTY(BlueprintReadOnly)
	bool bIsDestroyed = false;

	AJetskiSpline JetskiSpline;

	TInstigated<AJetskiCameraOverrideSpline> CameraOverrideSplines;
	FQuat CameraOverrideOffset;

	// Movement States
	private EJetskiMovementState MovementState = EJetskiMovementState::Water;
	private EJetskiMovementState PreviousMovementState = EJetskiMovementState::Water;
	bool bIsAirDiving = false;

	// Jump from Underwater
	bool bIsJumpingFromUnderwater = false;
	bool bHasJumpedFromUnderwater = false;

	FJetskiInput Input;
	FHazeAcceleratedFloat AccSteering;
	float AngularSpeed;
	float PreviousTurnAmount;

	private FHazeAcceleratedQuat AccUpVector;
	private FInstigator AccUpVectorInstigator;
	private uint LastAccUpVectorAccelerationFrame;

	FRotator ActualAngularVelocity;
	private FRotator PreviousActorRotation;

	UJetskiSettings Settings;

	TArray<UJetskiJosefVolumeComponent> JosefVolumes;

	access:Death
	uint DeathImpactFrame = 0;
	access:Death
	FHitResult DeathImpact;

	access:AnimInstance
	uint ReflectedFrame = 0;
	access:AnimInstance
	FVector ReflectedImpulse = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UJetskiSettings::GetSettings(this);
		MoveComp.SetupShapeComponent(SphereComp);

		MovementState = IsInWater() ? EJetskiMovementState::Water : EJetskiMovementState::Air;
		PreviousMovementState = MovementState;
		
		UMovementStandardSettings::SetAutoFollowGround(this, EMovementAutoFollowGroundType::FollowWalkable, this, EHazeSettingsPriority::Defaults);
		MoveComp.OverrideGravityDirection(FMovementGravityDirection::TowardsDirection(FVector::DownVector), this);

#if !RELEASE
		DevTogglesJetski::DisableFollowingDeath.MakeVisible();
		DevTogglesJetski::DisableRubberbanding.MakeVisible();
		DevTogglesJetski::AutoKill.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PreviousActorRotation.IsZero())
			PreviousActorRotation = ActorRotation;

		ActualAngularVelocity = (ActorRotation - PreviousActorRotation).GetNormalized() * (1 / DeltaSeconds);
		PreviousActorRotation = ActorRotation;

		//Debug::DrawDebugPlane(FVector(ActorLocation.X, ActorLocation.Y, GetTopOfSphere()), FVector::UpVector, 200, 200, FLinearColor::Green);
		//Debug::DrawDebugPlane(FVector(ActorLocation.X, ActorLocation.Y, GetWaveHeight()), GetUpVector(EJetskiUp::WaveNormal), 200, 200, FLinearColor::Blue);
		//Debug::DrawDebugPlane(FVector(ActorLocation.X, ActorLocation.Y, GetCenterOfSphere()), FVector::UpVector, 200, 200, FLinearColor::Yellow);
		//Debug::DrawDebugPlane(FVector(ActorLocation.X, ActorLocation.Y, GetWaterLineHeight()), FVector::UpVector, 200, 200, FLinearColor::Yellow);
		//Debug::DrawDebugPlane(FVector(ActorLocation.X, ActorLocation.Y, GetBotOfSphere()), FVector::UpVector, 200, 200, FLinearColor::Red);

		if(IsOnWaterSurface())
		{
			WaterEffectDecalComp.bEnabled = true;

			float SpeedFactor = GetForwardSpeed(EJetskiUp::WaveNormal) / MoveComp.MovementSettings.MaxSpeed;
			SpeedFactor = Math::Abs(SpeedFactor);
			SpeedFactor = Math::Max(SpeedFactor, 0.1);

			float WakeIntensity = SpeedFactor;
			if(Settings.WakeIntensityOverSpeedAlphaCurve != nullptr)
				WakeIntensity = Settings.WakeIntensityOverSpeedAlphaCurve.GetFloatValue(SpeedFactor);


			float DepthMultiplier = 1;
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Pawn);
			TraceSettings.UseLine();
			TraceSettings.IgnoreActor(this);
			TraceSettings.IgnoreActor(Jetski::GetOtherJetski(this));
			TraceSettings.IgnorePlayers();
			//TraceSettings.DebugDrawOneFrame();

			const FVector Start = ActorLocation;
			const float TraceDistance = Settings.WakeMaxIntensityDepth;
			const FVector End = Start - ActorUpVector * TraceDistance;
			FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);

			if(Hit.IsValidBlockingHit())
			{
				DepthMultiplier = Hit.Distance / TraceDistance;
			}

			WaterEffectDecalComp.Strength = -Settings.WakeStrength * WakeIntensity * DepthMultiplier;

			// const float WaterPlaneHeight = GetWaterPlaneHeight();
			// const float WaterLineHeight = GetWaterLineHeight();
			// WaterEffectDecalComp.Height = (WaterLineHeight - WaterPlaneHeight) / 5;
		}
		else
		{
			WaterEffectDecalComp.bEnabled = false;
		}

		if(HasControl())
		{
			FJetskiSyncedData SyncedData;
			SyncedData.Input = Input;
			SyncComponent.SetCrumbValueStruct(SyncedData);
		}
		else
		{
			FJetskiSyncedData SyncedData;
			SyncComponent.GetCrumbValueStruct(SyncedData);
			Input = SyncedData.Input;
		}

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Shape("Shape", MoveComp.ShapeComponent.WorldLocation, MoveComp.CollisionShape.Shape, MoveComp.ShapeComponent.WorldRotation);
		TemporalLog.DirectionalArrow("Velocity", ActorLocation, ActorVelocity);
		
		TemporalLog.Value("Driver", Driver);
		TemporalLog.Value("bIsDestroyed", bIsDestroyed);
		TemporalLog.Value("JetskiSpline", JetskiSpline);

		TemporalLog.Section("Movement State")
			.Value("Current", MovementState)
			.Value("Previous", PreviousMovementState)
		;

		TemporalLog.Value("bIsJumpingFromUnderwater", bIsJumpingFromUnderwater);

		TemporalLog.Value("Center of Sphere", GetCenterOfSphere());
		TemporalLog.Value("Wave Height", GetWaveHeight());
		TemporalLog.Value("Water Plane Height", GetWaterPlaneHeight());

		TemporalLog.Value("Is In Water", IsInWater());
		TemporalLog.Value("Is On WaterSurface", IsOnWaterSurface());
		TemporalLog.Value("Is Underwater", IsUnderwater());

		bool bIsWaveDataReady = OceanWaves::IsWaveDataReady(GetFrontWaterSampleComponent().GetWaveInstigator());
		TemporalLog.Value("OceanWave;Is Wave Data Ready", bIsWaveDataReady);

		TemporalLog.Value("OceanWave;Current Delay in Frames", OceanWaves::GetCurrentDelayInFrames());
		TemporalLog.Value("OceanWave;Current Delay in Seconds", OceanWaves::GetCurrentDelayInSeconds());
		TemporalLog.Value("OceanWave;Smooth Delay in Seconds", OceanWaves::GetSmoothDelayInSeconds());
#endif
	}

	void SetDriver(AHazePlayerCharacter InPlayer)
	{
		check(InPlayer != nullptr);
		Driver = InPlayer;
		CapabilityInput::LinkActorToPlayerInput(this, Driver);

		if(Driver.IsMio())		
			SkelMesh.SetMaterial(0, MioMat);
		else		
			SkelMesh.SetMaterial(0, ZoeMat);		
	}

	void Dismount(AHazePlayerCharacter InPlayer)
	{
		check(InPlayer != nullptr);
		CapabilityInput::LinkActorToPlayerInput(this, nullptr);
	}

	void SetMovementState(EJetskiMovementState NewMovementState)
	{
		if(MovementState == NewMovementState)
			return;

		PreviousMovementState = MovementState;
		MovementState = NewMovementState;
	}

	EJetskiMovementState GetMovementState() const
	{
		return MovementState;
	}

	EJetskiMovementState GetPreviousMovementState() const
	{
		return PreviousMovementState;
	}

	void AccelerateUpTowards(FQuat Target, float Duration, float DeltaTime, FInstigator Instigator)
	{
		check(LastAccUpVectorAccelerationFrame < Time::FrameNumber);
		AccUpVector.AccelerateTo(Target, Duration, DeltaTime);
		LastAccUpVectorAccelerationFrame = Time::FrameNumber;
		AccUpVectorInstigator = Instigator;
	}

	void SnapAcceleratedUp(FQuat SnapTo)
	{
		AccUpVector.SnapTo(SnapTo);
	}

	float GetTopOfSphere() const
	{
		return SphereComp.WorldLocation.Z + SphereComp.SphereRadius;
	}

	float GetCenterOfSphere() const
	{
		return SphereComp.WorldLocation.Z;
	}

	FVector GetCenterOfSphereLocation() const
	{
		return SphereComp.WorldLocation;
	}

	float GetWaterLineHeight() const
	{
		return SphereComp.WorldLocation.Z - (SphereComp.SphereRadius * 0.4);
	}

	float GetBotOfSphere() const
	{
		return SphereComp.WorldLocation.Z - SphereComp.SphereRadius;
	}

	float GetSphereRadius() const
	{
		return SphereComp.SphereRadius;
	}

	float GetWaveHeight() const
	{
		return WaterPlaneComp.GetWaveHeight();
	}

	UFUNCTION(BlueprintPure)
	FVector GetWaveLocation() const
	{
		return FVector(ActorLocation.X, ActorLocation.Y, GetWaveHeight());
	}

	float GetWaterPlaneHeight() const
	{
		if(!WaterPlaneComp.OverrideWaterHeight.IsDefaultValue())
			return WaterPlaneComp.OverrideWaterHeight.Get();

		if(OceanWaves::HasOceanWavePaint())
		{
			return OceanWaves::GetOceanWavePaint().TargetLandscape.ActorLocation.Z;
		}
		else
		{
			// Wait for the ocean wave paint actor to become available
			return ActorLocation.Z;
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsTouchingWater() const
	{
		const float TopOfSphere = GetTopOfSphere();
		const float WaveHeight = WaterPlaneComp.GetWaveHeight();

		return (TopOfSphere < WaveHeight);
	}

	UFUNCTION(BlueprintPure)
	bool IsInWater() const
	{
		const float BotOfSphere = GetBotOfSphere();
		const float WaveHeight = WaterPlaneComp.GetWaveHeight();

		if(BotOfSphere > WaveHeight)
			return false;

		// If the water is below us, and we are grounded, don't consider us to be in water
		if(WaveHeight < BotOfSphere && MoveComp.IsOnAnyGround())
			return false;

		return true;
	}
	
	UFUNCTION(BlueprintPure)
	bool IsOnWaterSurface() const
	{
		const float WaveHeight = WaterPlaneComp.GetWaveHeight();

		// If the water is below us, and we are grounded, don't consider us to be in water
		if(WaveHeight < GetCenterOfSphere() && MoveComp.IsOnAnyGround())
			return false;

		return GetBotOfSphere() < WaveHeight && GetTopOfSphere() > WaveHeight;
	}

	UFUNCTION(BlueprintPure)
	bool IsUnderwater() const
	{
		if(!IsInWater())
			return false;

		if(GetTopOfSphere() > WaterPlaneComp.GetWaveHeight())
			return false;

		return true;
	}
	
	UFUNCTION(BlueprintCallable)
	void ApplyWaterHeightOverride(float WaterHeight, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		WaterPlaneComp.OverrideWaterHeight.Apply(WaterHeight, Instigator, Priority);
	}

	UFUNCTION(BlueprintCallable)
	void ClearWaterHeightOverride(FInstigator Instigator)
	{
		WaterPlaneComp.OverrideWaterHeight.Clear(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void ClearAllWaterHeightOverrides()
	{
		WaterPlaneComp.OverrideWaterHeight.Empty();
	}

	float GetSteeringAngle(float Steering, float SpeedAlpha) const
	{
		// If we keep holding the same input, we get more steering over time
		float SteeringBiasAmount = Settings.SteeringBiasAmount * Input.GetSteeringBias();

		float SteeringAmount = Math::Lerp(Settings.SlowMaxSteeringAmount, Settings.FastMaxSteeringAmount, SpeedAlpha);
		SteeringAmount += SteeringBiasAmount;

		return Steering * SteeringAmount;
	}

	float GetSteeringValueFromAngle(float Angle, float SpeedAlpha)
	{
		float SteeringAmount = Math::Lerp(Settings.SlowMaxSteeringAmount, Settings.FastMaxSteeringAmount, SpeedAlpha);
		return Math::Clamp(Angle / SteeringAmount, -1, 1);
	}

	FVector GetUpVector(EJetskiUp Up) const
	{
		switch(Up)
		{
			case EJetskiUp::Global:
				return FVector::UpVector;

			case EJetskiUp::ActorUp:
				return ActorUpVector;

			case EJetskiUp::WorldUp:
				return MoveComp.WorldUp;

			case EJetskiUp::GroundNormal:
			{
				check(MoveComp.HasGroundContact());
				return MoveComp.GroundContact.Normal;
			}

			case EJetskiUp::GroundImpactNormal:
			{
				check(MoveComp.HasGroundContact());
				return MoveComp.GroundContact.ImpactNormal;
			}

			case EJetskiUp::WaterPlane:
			{
				return FVector::UpVector;
			}

			case EJetskiUp::WaveNormal:
			{
				return WaterPlaneComp.GetWaveNormal();
			}

			case EJetskiUp::Spline:
			{
				const UHazeSplineComponent Spline = GetActiveSplineComponent();
				const float DistanceAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
				return Spline.GetWorldRotationAtSplineDistance(DistanceAlongSpline).UpVector;
			}

			case EJetskiUp::Accelerated:
				return AccUpVector.Value.UpVector;
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetHorizontalForward(EJetskiUp Up) const
	{
		return ActorForwardVector.VectorPlaneProject(GetUpVector(Up)).GetSafeNormal();
	}

	UFUNCTION(BlueprintPure)
	float GetForwardSpeed(EJetskiUp Up) const
	{
		return MoveComp.Velocity.DotProduct(GetHorizontalForward(Up));
	}

	UFUNCTION(BlueprintPure)
	FVector GetHorizontalRight(EJetskiUp Up) const
	{
		return ActorRightVector.VectorPlaneProject(GetUpVector(Up)).GetSafeNormal();
	}

	UFUNCTION(BlueprintPure)
	float GetRightSpeed(EJetskiUp Up) const
	{
		return MoveComp.Velocity.DotProduct(GetHorizontalRight(Up));
	}

	UFUNCTION(BlueprintPure)
	float GetVerticalSpeed(EJetskiUp Up) const
	{
		return MoveComp.Velocity.DotProduct(GetUpVector(Up));
	}

	UFUNCTION(BlueprintPure)
	FVector GetHorizontalVelocity(EJetskiUp Up) const
	{
		return MoveComp.Velocity.VectorPlaneProject(GetUpVector(Up));
	}

	UFUNCTION(BlueprintPure)
	FVector GetVerticalVelocity(EJetskiUp Up) const
	{
		return MoveComp.Velocity.ProjectOnToNormal(GetUpVector(Up));
	}

	UFUNCTION(BlueprintPure)
	float GetThrottle() const
	{
		// Get the actual input acceleration (RT on controller, W on keyboard)
		float Throttle = Input.GetAcceleration();

		//Don't go lower than the idle throttle
		Throttle = Math::Max(Throttle, Settings.IdleThrottle);

		// While steering, we also apply some throttle, since it looks weird when the jetski turns in place
		const float ThrottleFromSteering = Math::Abs(AccSteering.Value) * Settings.ThrottleFromSteering;
		Throttle = Math::Max(Throttle, ThrottleFromSteering);

		// If we are diving, also change the throttle
		if(Input.IsActioningDive())
			Throttle = Math::Max(Throttle, Settings.ThrottleFromDiving);

		return Throttle;
	}

	bool TryGetForceThrottle(float&out OutThrottle) const
	{
		TOptional<FAlongSplineComponentData> PreviousForceThrottleComp = JetskiSpline.Spline.FindPreviousComponentAlongSpline(UJetskiSplineForceThrottleComponent, true, GetDistanceAlongSpline());
		if(PreviousForceThrottleComp.IsSet())
		{
			auto ForceThrottleComp = Cast<UJetskiSplineForceThrottleComponent>(PreviousForceThrottleComp.Value.Component);
			if(ForceThrottleComp != nullptr && ForceThrottleComp.bForceThrottle)
			{
				OutThrottle = ForceThrottleComp.ForcedThrottle;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	float GetThrottleInput() const
	{
		// Get the actual input acceleration (RT on controller, W on keyboard)
		return  Input.GetAcceleration();	
	}

	float GetAcceleratedSpeed(float InitialSpeed, float DeltaTime) const
	{
		float Speed = InitialSpeed;

		float TargetSpeed = GetTargetSpeed(MoveComp.MovementSettings.MaxSpeed, MoveComp.MovementSettings.MaxSpeedWhileTurning);

		const bool bIsAccelerating = Speed < TargetSpeed;

		float InterpSpeed = bIsAccelerating ? MoveComp.MovementSettings.Acceleration : MoveComp.MovementSettings.Deceleration;

		const FVector HorizontalForward = GetHorizontalForward(EJetskiUp::Global);
		const FVector SplineHorizontalForward = GetSplineHorizontalForward(EJetskiUp::Global);

		const bool bIsHeadingInCorrectDirection = HorizontalForward.DotProduct(SplineHorizontalForward) > 0.2;
		if(bIsHeadingInCorrectDirection)
		{
			const float RubberBandMultiplier = GetRubberBandMultiplier();
			const bool bIsBehind = RubberBandMultiplier > 1.0;
			TargetSpeed *= RubberBandMultiplier;

			// Only change the interp speed if it will help us rubberband
			if(bIsBehind && bIsAccelerating)
				InterpSpeed *= RubberBandMultiplier;
			else if(!bIsBehind && bIsAccelerating)
				InterpSpeed *= RubberBandMultiplier;
		}

		Speed = Math::FInterpConstantTo(Speed, TargetSpeed, DeltaTime, InterpSpeed);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("GetAcceleratedSpeed");
		TemporalLog.Value("InitialSpeed", InitialSpeed);
		TemporalLog.Value("DeltaTime", DeltaTime);
		TemporalLog.Value("TargetSpeed", TargetSpeed);
		TemporalLog.Value("bIsAccelerating", bIsAccelerating);
		TemporalLog.Value("InterpSpeed", InterpSpeed);
		TemporalLog.DirectionalArrow("HorizontalForward", ActorLocation, HorizontalForward * 1000);
		TemporalLog.DirectionalArrow("SplineHorizontalForward", ActorLocation, SplineHorizontalForward * 1000);
		TemporalLog.Value("bIsHeadingInCorrectDirection", bIsHeadingInCorrectDirection);
		TemporalLog.Value("Speed", Speed);
#endif

		return Speed;
	}

	float GetTargetSpeed(float MaxSpeed, float MaxSpeedWhileTurning) const
	{
		float TargetSpeed = Math::Lerp(MaxSpeed, MaxSpeedWhileTurning, Math::Abs(AccSteering.Value));
		TargetSpeed *= GetThrottle();

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("GetTargetSpeed");
		TemporalLog.Value("Initial TargetSpeed", Math::Lerp(MaxSpeed, MaxSpeedWhileTurning, Math::Abs(AccSteering.Value)));
		TemporalLog.Value("MaxSpeed", MaxSpeed);
		TemporalLog.Value("MaxSpeedWhileTurning", MaxSpeedWhileTurning);
		TemporalLog.Value("Steering", Math::Abs(AccSteering.Value));
		TemporalLog.Value("Throttle", GetThrottle());
		TemporalLog.Value("Final TargetSpeed", TargetSpeed);
#endif

		return TargetSpeed;
	}

	/**
	 * This funky function takes the current velocity (Horizontal AND Vertical)
	 * and injects a new forward speed into it, without changing the vertical speed
	 * What is vertical is decided by Up, so we can change it based on the movement mode
	 */
	FVector SetNewForwardVelocity(FVector Velocity, EJetskiUp Up, float DeltaTime) const
	{
		// First we calculate the old forward and side velocity. The side velocity is everything on the horizontal
		// plane that is not in the forward direction
		const FVector OldHorizontalVelocity = Velocity.VectorPlaneProject(GetUpVector(Up));
		const FVector OldForwardVelocity = OldHorizontalVelocity.ProjectOnToNormal(GetHorizontalForward(Up));
		const FVector OldSideVelocity = OldHorizontalVelocity - OldForwardVelocity;

		// We then calculate the new forward speed by interpolating towards it
		const float InitialForwardSpeed = GetForwardSpeed(Up);
		const float NewForwardSpeed = GetAcceleratedSpeed(InitialForwardSpeed, DeltaTime);

		// Then we calculate the new forward and side velocities separately
		// The side velocity is simply interpolated towards 0, so that we will eventually only travel in the horizontal forward direction
		const FVector NewForwardVelocity = GetHorizontalForward(Up) * NewForwardSpeed;
		const FVector NewSideVelocity = Math::VInterpTo(OldSideVelocity, FVector::ZeroVector, DeltaTime, MoveComp.MovementSettings.SideSpeedDeceleration);
		const FVector NewHorizontalVelocity = NewForwardVelocity + NewSideVelocity;

		// We then remove the old horizontal velocity, and add the new one instead
		const FVector OldVerticalVelocity = Velocity - OldHorizontalVelocity;
		const FVector NewVelocity = OldVerticalVelocity + NewHorizontalVelocity;

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("SetNewForwardVelocity");
		TemporalLog.DirectionalArrow("Old Velocity", ActorLocation, Velocity);
		TemporalLog.DirectionalArrow("Old HorizontalVelocity", ActorLocation, OldHorizontalVelocity);
		TemporalLog.DirectionalArrow("Old ForwardVelocity", ActorLocation, OldForwardVelocity);
		TemporalLog.DirectionalArrow("Old SideVelocity", ActorLocation, OldSideVelocity);

		TemporalLog.DirectionalArrow("HorizontalForward", ActorLocation, GetHorizontalForward(Up));
		TemporalLog.Value("Initial ForwardSpeed", InitialForwardSpeed);
		TemporalLog.Value("New ForwardSpeed", NewForwardSpeed);

		TemporalLog.DirectionalArrow("New HorizontalVelocity", ActorLocation, NewHorizontalVelocity);
		TemporalLog.DirectionalArrow("New ForwardVelocity", ActorLocation, NewForwardVelocity);

		TemporalLog.DirectionalArrow("Old VerticalVelocity", ActorLocation, OldVerticalVelocity);
		TemporalLog.DirectionalArrow("New Velocity", ActorLocation, NewVelocity);
#endif

		return NewVelocity;
	}

	FVector GetSplineHorizontalForward(EJetskiUp Up) const
	{
		const auto SplineComp = GetActiveSplineComponent();
		const float SplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		const FVector SplineForward = JetskiSpline.Spline.GetWorldForwardVectorAtSplineDistance(SplineDistance);
		return SplineForward.VectorPlaneProject(GetUpVector(Up)).GetSafeNormal();
	}

	float GetRubberBandMultiplier() const
	{
		const float RubberBandFactor = Jetski::GetRubberBandFactor(this);
		if(Math::Abs(RubberBandFactor) > KINDA_SMALL_NUMBER)
		{
			if(RubberBandFactor > 0)
				return Math::Lerp(1, Settings.RubberBandSpeedUpMultiplier, RubberBandFactor);
			else
				return Math::Lerp(1, Settings.RubberBandSlowDownMultiplier, -RubberBandFactor);
		}

		return 1;
	}

	void SteerJetski(UJetskiMovementData& Movement, float DeltaTime)
	{
		switch(Settings.SteeringMode)
		{
			case EJetskiSteeringMode::Rotate:
			{
				SteerJetskiRotate(Movement, DeltaTime);
				break;
			}

			case EJetskiSteeringMode::Spline:
			{
				SteerJetskiSpline(Movement, DeltaTime);
				break;
			}

			default:
			{
				devError(f"Unimplemented SteeringMode! {Settings.SteeringMode}");
				break;
			}
		}
	}

	private void SteerJetskiRotate(UJetskiMovementData& MoveData, float DeltaTime)
	{
		const float SpeedAlpha = Math::Clamp(MoveComp.HorizontalVelocity.Size(), Settings.SteerMinSpeed, Settings.SteerMaxSpeed) / Settings.SteerMaxSpeed;

		AngularSpeed = -GetSteeringAngle(AccSteering.Value, SpeedAlpha);

		FRotator DeltaRotation = Math::RotatorFromAxisAndAngle(AccUpVector.Value.UpVector, -AngularSpeed * DeltaTime);
		FRotator NewRotation = GetCurrentRotation().Compose(DeltaRotation);
		MoveData.SetRotation(NewRotation);
	}

	private void SteerJetskiSpline(UJetskiMovementData& MoveData, float DeltaTime)
	{
		const float SpeedAlpha = Math::Clamp(MoveComp.HorizontalVelocity.Size(), Settings.SteerMinSpeed, Settings.SteerMaxSpeed) / Settings.SteerMaxSpeed;

		float TurnAmount = GetSteeringAngle(AccSteering.Value, SpeedAlpha);

		const FTransform SplineTransform = GetSplineTransform();

		FQuat NewRotation = SplineTransform.TransformRotation(FQuat(FVector::UpVector, Math::DegreesToRadians(TurnAmount)));
		NewRotation = FQuat::MakeFromZX(FVector::UpVector, NewRotation.ForwardVector);

		MoveData.SetRotation(NewRotation);
		PrintToScreen(f"{TurnAmount=}");
		PrintToScreen(f"{PreviousTurnAmount=}");

		AngularSpeed = (TurnAmount - PreviousTurnAmount) / DeltaTime;
		PrintToScreen(f"{AngularSpeed=}");

		PreviousTurnAmount = TurnAmount;
	}

	FRotator GetCurrentRotation() const
	{
		return FRotator::MakeFromZX(AccUpVector.Value.UpVector, ActorForwardVector);
	}

	UHazeSplineComponent GetActiveSplineComponent() const
	{
		if(JetskiSpline == nullptr)
			return nullptr;

		return JetskiSpline.Spline;
	}

	FTransform GetSplineTransform(float LeadAmount = 0) const
	{
		const UHazeSplineComponent SplineComp = GetActiveSplineComponent();
		if(LeadAmount == 0)
		{
			return SplineComp.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
		}
		else
		{
			float SplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
			return SplineComp.GetWorldTransformAtSplineDistance(SplineDistance + LeadAmount);
		}
	}

	float GetSideDistance(bool bAbsolute) const
	{
		const FVector Diff = ActorLocation - GetSplineTransform().Location;
		if(bAbsolute)
			return Math::Abs(Diff.DotProduct(GetSplineTransform().Rotation.RightVector));
		else
			return Diff.DotProduct(GetSplineTransform().Rotation.RightVector);
	}

	FVector GetSplineUp() const
	{
		return GetSplineTransform().Rotation.UpVector;
	}

	FVector GetSplineRight() const
	{
		return GetSplineTransform().Rotation.RightVector;
	}

	FVector GetSplineForward() const
	{
		return GetSplineTransform().Rotation.ForwardVector;
	}

	float GetSplineWidth() const
	{
		const FTransform Transform = GetSplineTransform();
		return Transform.Scale3D.Y;
	}

	bool IsOutsideSplineWidth() const
	{
		const float SideDistance = GetSideDistance(true);
		const float Width = GetSplineWidth();
		return SideDistance > Width;
	}

	float GetDistanceAlongSpline() const
	{
		const UHazeSplineComponent SplineComp = GetActiveSplineComponent();
		return SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
	}

	UFUNCTION(BlueprintEvent)
	UJetskiWaterSampleComponent GetFrontWaterSampleComponent() const
	{
		return nullptr;
	}

	access:Resolver
	void ApplyPoleRedirect(FVector InPoleRedirectImpulse)
	{
		MeshOffset.FreezeLocationAndLerpBackToParent(this, 0.1);
		BobbingComponent.AddBobbingAngularImpulse(InPoleRedirectImpulse * Settings.BobbingReflectImpulseMultiplier);

		ReflectedFrame = Time::FrameNumber;
		ReflectedImpulse = InPoleRedirectImpulse;

		ApplyCameraImpulseFromReflect(InPoleRedirectImpulse);

		FJetskiOnHitWallEventData EventData;
		EventData.Impulse = InPoleRedirectImpulse;
		EventData.Player = Driver;
		UJetskiEventHandler::Trigger_OnHitWall(this, EventData);
	}

	access:Resolver
	void ApplyDeathFromImpact(uint InDeathFromImpactFrame, FHitResult InDeathImpact, FVector InDeathVelocity)
	{
		DeathImpactFrame = InDeathFromImpactFrame;
		DeathImpact = InDeathImpact;
		BobbingComponent.AddBobbingImpulse(InDeathVelocity);
	}

	access:Death
	bool DeathImpactThisFrame() const
	{
		return DeathImpactFrame == Time::FrameNumber;
	}

	access:Death
	FHitResult GetDeathImpact() const
	{
		check(DeathImpactThisFrame());
		return DeathImpact;
	}

	access:Resolver
	void ApplyReflectedOffWall(FVector ReflectionImpulse, FQuat ReflectionDeltaRotation)
	{
		BobbingComponent.AddBobbingAngularImpulse(ReflectionImpulse * Settings.BobbingReflectImpulseMultiplier);
		BobbingComponent.RelativeOffsetFromImpact = ReflectionDeltaRotation.Inverse().Rotator();

		ReflectedFrame = Time::FrameNumber;
		ReflectedImpulse = ReflectionImpulse;

		ApplyCameraImpulseFromReflect(ReflectionImpulse);

		FJetskiOnHitWallEventData EventData;
		EventData.Impulse = ReflectionImpulse;
		EventData.Player = Driver;
		UJetskiEventHandler::Trigger_OnHitWall(this, EventData);
	}

	private void ApplyCameraImpulseFromReflect(FVector ReflectionImpulse) const
	{
		if(Driver == nullptr)
			return;

		if(!Settings.bBobbingReflectApplyCameraImpulse)
			return;

		// Apply the impulse to the camera, making it react to the hit
		FHazeCameraImpulse CameraImpulse;
		CameraImpulse.WorldSpaceImpulse = ReflectionImpulse * Settings.BobbingReflectCameraImpulseMultiplier;
		CameraImpulse.AngularImpulse = FQuat(ReflectionImpulse.GetSafeNormal(), ReflectionImpulse.Size() * Settings.BobbingReflectCameraAngularImpulseMultiplier).Rotator();
		CameraImpulse.Dampening = Settings.BobbingReflectCameraImpulseDampening;
		CameraImpulse.ExpirationForce = Settings.BobbingReflectCameraImpulseExpirationForce;
		Driver.ApplyCameraImpulse(CameraImpulse, this);
	}

	void AttachSoundDefs()
	{
		TArray<FSoundDefReference> SoundDefs = Driver.IsMio() ? MioSoundDefs : ZoeSoundDefs;
		for(auto SoundDefData : SoundDefs)
		{
			if(!SoundDefData.SoundDef.IsValid())
				continue;

			SoundDefData.SpawnSoundDefAttached(this, this);
		}
	}

	void RemoveSoundDefs()
	{
		TArray<FSoundDefReference> SoundDefs = Driver.IsMio() ? MioSoundDefs : ZoeSoundDefs;
		for(auto SoundDefData : SoundDefs)
		{
			if(!SoundDefData.SoundDef.IsValid())
				continue;
		
			RemoveSoundDef(SoundDefData);
		}
	}

	UFUNCTION()
	void ActivateCutsceneEffects()
	{
		UJetskiEventHandler::Trigger_OnStartThrottleInWaterVisual(this);
		UJetskiEventHandler::Trigger_OnStartWaterSurfaceVisual(this);
		UJetskiEventHandler::Trigger_OnStartThrottle(this);
	}
}