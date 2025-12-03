// Spawned actor will immediately play given animation with root motion
UCLASS(meta = (ShortTooltip="Spawned actor will immediately play given animation with root motion"))
class UHazeActorSpawnPatternEntryAnimation : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;

	// Spawned actors will use these animations in sequence, so first spawned actor will use first animation etc.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	TArray<UAnimSequence> Animations;

	// If true, animations will repeat when all anims have been used. If false, we stop (i.e. if you have three animations only the three first spawned actors will use entrance animations) 
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	bool bRepeatAnimations = false;

	// If true, we play animations in random order. If false, we always use specified order.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	bool bRandomAnimationOrder = false;

	int CurrentAnimationIndex = 0;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Preview", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewFraction = 0.0;

	UPROPERTY(EditInstanceOnly, Category = "Preview", AdvancedDisplay)
	int PreviewIndex = 0;

	UPROPERTY(EditInstanceOnly, Category = "Preview", AdvancedDisplay)
	int PreviewSpawnIndex = 0;

	UHazeEditorPreviewSkeletalMeshComponent PreviewMeshComp;
	UHazeEditorPreviewSkeletalMeshComponent PreviewDestinationMeshComp;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (Animations.Num() == 0)
		{
			// Uninitialized, this will not have any effect
			DeactivatePattern(this, EInstigatePriority::Override);
			return;
		}

		if (bRandomAnimationOrder)
			Animations.Shuffle();

		// Spawned actor will need to replicate which animation to use, when appropriate 
		// TODO: Replicate shuffle order instead, then the rest will be deterministic. For AIs we use a capability so replication is trivial, but it would be nicer.
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if (ensure(Spawner != nullptr))
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"OnAnyPatternSpawn");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternSpawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (IsActivePattern() && (Animations.IsValidIndex(CurrentAnimationIndex)))
		{
			UBasicAIEntranceComponent EntranceComp = UBasicAIEntranceComponent::GetOrCreate(Spawn);
			if (EntranceComp == nullptr)
				return;
			
			EntranceComp.EntranceAnim = Animations[CurrentAnimationIndex];

			CurrentAnimationIndex++;
			if (CurrentAnimationIndex == Animations.Num())
			{
				if (bRepeatAnimations)
				{
					CurrentAnimationIndex = 0;
					if (bRandomAnimationOrder)	
						Animations.Shuffle();
				}
				else
				{
					// We've played all animations
					DeactivatePattern(this, EInstigatePriority::Override);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (IsBeingDestroyed())
		{
			PreviewMeshComp.DestroyComponent(Owner);
			PreviewDestinationMeshComp.DestroyComponent(Owner);	
			return;			
		}

		PreviewIndex = Math::Clamp(PreviewIndex, 0, Math::Max(Animations.Num() - 1, 0));
		if (!Animations.IsValidIndex(PreviewIndex))
			return;

		UAnimSequence Anim = Animations[PreviewIndex];
		if (Anim == nullptr)
			return;

		// Get all patterns that can spawn and all classes that can be spawned with one entry for each <pattern,spawnclass> 
		TArray<UHazeActorSpawnPattern> SpawningPatterns;
		TArray<TSubclassOf<AHazeActor>> SpawnClasses;
		GetSpawningPatternsSpawn(SpawningPatterns, SpawnClasses);
		HazeActorSpawnPattern::GetSpawnClasses(Owner, SpawnClasses);
		PreviewSpawnIndex = Math::Clamp(PreviewSpawnIndex, 0, Math::Max(SpawnClasses.Num() - 1, 0));

		FVector PreviewScale = FVector::OneVector;
		USkeletalMesh PreviewMesh = GetPreviewMesh(PreviewSpawnIndex, SpawnClasses, Anim, PreviewScale);

		PreviewMeshComp = UHazeEditorPreviewSkeletalMeshComponent::Create(Owner);  
		PreviewMeshComp.bApplyRootOnRelativeTransform = true;
		PreviewDestinationMeshComp = UHazeEditorPreviewSkeletalMeshComponent::Create(Owner);  
		PreviewDestinationMeshComp.bApplyRootOnRelativeTransform = true;
		PreviewMeshComp.SkeletalMeshAsset = PreviewMesh;
		PreviewDestinationMeshComp.SkeletalMeshAsset = PreviewMesh;
		PreviewMeshComp.RelativeScale3D = PreviewScale; 
		PreviewDestinationMeshComp.RelativeScale3D = PreviewScale;
		if (SpawningPatterns.IsValidIndex(PreviewSpawnIndex))
		{
			PreviewMeshComp.AttachToComponent(SpawningPatterns[PreviewSpawnIndex]);	
			PreviewDestinationMeshComp.AttachToComponent(SpawningPatterns[PreviewSpawnIndex]);				
		}

		PreviewMeshComp.SetAnimationPreview(Anim, Anim.PlayLength * PreviewFraction, true);
		PreviewDestinationMeshComp.SetAnimationPreview(Anim, Anim.PlayLength, true);
#endif
	}

#if EDITOR
	private USkeletalMesh GetPreviewMesh(int SpawnIndex, TArray<TSubclassOf<AHazeActor>> SpawnClasses, UAnimSequence Anim, FVector& PreviewScale)
	{
		PreviewScale = FVector::OneVector;
		TSubclassOf<AHazeActor> SpawnClass = nullptr;
		if (SpawnClasses.IsValidIndex(SpawnIndex)) 
			SpawnClass = SpawnClasses[SpawnIndex];

		USkeletalMesh PreviewMesh = nullptr;
		if (SpawnClass.IsValid())
		{
			AHazeCharacter CharCDO = Cast<AHazeCharacter>(SpawnClass.Get().DefaultObject);
			if ((CharCDO != nullptr) && (CharCDO.Mesh != nullptr))
			{
				PreviewMesh = CharCDO.Mesh.SkeletalMeshAsset;
				PreviewScale = CharCDO.Mesh.RelativeScale3D;				
			}
			else		
			{
				AActor ActorCDO = Cast<AActor>(SpawnClass.Get().DefaultObject);
				UHazeSkeletalMeshComponentBase CDOMeshComp	= (ActorCDO != nullptr) ? UHazeSkeletalMeshComponentBase::Get(ActorCDO) : nullptr;			 
				if (CDOMeshComp != nullptr)
				{
					PreviewMesh = CDOMeshComp.SkeletalMeshAsset;
					PreviewScale = CDOMeshComp.RelativeScale3D;				
				}
			}
		}
		if (PreviewMesh == nullptr)
		{
			// No spawn class with mesh, fall back to animation preview mesh
			TArray<USkeletalMesh> Meshes;
			if (EditorAnimation::GetPreviewMeshes(Anim, Meshes))
				PreviewMesh = Meshes[0];
		}
		return PreviewMesh;
	}

	void GetSpawningPatternsSpawn(TArray<UHazeActorSpawnPattern>& OutSpawningPatterns, TArray<TSubclassOf<AHazeActor>>& OutSpawnClasses)
	{
		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		Owner.GetComponentsByClass(SpawnPatterns);
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{	
			if (Pattern == nullptr)
				continue;

			TArray<TSubclassOf<AHazeActor>> PatternSpawnClasses;	
			Pattern.GetSpawnClasses(PatternSpawnClasses);
			for (TSubclassOf<AHazeActor> SpawnClass : PatternSpawnClasses)
			{
				if (!SpawnClass.IsValid())
					continue;
				OutSpawningPatterns.Add(Pattern);
				OutSpawnClasses.Add(SpawnClass);
			}
		}
	}
#endif
}
