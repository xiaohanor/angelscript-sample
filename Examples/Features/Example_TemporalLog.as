
class AExampleTemporalLog : AActor
{
	UPROPERTY(DefaultComponent)
	UCapsuleComponent Capsule;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Log some of the state of the actor every frame
		TEMPORAL_LOG(this)
			.Value("LogVector", FVector(1.0, 2.0, 3.0))
			.Value("LogString", GetPathName())
			.Value("LogFloat", ActorVelocity.Size());

		// Log the position of the capsule as a visual shape
		TEMPORAL_LOG(this).Capsule(
			"ActorPosition",
			Capsule.WorldLocation,
			Capsule.ScaledCapsuleRadius,
			Capsule.ScaledCapsuleHalfHeight,
			Capsule.WorldRotation,
			FLinearColor::Blue);

		// Log a visual line pointing in the forward direction of the actor
		TEMPORAL_LOG(this).Line(
			"ForwardLine",
			ActorLocation,
			ActorLocation + (ActorForwardVector * 100.0),
			Color = FLinearColor::Purple
		);

		// Log a visual sphere around the actor location
		TEMPORAL_LOG(this).Sphere(
			"ActorSphere",
			Origin = ActorLocation,
			Radius = 1000.0,
			Color = FLinearColor::Red
		);

		// Log a visual box around the actor location
		TEMPORAL_LOG(this).Box(
			"RotatedBox",
			Origin = ActorLocation,
			BoxExtent = FVector(100.0, 50.0, 50.0),
			Rotation = ActorRotation,
			Color = FLinearColor(1.0, 0.5, 1.0)
		);

		// Log a visual point somewhere above the actor location
		TEMPORAL_LOG(this).Point(
			"AboveActor",
			Point = (ActorLocation + FVector(0.0, 0.0, 150.0)),
			Size = 10.0,
			Color = FLinearColor::Red
		);

		// Log a visual circle centered around the actor location
		TEMPORAL_LOG(this).Circle(
			"AroundActor",
			ActorLocation,
			Radius = 100.0
		);

		// Log a Status value for this actor that determines its base color in the list
		// OBS! only 1 status can be added
		if (ActorVelocity.Size() > 0.0)
		{
			TEMPORAL_LOG(this).Status("Moving", FLinearColor::Blue);
		}
		else if (ActorLocation.Z < 0.0)
		{
			TEMPORAL_LOG(this).Status("Underground", FLinearColor::Red);
		}
		else
		{
			TEMPORAL_LOG(this).Status("Normal", FLinearColor::Green);
		}

		// When we hit the Mio player, explode
		if (IsOverlappingActor(Game::Mio))
		{
			// Log an event to the temporal log that we have exploded
			TEMPORAL_LOG(this).Event("Exploded");

			// We can also log with an f-string to show which actor exploded it
			TEMPORAL_LOG(this).Event(f"Exploded by hitting {Game::Mio}");
		}

		// We can create section headings within the same temporal log page:
		auto Heading1 = TEMPORAL_LOG(this).Section("Heading 1");
		Heading1.Value("Value", "Value One");
		Heading1.Value("Value Two", "Value Two");

		// Headings can have a sort order to display them in a particular order:
		auto Heading2 = TEMPORAL_LOG(this).Section("Heading 2", SortOrder = 10);
		Heading2.Value("Value", "Second One");
		Heading2.Value("Value Two", "Second Two");

		// We can log values to a subcategory within the actor by using pages:
		FTemporalLog SubValuesPage = TEMPORAL_LOG(this).Page("SubValues");
		SubValuesPage.Value("SubValue", "Test");
	}
};

/**
 * Capabilities have two helper methods to collect all the state that should be added to the temporal log in one place.
 */
class UExampleTemporalLogCapability : UHazeCapability
{
	float Cooldown = 0.0;

	// Called every frame to log important values on the capability
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		// Current cooldown is important even if the capability is deactive
		TemporalLog.Value("Cooldown", Cooldown);
	}

	// Called only on frames where the capability is active, can be used to log specific active state
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		// Log how long the capability has been active for
		TemporalLog.Value("ActiveDuration", ActiveDuration);
	}
};

