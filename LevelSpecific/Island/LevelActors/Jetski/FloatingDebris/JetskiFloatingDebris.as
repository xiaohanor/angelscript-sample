event void FJetskiFloatingDebrisStartFalling();
event void FJetskiFloatingDebrisHitWater();
event void FJetskiFloatingDebrisSurfaced();

enum EJetskiFloatingDebrisState
{
	// Non-ticking mode where we simply wait to be activated.
	Waiting,

	// Fall until we hit the water surface.
	Falling,

	// Float up from under the water surface to the surface.
	Floating,

	// Float on top of the surface, locked with a spring to the wave height.
	Surface,
};

enum EJetskiFloatingDebrisSurfaceBehaviour
{
	// Use cool maths to fake being on a watery surface. May not match the visual appearance of the waves.
	// FB TODO: Rename to Perlin
	CalculateSineWaves,

	// Query the water surface for actual wave data. Limited to max 32 per level, so only use if other methods do not suffice.
	QueryWaveHeight,
};

struct FJetskiFloatingDebrisCalculatedSineSettings
{
	UPROPERTY(EditAnywhere)
	float WaveHeight = 150.0;

	UPROPERTY(EditAnywhere)
	float WaveSpeed = 1000.0;

	UPROPERTY(EditAnywhere)
	float WaveSize = 1;

	/**
	 * How big of an area we sample for the normal calculation.
	 * The bigger the area, the less sensitive the normal will be to small waves.
	 */
	UPROPERTY(EditAnywhere)
	float NormalSampleArea = 1000;
};

