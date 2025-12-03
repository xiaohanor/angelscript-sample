UCLASS(Abstract)
class UGravityBikeFreeCameraDataComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset TankDeathSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset TripodDeathSettings;

	float NoInputDuration;
	float FallDuration;
	FHazeAcceleratedQuat AccCameraRotation;

	TInstigated<FVector> YawAxisBase;
	default YawAxisBase.DefaultValue = FVector::UpVector;
	FHazeAcceleratedFloat AccYawAxisRollOffset;

	FHitResult ApproachingGround;

	private FQuat InputOffset = FQuat::Identity;
	private float InputOffsetSetTime = -1;
	private uint InputOffsetFrame = 0;

	private AHazePlayerCharacter Player;
	private UGravityBikeFreeDriverComponent DriverComp;
	private UCameraUserComponent CameraUser;

	private AGravityBikeFree GravityBike;
	private uint AppliedDesiredRotationFrame = 0;
	private FInstigator AppliedDesiredRotationInstigator;
	private FHazeAcceleratedFloat AccSideOffsetFromAngularSpeed;

	private UHazeCrumbSyncedVectorComponent SyncedCameraOffsetFromSpeedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);

		GravityBike = DriverComp.GetOrSpawnGravityBike();
		GravityBike.OnTeleported.AddUFunction(this, n"OnDriverTeleported");
		SyncedCameraOffsetFromSpeedComp = UHazeCrumbSyncedVectorComponent::GetOrCreate(GravityBike, n"SyncedCameraOffsetFromSpeedComp");

		Reset();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("State;No Input Duration", NoInputDuration);
		TemporalLog.Value("State;Fall Duration", FallDuration);

		TemporalLog.Value("State;Is Inputting", IsInputting());
		TemporalLog.Value("State;Is Falling", IsFalling());
		TemporalLog.Value("State;Speed Alpha", GetSpeedAlpha());

		TemporalLog.Value("State;Approaching Ground", ApproachingGround.IsValidBlockingHit());
		TemporalLog.Rotation("State;InputOffset", InputOffset, Owner.ActorLocation);
		TemporalLog.Value("State;InputOffsetSetTime", InputOffsetSetTime);

		TemporalLog.Value("AccCameraRotation;Value", AccCameraRotation.Value);
		TemporalLog.Value("AccCameraRotation;VelocityAxisAngle", AccCameraRotation.VelocityAxisAngle);

		TemporalLog.Value("AccSideOffsetFromAngularSpeed; Value", AccSideOffsetFromAngularSpeed.Value);
		TemporalLog.Value("AccSideOffsetFromAngularSpeed; Velocity", AccSideOffsetFromAngularSpeed.Velocity);

		TemporalLog.Value("Desired Rotation;Has Applied Desired Rotation", HasAppliedDesiredRotation());
		TemporalLog.Value("Desired Rotation;Applied Desired Rotation Instigator", AppliedDesiredRotationInstigator);

		TemporalLog.Section("AccCameraRoll")
			.Value("Value", AccYawAxisRollOffset.Value)
			.Value("Velocity", AccYawAxisRollOffset.Velocity)
		;
	}
