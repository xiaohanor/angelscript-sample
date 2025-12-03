UCLASS()
class USandSharkAnimationComponent : UActorComponent
{
	private TSet<FInstigator> SplineDisableInstigators;
	private TSet<FInstigator> DiveInstigators;
	private TSet<FInstigator> MeshOffsetRemovalInstigators;
	private TSet<FInstigator> AnimationUpdateInstigators;
	private TSet<FInstigator> AnimationChaseInstigators;

	FVector OriginalMeshOffset;

	FSandSharkAnimData Data;

	ASandShark SandShark;

	EVisibilityBasedAnimTickOption DefaultAnimTickOption;

	UHazeCharacterSkeletalMeshComponent SharkMesh;

	private bool bHasUnconsumedSandDiveBreachEvent = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SandShark = Cast<ASandShark>(Owner);
		if (SandShark != nullptr)
		{
			SharkMesh = SandShark.SharkMesh;
			OriginalMeshOffset = SharkMesh.RelativeLocation;
			DefaultAnimTickOption = SharkMesh.VisibilityBasedAnimTickOption;
		}
	}

	FVector GetNeckLocation() const
	{
		return SandShark.SharkMesh.GetSocketLocation(n"Neck");
	}

	void OnAnimSandDiveBreach()
	{
		bHasUnconsumedSandDiveBreachEvent = true;
	}

	bool HasBreachedSand() const
	{
		return bHasUnconsumedSandDiveBreachEvent;
	}

	void ConsumeSandBreach()
	{
		bHasUnconsumedSandDiveBreachEvent = false;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Animation");
		LogInstigators(TemporalLog, "Instigators;SplineDisableInstigators;", SplineDisableInstigators);
		LogInstigators(TemporalLog, "Instigators;DiveInstigators;", DiveInstigators);
		LogInstigators(TemporalLog, "Instigators;MeshOffsetRemovalInstigators;", MeshOffsetRemovalInstigators);
		LogInstigators(TemporalLog, "Instigators;AnimationUpdateInstigators;", AnimationUpdateInstigators);
		LogInstigators(TemporalLog, "Instigators;AnimationChaseInstigators;", AnimationChaseInstigators);
		Data.Log(TemporalLog);
	}
#endif

	void LogInstigators(FTemporalLog Log, FString Category, TSet<FInstigator> Instigators)
	{
		if (Instigators.IsEmpty())
		{
			Log.Value(f"{Category}", "");
		}
		else
		{
			for (auto Instigator : Instigators)
			{
				Log.Value(f"{Category};{Instigator.ToPlainString()} ", "");
			}
		}
	}

	FVector GetFinTopLocation() const property
	{
		return SharkMesh.GetSocketLocation(n"TrailFinTop");
	}

	FVector GetFinBotLocation() const property
	{
		return SharkMesh.GetSocketLocation(n"TrailFinBottom");
	}

	void AddHighAnimUpdateInstigator(FInstigator Instigator)
	{
		AnimationUpdateInstigators.Add(Instigator);
		SharkMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	}
	void RemoveHighAnimUpdateInstigator(FInstigator Instigator)
	{
		AnimationUpdateInstigators.Remove(Instigator);
		if (AnimationUpdateInstigators.Num() == 0)
			SharkMesh.VisibilityBasedAnimTickOption = DefaultAnimTickOption;
	}

	void AddAnimChaseInstigator(FInstigator Instigator)
	{
		AnimationChaseInstigators.Add(Instigator);
		Data.bIsChasing = true;
	}

	void RemoveAnimChaseInstigator(FInstigator Instigator)
	{
		AnimationChaseInstigators.Remove(Instigator);
		if (AnimationChaseInstigators.Num() <= 0)
			Data.bIsChasing = false;
	}

	void AddDiveInstigator(FInstigator Instigator)
	{
		DiveInstigators.Add(Instigator);
		Data.bIsDiving = true;
	}

	void RemoveDiveInstigator(FInstigator Instigator)
	{
		DiveInstigators.Remove(Instigator);
		if (DiveInstigators.Num() <= 0)
			Data.bIsDiving = false;
	}
};