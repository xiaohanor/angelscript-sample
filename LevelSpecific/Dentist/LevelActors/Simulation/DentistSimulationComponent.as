delegate void FDentistSimulationPlayDelegate(float StartTime);
delegate void FDentistSimulationTickDelegate(float LoopTime, float LoopDuration, int LoopCount);

enum EDentistSimulationVisualization
{
	EntireLoop,
	OnlyThis,
	None,
};

UCLASS(NotBlueprintable, HideCategories = "Activation Rendering Tags Navigation ComponentTick Cooking Disable")
class UDentistSimulationComponent : UActorComponent
{
	/**
	 * What loop currently owns us?
	 * This cannot be edited here, since it should be a one-way relationship in the editor.
	 * Assign us on the loop instead.
	 */
	UPROPERTY(VisibleInstanceOnly, Category = "Simulation")
	ADentistSimulationLoop SimulationLoop;

	/**
	 * Should we resimulate everything when we are modified?
	 * Disable if the performance is too bad.
	 */
	UPROPERTY(EditAnywhere, Category = "Simulation")
	bool bSimulateOnModified = false;

	/**
	 * Delaying the start of simulation will allow it to continue into the next loop, hiding the looping behaviour.
	 */
	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	float SimulationStartOffset = 0;

	/**
	 * If false, we are excluded from the simulation outside of our loop window
	 */
	UPROPERTY(EditAnywhere, Category = "Simulation")
	bool bLoopSimulation = false;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Visualization")
	EDentistSimulationVisualization Visualization = EDentistSimulationVisualization::EntireLoop;

	int TickOrder = 100;

	FDentistSimulationPlayDelegate OnPlaySimulationDelegate;
	FDentistSimulationTickDelegate OnTickSimulationDelegate;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		SimulationLoop = Dentist::Simulation::FindOwningSimulationLoop(this);

		if(SimulationLoop != nullptr && bSimulateOnModified)
			SimulationLoop.RunSimulation();
	}
#endif

#if EDITOR
	/**
	 * Called once, when simulation is initializing
	 */
	void PrepareSimulation(ADentistSimulationLoop InSimulationLoop)
	{
		SimulationLoop = InSimulationLoop;
	}

	/**
	 * Before any movement
	 * Called each iteration before RunIteration
	 */
	void PreIteration(float TimeSinceStart, float LoopDuration)
	{
	}

	/**
	 * Perform iteration movement
	 * Called each iteration
	 */
	void RunIteration(float TimeSinceStart, float TimeStep)
	{
	}

	/**
	 * Respond to the iteration
	 * Called each iteration after RunIteration
	 */
	void PostIteration(float TimeSinceStart)
	{
	}

	void SerializeSimulation()
	{
	}

	/**
	 * Reset everything back to the way it was before simulating
	 * Called once, after the simulation is finished
	 */
	void ResetPostSimulation()
	{
	}

	void Visualize(UHazeScriptComponentVisualizer Visualizer, float LoopTime, float LoopDuration) const
	{
	}

	UFUNCTION(CallInEditor, Category = "Simulation")
	void PlayVisualizationFromStart()
	{
		ADentistSimulationLoop OwningSimulationLoop = Dentist::Simulation::FindOwningSimulationLoop(this);
		if(OwningSimulationLoop == nullptr)
			return;

		OwningSimulationLoop.PlayVisualizationFromStart();
	}

	UFUNCTION(CallInEditor, Category = "Simulation")
	void RunSimulation()
	{
		ADentistSimulationLoop OwningSimulationLoop = Dentist::Simulation::FindOwningSimulationLoop(this);
		if(OwningSimulationLoop == nullptr)
			return;

		OwningSimulationLoop.RunSimulation();
	}
#endif
};

namespace Dentist::Simulation
{
#if EDITOR
	ADentistSimulationLoop FindOwningSimulationLoop(const UDentistSimulationComponent SimulationComp)
	{
		const TArray<ADentistSimulationLoop> Actors = Editor::GetAllEditorWorldActorsOfClass(ADentistSimulationLoop);

		for(const AActor Actor : Actors)
		{
			auto FoundSimulationLoop = Cast<ADentistSimulationLoop>(Actor);
			if(FoundSimulationLoop == nullptr)
				continue;

			if(!FoundSimulationLoop.SimulationActors.Contains(SimulationComp.Owner))
				continue;

			return FoundSimulationLoop;
		}

		return nullptr;
	}

	void DrawAllStaticMeshesOnActor(const UHazeScriptComponentVisualizer Visualizer, const AActor AttachedActor, FTransform ActorTransform, UMaterialInterface Material)
	{
		TArray<UStaticMeshComponent> MeshComponents;
		AttachedActor.GetComponentsByClass(MeshComponents);

		for(auto MeshComponent : MeshComponents)
		{
			if(!IsValid(MeshComponent))
				continue;
			
			if(!MeshComponent.bVisible)
				continue;
			
			const FTransform RelativeTransform = MeshComponent.WorldTransform.GetRelativeTransform(MeshComponent.Owner.ActorTransform);
			const FTransform MeshTransform = RelativeTransform * ActorTransform;

			Visualizer.DrawMeshWithMaterial(
				MeshComponent.StaticMesh,
				Material,
				MeshTransform.Location,
				MeshTransform.Rotation,
				MeshTransform.Scale3D
			);
		}
	}
#endif
}

#if EDITOR
class UDentistSimulationComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDentistSimulationComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto SimulationComp = Cast<UDentistSimulationComponent>(Component);

		if(SimulationComp == nullptr)
			return;

		if(SimulationComp.Visualization == EDentistSimulationVisualization::None)
			return;

		ADentistSimulationLoop SimulationLoop = SimulationComp.SimulationLoop;
		if(SimulationLoop == nullptr && !Editor::IsPlaying())
			SimulationLoop = Dentist::Simulation::FindOwningSimulationLoop(SimulationComp);

		if(SimulationLoop == nullptr)
		{
			DrawWorldString("NOT ASSIGNED TO A LOOP", SimulationComp.Owner.ActorLocation, FLinearColor::Red, 2, -1, false, true);
			return;
		}

		switch(SimulationComp.Visualization)
		{
			case EDentistSimulationVisualization::EntireLoop:
				SimulationLoop.Visualize(this);
				break;

			case EDentistSimulationVisualization::OnlyThis:
			{
				const float TimeSinceStart = SimulationLoop.GetVisualizationTimeSinceStart();

				FDentistSimulationData SimulationData = FDentistSimulationData(SimulationComp);
				SimulationData.SetTimeSinceStart(TimeSinceStart);

				SimulationComp.Visualize(this, SimulationData.GetLoopTime(SimulationLoop.LoopDuration), SimulationLoop.LoopDuration);
				break;
			}

			case EDentistSimulationVisualization::None:
				return;
		}
	}
}
#endif