UCLASS(Abstract)
class AIslandLockPickingPuzzlePin : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshParent;

	UPROPERTY(DefaultComponent, Attach = MeshParent)
	UStaticMeshComponent TopMesh;

	UPROPERTY(DefaultComponent, Attach = MeshParent)
	UStaticMeshComponent BottomMesh;

	UPROPERTY(DefaultComponent, Attach = TopMesh)
	UStaticMeshComponent TopCollision;

	UPROPERTY(DefaultComponent, Attach = BottomMesh)
	UStaticMeshComponent BottomCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocation;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditAnywhere)
	float MovementDistance = 250.0;

	UPROPERTY(EditAnywhere)
	float MovementDuration = 2.0;

	UPROPERTY(EditAnywhere)
	bool bReversed = false;

	/* Higher starting offset alpha will make the pin start higher up, lower will make it start lower down */
	UPROPERTY(EditAnywhere, Meta = (ClampMin = "-0.5", ClampMax = "0.5"))
	float StartingOffsetAlpha = 0.0;

	UPROPERTY(EditAnywhere)
	EHazePlayer ControlledPlayer = EHazePlayer::Mio;

	AIslandLockPickingPuzzleBolt Bolt;

	private float MovementDirection = 1.0;
	private float MovementAlpha = 0.5;
	bool bStoppedByBolt = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		float OffsetAlpha = MovementAlpha + StartingOffsetAlpha;
		MeshParent.WorldLocation = GetNewLocation(OffsetAlpha);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::GetPlayer(ControlledPlayer));

		if(bReversed)
			MovementDirection = -1.0;

		if(Math::Abs(StartingOffsetAlpha) == 0.5)
		{
			MovementDirection = -Math::Sign(StartingOffsetAlpha);
		}

		MovementAlpha += StartingOffsetAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl())
		{
			float NewAlpha = GetNewAlpha(DeltaTime);
			float MoveAlpha = MoveCurve.GetFloatValue(NewAlpha);
			FVector NewLocation = GetNewLocation(MoveAlpha);
			float Time = TraceAgainstBolt(NewLocation);
			MovementAlpha = Math::Lerp(MovementAlpha, NewAlpha, Time);
			NewLocation = Math::Lerp(MeshParent.WorldLocation, NewLocation, Time);

			SyncedLocation.Value = NewLocation;

			if(MovementAlpha >= 1.0 - KINDA_SMALL_NUMBER || MovementAlpha <= KINDA_SMALL_NUMBER)
			{
				FIslandLockPickingPuzzlePinGenericEffectParams Params;
				Params.Pin = this;

				if(MovementAlpha <= KINDA_SMALL_NUMBER)
					UIslandLockPickingPuzzlePinEffectHandler::Trigger_OnPinHitLowestPoint(this, Params);
				else
					UIslandLockPickingPuzzlePinEffectHandler::Trigger_OnPinHitHighestPoint(this, Params);

				if (MovementDirection < 0.5)
					MovementDirection = 1.0;
				else
					MovementDirection = -1.0;
			}

			TEMPORAL_LOG(this)
				.Value("MovementAlpha", MovementAlpha)
				.Value("MoveAlpha", MoveAlpha)
				.Value("Time", Time)
			;
		}
		
		MeshParent.WorldLocation = SyncedLocation.Value;
	}

	float GetNewAlpha(float DeltaTime)
	{
		float NewAlpha = MovementAlpha + DeltaTime / MovementDuration * MovementDirection;
		NewAlpha = Math::Saturate(NewAlpha);
		return NewAlpha;
	}

	FVector GetNewLocation(float MoveAlpha)
	{
		FVector Origin = ActorLocation + FVector::UpVector * -MovementDistance;
		FVector Destination =  ActorLocation + FVector::UpVector * MovementDistance;
		FVector NewLocation = Math::Lerp(Origin, Destination, MoveAlpha);
		return NewLocation;
	}

	float TraceAgainstBolt(FVector NewLocation)
	{
		UPrimitiveComponent CompToTraceWith = GetComponentToTraceWith();
		FHazeTraceSettings Trace = Trace::InitAgainstComponent(Bolt.Mesh);
		FBox Bounds = CompToTraceWith.GetBoundingBoxRelativeToOwner();
		FVector ScaledExtents = Bounds.Extent * ActorScale3D;
		Trace.UseBoxShape(ScaledExtents, ActorQuat);
		FVector LocationForComponent = CompToTraceWith.WorldLocation + (NewLocation - MeshParent.WorldLocation);

		FVector Start = CompToTraceWith.WorldLocation;
		FVector End = LocationForComponent;
		
		if(Start.Equals(End))
			return 1.0;

		FHitResult Hit = Trace.QueryTraceComponent(Start, End);
		if(bStoppedByBolt != Hit.bBlockingHit)
		{
			FIslandLockPickingPuzzlePinGenericEffectParams Params;
			Params.Pin = this;
			bStoppedByBolt = Hit.bBlockingHit;
			if(bStoppedByBolt)
				UIslandLockPickingPuzzlePinEffectHandler::Trigger_OnPinStoppedByBolt(this, Params);
			else
				UIslandLockPickingPuzzlePinEffectHandler::Trigger_OnPinStartMovingAgain(this, Params);
		}

		if(Hit.bBlockingHit)
		{
			if(Math::IsNearlyZero(Hit.Distance))
				return 0.0;

			float AlphaToDeduct = 0.125 / Hit.Distance;
			return Math::Saturate(Hit.Time - AlphaToDeduct);
		}

		return 1.0;
	}

	UPrimitiveComponent GetComponentToTraceWith()
	{
		if(MovementDirection > 0.0)
			return BottomCollision;

		return TopCollision;
	}
}