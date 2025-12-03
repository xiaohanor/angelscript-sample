
class UPlayerDefaultListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::DefaultListener);
	default TickGroup = Audio::ListenerTickGroup;

	UHazeAudioListenerComponent Listener;
	UHazeMovementComponent MoveComp;
	UCameraUserComponent User;

	FVector PreviousLocation;
	float PreviousDistance = 0;
	FHazeAcceleratedFloat AcceleratedDistanceAlpha;

	// These are just arbitrary values
	const float AccelerationDuration = 1.0;
	const float MaxDistanceDelta = 0.25 * 100;
	const float MaxDistanceFromPlayer = 5.0 * 100;
	private const float DefaultMaximumSpeed = 1000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Listener = Player.PlayerListener;
		MoveComp = UHazeMovementComponent::Get(Player);
		User = UCameraUserComponent::Get(Player);
		SetDefaultTransform();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	void SetDefaultTransform()
	{
		Listener.SetWorldTransform(Audio::GetEarsTransform(Player));
	}

	UFUNCTION(BlueprintOverride)
	void OnStopQuiet()
	{
		SetDefaultTransform();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SetDefaultTransform();
	}

	float GetMaximumSpeed()
	{
		return DefaultMaximumSpeed;
	}

	void MoveTowardsInBetweenCameraTransform(float DeltaTime)
	{
		float ActorScale = Player.GetActorScale3D().Y;

		// Distance based on speed.
		float MaxSpeed = Math::Max(GetMaximumSpeed(), SMALL_NUMBER);
		float MinDistanceToEars = 100 / MaxDistanceFromPlayer; // a meter behind the player

		FVector Velocity = FVector(MoveComp.Velocity.X, 0.0, MoveComp.Velocity.Y);
		float CurrentSpeed = Velocity.Size();
		float PlayerDistanceAlpha = Math::Clamp(CurrentSpeed / MaxSpeed, MinDistanceToEars, 1.0);

		// Distance clamp based on distance change.
		FVector EarsLocation = Audio::GetEarsLocation(Player);
		FVector CameraLocation = Player.GetViewLocation();
		FVector CameraDirection = (CameraLocation-EarsLocation);
		CameraDirection.Normalize();

		const float MaxScaledDistanceFromPlayer = (CameraLocation-EarsLocation).Size() * 0.5 * ActorScale;

		UpdateListenerTransform(
			DeltaTime,
			PlayerDistanceAlpha,
			MaxScaledDistanceFromPlayer,
			EarsLocation,
			CameraDirection,
			Player.ViewTransform
		);
	}

	void MoveTowardsDefaultTransform(float DeltaTime)
	{
		auto EarsTransform = Audio::GetEarsTransform(Player);

		auto Direction = EarsTransform.Location - Listener.WorldLocation;
		Direction.Normalize();

		UpdateListenerTransform(
			DeltaTime,
			0,
			10000,
			EarsTransform.Location,
			Direction,
			EarsTransform
		);
	}

	void UpdateListenerTransform(
		const float& DeltaTime,
		const float& Alpha, 
		const float& MaxDistance,
		const FVector& Location,
		const FVector& Direction,
		const FTransform& ViewTransform)
	{
		// Listener location has been changed somewhere else, reset!
		FVector ListenerLocation = Listener.GetWorldLocation();
		if (PreviousLocation != ListenerLocation)
		{
			PreviousDistance = 0;
			AcceleratedDistanceAlpha.SnapTo(Alpha);
		}
		
		AcceleratedDistanceAlpha.AccelerateTo(Alpha, AccelerationDuration, DeltaTime, EHazeAcceleratedValueSnapCondition::TargetLower);
		// Clamp the alpha based on the max distance from player, this is just a random set number.
		// NOTE: This means the listener can be behind the camera
		PreviousDistance = Math::Clamp(MaxDistance * AcceleratedDistanceAlpha.Value, SMALL_NUMBER, MaxDistance);
		PreviousLocation = Location + Direction * PreviousDistance;

		Listener.SetWorldTransform(FTransform(ViewTransform.GetRotation(), PreviousLocation));

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Audio::DebugListenerLocations(Player);
			
			if (IsDebugActive())
			{
				PrintToScreen(Player.GetName() + " ViewRatio: " + AcceleratedDistanceAlpha.Value, 0.0);
				PrintToScreen(Player.GetName() + " Alpha: " + Alpha, 0.0);
				PrintToScreen(Player.GetName() + " WantedDistance: " + PreviousDistance, 0.0);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Audio::SetPanningBasedOnScreenPercentage(Player);
		
		if (User.CanControlCamera() && User.IsCameraAttachedToPlayer())
			MoveTowardsInBetweenCameraTransform(DeltaTime);
		else 
			MoveTowardsDefaultTransform(DeltaTime);
		
	}
}
