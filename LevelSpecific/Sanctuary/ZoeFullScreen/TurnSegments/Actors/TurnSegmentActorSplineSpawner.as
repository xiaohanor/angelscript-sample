UCLASS(Abstract)
class ATurnSegmentActorSplineSpawner : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UHazeSplineComponent SplineComp;

    UPROPERTY(EditAnywhere, Category = "Settings")
    TSubclassOf<ATurnSegmentsActor> ActorClass;

    UPROPERTY(EditAnywhere, Category = "Settings")
    int Count;

    UPROPERTY(EditAnywhere, Category = "Settings")
    float Offset = 100.0;

    UPROPERTY(EditAnywhere, Category = "Settings")
    TArray<UMaterial> Materials;

	UPROPERTY(EditAnywhere, Category = "Spawned")
    TArray<ATurnSegmentsActor> Segments;

	UPROPERTY(EditAnywhere, Category = "Spawned")
	TArray<FTransform> SavedTransforms;

	UPROPERTY(EditAnywhere, Category = "Spawned")
	TMap<int, FSegmentChildrenArray> SavedChildren;

	/**
	 * This will update the segment count to match Count,
	 * while also
	 */
	UFUNCTION(CallInEditor, Category = "Spawning")
	void UpdateSegments()
	{
		int OldCount = Segments.Num();

		if(Count <= OldCount)
		{
			SaveTransforms();
			SaveChildren();
		}

		if(Count < OldCount)
		{
			for(int i = Segments.Num() - 1; i >= Count; i--)
			{
				if(Segments[i] != nullptr)
				{
					TArray<AActor> Actors;
					Segments[i].GetAttachedActors(Actors, false);

					for(auto Actor : Actors)
					{
						Actor.DetachFromActor();
					}

					Segments[i].DestroyActor();
				}

				Segments.RemoveAt(i);
			}
		}

		if(Count > OldCount)
		{
			float DistanceAlongSpline = Segments.Num() * Offset;
			while(DistanceAlongSpline < SplineComp.SplineLength)
			{
				if(Segments.Num() >= Count)
					break;

				DistanceAlongSpline += Offset;

				FTransform Transform = SplineComp.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
				ATurnSegmentsActor Actor = SpawnActor(ActorClass, Transform.Location, Transform.Rotation.Rotator(), NAME_None, true);
				if(Actor != nullptr)
					Segments.Add(Actor);
			}
		}

        for(int i = 0; i < Segments.Num(); i++)
        {
			Segments[i].TurnSegmentResponseComponent.SegmentActors.Empty();

            if(i > 0)
                Segments[i].TurnSegmentResponseComponent.SegmentActors.Add(Segments[i - 1]);
            
            if(i < Segments.Num() - 1)
                Segments[i].TurnSegmentResponseComponent.SegmentActors.Add(Segments[i + 1]);

			if(i >= OldCount)
			{
				if(Materials.Num() > 0)
					Segments[i].SetMaterial(Materials[i % Materials.Num()]);

				Segments[i].AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);

				#if EDITOR
				Segments[i].SetActorLabel("Segment_" + i);
				#endif

            	FinishSpawningActor(Segments[i]);
			}

        }

		LoadTransforms();
		LoadChildren();

		if(Count >= OldCount)
		{
			SaveTransforms();
			SaveChildren();
		}

		Count = Segments.Num();
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void ClearSegments()
	{
		for(auto Segment : Segments)
		{
			if(Segment != nullptr)
				Segment.DestroyActor();
		}

		Segments.Empty();
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void SaveTransforms()
	{
		SavedTransforms.Empty(Segments.Num());

		for(auto Segment : Segments)
		{
			if(Segment == nullptr)
				continue;

			FTransform RelativeTransform = Segment.ActorTransform * ActorTransform.Inverse();
			SavedTransforms.Add(RelativeTransform);
		}
	}

	UFUNCTION(CallInEditor, Category = "X Advanced X")
	void LoadTransforms()
	{
		for(int i = 0; i < Math::Min(SavedTransforms.Num(), Segments.Num()); i++)
		{
			if(Segments[i] == nullptr)
				continue;

			Segments[i].SetActorRelativeTransform(SavedTransforms[i]);
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

		for(int i = 0; i < Segments.Num(); i++)
		{
			if(Segments[i] == nullptr)
				continue;

			FSegmentChildrenArray ChildrenData;

			TArray<AActor> Actors;
			Segments[i].GetAttachedActors(Actors, false);

			if(Actors.Num() == 0)
				continue;

			for(int j = 0; j < Actors.Num(); j++)
			{
				FTransform RelativeTransform = Actors[j].ActorTransform * Segments[i].ActorTransform.Inverse();

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
		for(int i = 0; i < Segments.Num(); i++)
		{
			if(Segments[i] == nullptr)
				continue;

			FSegmentChildrenArray Children;
			if(!SavedChildren.Find(i, Children))
				continue;

			for(int j = 0; j < Children.Array.Num(); j++)
			{
				SavedChildren[i].Array[j].Actor.AttachToActor(Segments[i]);
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
		for(int i = 0; i < Segments.Num(); i++)
		{
			if(Segments[i] != nullptr)
				Segments[i].DestroyActor();
		}

		Segments.Empty();
	}
}