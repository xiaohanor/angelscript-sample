// I named this specifically for you Luke and Oliver <3
struct FDentistSimulationData
{
	UDentistSimulationComponent SimulationComp;
	private float TimeSinceStart;

	FDentistSimulationData(UDentistSimulationComponent InSimulationComp)
	{
		SimulationComp = InSimulationComp;
		TimeSinceStart = 0;
	}

	void SetTimeSinceStart(float LoopTimeSinceStart)
	{
		// Offset the TimeSinceStart to allow shifting the simulation
		TimeSinceStart = LoopTimeSinceStart - SimulationComp.SimulationStartOffset;
	}

	float GetTimeSinceStart() const
	{
		return TimeSinceStart;
	}

	float GetLoopTime(float LoopDuration) const
	{
		if(SimulationComp.bLoopSimulation)
		{
			if(TimeSinceStart < 0)
				return Math::Wrap(TimeSinceStart, 0, LoopDuration);
		}

		return TimeSinceStart % LoopDuration;
	}

	bool IsSimulating(float LoopDuration) const
	{
		if(SimulationComp.bLoopSimulation)
			return true;

		// If our time to start is negative, we haven't started yet
		// If it is higher than LoopDuration, we have ended
		return TimeSinceStart >= 0 && TimeSinceStart < LoopDuration;
	}

	int opCmp(const FDentistSimulationData& Other) const
	{
		if(SimulationComp.TickOrder > Other.SimulationComp.TickOrder)
			return 1;
		else
			return -1;
	}
}

UCLASS(Abstract)
class ADentistSimulationLoop : AHazeActor
{
	access Internal = private, UDentistSimulationComponent (inherited), FindOwningSimulationLoop(), UDentistSimulationComponentVisualizer (inherited);

	default TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	private USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	private UEditorBillboardComponent EditorIcon;
	default EditorIcon.SetRelativeScale3D(FVector(5));
	default EditorIcon.SpriteName = "Ai_Spawnpoint";

	UPROPERTY(DefaultComponent)
	private UDentistSimulationLoopEditorComponent EditorComp;
#endif

	/**
	 * How fast to replay the simulation
	 */
	UPROPERTY(EditInstanceOnly, Category = "Playback", Meta = (ClampMin = "0.001", ClampMax = "5.0"))
	float PlayRate = 1;

	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	access:Internal
	float LoopDuration = 10;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (ClampMin = "0.01", ClampMax = "0.2"))
	access:Internal
	float SimulationTimeStep = 0.05;

	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	access:Internal
	TArray<AActor> SimulationActors;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	bool bSimulateOnModified = false;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Visualization")
	bool bVisualize = true;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Visualization")
	bool bPlayVisualization = true;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Visualization", Meta = (EditCondition = "!bPlayVisualization"))
	float VisualizationTime = 0;
#endif

	access:Internal
	TArray<FDentistSimulationData> SimulationDatas;

	private float StartTime = 0;

