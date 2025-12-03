enum ESplineCorridorBlendPreview
{
	Down,
	Up,
	Middle,
	Straight
}

UCLASS(Abstract)
class ASplineCorridorBendActorSplineSpawner : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    default Root.Mobility = EComponentMobility::Movable;

    UPROPERTY(DefaultComponent, Attach = "Root")
    UHazeSplineComponent SplineCompUp;

    UPROPERTY(DefaultComponent, Attach = "Root")
    UHazeSplineComponent SplineCompDown;

	UPROPERTY(DefaultComponent)
    USplineCorridorBendResponseComponent SplineCorridorBendResponseComp;

    UPROPERTY(EditAnywhere, Category = "Settings")
    TSubclassOf<ASplineCorridorBendActor> ActorClass;

    UPROPERTY(EditAnywhere, Category = "Settings")
    int Count;

    UPROPERTY(EditAnywhere, Category = "Settings")
    float Offset = 100.0;

    UPROPERTY(EditAnywhere, Category = "Settings")
    TArray<UMaterial> Materials;

	UPROPERTY(EditAnywhere, Category = "Spawned")
    TArray<ASplineCorridorBendActor> BendActors;

	UPROPERTY(EditAnywhere, Category = "Spawned")
	TArray<FTransform> SavedTransforms;

	UPROPERTY(EditAnywhere, Category = "Spawned")
	TMap<int, FSegmentChildrenArray> SavedChildren;

	UPROPERTY(EditAnywhere)
    ESplineCorridorBlendPreview Preview = ESplineCorridorBlendPreview::Middle;
	float Alpha;
	float PreviousAlpha = 0.0;

	int CollisionMinIndex;
	int CollisionMaxIndex;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if(Preview == ESplineCorridorBlendPreview::Straight)
		{
			for(auto BendActor : BendActors)
			{
				BendActor.CacheStartAndEnd();
				BendActor.ResetBend(true);
			}
		}
		else
		{
			float PreviewAlpha = 0.0;
			switch(Preview)
			{
				case ESplineCorridorBlendPreview::Straight:
				 	break;

				 case ESplineCorridorBlendPreview::Down:
				 	PreviewAlpha = 1.0;
					break;

				case ESplineCorridorBlendPreview::Up:
					PreviewAlpha = 0.0;
					break;
					
				case ESplineCorridorBlendPreview::Middle:
					PreviewAlpha = 0.5;
					break;
			}

			for(auto BendActor : BendActors)
			{
				BendActor.CacheStartAndEnd();
				BendActor.SetBendFromAlpha(PreviewAlpha);
			}
		}

		if(Materials.Num() > 0)
		{
			for(int i = 0; i < BendActors.Num(); i++)
				BendActors[i].SplineMeshComp.SetMaterial(0, Materials[i % 2]);
		}
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto BendActor : BendActors)
		{
			BendActor.CacheStartAndEnd();
        	BendActor.ResetBend(false);
			BendActor.SetBendFromAlpha(0.5);
		}

		CollisionMinIndex = 0;
		CollisionMaxIndex = BendActors.Num();

		SetCollisionsEnabled();
	}

	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Alpha = SplineCorridorBendResponseComp.AccBendAmount.Value;

		SetCollisionsEnabled();

		if(Math::Abs(Alpha - PreviousAlpha) > KINDA_SMALL_NUMBER)
		{
			for(auto BendActor : BendActors)
				BendActor.SetBendFromAlpha(Alpha);
		}

		PreviousAlpha = Alpha;
    }

	private void SetCollisionsEnabled()
	{
		int RangeMin = Math::Max(CollisionMinIndex - 1, 0);
		int RangeMax = Math::Min(CollisionMaxIndex + 1, BendActors.Num());
		for(int i = RangeMin; i < RangeMax; i++)
		{
			FBox Bounds = BendActors[i].GetFakeBounds();
			if(Bounds.Intersect(Game::Zoe.Mesh.Bounds.Box))
			{
				if(BendActors[i].SplineMeshComp.CollisionEnabled != ECollisionEnabled::QueryAndPhysics)
				{
					BendActors[i].SplineMeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
            		BendActors[i].SplineMeshComp.UpdateMesh();

					if(Materials.Num() >= 3)
						BendActors[i].SplineMeshComp.SetMaterial(0, Materials[2]);
				}


				if(i < CollisionMinIndex)
					CollisionMinIndex = i;

				if(i > CollisionMaxIndex)
					CollisionMaxIndex = i;
			}
			else
			{
				if(BendActors[i].SplineMeshComp.CollisionEnabled != ECollisionEnabled::NoCollision)
				{
					BendActors[i].SplineMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
					
					if(Materials.Num() > 0)
						BendActors[i].SplineMeshComp.SetMaterial(0, Materials[i % 2]);
				}
			}
		}
	}

	/**
	 * This will update the segment count to match Count
	 */
	UFUNCTION(CallInEditor, Category = "Spawning")
	void UpdateSegments()
	{
		int OldCount = BendActors.Num();

		if(Count <= OldCount)
		{
			SaveTransforms();
			SaveChildren();
		}

		if(Count < OldCount)
		{
			for(int i = BendActors.Num() - 1; i >= Count; i--)
			{
				if(BendActors[i] != nullptr)
				{
					TArray<AActor> Actors;
					BendActors[i].GetAttachedActors(Actors, false);

					for(auto Actor : Actors)
					{
						Actor.DetachFromActor();
					}

					BendActors[i].DestroyActor();
				}

				BendActors.RemoveAt(i);
			}
		}

		if(Count > OldCount)
		{
			float DistanceAlongSpline = Offset * 0.5;
			while(DistanceAlongSpline < SplineCompUp.SplineLength)
			{
				if(BendActors.Num() >= Count)
					break;

				FTransform Transform = SplineCompUp.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
				auto BendActor = SpawnActor(ActorClass, Transform.Location, Transform.Rotation.Rotator(), NAME_None, true);

				BendActor.Spawner = this;
				BendActor.DistanceAlongSpline = DistanceAlongSpline;
				BendActor.Offset = Offset;

				if(BendActor != nullptr)
					BendActors.Add(BendActor);

				DistanceAlongSpline += Offset;
			}
		}

        for(int i = 0; i < BendActors.Num(); i++)
        {
			if(i >= OldCount)
			{
				BendActors[i].AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);

				#if EDITOR
				BendActors[i].SetActorLabel("BendActor_" + i);
				#endif

            	FinishSpawningActor(BendActors[i]);
			}

			BendActors[i].ResetBend(false);

        }

		LoadTransforms();
		LoadChildren();

		if(Count >= OldCount)
		{
			SaveTransforms();
			SaveChildren();
		}

		Count = BendActors.Num();
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void ClearActors()
	{
		for(auto Actor : BendActors)
		{
			if(Actor != nullptr)
				Actor.DestroyActor();
		}

		BendActors.Empty();
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void SaveTransforms()
	{
		SavedTransforms.Empty(BendActors.Num());

		for(auto Actor : BendActors)
		{
			if(Actor == nullptr)
				continue;

			FTransform RelativeTransform = Actor.ActorTransform * ActorTransform.Inverse();
			SavedTransforms.Add(RelativeTransform);
		}
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void LoadTransforms()
	{
		for(int i = 0; i < Math::Min(SavedTransforms.Num(), BendActors.Num()); i++)
		{
			if(BendActors[i] == nullptr)
				continue;

			BendActors[i].SetActorRelativeTransform(SavedTransforms[i]);
		}
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void ClearTransforms()
	{
		SavedTransforms.Empty();
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void SaveChildren()
	{
		SavedChildren.Empty();

		for(int i = 0; i < BendActors.Num(); i++)
		{
			if(BendActors[i] == nullptr)
				continue;

			FSegmentChildrenArray ChildrenData;

			TArray<AActor> Actors;
			BendActors[i].GetAttachedActors(Actors, false);

			if(Actors.Num() == 0)
				continue;

			for(int j = 0; j < Actors.Num(); j++)
			{
				FTransform RelativeTransform = Actors[j].ActorTransform * BendActors[i].ActorTransform.Inverse();

				FSegmentChildData ChildData;
				ChildData.Actor = Actors[j];
				ChildData.RelativeTransform = RelativeTransform;
				ChildrenData.Array.Add(ChildData);
			}

			SavedChildren.Add(i, ChildrenData);
		}
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void LoadChildren()
	{
		for(int i = 0; i < BendActors.Num(); i++)
		{
			if(BendActors[i] == nullptr)
				continue;

			FSegmentChildrenArray Children;
			if(!SavedChildren.Find(i, Children))
				continue;

			for(int j = 0; j < Children.Array.Num(); j++)
			{
				SavedChildren[i].Array[j].Actor.AttachToActor(BendActors[i]);
				SavedChildren[i].Array[j].Actor.SetActorRelativeTransform(SavedChildren[i].Array[j].RelativeTransform);
			}
		}
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void ClearChildren()
	{
		SavedChildren.Empty();
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void ClearAll()
	{
		DestroyAllSegments();
		ClearTransforms();
		ClearChildren();
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void DestroyAllSegments()
	{
		for(int i = 0; i < BendActors.Num(); i++)
		{
			if(BendActors[i] != nullptr)
				BendActors[i].DestroyActor();
		}

		BendActors.Empty();
	}
}