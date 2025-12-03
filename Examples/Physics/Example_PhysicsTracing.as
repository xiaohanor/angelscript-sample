

class AExamplePhysicsTracing : AHazeActor
{
	/*
	* Tracing in the physical world is made using the 'Trace::' library
	* That will initialize FHazeTraceSettings.
	* You then call all the trace functions on FHazeTraceSettings.
	*/
	void NormalTracing()
	{
		/** 
		* This is the struct used for setting up traces 
		*/
		FHazeTraceSettings Trace;

		/*
		* This is how you setup what kind of trace type you want to use 
		*/
		Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Trace = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
		Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace = Trace::InitFromPrimitiveComponent(ExampleCapsuleComponent);

		/*
		* Trace settings are extendable with custom settings
		*/
		Trace = Trace::InitChannel(ETraceTypeQuery::Visibility, CustomTraceTag = n"CustomTrace");
		Trace.SetTraceComplex(true);
		Trace.SetReturnPhysMaterial(true);
		Trace.IgnoreActor(this);
		Trace.IgnoreComponent(ExampleCapsuleComponent);

		/*
		* This is how you define what kind of shape you want to trace with
		*/	
		Trace.UseLine();
		Trace.UseBoxShape(FVector(100, 100, 100));
		Trace.UseSphereShape(100);
		Trace.UseCapsuleShape(80.0, 200.0);
		
		/*
		* You can also add shapes using the FHazeTraceShape
		*/	
		Trace.UseShape(FHazeTraceShape::MakeLine());
		Trace.UseShape(FHazeTraceShape::MakeBox(FVector(100, 100, 100)));
		Trace.UseShape(FHazeTraceShape::MakeSphere(100));
		Trace.UseShape(FHazeTraceShape::MakeCapsule(80.0, 200.0));
		Trace.UseShape(FHazeTraceShape::MakeFromComponent(ExampleCapsuleComponent));

		/* or FCollisionShape */
		Trace.UseShape(FCollisionShape::MakeBox(FVector(100, 100, 100)));

		// Some shapes can also have a rotation
		Trace.UseShape(FHazeTraceShape::MakeCapsule(80.0, 200.0, FQuat::Identity));

		/*
		* TraceSingle will trace up until the first collision is detected
		*/
		FHitResult HitResult;

		HitResult =	Trace.QueryTraceSingle(ExampleTraceStart, ExampleTraceEnd);

		// We have a collision hit
		bool bBlockingHit = HitResult.bBlockingHit;
			
		/*
		* TraceMulti will trace the entire distance, collecting all overlaps and all collision along the way
		*/
		FHitResultArray HitResults = Trace.QueryTraceMulti(ExampleTraceStart, ExampleTraceEnd);

		// We have a hit
		bBlockingHit = HitResults.bHasBlockingHit;

		// Then you itterate on the trace results
		for(auto Result : HitResults)
		{
			bool bStartPenetrating = Result.bStartPenetrating;
			FVector Location = Result.Location;
			// etc...
		}	

			// Helper functions for the multi result
		FHitResult FirstBlockingHit = HitResults.FirstBlockHit;
		FHitResult FirstOverlapHit = HitResults.FirstOverlapHit;
		TArray<FHitResult> BlockHits = HitResults.BlockHits;
		TArray<FHitResult> OverlapHits = HitResults.OverlapHits;


		/*
		* TraceMultiUntilBlock will trace up until the first collision is detected but include all overlapping collisions
		*/
		HitResults = Trace.QueryTraceMultiUntilBlock(ExampleTraceStart, ExampleTraceEnd);

				
		/*
		* Debugging as made by setting up a debug settings struct
		*/
		Trace.DebugDrawOneFrame();
		Trace.DebugDraw(1.0);

		/**
		* You can customize you debug using extra settings 
		*/ 
		auto OneFrameDebug = TraceDebug::MakeOneFrame();
		auto DurationDebug = TraceDebug::MakeDuration(1.0);
		auto PersistentDebug = TraceDebug::MakePersistent();

		OneFrameDebug.Thickness = 1;
		OneFrameDebug.NumSegments = 16;
		OneFrameDebug.TraceColor = FLinearColor::Green;

		Trace.DebugDraw(OneFrameDebug);

		// Print the impact to screen
		PrintToScreen(HitResult.ToDebugString());
		PrintToScreen(HitResults.ToDebugString());
	}

	/**
	 * If you want to trace whether a player _could_ move a particular path,
	 * use `InitFromPlayer`. This does not care whether the player's collision is currently
	 * turned off or not.
	 */
	void PlayerTracing()
	{
		FHazeTraceSettings Trace = Trace::InitFromPlayer(Game::Mio);
		auto TraceResult = Trace.QueryTraceSingle(ExampleTraceStart, ExampleTraceEnd);
	}




	/** If you only want to validate 2 if two shapes are intersection
	 * and you dont care about the collision profiles, or if the collisions
	 * are enabled or disabled, you can use the 'Overlap' lib
	 */
	void ShapeIntersection()
	{
		// In this example, we will intersection check a box vs a sphere
		bool bIsIntersecting = Overlap::QueryShapeOverlap(
			FCollisionShape::MakeBox(FVector(100)), FTransform(ExampleShapeOriginOne),
			FCollisionShape::MakeSphere(100), FTransform(ExampleShapeOriginTwo),
		 );
	}















	// Interal params for creating the example file only
	const FVector ExampleTraceStart = FVector(0.0);
	const FVector ExampleTraceEnd = FVector(500.0);
	const FVector ExampleShapeOriginOne = FVector(0.0);
	const FVector ExampleShapeOriginTwo = FVector(500.0);
	UCapsuleComponent ExampleCapsuleComponent;
	UHazeMovementComponent ExampleMovementComponent;
}