#if EDITOR
	private float VisualizationStartTime = -1;
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(bSimulateOnModified)
		{
			if(!bPlayVisualization)
				return;	// Don't simulate while scrubbing visualization

			RunSimulation();
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTime = Time::PredictedGlobalCrumbTrailTime;
		FetchSimulationComponents();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float TimeSinceStart = Math::Max(Time::PredictedGlobalCrumbTrailTime - StartTime, 0) * PlayRate;

		for(auto& SimulationData : SimulationDatas)
		{
			SimulationData.SetTimeSinceStart(TimeSinceStart);
			const int LoopCount = Math::CeilToInt(SimulationData.GetTimeSinceStart() / LoopDuration);
			SimulationData.SimulationComp.OnTickSimulationDelegate.ExecuteIfBound(SimulationData.GetLoopTime(LoopDuration), LoopDuration, LoopCount);
		}
	}

	private void FetchSimulationComponents()
	{
		SimulationDatas.Reset();

		for(int i = SimulationActors.Num() - 1; i >= 0; i--)
		{
			AActor Actor = SimulationActors[i];
			if(Actor == nullptr)
				continue;

			bool bFoundSimulationComp = false;
			while(Actor != nullptr)
			{
				auto SimulationComp = UDentistSimulationComponent::Get(Actor);
				if(SimulationComp != nullptr)
				{
					SimulationDatas.Add(FDentistSimulationData(SimulationComp));
					SimulationActors[i] = Actor;
					bFoundSimulationComp = true;
					break;
				}

				Actor = Actor.AttachParentActor;
			}

			if(!bFoundSimulationComp)
			{
				PrintWarning(f"Actor {Actor} does not have a DentistSimulationComponent!");
				SimulationActors[i] = nullptr;
			}
		}
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Simulation")
	access:Internal
	void PlayVisualizationFromStart()
	{
		VisualizationStartTime = Time::GameTimeSeconds;
		bPlayVisualization = true;
	}

	UFUNCTION(CallInEditor, Category = "Simulation")
	access:Internal
	void RunSimulation()
	{
		PrepareSimulation();

		RunIterations();

		Reset();
	}

	private void PrepareSimulation()
	{
		FetchSimulationComponents();

		SimulationDatas.Sort();
		
		for(auto SimulationData : SimulationDatas)
			SimulationData.SimulationComp.PrepareSimulation(this);
	}
	private void RunIterations()
	{
		float TimeSinceStart = 0;

		float HighestLoopStartOffset = 0;
		for(auto SimulationData : SimulationDatas)
			HighestLoopStartOffset = Math::Max(SimulationData.SimulationComp.SimulationStartOffset, HighestLoopStartOffset);

		// We must offset the simulation duration by the highest start offset, to allow it to completely finish
		const float SimulationDuration = LoopDuration + HighestLoopStartOffset;

		while(TimeSinceStart < SimulationDuration)
		{
			TimeSinceStart += SimulationTimeStep;

			ProcessPreIteration(TimeSinceStart);
			ProcessRunIteration();
			ProcessPostIteration();
		}
	}

	private void ProcessPreIteration(float TimeSinceStart)
	{
		for(FDentistSimulationData& SimulationData : SimulationDatas)
		{
			// Prepare by assigning the time since start
			SimulationData.SetTimeSinceStart(TimeSinceStart);

			if(!SimulationData.IsSimulating(LoopDuration))
				continue;

			SimulationData.SimulationComp.PreIteration(SimulationData.GetTimeSinceStart(), LoopDuration);
		}
	}

	private void ProcessRunIteration()
	{
		for(FDentistSimulationData& SimulationData : SimulationDatas)
		{
			if(!SimulationData.IsSimulating(LoopDuration))
				continue;

			SimulationData.SimulationComp.RunIteration(SimulationData.GetTimeSinceStart(), SimulationTimeStep);
		}
	}

	private void ProcessPostIteration()
	{
		for(FDentistSimulationData& SimulationData : SimulationDatas)
		{
			if(!SimulationData.IsSimulating(LoopDuration))
				continue;

			SimulationData.SimulationComp.PostIteration(SimulationData.GetTimeSinceStart());
		}
	}

	private void Reset()
	{
		for(FDentistSimulationData& SimulationData : SimulationDatas)
		{
			SimulationData.SimulationComp.SerializeSimulation();
			SimulationData.SimulationComp.ResetPostSimulation();
		}
	}

	float GetVisualizationTimeSinceStart() const
	{
		if(bPlayVisualization)
		{
			float TimeSinceStart = Time::GameTimeSeconds - VisualizationStartTime;
			TimeSinceStart *= PlayRate;
			return TimeSinceStart;
		}
		else
		{
			return VisualizationTime;
		}
	}

	void Visualize(UHazeScriptComponentVisualizer Visualizer) const
	{
		if(!bVisualize)
			return;

		const float TimeSinceStart = GetVisualizationTimeSinceStart();

		for(auto Actor : SimulationActors)
		{
			if(Actor == nullptr)
				continue;

			auto SimulationComp = UDentistSimulationComponent::Get(Actor);
			if(SimulationComp == nullptr)
				continue;

			if(SimulationComp.Visualization == EDentistSimulationVisualization::None)
				continue;

			FDentistSimulationData SimulationData = FDentistSimulationData(SimulationComp);
			SimulationData.SetTimeSinceStart(TimeSinceStart);

			Visualizer.DrawArrow(ActorLocation, Actor.ActorLocation, FLinearColor::Yellow, 10, 3);
			SimulationComp.Visualize(Visualizer, SimulationData.GetLoopTime(LoopDuration), LoopDuration);
		}
	}
#endif
};

#if EDITOR
class UDentistSimulationLoopEditorComponent : UActorComponent
{
};

class UDentistSimulationLoopVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDentistSimulationLoopEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		ADentistSimulationLoop SimulationLoop = Cast<ADentistSimulationLoop>(Component.Owner);
		if(SimulationLoop == nullptr)
			return;

		if(!SimulationLoop.bVisualize)
			return;

		SimulationLoop.Visualize(this);
	}
};
#endif