UCLASS(Abstract)
class AJetskiFloatingDebris : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UJetskiWaterSampleComponent WaterSampleComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	UJetskiFloatingDebrisEditorComponent EditorComp;
#endif

	/**
	 * What initial state we want for this actor.
	 */
	UPROPERTY(EditAnywhere, Category = "Floating Debris")
	EJetskiFloatingDebrisState CurrentState;

	UPROPERTY(EditAnywhere, Category = "Floating Debris")
	float FallFromHeightOffset = 10000;

	UPROPERTY(EditAnywhere, Category = "Floating Debris")
	bool bShouldBeHiddenWhenWaiting;

	/**
	 * To save performance, ticking is turned off while in the idle "Waiting" state,
	 * if ticking is enabled, we will throw an error unless this is checked to make sure
	 * that it's not accidentally enabled anywhere.
	 */
	UPROPERTY(EditAnywhere, Category = "Waiting")
	bool bAllowTickingWhileWaiting = false;

	UPROPERTY(EditAnywhere, Category = "Falling")
	float GravityAcceleration = 5000;

	/**
	 * How fast we should fall at the start of the Falling state
	 * Higher values means faster falling
	 */
	UPROPERTY(EditAnywhere, Category = "Falling")
	float InitialFallingSpeed = 0;

	UPROPERTY(EditAnywhere, Category = "Falling")
	float FallingMaxSpeed = 10000;

	/**
	 * How much of the falling velocity to keep after we hit the water.
	 * 1 makes us keep all velocity and go straight through the water.
	 * 0 is a complete stop at the surface.
	 */
	UPROPERTY(EditAnywhere, Category = "Falling", Meta = (UIMin = "0.0", UIMax = "1.0"))
	float HitSurfaceKeepVelocityFactor = 0.3;

	UPROPERTY(EditAnywhere, Category = "Floating")
	float FloatUpAcceleration = 5000;

	UPROPERTY(EditAnywhere, Category = "Floating")
	float FloatUpMaxSpeed = 5000;

	/**
	 * While on the surface, we use a spring to settle down after the fall.
	 */
	UPROPERTY(EditAnywhere, Category = "Surface")
	float SurfaceSpringStiffness = 10.0;

	UPROPERTY(EditAnywhere, Category = "Surface")
	float SurfaceSpringDamping = 1;

	UPROPERTY(EditAnywhere, Category = "Surface")
	EJetskiFloatingDebrisSurfaceBehaviour SurfaceBehaviour = EJetskiFloatingDebrisSurfaceBehaviour::QueryWaveHeight;

	UPROPERTY(EditAnywhere, Category = "Surface", Meta = (EditCondition = "SurfaceBehaviour == EJetskiFloatingDebrisSurfaceBehaviour::CalculateSineWaves", EditConditionHides))
	FJetskiFloatingDebrisCalculatedSineSettings SurfaceCalculatedSineSettings;

	/**
	 * Should we adjust the rotation so that up is pointing in the water normal direction?
	 */
	UPROPERTY(EditAnywhere, Category = "Surface|Rotation")
	bool bSpringRotationToSurfaceNormal = true;

	/**
	 * How strong we want the surface normal to be.
	 * Lower values means that the target rotation will be more up instead of following the water normal.
	 */
	UPROPERTY(EditAnywhere, Category = "Surface|Rotation", Meta = (UIMin = "0.0", UIMax = "1.0", EditCondition = "bSpringRotationToSurfaceNormal", EditConditionHides))
	float SurfaceRotationAlpha = 1.0;

	UPROPERTY(EditAnywhere, Category = "Surface|Rotation", Meta = (EditCondition = "bSpringRotationToSurfaceNormal", EditConditionHides))
	float SurfaceRotationSpringStiffness = 1.0;

	UPROPERTY(EditAnywhere, Category = "Surface|Rotation", Meta = (EditCondition = "bSpringRotationToSurfaceNormal", EditConditionHides))
	float SurfaceRotationSpringDamping = 0.1;

	UPROPERTY()
	FJetskiFloatingDebrisStartFalling OnStartFalling;

	UPROPERTY()
	FJetskiFloatingDebrisHitWater OnHitWater;

	UPROPERTY()
	FJetskiFloatingDebrisSurfaced OnSurfaced;

	private float VerticalSpeed = 0;
	private FHazeAcceleratedFloat AccOffsetToSurface;
	private FHazeAcceleratedQuat AccSurfaceRotation;
	private TOptional<float> WaterPlaneHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialFallingSpeed = Math::Abs(InitialFallingSpeed);
		FallingMaxSpeed = Math::Abs(FallingMaxSpeed);
		FloatUpMaxSpeed = Math::Abs(FloatUpMaxSpeed);
		WaterPlaneHeight.Set(ActorLocation.Z);

		// Move up to the falling location
		if(CurrentState == EJetskiFloatingDebrisState::Waiting || CurrentState == EJetskiFloatingDebrisState::Falling)
		{
			VerticalSpeed = -InitialFallingSpeed;
			SetActorLocation(ActorLocation + (FVector::UpVector * FallFromHeightOffset));
		}

		if(CurrentState == EJetskiFloatingDebrisState::Waiting)
		{
			if(!bAllowTickingWhileWaiting)
				SetActorTickEnabled(false);

			if(bShouldBeHiddenWhenWaiting)
				SetActorHiddenInGame(true);
		}
		else
		{
			// Everything but Waiting should tick the actor
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		switch(CurrentState)
		{
			case EJetskiFloatingDebrisState::Waiting:
				check(bAllowTickingWhileWaiting, "Ticking while in Waiting state on a Floating Debris actor! Check bAllowTickingWhileWaiting if this is intended.");
				break;

			case EJetskiFloatingDebrisState::Falling:
				TickFalling(DeltaSeconds);
				break;

			case EJetskiFloatingDebrisState::Floating:
				TickFloating(DeltaSeconds);
				break;

			case EJetskiFloatingDebrisState::Surface:
				TickSurface(DeltaSeconds);
				break;
		}
	}

	private void TickFalling(float DeltaTime)
	{
		// Apply Gravity to the vertical speed
		VerticalSpeed = Math::FInterpConstantTo(VerticalSpeed, -FallingMaxSpeed, DeltaTime, GravityAcceleration);

		// Get the delta from the vertical speed
		float Delta = VerticalSpeed * DeltaTime;

		// Subtract delta from the acceleration
		 Delta += GravityAcceleration * Math::Square(DeltaTime) * 0.5;

		 // Apply the delta to the falling component
		AddActorWorldOffset(FVector::UpVector * Delta);

		const float WaveHeight = GetWaveHeight();

		if(ActorLocation.Z < WaveHeight)
		{
			// We hit the water surface!
			if(HasControl())
				CrumbTransitionToState(EJetskiFloatingDebrisState::Floating);
		}
	}

	private void TickFloating(float DeltaTime)
	{
		VerticalSpeed = Math::FInterpConstantTo(VerticalSpeed, FloatUpMaxSpeed, DeltaTime, FloatUpAcceleration);

		float Delta = VerticalSpeed * DeltaTime;
		Delta -= FloatUpAcceleration * Math::Square(DeltaTime) * 0.5;

		AddActorWorldOffset(FVector::UpVector * Delta);

		const float WaveHeight = GetWaveHeight();

		if(ActorLocation.Z > WaveHeight && VerticalSpeed > 0)
		{
			// We went from under the water to the surface!
			if(HasControl())
				CrumbTransitionToState(EJetskiFloatingDebrisState::Surface);
		}
	}

	private void TickSurface(float DeltaTime)
	{
		AccOffsetToSurface.SpringTo(
			0,
			SurfaceSpringStiffness,
			SurfaceSpringDamping,
			DeltaTime
		);

		const float WaveHeight = GetWaveHeight();
		const float SurfaceHeight = WaveHeight + AccOffsetToSurface.Value;

		FVector SurfaceLocation = ActorLocation;
		SurfaceLocation.Z = SurfaceHeight;

		if(bSpringRotationToSurfaceNormal)
		{
			const FVector WaveNormal = GetWaveNormal();
			const FQuat TargetRotation = FQuat::MakeFromZX(WaveNormal, ActorForwardVector);
			AccSurfaceRotation.Value = ActorQuat;
			AccSurfaceRotation.SpringTo(TargetRotation, SurfaceRotationSpringStiffness, SurfaceRotationSpringDamping, DeltaTime);
			SetActorLocationAndRotation(SurfaceLocation, AccSurfaceRotation.Value);
		}
		else
		{
			SetActorLocation(SurfaceLocation);
		}
	}

	private float GetWaveHeight() const
	{
		switch(SurfaceBehaviour)
		{
			case EJetskiFloatingDebrisSurfaceBehaviour::CalculateSineWaves:
				return CalculatePerlinWaveHeight(ActorLocation);

			case EJetskiFloatingDebrisSurfaceBehaviour::QueryWaveHeight:
				return QueryWaveHeight();
		}
	}

	float CalculatePerlinWaveHeight(FVector Location) const
	{
		FJetskiWaterPerlinWaves PerlinWaves(SurfaceCalculatedSineSettings);
		const float Offset = PerlinWaves.CalculatePerlinWaveHeightOffset(Location);
		return GetWaterPlaneHeight() + Offset;
	}

	float GetWaterPlaneHeight() const
	{
		if(WaterPlaneHeight.IsSet())
			return WaterPlaneHeight.Value;
		else
			return ActorLocation.Z;
	}

	float QueryWaveHeight() const
	{
		return WaterSampleComp.SampleWaveHeight();
	}

	private FVector GetWaveNormal() const
	{
		switch(SurfaceBehaviour)
		{
			case EJetskiFloatingDebrisSurfaceBehaviour::CalculateSineWaves:
				return CalculatePerlinWaveNormal();

			case EJetskiFloatingDebrisSurfaceBehaviour::QueryWaveHeight:
				return QueryWaveNormal();
		}
	}

	FVector CalculatePerlinWaveNormal() const
	{
		FJetskiWaterPerlinWaves PerlinWaves(SurfaceCalculatedSineSettings);
		const FVector WaveNormal = PerlinWaves.CalculatePerlinWaveNormal(ActorLocation);
		return Math::Lerp(FVector::UpVector, WaveNormal, SurfaceRotationAlpha);
	}

	FVector QueryWaveNormal() const
	{
		const FVector WaveNormal =  WaterSampleComp.SampleWaveNormal();
		return Math::Lerp(FVector::UpVector, WaveNormal, SurfaceRotationAlpha);
	}

	UFUNCTION(BlueprintCallable)
	void StartFalling()
	{
		if(HasControl())
			CrumbTransitionToState(EJetskiFloatingDebrisState::Falling);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTransitionToState(EJetskiFloatingDebrisState NewState)
	{
		if(!ensure(NewState != CurrentState, "Trying to change state to the current state! This should not happen..."))
			return;

		switch(NewState)
		{
			case EJetskiFloatingDebrisState::Waiting:
				devError("Can't change state to Waiting, it is only valid as an initial state!");
				return;

			case EJetskiFloatingDebrisState::Falling:
			{
				if(!devEnsure(CurrentState == EJetskiFloatingDebrisState::Waiting, f"Tried to start falling, but we weren't waiting to start falling! We were in state {CurrentState}"))
					return;

				VerticalSpeed = -InitialFallingSpeed;
				OnStartFalling.Broadcast();
				UJetskiFloatingDebrisEventHandler::Trigger_OnStartFalling(this);
				SetActorTickEnabled(true);

				if(bShouldBeHiddenWhenWaiting)
					SetActorHiddenInGame(false);
				
				break;
			}

			case EJetskiFloatingDebrisState::Floating:
			{
				FJetskiFloatingDebrisOnHitWaterEventData EventData;
				EventData.Location = FVector(ActorLocation.X, ActorLocation.Y, GetWaveHeight());
				EventData.ImpactSpeed = Math::Abs(VerticalSpeed);

				VerticalSpeed *= HitSurfaceKeepVelocityFactor;

				CurrentState = EJetskiFloatingDebrisState::Floating;
				OnHitWater.Broadcast();
				UJetskiFloatingDebrisEventHandler::Trigger_OnHitWater(this, EventData);
				SetActorTickEnabled(true);
				break;
			}

			case EJetskiFloatingDebrisState::Surface:
			{
				FJetskiFloatingDebrisOnSurfacedEventData EventData;

				const float WaveHeight = GetWaveHeight();

				AccOffsetToSurface.SnapTo(
					ActorLocation.Z - WaveHeight,
					VerticalSpeed
				);

				AccSurfaceRotation.SnapTo(ActorQuat);

				CurrentState = EJetskiFloatingDebrisState::Surface;
				OnSurfaced.Broadcast();
				EventData.Location = FVector(ActorLocation.X, ActorLocation.Y, WaveHeight);
				UJetskiFloatingDebrisEventHandler::Trigger_OnSurfaced(this, EventData);
				SetActorTickEnabled(true);
				break;
			}
		}

		CurrentState = NewState;
	}
};