#endif

	void Reset()
	{
		NoInputDuration = BIG_NUMBER;
		FallDuration = GravityBike.IsAirborne.Get() ? GravityBike.Settings.CameraFallDelay : 0;

		AccCameraRotation.SnapTo(GetBikeForwardTargetRotation(0));
		CameraUser.SetDesiredRotation(AccCameraRotation.Value.Rotator(), this);
		AccSideOffsetFromAngularSpeed.SnapTo(0);
		SyncedCameraOffsetFromSpeedComp.SetValue(FVector::ZeroVector);

		ResetInputOffset();

		if(HasControl())
			ApplyDesiredRotation(this, true);
	}

	UFUNCTION()
	private void OnDriverTeleported()
	{
		Reset();
	}

	bool IsInputting() const
	{
		return NoInputDuration < GravityBike.Settings.CameraInputDelay;
	}

	bool IsFalling() const
	{
		return FallDuration > GravityBike.Settings.CameraFallDelay;
	}

	FQuat GetBikeForwardTargetRotation(float CameraLeadAmount) const
	{
		const float CameraYawLead = GravityBike.AccSteering.Value * -CameraLeadAmount;
		FQuat Rotation = FQuat(FVector::UpVector, Math::DegreesToRadians(CameraYawLead));
		return Rotation * GravityBike.ActorQuat;
	}

	float GetSpeedAlpha() const
	{
		return Math::Saturate(Math::NormalizeToRange(GravityBike.MoveComp.GetForwardSpeed(), GravityBike.Settings.MinimumSpeed, GravityBike.Settings.MaxSpeed));
	}

	void ApplyDesiredRotation(FInstigator Instigator, bool bForce = false)
	{
		check(HasControl());
		check(CameraUser != nullptr);

		if(!bForce)
		{
			if(!ensure(!HasAppliedDesiredRotation()))
				return;
		}

		const FQuat DesiredRotation = GetInputOffsetAppliedToAccCameraRotation();

		CameraUser.SetDesiredRotation(DesiredRotation.Rotator(), Instigator);
		AppliedDesiredRotationFrame = Time::FrameNumber;
		AppliedDesiredRotationInstigator = Instigator;

		FVector Forward = DesiredRotation.ForwardVector.VectorPlaneProject(FVector::UpVector);
		FQuat YawOffset = FQuat(Forward, AccYawAxisRollOffset.Value);
		FVector YawAxis = YawOffset.RotateVector(YawAxisBase.Get());
		CameraUser.SetYawAxis(YawAxis, this);
	}

	FQuat GetInputOffsetAppliedToAccCameraRotation() const
	{
		FQuat DesiredRotation = AccCameraRotation.Value;

		if(InputOffsetSetTime >= 0)
		{
			float Alpha = Math::Saturate(Time::GetGameTimeSince(InputOffsetSetTime) / GravityBike.Settings.CameraInputOffsetResetDuration);
			Alpha = Math::EaseInOut(0, 1, Alpha, 2);
			FQuat Offset = FQuat::Slerp(InputOffset, FQuat::Identity, Alpha);

			DesiredRotation = Offset * DesiredRotation;
		}

		return DesiredRotation;
	}

	FRotator GetDesiredRotation() const
	{
		check(CameraUser != nullptr);
		return CameraUser.GetDesiredRotation();
	}

	FRotator GetViewAngularVelocity() const
	{
		check(CameraUser != nullptr);
		return CameraUser.ViewAngularVelocity;
	}

	bool HasAppliedDesiredRotation() const
	{
		return AppliedDesiredRotationFrame == Time::FrameNumber;
	}

	void ApplyCameraOffsetFromSpeed(float DeltaTime)
	{
		check(HasControl());

		float SideOffsetFromAngularSpeed = GravityBike.AccSteering.Value;
		SideOffsetFromAngularSpeed *= GravityBike.Settings.OffsetFromAngularSpeed;
		SideOffsetFromAngularSpeed *= GravityBike.GetSpeedAlpha(GravityBike.MoveComp.GetForwardSpeed());

		AccSideOffsetFromAngularSpeed.AccelerateTo(
			SideOffsetFromAngularSpeed,
			GravityBike.Settings.OffsetFromAngularSpeedDuration,
			DeltaTime
		);

		const float ForwardOffsetFromSpeed = Math::Lerp(
			0,
			GravityBike.Settings.ForwardOffsetFromSpeed,
			GetSpeedAlpha()
		);

		const FVector OffsetFromSpeed = FVector(
			ForwardOffsetFromSpeed,
			AccSideOffsetFromAngularSpeed.Value,
			0
		);

		UCameraSettings::GetSettings(GravityBike.GetDriver()).CameraOffsetOwnerSpace.ApplyAsAdditive(
			OffsetFromSpeed,
			this,
			0
		);
	
		SyncedCameraOffsetFromSpeedComp.SetValue(OffsetFromSpeed);
	}

	void ResetCameraOffsetFromSpeed(float Duration = 1)
	{
		check(HasControl());

		AccSideOffsetFromAngularSpeed.AccelerateTo(0, Duration, Time::GetActorDeltaSeconds(GravityBike));
		const FVector OffsetFromSpeed = FVector(0, AccSideOffsetFromAngularSpeed.Value, 0);
		UCameraSettings::GetSettings(GravityBike.GetDriver()).CameraOffsetOwnerSpace.ApplyAsAdditive(OffsetFromSpeed, this, 0);
		
		bool bHasChanged = !SyncedCameraOffsetFromSpeedComp.Value.Equals(OffsetFromSpeed);

		SyncedCameraOffsetFromSpeedComp.SetValue(OffsetFromSpeed);

		if(bHasChanged && Duration < 0)
			SyncedCameraOffsetFromSpeedComp.SnapRemote();
	}

	void ApplyCrumbSyncedCameraOffset()
	{
		const FVector OffsetFromSpeed = SyncedCameraOffsetFromSpeedComp.Value;
		UCameraSettings::GetSettings(GravityBike.GetDriver()).CameraOffsetOwnerSpace.ApplyAsAdditive(OffsetFromSpeed, this, 0);
	}

	FVector GetYawAxis() const
	{
		return CameraUser.ActiveCameraYawAxis;
	}

	void ApplyInputOffset(FQuat InInputOffset)
	{
		if(InputOffsetFrame == Time::FrameNumber)
			return;

		InputOffset = InInputOffset;
		InputOffsetSetTime = Time::GameTimeSeconds;
		InputOffsetFrame = Time::FrameNumber;
	}

	void ResetInputOffset()
	{
		InputOffset = FQuat::Identity;
		InputOffsetSetTime = -1;
		InputOffsetFrame = Time::FrameNumber;
	}

	bool HasDeathSettings() const
	{
		return GetDeathCameraSettings() != nullptr;
	}

	UHazeCameraSettingsDataAsset GetDeathCameraSettings() const
	{
		auto BossTank = ASkylineBossTank::Get();
		if(IsValid(BossTank) && !BossTank.IsActorDisabled())
			return TankDeathSettings;

		auto TripodBoss = ASkylineBoss::Get();
		if(IsValid(TripodBoss) && !TripodBoss.IsActorDisabled())
			return TripodDeathSettings;

		return nullptr;
	}
};