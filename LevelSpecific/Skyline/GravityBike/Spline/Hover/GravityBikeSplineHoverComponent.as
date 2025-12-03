UCLASS(NotBlueprintable)
class UGravityBikeSplineHoverComponent : UActorComponent
{
	private AGravityBikeSpline GravityBike;
	UGravityBikeSplineHoverSettings Settings;

	FHazeAcceleratedFloat AccPitch;
	int PitchBounceCount = 0;
	FHazeAcceleratedFloat AccYaw;
	FHazeAcceleratedFloat AccRoll;

	FTransform InitialRelativeTransform;
	FRotator RelativeOffsetFromImpact;

	UGravityBikeSplineHoverSyncedDataComponent SyncedHoverDataComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		Settings = UGravityBikeSplineHoverSettings::GetSettings(GravityBike);

		InitialRelativeTransform = GravityBike.MeshPivot.RelativeTransform;

		SyncedHoverDataComp = UGravityBikeSplineHoverSyncedDataComponent::GetOrCreate(GravityBike, n"SyncedHoverDataComp");

		auto TeleportComp = UTeleportResponseComponent::GetOrCreate(GravityBike);
		TeleportComp.OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value("Pitch;Value", AccPitch.Value);
		TemporalLog.Value("Pitch;Velocity", AccPitch.Velocity);

		TemporalLog.Value("Yaw;Value", AccYaw.Value);
		TemporalLog.Value("Yaw;Velocity", AccYaw.Velocity);

		TemporalLog.Value("Roll;Value", AccRoll.Value);
		TemporalLog.Value("Roll;Velocity", AccRoll.Velocity);

