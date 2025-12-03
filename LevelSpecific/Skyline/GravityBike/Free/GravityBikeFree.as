#if !RELEASE
namespace DevToggleGravityBikeFree
{
	const FHazeDevToggleBool DisableGravityBikeDriving;
	const FHazeDevToggleBool PrintGravityBikeMaxSpeed;
};
#endif

event void FGravityBikeFreeOnHitImpactResponseComponent(UGravityBikeFreeImpactResponseComponent ResponseComp, FGravityBikeFreeOnImpactData ImpactData);
event void FGravityBikeFreeOnTeleported();

struct FGravityBikeFreeAnimationData
{
	float SpeedAlpha;
    float AngularSpeedAlpha;

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
};

struct FGravityBikeFreeInput
{
	access Sync = private, UGravityBikeFreeSyncComponent;

	private const UGravityBikeFreeSyncComponent SyncComp;

	float Steering = 0;
    access:Sync float ControlThrottle = 0;

    bool bTappedDrift = false;
    bool bDrift = false;

	void Initialize(const UGravityBikeFreeSyncComponent InSyncComp)
	{
		SyncComp = InSyncComp;
	}

	void SetThrottle(float InThrottle) property
	{
		check(SyncComp.HasControl());
		ControlThrottle = InThrottle;
	}

	float GetThrottle() const property
	{
		if(SyncComp == nullptr || SyncComp.HasControl())
			return ControlThrottle;
		else
			return SyncComp.GetValue().Throttle;
	}

	void Reset()
	{
		Steering = 0;
		Throttle = 0;
		bTappedDrift = false;
		bDrift = false;
	}
};

UCLASS(Abstract)
class AGravityBikeFree : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	access Resolver = private, UGravityBikeFreeMovementResolver;
	access Death = private, UGravityBikeFreeDriverDeathCapability;

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Sphere;
	default Sphere.SphereRadius = 48;
	default Sphere.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default Sphere.CollisionProfileName = n"PlayerCharacter";

	UPROPERTY(DefaultComponent, Attach = Sphere)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.RelativeLocation = FVector(26, 0, -58);

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh, AttachSocket = "Base")
	USceneComponent DriverAttachment;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UGravityBikeWheelComponent FrontWheelComp;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UGravityBikeWheelComponent BackWheelComp;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	USceneComponent CrosshairPivot;

	UPROPERTY(DefaultComponent, Attach = CrosshairPivot)
	UWidgetComponent CrosshairWidgetComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	USplineLockComponent SplineLockComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedActorPositionComp;
	default CrumbSyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default CrumbSyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeSyncComponent SyncComp;
	default SyncComp.SyncRate = EHazeCrumbSyncRate::High;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLogger;

	UPROPERTY(DefaultComponent)
	UMovementInstigatorLogComponent MovementInstigatorLogComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeSequenceEditorComponent SequenceEditorComponent;
#endif

	private AHazePlayerCharacter Driver = nullptr;
	AHazePlayerCharacter GetBikeDriver() const property
	{
		return Driver;
	}

	FHazeAcceleratedFloat AccSteering;

	TInstigated<bool> IsAirborne;
	default IsAirborne.DefaultValue = false;

	private FHazeAcceleratedQuat AccUpVector;
	private uint LastAccUpModifiedFrame = 0;
	private FInstigator LastAccUpModifiedInstigator;

	uint ForwardTraceWasRedirectedFrame;

	FGravityBikeFreeInput Input;
	TInstigated<float> ForcedThrottle;
	TInstigated<float> ForcedSteering;

	float CachedForwardAcceleration;
	uint CachedForwardAccelerationFrame = 0;

	access:Death
	uint DeathFromWallHitFrame = 0;
	access:Death
	FHitResult DeathFromWallHitResult;

	private uint AlignedWithWallFrame = 0;
	float AlignedWithWallTime = -1;

	UPROPERTY()
	FGravityBikeFreeOnHitImpactResponseComponent OnHitImpactResponseComponent;

	UPROPERTY()
	FGravityBikeFreeOnTeleported OnTeleported;

	// Animation
	FGravityBikeFreeAnimationData AnimationData;

	UGravityBikeFreeSettings Settings;

	UGravityBikeFreeHoverComponent HoverComp;
	private UGravityBikeFreeCameraDataComponent CameraDataComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UGravityBikeFreeSettings::GetSettings(this);

		MoveComp.SetupShapeComponent(Sphere);

		UMovementGravitySettings::SetGravityAmount(this, GravityBikeFree::GravityFactor, this);

		AccUpVector.SnapTo(FQuat::MakeFromZX(ActorUpVector, ActorForwardVector));

		if(Settings.MinimumSpeed > 0)
		{
			SetActorVelocity(ActorForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal() * Settings.MinimumSpeed);
		}

		HoverComp = UGravityBikeFreeHoverComponent::Get(this);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(this);

