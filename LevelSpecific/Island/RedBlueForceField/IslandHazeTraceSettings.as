// Haze trace settings but will ignore force field holes
struct FIslandHazeTraceSettings
{
	access Internal = private, IslandTrace;

	access:Internal FHazeTraceSettings Internal_Settings;
	access:Internal float ForceFieldTimeOffset = 0.0;

	// Redirect functions to standard FHazeTraceSettings functions
	// I hate this, but it will work for prototyping purposes (which means it will probably never change)
	void DebugDraw(float32 Duration) { Internal_Settings.DebugDraw(Duration); }
	void DebugDraw(FHazeTraceDebugSettings DebugSettings) { Internal_Settings.DebugDraw(DebugSettings); }
	void UseLine() { Internal_Settings.UseLine(); }
	void UseSphereShape(float32 Radius) { Internal_Settings.UseSphereShape(Radius); }
	void UseSphereShape(USphereComponent Shape, bool bIncludeScale = true) { Internal_Settings.UseSphereShape(Shape, bIncludeScale); }
	void TraceWithPlayerProfile(AHazePlayerCharacter Player) { Internal_Settings.TraceWithPlayerProfile(Player); }
	void UseShapeWorldOffset(FVector ShapeWorldOffset) { Internal_Settings.UseShapeWorldOffset(ShapeWorldOffset); }
	void IgnorePlayers() { Internal_Settings.IgnorePlayers(); }
	void IgnoreActor(const AActor Actor, bool bIncludeAscendants = true) { Internal_Settings.IgnoreActor(Actor, bIncludeAscendants); }
	void IgnoreActors(TArray<AActor> Actors) { Internal_Settings.IgnoreActors(Actors); }
	void IgnoreCameraHiddenComponents(AHazePlayerCharacter Player) { Internal_Settings.IgnoreCameraHiddenComponents(Player); }
	void IgnoreCameraHiddenComponents(UHazeCameraUserComponent UserComp) { Internal_Settings.IgnoreCameraHiddenComponents(UserComp); }

	/* Positive values will mean we will trace as if the force fields have shrunk from their current state by the specified time offset, negative values aren't supported */
	void AddForceFieldTimeOffset(float AdditionalTimeOffset)
	{
		devCheck(AdditionalTimeOffset >= 0.0, "Cannot add negative force field time offset!");
		ForceFieldTimeOffset += AdditionalTimeOffset;
	}

	/* Positive values will mean we will trace as if the force fields have shrunk from their current state by the specified time offset, negative values aren't supported */
	void SetForceFieldTimeOffset(float NewTimeOffset)
	{
		devCheck(NewTimeOffset >= 0.0, "Cannot set negative force field time offset!");
		ForceFieldTimeOffset = NewTimeOffset;
	}

	FHitResult QueryTraceSingle(FVector TraceStart, FVector TraceEnd) 
	{
		devCheck(!Internal_Settings.Shape.IsBox(), "FIslandHazeTraceSettings doesn't support box shapes!");

		FHitResultArray Results = Internal_Settings.QueryTraceMulti(TraceStart, TraceEnd);
		TArray<FHitResult> BlockHits = Results.BlockHits;
		for(FHitResult Hit : BlockHits)
		{
			// If we didn't hit a force field just return the hit
			if(!Hit.Actor.IsA(AIslandRedBlueForceField))
				return Hit;

			// If we should hit the force field we return this hit, otherwise we just ignore this hit and continue in the loop to the next blocking hit
			if(ShouldHitForceField(Hit, Internal_Settings.Shape))
				return Hit;
		}

		FHitResult Hit;
		Hit.bBlockingHit = false;
		Hit.TraceStart = TraceStart;
		Hit.TraceEnd = TraceEnd;
		return Hit;
	}
	
	bool ShouldHitForceField(FHitResult Hit, FHazeTraceShape Shape)
	{
		auto ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		devCheck(ForceField != nullptr, "Tried to check if a hit should hit a force field but we didn't hit a force field!");

		FIslandForceFieldHoleDataArray HoleData = ForceField.GetHoleDataArrayInTheFuture(ForceFieldTimeOffset);

		if(Shape.IsLine())
		{
			if(HoleData.IsPointInsideHoles(Hit.ImpactPoint))
				return false;
		}
		else if(Shape.IsSphere())
		{
			FRotator ShapeRotation = FRotator::MakeFromZX(FVector::UpVector, (Hit.TraceEnd - Hit.TraceStart));
			FTransform ShapeTransform = FTransform(ShapeRotation, Hit.Location);
			if(HoleData.IsShapeInsideHoles(Shape.Shape, ShapeTransform, 0.0))
				return false;
		}
		else if(Shape.IsCapsule())
		{
			FRotator ShapeRotation = FRotator::MakeFromZX(FVector::UpVector, (Hit.TraceEnd - Hit.TraceStart));
			FTransform ShapeTransform = FTransform(ShapeRotation, Hit.Location);
			if(HoleData.IsShapeInsideHoles(Shape.Shape, ShapeTransform, 0.0))
				return false;
		}
		else
			devError("Forgot to add case!");

		return true;
	}
}

namespace IslandTrace
{
	/**
	 * Init a trace that responds as if the player was trying to move between two locations.
	 * 
	 * NOTE: Even if the player's collision is currently blocked, this will still return hits
	 * as if the player had normal collision.
	 */
	FIslandHazeTraceSettings InitFromPlayer(AHazePlayerCharacter Player, FName CustomTraceTag = NAME_None)
	{
		FHazeTraceSettings Settings = Trace::InitFromPlayer(Player, CustomTraceTag);
		FIslandHazeTraceSettings IslandSettings;
		IslandSettings.Internal_Settings = Settings;
		return IslandSettings;
	}

	/**
	 * Init a trace that uses a movement component to represent an actor.
	 * The trace will be done at an offset from the movement's shape, so pass the actor location for start and end.
	 */
	FIslandHazeTraceSettings InitFromMovementComponent(UHazeMovementComponent MoveComp, FName CustomTraceTag = NAME_None)
	{
		FHazeTraceSettings Settings = Trace::InitFromMovementComponent(MoveComp, CustomTraceTag);
		FIslandHazeTraceSettings IslandSettings;
		IslandSettings.Internal_Settings = Settings;
		return IslandSettings;
	}

	FIslandHazeTraceSettings InitChannel(ECollisionChannel InChannel, FName CustomTraceTag = NAME_None)
	{
		FHazeTraceSettings Settings = Trace::InitChannel(InChannel, CustomTraceTag);
		FIslandHazeTraceSettings IslandSettings;
		IslandSettings.Internal_Settings = Settings;
		return IslandSettings;
	}
}