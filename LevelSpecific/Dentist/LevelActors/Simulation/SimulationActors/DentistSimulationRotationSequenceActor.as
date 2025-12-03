struct FDentistSimulationRotationSequenceEntry
{
	UPROPERTY(EditAnywhere)
	FRotator RelativeRotation;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0.0", ClampMax = "100.0"))
	float Time = 100;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0.0", ClampMax = "10.0"))
	float PreDuration = 0;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0.0", ClampMax = "10.0"))
	float PostDuration = 0;

	int opCmp(const FDentistSimulationRotationSequenceEntry Other) const
	{
		if(Other.Time > Time)
			return -1;
		else
			return 1;
	}
};

UCLASS(Abstract)
class ADentistSimulationRotationSequenceActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDentistSimulationRotationSequenceSimulationComponent SimulationComp;

	/**
	 * A sequence of rotations to hit at specific times
	 */
	UPROPERTY(EditAnywhere, Category = "Rotation")
	TArray<FDentistSimulationRotationSequenceEntry> Sequence;

	bool bWasMoving = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Sequence.Sort();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SimulationComp.OnTickSimulationDelegate.BindUFunction(this, n"OnTickSimulation");
	}

	UFUNCTION()
	private void OnTickSimulation(float LoopTime, float LoopDuration, int LoopCount)
	{
		UpdateSimulationLocation(LoopTime);

		const bool bIsMoving = IsMovingAtTime(LoopTime);

		if(bIsMoving != bWasMoving)
		{
			if(bIsMoving)
			{
				UDentistSimulationRotationSequenceActorEventHandler::Trigger_OnStartMoving(this);
				//Debug::DrawDebugString(ActorLocation + FVector(0, 0, 1000), "Start Moving", Duration = 0.1, Scale = 5);
			}
			else
			{
				UDentistSimulationRotationSequenceActorEventHandler::Trigger_OnStopMoving(this);
				//Debug::DrawDebugString(ActorLocation, "Stop Moving", Duration = 0.1, Scale = 5);
			}
		}

		bWasMoving = bIsMoving;
	}

	void UpdateSimulationLocation(float LoopTime)
	{
		SetActorRelativeRotation(GetRotationAtTime(LoopTime));
	}

	FRotator GetRotationAtTime(float LoopTime) const
	{
		if(Sequence.IsEmpty())
			return FRotator::ZeroRotator;

		if(Sequence.Num() == 1 || LoopTime <= Sequence[0].Time + KINDA_SMALL_NUMBER)
			return Sequence[0].RelativeRotation;

		if(LoopTime >= Sequence.Last().Time - KINDA_SMALL_NUMBER)
			return Sequence.Last().RelativeRotation;

		for(int i = 0; i < Sequence.Num() - 1; i++)
		{
			if(Sequence[i].Time <= LoopTime && LoopTime <= Sequence[i + 1].Time)
			{
				return Lerp(Sequence[i], Sequence[i + 1], LoopTime);
			}
		}

		check(false);
		return FRotator::ZeroRotator;
	}

	FRotator Lerp(const FDentistSimulationRotationSequenceEntry A, const FDentistSimulationRotationSequenceEntry B, float LoopTime) const
	{
		float AEndTime = A.Time + A.PostDuration;
		if(LoopTime < AEndTime)
			return A.RelativeRotation;

		float BStartTime = B.Time - B.PreDuration;
		if(LoopTime > BStartTime)
			return B.RelativeRotation;

		float Alpha = Math::NormalizeToRange(LoopTime, AEndTime, BStartTime);
		return Math::LerpShortestPath(A.RelativeRotation, B.RelativeRotation, Alpha);
	}

	bool IsMovingAtTime(float LoopTime) const
	{
		if(Sequence.IsEmpty())
			return false;

		if(Sequence.Num() == 1 || LoopTime <= Sequence[0].Time + KINDA_SMALL_NUMBER)
			return false;

		if(LoopTime >= Sequence.Last().Time - KINDA_SMALL_NUMBER)
			return false;

		for(int i = 0; i < Sequence.Num() - 1; i++)
		{
			if(Sequence[i].Time <= LoopTime && LoopTime <= Sequence[i + 1].Time)
			{
				const FDentistSimulationRotationSequenceEntry& A = Sequence[i];
				const FDentistSimulationRotationSequenceEntry& B = Sequence[i + 1];

				float AEndTime = A.Time + A.PostDuration;
				if(LoopTime < AEndTime)
					return false;

				float BStartTime = B.Time - B.PreDuration;
				if(LoopTime > BStartTime)
					return false;

				return true;
			}
		}

		return false;
	}
};

UCLASS(NotBlueprintable)
class UDentistSimulationRotationSequenceSimulationComponent : UDentistSimulationComponent
{
	default bSimulateOnModified = false;
	default bLoopSimulation = true;

#if EDITOR
	void PrepareSimulation(ADentistSimulationLoop InSimulationLoop) override
	{
		Super::PrepareSimulation(InSimulationLoop);
		
		auto RotationSequence = Cast<ADentistSimulationRotationSequenceActor>(Owner);
		RotationSequence.Sequence.Sort();
	}
	
	void PreIteration(float TimeSinceStart, float LoopDuration) override
	{
		auto RotationSequence = Cast<ADentistSimulationRotationSequenceActor>(Owner);
		RotationSequence.UpdateSimulationLocation(TimeSinceStart);
	}

	void ResetPostSimulation() override
	{
		auto RotationSequence = Cast<ADentistSimulationRotationSequenceActor>(Owner);
		RotationSequence.UpdateSimulationLocation(0);
	}

	void Visualize(UHazeScriptComponentVisualizer Visualizer, float LoopTime, float LoopDuration) const override
	{
#if EDITOR
		if(Editor::IsPlaying())
			return;
#endif

		auto RotationSequence = Cast<ADentistSimulationRotationSequenceActor>(Owner);

		const FRotator Rotation = RotationSequence.GetRotationAtTime(LoopTime);

		FTransform Transform = RotationSequence.ActorRelativeTransform;

		if(RotationSequence.AttachParentActor != nullptr)
		{
			Transform.SetRotation(Rotation);
			Transform = Transform * RotationSequence.AttachParentActor.ActorTransform;
		}
		else
		{
			Transform.SetRotation(Rotation);
		}

		Visualizer.DrawCoordinateSystem(Transform.Location, Transform.Rotator(), 100, 10);

		TArray<AActor> AttachedActors;
		RotationSequence.GetAttachedActors(AttachedActors, false, true);
		for(AActor Actor : AttachedActors)
		{
			auto SimulationComp = UDentistSimulationComponent::Get(Actor);
			if(SimulationComp != nullptr)
				continue;	// Please don't do this...

			FTransform RelativeTransform = Actor.ActorTransform.GetRelativeTransform(RotationSequence.ActorTransform);

			FTransform AttachedTransform = RelativeTransform * Transform;

			// Go through all children and visualize them as well
			UMaterialInterface Material = Editor::IsSelected(Owner) ? KineticActorVisualizer::GetSelectedMaterial() : KineticActorVisualizer::GetUnselectedMaterial();
			Dentist::Simulation::DrawAllStaticMeshesOnActor(Visualizer, Actor, AttachedTransform, Material);
		}
	}
#endif
};