#if !RELEASE
		DevToggleGravityBikeFree::DisableGravityBikeDriving.MakeVisible();
		DevToggleGravityBikeFree::PrintGravityBikeMaxSpeed.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(EndPlayReason == EEndPlayReason::Destroyed && !(World.IsTearingDown() || Level.IsBeingRemoved() || !Level.IsLevelActive()))
		{
			check(false, "Don't destroy! Call Unspawn instead!");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsControlledByCutscene)
			return;

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value("Steering;AccSteering", AccSteering.Value);

		TemporalLog.Value("Input;Steering", Input.Steering);
		TemporalLog.Value("Input;Throttle", Input.Throttle);
		TemporalLog.Value("Input;bDrift", Input.bDrift);

		TemporalLog.Value("Misc;IsAirborne", IsAirborne.Get());
		TemporalLog.Value("Misc;IsAirborne Instigator", IsAirborne.CurrentInstigator);
		
		TemporalLog.DirectionalArrow("Misc;AccUpVector", ActorLocation, GetAcceleratedUp() * 200, 5, 20);
		TemporalLog.Value("Misc;HasModifiedAccUpVectorThisFrame", HasModifiedAccUpVectorThisFrame());
		TemporalLog.Value("Misc;LastAccUpModifiedInstigator", LastAccUpModifiedInstigator);

		TemporalLog.Value("Misc;CachedForwardAcceleration", CachedForwardAcceleration);

		if(DevToggleGravityBikeFree::PrintGravityBikeMaxSpeed.IsEnabled())
		{
			PrintToScreen(f"{GetActorNameOrLabel()} MaxSpeed: {MoveComp.GetMaxSpeed()}");
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return Sphere.WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetDriver() const
	{
		return Driver;
	}

	void SetDriver(AHazePlayerCharacter InDriver)
	{
		check(Driver == nullptr);
		Driver = InDriver;
	}

	void SnapToTransform(FTransform Transform)
	{
		TeleportActor(Transform.Location, Transform.Rotator(), this);
		SnapUpTo(Transform.Rotation.UpVector, FInstigator(this, n"OnPlayerTeleported"));
		ResetAccUpVectorFrame();
		AccSteering.SnapTo(0);

		MoveComp.Reset(false, Transform.Rotation.UpVector, true);
	}

	bool HasExploded() const
	{
		if(Driver.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentRollAmount() const
	{
		const float CurrentRoll = MeshPivot.RelativeRotation.Roll;
		const float NormalizedValue = CurrentRoll / HoverComp.Settings.MaxRoll;
		return Math::Clamp(NormalizedValue, -1, 1);
	}
	
	float GetSpeedAlpha(float Speed) const
	{
		return Math::Saturate(Speed / Settings.FastSpeedThreshold);
	}

	float GetSteerAlpha(float Speed, bool bAccelerated) const
	{
		const float Steering = bAccelerated ? AccSteering.Value : Input.Steering;
		return Steering * GetSpeedAlpha(Speed);
	}

	float GetSteeringAngleRad(float Speed) const
	{
		if(IsDrifting())
		{
			const float SteeringAmount = Settings.FastMaxSteeringAngleDeg;
			return AccSteering.Value * Math::DegreesToRadians(SteeringAmount);
		}
		else
		{
			const float SpeedAlpha = Math::Saturate(Math::NormalizeToRange(Speed, Settings.SlowSpeedThreshold, Settings.FastSpeedThreshold));
			const float SteeringAmount = Math::Lerp(Settings.SlowMaxSteeringAngleDeg, Settings.FastMaxSteeringAngleDeg, SpeedAlpha);
			return AccSteering.Value * Math::DegreesToRadians(SteeringAmount);
		}
	}

	void TurnBike(UGravityBikeFreeMovementData& Movement, float DeltaTime)
	{
		float Speed = MoveComp.HorizontalVelocity.Size();

		const FQuat DeltaRotation = FQuat(GetAcceleratedUp(), GetSteeringAngleRad(Speed) * DeltaTime);
		const FVector NewForward = DeltaRotation * ActorForwardVector;
		const FQuat NewRotation = FQuat::MakeFromZX(GetAcceleratedUp(), NewForward);
		Movement.SetRotation(NewRotation);
	}

	bool IsSteering() const
	{
		if(Math::Abs(Input.Steering) > 0.2)
			return true;

		return false;
	}

	FVector GetCameraDir() const
	{
		return Driver.ViewRotation.ForwardVector.VectorPlaneProject(ActorUpVector).GetSafeNormal();
	}

	bool HasModifiedAccUpVectorThisFrame() const
	{
		return LastAccUpModifiedFrame == Time::FrameNumber;
	}

	void ResetAccUpVectorFrame()
	{
		LastAccUpModifiedFrame = 0;
		LastAccUpModifiedInstigator = nullptr;
	}

	void AccelerateUpTo(FVector TargetUp, float Duration, float DeltaTime, FInstigator Instigator)
	{
		AccelerateUpTo(TargetUp, ActorForwardVector, Duration, DeltaTime, Instigator);
	}

	void AccelerateUpTo(FVector TargetUp, FVector TargetForward, float Duration, float DeltaTime, FInstigator Instigator)
	{
		check(!HasModifiedAccUpVectorThisFrame());

		const FQuat TargetRot = FQuat::MakeFromZX(TargetUp, TargetForward);
		AccUpVector.AccelerateTo(TargetRot, Duration, DeltaTime);

		LastAccUpModifiedFrame = Time::FrameNumber;
		LastAccUpModifiedInstigator = Instigator;
	}

	void SnapUpTo(FVector TargetUp, FInstigator Instigator)
	{
		SnapUpTo(TargetUp, ActorForwardVector, Instigator);
	}

	void SnapUpTo(FVector TargetUp, FVector TargetForward, FInstigator Instigator)
	{
		const FQuat TargetRot = FQuat::MakeFromZX(TargetUp, TargetForward);
		AccUpVector.SnapTo(TargetRot);

		LastAccUpModifiedFrame = Time::FrameNumber;
		LastAccUpModifiedInstigator = Instigator;
	}

	FVector GetAcceleratedUp() const
	{
		return AccUpVector.Value.UpVector;
	}

	UFUNCTION(BlueprintCallable)
	void ApplyForcedThrottle(float Throttle, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		ForcedThrottle.Apply(Throttle, Instigator, Priority);
	}
	
	UFUNCTION(BlueprintCallable)
	void ClearForcedThrottle(FInstigator Instigator)
	{
		ForcedThrottle.Clear(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void ApplyForcedSteering(float Steering, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		ForcedSteering.Apply(Steering, Instigator, Priority);
	}
	
	UFUNCTION(BlueprintCallable)
	void ClearForcedSteering(FInstigator Instigator)
	{
		ForcedSteering.Clear(Instigator);
	}

	access:Resolver
	void OnLanding(float LandingImpulse, FHitResult LandingHit)
	{
		if(!ensure(HasControl()))
			return;

		FGravityBikeFreeOnGroundImpactEventData EventData;
		EventData.GroundImpactPoint = LandingHit.ImpactPoint;
		EventData.GroundNormal = LandingHit.Normal;
		EventData.ImpactStrength = LandingImpulse;

		FPlane LandingGroundPlane = FPlane(LandingHit.ImpactPoint, LandingHit.ImpactNormal);

		CrumbOnLanding(LandingImpulse, EventData, LandingGroundPlane);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnLanding(float LandingImpulse, FGravityBikeFreeOnGroundImpactEventData EventData, FPlane LandingGroundPlane)
	{
		UGravityBikeFreeEventHandler::Trigger_OnGroundImpact(this, EventData);

		AnimationData.FloorImpactFrame = Time::FrameNumber;
		AnimationData.FloorImpactImpulse = LandingImpulse;

		if(Settings.bApplyPitchImpulseOnLanding)
			ApplyPitchImpulseOnLanding(LandingImpulse, LandingGroundPlane);
	}

	private void ApplyPitchImpulseOnLanding(float LandingImpulse, FPlane LandingGroundPlane)
	{
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
		AnimationData.LeaveGroundFrame = Time::FrameNumber;
		UGravityBikeFreeEventHandler::Trigger_OnLeaveGround(this);
	}

	access:Resolver
	void BroadcastMovementImpacts(TArray<FGravityBikeFreeImpactResponseComponentAndData> Impacts)
	{
		if(!ensure(HasControl()))
			return;

		CrumbBroadcastMovementImpacts(Impacts);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBroadcastMovementImpacts(TArray<FGravityBikeFreeImpactResponseComponentAndData> Impacts)
	{
		for(const FGravityBikeFreeImpactResponseComponentAndData& Impact : Impacts)
		{
			// Notify ourselves of the impact
			OnHitImpactResponseComponent.Broadcast(Impact.ResponseComp, Impact.ImpactData);

			// Notify the response component of the impact
			Impact.ResponseComp.OnImpact.Broadcast(this, Impact.ImpactData);
		}
	}

	access:Resolver
	void ApplyDeathFromWall(uint InDeathFromWallHitFrame, FHitResult InDeathFromWallHitResult)
	{
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

	access:Resolver
	void ApplyAlignWithWall(FHitResult WallImpact, FVector AlignWithWallImpulse, FQuat AlignWithWallDeltaRotation)
	{
		FGravityBikeFreeOnWallImpactEventData EventData;
		EventData.ImpactPoint = WallImpact.ImpactPoint;
		EventData.ImpactNormal = WallImpact.ImpactNormal;
		UGravityBikeFreeEventHandler::Trigger_OnWallImpact(this, EventData);

		if(Time::GetGameTimeSince(AlignedWithWallTime) > 0.5)
			ApplyAlignWithWallImpulse(AlignWithWallImpulse, AlignWithWallDeltaRotation);

		AlignedWithWallFrame = Time::FrameNumber;
		AlignedWithWallTime = Time::GameTimeSeconds;
	}

	private void ApplyAlignWithWallImpulse(FVector AlignWithWallImpulse, FQuat AlignWithWallDeltaRotation)
	{
		FVector PreRotationReflectionImpulse = AlignWithWallDeltaRotation.Inverse() * AlignWithWallImpulse;
		HoverComp.AddRotationalImpulse(-PreRotationReflectionImpulse * GravityBikeFree::WallAlign::WallAlignImpulseMultiplier);
		HoverComp.RelativeOffsetFromImpact = AlignWithWallDeltaRotation.Inverse().Rotator();

		if(Driver == nullptr)
			return;

		if(GravityBikeFree::WallAlign::bWallAlignApplyCameraImpulse)
		{
			// Apply the impulse to the camera, making it react to the hit
			FHazeCameraImpulse CameraImpulse;
			CameraImpulse.WorldSpaceImpulse = AlignWithWallImpulse * GravityBikeFree::WallAlign::WallAlignCameraImpulseMultiplier;
			CameraImpulse.AngularImpulse = FQuat(AlignWithWallImpulse.GetSafeNormal(), AlignWithWallImpulse.Size() * GravityBikeFree::WallAlign::WallAlignCameraAngularImpulseMultiplier).Rotator();
			CameraImpulse.Dampening = GravityBikeFree::WallAlign::WallAlignCameraImpulseDampening;
			CameraImpulse.ExpirationForce = GravityBikeFree::WallAlign::WallAlignCameraImpulseExpirationForce;
			Driver.ApplyCameraImpulse(CameraImpulse, this);
		}
	}

	bool AlignedWithWallThisOrLastFrame() const
	{
		return AlignedWithWallFrame >= Time::FrameNumber - 1;
	}

	bool IsDrifting() const
	{
		if(IsKartDrifting())
			return true;

		return false;
	}

	void ApplyVentAlignWithSide(FVector AlignWithWallImpulse, FQuat AlignWithWallDeltaRotation)
	{
		if(Time::GetGameTimeSince(AlignedWithWallTime) > 0.5)
			ApplyAlignWithWallImpulse(AlignWithWallImpulse, AlignWithWallDeltaRotation);

		AlignedWithWallFrame = Time::FrameNumber;
		AlignedWithWallTime = Time::GameTimeSeconds;
	}
}