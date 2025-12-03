UCLASS(Abstract)
class ADentistSimulationRotatingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDentistRotatingActorSimulationComponent SimulationComp;

	/**
	 * How many rotations to do per loop.
	 * Negative values are fine.
	 * By defining rotation like this instead of speed, we ensure that
	 * the loop is always perfect, however it also means that the speed
	 * varies based on the loop duration.
	 */
	UPROPERTY(EditAnywhere, Category = "Rotation")
	int RotationsPerLoop = 3;

	/**
	 * What axis to rotate around. Defined as a Vector 2 since we only need a direction.
	 */
	UPROPERTY(EditAnywhere, Category = "Rotation")
	FVector2D RotationAxis = FVector2D::ZeroVector;

	/**
	 * How many extra degrees to add to the rotation (for visual difference)
	 */
	UPROPERTY(EditAnywhere, Category = "Rotation")
	float RotationOffset = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SimulationComp.OnTickSimulationDelegate.BindUFunction(this, n"OnTickSimulation");
	}

	UFUNCTION()
	private void OnTickSimulation(float LoopTime, float LoopDuration, int LoopCount)
	{
		UpdateSimulationLocation(LoopTime, LoopDuration);
	}

	void UpdateSimulationLocation(float LoopTime, float LoopDuration)
	{
		SetActorRelativeRotation(GetRotationAtTime(LoopTime, LoopDuration));
	}

	FQuat GetRotationAtTime(float LoopTime, float LoopDuration) const
	{
		const float Alpha = Math::Saturate(LoopTime / LoopDuration);
		const FQuat Rotation = FQuat(FVector::UpVector, (RotationsPerLoop * PI * 2 * Alpha) + Math::DegreesToRadians(RotationOffset));

		const FRotator AxisRotation = FRotator(RotationAxis.X, RotationAxis.Y, 0);
		return AxisRotation.Quaternion() * Rotation;
	}
};

UCLASS(NotBlueprintable)
class UDentistRotatingActorSimulationComponent : UDentistSimulationComponent
{
	default bLoopSimulation = true;
	
#if EDITOR
	void PreIteration(float TimeSinceStart, float LoopDuration) override
	{
		auto RotatingActor = Cast<ADentistSimulationRotatingActor>(Owner);
		RotatingActor.UpdateSimulationLocation(TimeSinceStart, LoopDuration);
	}

	void ResetPostSimulation() override
	{
		auto RotatingActor = Cast<ADentistSimulationRotatingActor>(Owner);
		RotatingActor.UpdateSimulationLocation(0, 1);
	}

	void Visualize(UHazeScriptComponentVisualizer Visualizer, float LoopTime, float LoopDuration) const override
	{
#if EDITOR
		if(Editor::IsPlaying())
			return;
#endif
	
		auto RotatingActor = Cast<ADentistSimulationRotatingActor>(Owner);

		const FQuat Rotation = RotatingActor.GetRotationAtTime(LoopTime, LoopDuration);
		FTransform Transform = RotatingActor.ActorTransform;
		Transform.SetRotation(Rotation);

		Visualizer.DrawCoordinateSystem(Transform.Location, Transform.Rotator(), 100, 10);

		TArray<AActor> AttachedActors;
		RotatingActor.GetAttachedActors(AttachedActors, false, true);
		for(AActor Actor : AttachedActors)
		{
			auto SimulationComp = UDentistSimulationComponent::Get(Actor);
			if(SimulationComp != nullptr)
				continue;	// Please don't do this...

			FTransform RelativeTransform = Actor.ActorTransform.GetRelativeTransform(RotatingActor.ActorTransform);

			FTransform AttachedTransform = RelativeTransform * Transform;

			// Go through all children and visualize them as well
			UMaterialInterface Material = Editor::IsSelected(Owner) ? KineticActorVisualizer::GetSelectedMaterial() : KineticActorVisualizer::GetUnselectedMaterial();
			Dentist::Simulation::DrawAllStaticMeshesOnActor(Visualizer, Actor, AttachedTransform, Material);
		}
	}
#endif
};