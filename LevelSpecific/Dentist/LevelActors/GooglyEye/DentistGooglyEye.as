UCLASS(Abstract)
class ADentistGooglyEye : AHazeActor
{
	default ActorEnableCollision = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent EyeMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent PupilRoot;

	UPROPERTY(DefaultComponent, Attach = "PupilRoot")
	UStaticMeshComponent PupilMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LensMesh;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	UDentistGooglyEyeEditorComponent EditorComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Dimensions")
	float BoundaryRadius = 25;

	UPROPERTY(EditAnywhere, Category = "Dimensions", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float PupilPercentage = 0.5;

	UPROPERTY(EditAnywhere, Category = "Simulation")
	float TimeScale = 0.8;

	UPROPERTY(EditAnywhere, Category = "Simulation")
	float Restitution = 0.3;

	UPROPERTY(EditAnywhere, Category = "Simulation")
	float Gravity = 1000;

	UPROPERTY(EditAnywhere, Category = "Inertia")
	float InertiaMultiplier = 0.9;
	
	// Inertia
	FVector LocationLastFrame;
	FVector VelocityLastFrame;

	FVector RelativeVelocity;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		UpdateMeshScale();
	}
#endif

	void UpdateMeshScale()
	{
		const float EyeScale = BoundaryRadius / 50;
		EyeMesh.SetWorldScale3D(FVector(EyeScale, EyeScale, EyeMesh.GetWorldScale().Z));
		EyeMesh.MarkRenderStateDirty();

		const float PupilScale = GetPupilRadius() / 50;
		PupilMesh.SetWorldScale3D(FVector(PupilScale, PupilScale, PupilMesh.GetWorldScale().Z));
		PupilMesh.MarkRenderStateDirty();

		const float LensScale = BoundaryRadius / 50;
		LensMesh.SetWorldScale3D(FVector(LensScale, LensScale, EyeMesh.GetWorldScale().Z * 2));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Reset();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TickInertia(DeltaTime);
		TickSimulation(DeltaTime * TimeScale);
	}

	private void TickInertia(float DeltaTime)
	{
		FVector DeltaMove = ActorLocation - LocationLastFrame;
		FVector OwnerVelocity = DeltaMove / DeltaTime;
		FVector DeltaVelocity = OwnerVelocity - VelocityLastFrame;

		AddWorldImpulse(-DeltaVelocity * InertiaMultiplier);

		LocationLastFrame = ActorLocation;
		VelocityLastFrame = OwnerVelocity;
	}

	private void TickSimulation(float DeltaTime)
	{
		if(DeltaTime < KINDA_SMALL_NUMBER)
			return;

		// Gravity
		FVector Delta = RelativeVelocity * DeltaTime;
		Acceleration::ApplyAccelerationToVelocity(RelativeVelocity, FVector::DownVector * Gravity, DeltaTime, Delta);

		FVector NewLocation = PupilRoot.RelativeLocation + Delta;
		const float NewDistanceFromCenter = NewLocation.Size();

		const float SimulationRadius = BoundaryRadius - GetPupilRadius();

		if(NewDistanceFromCenter > SimulationRadius)
		{
			if(RelativeVelocity.Size() < 1)
			{
				// Basically standing still
				RelativeVelocity = FVector::ZeroVector;
				PupilRoot.SetRelativeLocation(NewLocation.GetClampedToMaxSize(SimulationRadius));
				return;
			}

			// Bounce off edge!
			FVector ClampedRelativeLocation = NewLocation.GetClampedToMaxSize(SimulationRadius);
			const FVector ClampedDelta = ClampedRelativeLocation - PupilRoot.RelativeLocation;

			PupilRoot.SetRelativeLocation(ClampedRelativeLocation);
			RelativeVelocity = RelativeVelocity.GetReflectionVector(PupilRoot.RelativeLocation.GetSafeNormal()) * Restitution;
			return;
		}

		PupilRoot.SetRelativeLocation(NewLocation);
	}

	void AddWorldImpulse(FVector Impulse)
	{
		FVector RelativeImpulse = ActorTransform.InverseTransformVectorNoScale(Impulse);
		RelativeImpulse.X = 0;
		RelativeVelocity += RelativeImpulse;
	}

	float GetPupilRadius() const
	{
		return BoundaryRadius * PupilPercentage;
	}

	void Reset()
	{
		LocationLastFrame = ActorLocation;
		VelocityLastFrame = FVector::ZeroVector;
		RelativeVelocity = FVector::ZeroVector;

		// Put the pupil at the bottom
		const float SimulationRadius = BoundaryRadius - GetPupilRadius();
		PupilRoot.SetRelativeLocation(FVector(0, 0, -SimulationRadius));
	}
};

class UDentistGooglyEyeEditorComponent : UActorComponent
{
};

#if EDITOR
class UDentistGooglyEyeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDentistGooglyEyeEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto GooglyEye = Cast<ADentistGooglyEye>(Component.Owner);
		if(GooglyEye == nullptr)
			return;

		DrawWireCylinder(GooglyEye.ActorLocation, FRotator::MakeFromZ(GooglyEye.ActorForwardVector), FLinearColor::White, GooglyEye.BoundaryRadius, 10, 32);
		DrawWireCylinder(GooglyEye.PupilRoot.WorldLocation, FRotator::MakeFromZ(GooglyEye.PupilRoot.ForwardVector), FLinearColor::Black, GooglyEye.GetPupilRadius(), 10, 32);
	}
};
#endif