#if EDITOR
class UJetskiFloatingDebrisEditorComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Visualization")
	bool bVisualizeWaveHeight = true;

	UPROPERTY(EditInstanceOnly, Category = "Visualization")
	bool bVisualizeFallHeight = true;
};

class UJetskiFloatingDebrisEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UJetskiFloatingDebrisEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto EditorComp = Cast<UJetskiFloatingDebrisEditorComponent>(Component);
		if(EditorComp == nullptr)
			return;

		auto FloatingDebris = Cast<AJetskiFloatingDebris>(Component.Owner);
		if(FloatingDebris == nullptr)
			return;

		if(EditorComp.bVisualizeWaveHeight)
		{
			if(FloatingDebris.SurfaceBehaviour == EJetskiFloatingDebrisSurfaceBehaviour::CalculateSineWaves)
				DrawCalculatedSineWaves(FloatingDebris);
		}

		if(EditorComp.bVisualizeFallHeight)
		{
			if(FloatingDebris.CurrentState == EJetskiFloatingDebrisState::Waiting || FloatingDebris.CurrentState == EJetskiFloatingDebrisState::Falling)
				DrawFallFromHeight(FloatingDebris);
		}
	}

	void DrawCalculatedSineWaves(AJetskiFloatingDebris FloatingDebris) const
	{
		FJetskiWaterPerlinWaves PerlinWaves(FloatingDebris.SurfaceCalculatedSineSettings);
		FVector Location = FloatingDebris.ActorLocation;
		Location.Z = FloatingDebris.GetWaterPlaneHeight();

		FVector WaveLocation;
		FVector WaveNormal;
		PerlinWaves.Visualize(this, Location, WaveLocation, WaveNormal);

		FVector Origin;
		FVector Extents;
		FloatingDebris.GetActorLocalBounds(true, Origin, Extents);

		Origin = FTransform(FloatingDebris.ActorQuat, WaveLocation, FloatingDebris.ActorScale3D).TransformPosition(Origin);
		Extents *= FloatingDebris.ActorScale3D;

		const FQuat Rotation = FQuat::MakeFromZX(WaveNormal, FloatingDebris.ActorForwardVector);
		const FTransform ActorTransform = FTransform(Rotation, Origin);

		DrawWireBox(ActorTransform.Location, Extents, ActorTransform.Rotation, FLinearColor::White, 3, true);
	}

	void DrawFallFromHeight(AJetskiFloatingDebris FloatingDebris) const
	{
		FVector Origin;
		FVector Extents;
		FloatingDebris.GetActorLocalBounds(true, Origin, Extents);

		Origin = FloatingDebris.ActorTransform.TransformPosition(Origin);
		Extents *= FloatingDebris.ActorScale3D;

		FTransform FallFromTransform(FloatingDebris.ActorQuat, FloatingDebris.ActorLocation + FVector(0, 0, FloatingDebris.FallFromHeightOffset));
		DrawWireBox(FallFromTransform.Location, Extents, FallFromTransform.Rotation, FLinearColor::Red, 3, true);
		DrawArrow(FallFromTransform.Location - FVector(0, 0, Extents.Z), FloatingDebris.ActorLocation + FVector(0, 0, Extents.Z * 2), FLinearColor::Red, 100, 3, true);
	}
};
#endif