		FRotator AccRotation = FRotator(AccPitch.Value, AccYaw.Value, AccRoll.Value);
		AccRotation = GravityBike.ActorTransform.TransformRotation(AccRotation);
		TemporalLog.DirectionalArrow("Combined Rotation", GravityBike.ActorLocation, AccRotation.ForwardVector * 1000);
#endif
	}

	void AddRotationalImpulse(FVector Impulse)
	{
		FVector RotateAxis = -FVector::UpVector.CrossProduct(Impulse).GetSafeNormal();

		if(Settings.bImpactRollTowardsWall)
			RotateAxis *= -1;
		
		const FVector AngularImpulse = RotateAxis * Impulse.Size();
		
		AddPitchImpulse(AngularImpulse);
		AddRollImpulse(AngularImpulse);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Impulses");
		TemporalLog.DirectionalArrow("Impulse", GravityBike.ActorLocation, Impulse);
		TemporalLog.DirectionalArrow("Right", GravityBike.ActorLocation, RotateAxis * 1000);
		TemporalLog.DirectionalArrow("AngularVelocity", GravityBike.ActorLocation, AngularImpulse);
#endif
	}

	void AddPitchImpulse(FVector AngularImpulse, bool bClamp = true)
	{
		const float PitchImpulse = AngularImpulse.DotProduct(GravityBike.ActorRightVector);

		AccPitch.Velocity += PitchImpulse;

		PitchBounceCount = 0;

		if(bClamp)
			AccPitch.Velocity = GetClampedPitchVelocity(AccPitch.Velocity);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Impulses");
		TemporalLog.DirectionalArrow("PitchImpulse", GravityBike.ActorLocation, GravityBike.ActorRightVector * PitchImpulse);
#endif
	}

	void AddRollImpulse(FVector AngularImpulse)
	{
		const float RollImpulse = AngularImpulse.DotProduct(GravityBike.ActorForwardVector);

		AccRoll.Velocity += RollImpulse;
		AccRoll.Velocity = GetClampedRollVelocity(AccRoll.Velocity);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Impulses");
		TemporalLog.DirectionalArrow("RollImpulse", GravityBike.ActorLocation, GravityBike.ActorForwardVector * RollImpulse);
#endif
	}

			float GetClampedPitch(float Pitch)
	{
		float MaxPitch = Settings.MaxPitch;
		return Math::Clamp(Pitch, -MaxPitch, MaxPitch);
	}

	float GetClampedPitchVelocity(float PitchVelocity)
	{
		float MaxPitchVelocity = Settings.MaxPitchVelocity;
		return Math::Clamp(PitchVelocity, -MaxPitchVelocity, MaxPitchVelocity);
	}

	float GetClampedRoll(float Roll)
	{
		float MaxRoll = Settings.MaxRoll;
		return Math::Clamp(Roll, -MaxRoll, MaxRoll);
	}

	float GetClampedRollVelocity(float RollVelocity)
	{
		float MaxRollVelocity = Settings.MaxRollVelocity;
		return Math::Clamp(RollVelocity, -MaxRollVelocity, MaxRollVelocity);
	}

	void ApplyLocationAndRotation()
	{
		if(GravityBike.bIsControlledByCutscene)
			return;

		AccPitch.Value = GetClampedPitch(AccPitch.Value);
		AccRoll.Value = GetClampedRoll(AccRoll.Value);

		FRotator RelativeRotation;
		RelativeRotation.Pitch = AccPitch.Value;
		RelativeRotation.Yaw = AccYaw.Value;
		RelativeRotation.Roll = -AccRoll.Value;

		RelativeRotation += RelativeOffsetFromImpact;
		
		FVector RelativeLocation = InitialRelativeTransform.Location;
		RelativeRotation = InitialRelativeTransform.TransformRotation(RelativeRotation);

		const FVector BackWheelLocation = RelativeRotation.RotateVector(GravityBike.BackWheelComp.RelativeLocation);
		const FVector FrontWheelLocation = RelativeRotation.RotateVector(GravityBike.FrontWheelComp.RelativeLocation);

		float LowestWheel = Math::Min(BackWheelLocation.Z, FrontWheelLocation.Z);
		RelativeLocation += FVector(
			0,
			Math::Sin(Math::DegreesToRadians(-RelativeRotation.Roll)) * (GravityBike.Sphere.SphereRadius * 2),	// Offset from roll to keep the heartline at the center of the turn
			(-LowestWheel) + GravityBike.BackWheelComp.Radius // Offset to keep the lowest wheel at the bottom
		);
		GravityBike.MeshPivot.SetRelativeLocationAndRotation(RelativeLocation, RelativeRotation);

		GravityBike.AnimationData.RollAngle = AccRoll.Value;
		GravityBike.AnimationData.RollVelocity = AccRoll.Velocity;

		GravityBike.AnimationData.PitchAngle = AccPitch.Value;
		GravityBike.AnimationData.PitchVelocity = AccPitch.Velocity;

		FGravityBikeSplineHoverSyncedData SyncedData;
		SyncedData.RelativeLocation = GravityBike.MeshPivot.RelativeLocation;
		SyncedData.RelativeRotation = GravityBike.MeshPivot.RelativeRotation;
		SyncedData.RollVelocity = AccRoll.Velocity;
		SyncedData.PitchVelocity = AccPitch.Velocity;

		SyncedHoverDataComp.SetCrumbValueStruct(SyncedData);
	}

	void ApplyCrumbSyncedLocationAndRotation()
	{
		check(!HasControl());

		FGravityBikeSplineHoverSyncedData SyncedData;
		SyncedHoverDataComp.GetCrumbValueStruct(SyncedData);

		GravityBike.MeshPivot.SetRelativeLocationAndRotation(
			SyncedData.RelativeLocation,
			SyncedData.RelativeRotation
		);

		GravityBike.AnimationData.RollAngle = -SyncedData.RelativeRotation.Roll;
		GravityBike.AnimationData.RollVelocity = SyncedData.RollVelocity;

		GravityBike.AnimationData.PitchAngle = SyncedData.RelativeRotation.Pitch;
		GravityBike.AnimationData.PitchVelocity = SyncedData.PitchVelocity;
	}

	void Reset()
	{
		AccPitch.SnapTo(0);
		PitchBounceCount = 0;
		AccYaw.SnapTo(0);
		AccRoll.SnapTo(0);
		RelativeOffsetFromImpact = FRotator::ZeroRotator;

		ApplyLocationAndRotation();
	}

	UFUNCTION()
	private void OnTeleported()
	{
		Reset();
	}
};