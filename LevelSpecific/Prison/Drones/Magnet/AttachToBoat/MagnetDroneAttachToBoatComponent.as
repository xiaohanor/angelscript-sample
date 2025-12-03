UCLASS(Abstract)
class UMagnetDroneAttachToBoatComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	protected UMagnetDroneAttachToBoatSettings DefaultSettings;

	private AHazePlayerCharacter Player;
	private UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachToBoatSettings Settings;

	private AHazePlayerCharacter SwarmDrone;
	private UPlayerSwarmDroneComponent SwarmDroneComp;

	private bool bIsAttachedToBoat = false;
	bool bHasLandedOnBoat = false;
	uint BoatCollisionFrame = 0;
	EMagnetDroneAttachToBoatMovementState MovementState = EMagnetDroneAttachToBoatMovementState::FallingIntoBoat;
	bool bIsPerformingRelativeJump = false;

	float VerticalOffset;
	float VerticalSpeed;

	FHazeAcceleratedVector AccHorizontalOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DroneComp = UMagnetDroneComponent::Get(Player);

		if(DefaultSettings != nullptr)
			Player.ApplyDefaultSettings(DefaultSettings);

		Settings = UMagnetDroneAttachToBoatSettings::GetSettings(Player);

		SwarmDrone = Drone::GetSwarmDronePlayer();
		SwarmDroneComp = UPlayerSwarmDroneComponent::Get(SwarmDrone);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneAttachToBoatComponent");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this, Owner, "Attach To Boat")
			.Value("bIsAttachedToBoat", bIsAttachedToBoat)
			.Value("bHasLandedOnBoat", bHasLandedOnBoat)
			.Value("BoatCollisionFrame", BoatCollisionFrame)
			.Value("bIsPerformingRelativeJump", bIsPerformingRelativeJump)
			.Value("VerticalOffset", VerticalOffset)
			.Value("VerticalSpeed", VerticalSpeed)
			.Value("HorizontalOffset.Value", AccHorizontalOffset.Value)
			.Value("HorizontalOffset.Velocity", AccHorizontalOffset.Velocity)
		;
#endif
	}

	void RelativeJump()
	{
		const float Impulse = DroneComp.MovementSettings.JumpImpulse - VerticalSpeed;

		if(Impulse < 0)
			return;
		
		VerticalSpeed += Impulse;

		if(VerticalOffset < 1)
			VerticalOffset = 1;

		bHasLandedOnBoat = false;
		AccHorizontalOffset.SnapTo(FVector::ZeroVector);

		MovementState = EMagnetDroneAttachToBoatMovementState::FallingIntoBoat;
	}

	void AttachToBoat()
	{
		if(bIsAttachedToBoat)
			return;

		bIsAttachedToBoat = true;
	}

	void DetachFromBoat()
	{
		if(!bIsAttachedToBoat)
			return;

		bIsAttachedToBoat = false;
	}

	bool IsAttachedToBoat() const
	{
		return bIsAttachedToBoat;
	}

	bool HadCollisionWhileOnBoatThisFrame() const
	{
		if(Time::FrameNumber > BoatCollisionFrame + 1)
			return false;

		return true;
	}

	FVector GetTargetLocation() const
	{
		return SwarmDroneComp.CollisionComponent.WorldTransform.TransformPositionNoScale(FVector(0, 0, 50));
	}

	FVector GetTargetVelocity() const
	{
		return SwarmDrone.ActorVelocity;
	}

	float CalculateTimeToLand() const
	{
		float TimeToLand = 0;
		const float Height = GetTargetLocation().Z - Player.ActorLocation.Z;
		Trajectory::TrajectoryTimeToReachHeight(Player.ActorVelocity.Z, DroneComp.MovementSettings.AirMaxFallDeceleration, Height, TimeToLand);

		// Acceleration is rather harsh, so we add some extra time to it
		TimeToLand *= 2;

		// Too short times look odd
		return Math::Max(TimeToLand, 0.2);
	}
};