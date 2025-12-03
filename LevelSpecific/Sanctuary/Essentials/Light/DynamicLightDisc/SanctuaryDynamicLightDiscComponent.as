struct FSanctuaryDynamicLightDiscMeshData
{
	TArray<FVector> Vertices;
	TArray<FVector2D> UVs;

	void Initialize(int Resolution)
	{
		Vertices.Reserve(Resolution + 1);
		UVs.Reserve(Resolution + 1);

		// Add center UVs
		Vertices.Add(FVector::ZeroVector);
		UVs.Add(FVector2D(0.5, 0.5));
	}

	void Reset()
	{
		Vertices.Reset();
		UVs.Reset();

		// Add center UVs
		Vertices.Add(FVector::ZeroVector);
		UVs.Add(FVector2D(0.5, 0.5));
	}

	int AddVertex(FVector Vertex, float Angle, float DistanceAlpha)
	{
		Vertices.Add(Vertex);
		UVs.Add(FVector2D(0.5, 0.5) + FVector2D(Math::Cos(Angle) * 0.5, Math::Sin(Angle) * 0.5) * DistanceAlpha);
		return Vertices.Num() - 1;
	}

	bool HasSameVertexCount(FSanctuaryDynamicLightDiscMeshData Other) const
	{
		return Vertices.Num() == Other.Vertices.Num();
	}

	bool HasVertexAtIndex(FVector Vertex, int Index) const
	{
		if(!Vertices.IsValidIndex(Index))
			return false;

		return Vertices[Index].Equals(Vertex, 1);
	}
};

struct FSanctuaryDynamicLightDiscSubstepVertex
{
	FVector Vertex;
	float Angle;
	float DistanceAlpha;

	FSanctuaryDynamicLightDiscSubstepVertex(FVector InVertex, float InAngle, float InDistanceAlpha)
	{
		Vertex = InVertex;
		Angle = InAngle;
		DistanceAlpha = InDistanceAlpha;
	}

	int opCmp(const FSanctuaryDynamicLightDiscSubstepVertex Other) const
	{
		if(Angle < Other.Angle)
			return -1;
		else
			return 1;
	}
};

UCLASS(NotBlueprintable, HideCategories = "ComponentTick Physics Debug Activation Cooking TextureStreaming Navigation LOD")
class USanctuaryDynamicLightDiscComponent : UProceduralMeshComponent
{
	default SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
	default SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	default RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);

	UPROPERTY(EditAnywhere, Category = "Light Disc")
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere, Category = "Light Disc")
	float Radius = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Light Disc", Meta = (ClampMin = "10"))
	int Resolution = 50;

	UPROPERTY(EditAnywhere)
	TArray<FVector4f> DataArray = TArray<FVector4f>();

	UPROPERTY(EditAnywhere)
	UTexture2D Data;

#if EDITOR
	/**
	 * Updates in Editor to show the current vertices (same as trace count)
	 */
	UPROPERTY(VisibleInstanceOnly, Category = "Light Disc")
	int PreviewVertexCount = 0;
#endif

	UPROPERTY(EditAnywhere, Category = "Light Disc")
	float UpdateRate = 0.0;

	UPROPERTY(EditAnywhere, Category = "Light Disc")
	bool bStartEnabled;

	UPROPERTY(EditAnywhere, Category = "Light Disc|Substeps")
	bool bSubstep = true;

	/**
	 * How many substep levels we allow between 
	 */
	UPROPERTY(EditAnywhere, Category = "Light Disc|Substeps", Meta = (EditCondition = "bSubstep", ClampMin = "1", ClampMax = "10"))
	int MaxSubsteps = 3;

	/**
	 * If the trace distance between two traces is higher than this, we insert a substep.
	 */
	UPROPERTY(EditAnywhere, Category = "Light Disc|Substeps", Meta = (EditCondition = "bSubstep", ClampMin = "1", ClampMax = "1000"))
	float SubstepDistanceThreshold = 100;

#if EDITOR
	/**
	 * The max resolution if all substeps are used (highly unlikely).
	 * Look at Preview Vertex Count to see the actual vertex count used.
	 * Calculated as Resolution * MaxSubsteps^2.
	 */
	UPROPERTY(VisibleInstanceOnly, Category = "Light Disc|Substeps", Meta = (EditCondition = "bSubstep"))
	int MaxResolutionAfterSubsteps = 0;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Light Disc|Trace Targets")
	bool bUseTraceTargets = false;

	// If added, a trace will always be performed onto these locations
	UPROPERTY(EditInstanceOnly, Category = "Light Disc|Trace Targets", Meta = (EditCondition = "bUseTraceTargets"))
	TArray<ASancturaryDynamicLightDiscTraceTarget> TraceTargets;

	bool bUseMeshDataA = true;
	FSanctuaryDynamicLightDiscMeshData MeshDataA;
	FSanctuaryDynamicLightDiscMeshData MeshDataB;
	TArray<int> Triangles;

	private TArray<float> ConstantTraceAngles;

	// Unused
	TArray<FVector> Normals;
	TArray<FLinearColor> VertexColors;
	TArray<FProcMeshTangent> Tangents;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if(bSubstep)
			MaxResolutionAfterSubsteps = Resolution * (MaxSubsteps * MaxSubsteps);
	}

	UFUNCTION(BlueprintCallable)
	void Preview()
	{
		Initialize();
	}
#endif	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();

		SetComponentTickInterval(UpdateRate);

		if (!bStartEnabled)
			Disable();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Flip which mesh data to use this frame
		bUseMeshDataA = !bUseMeshDataA;

		bool bHasChangedVertices = UpdateVertices();

		if (bHasChangedVertices)
			UpdateMesh();
	}

	void Initialize()
	{
		DataArray.SetNum(128);
		Data = Rendering::CreateTexture2D(DataArray.Num(), 1, TextureCompressionSettings::TC_HDR_F32);

		MeshDataA.Initialize(Resolution);
		MeshDataB.Initialize(Resolution);

		ConstantTraceAngles.SetNum(Resolution);
		for(int i = 0; i < Resolution; i++)
		{
			const float CurrentAlpha = (i / float(Resolution));
			ConstantTraceAngles[i] = CurrentAlpha * TWO_PI;
		}

		UpdateVertices();
		UpdateMesh(true);
		SetMaterial(0, Material);
		SetTextureParameterValueOnMaterials(n"LightDepths", Data);
	}

	/**
	 * Trace out to find vertices for the light disc.
	 * @return True if the vertices changed.
	 */
	bool UpdateVertices()
	{
		// Reset the current mesh data, since we will be filling that now
		FSanctuaryDynamicLightDiscMeshData& MeshData = GetCurrentMeshData();
		MeshData.Reset();

		// Get the previous frames mesh data, so that we can compare and check if we changed
		const FSanctuaryDynamicLightDiscMeshData PreviousMeshData = GetPreviousMeshData();
		bool bHasChangedVertices = false;

		// Setup the trace once for all traces
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(Owner);
		//Trace.DebugDrawOneFrame();

		TArray<float> TraceAngles = ConstantTraceAngles;

		if(bUseTraceTargets)
			InsertTraceTargetAngles(TraceAngles);

		float PreviousAngle = 0;
		float PreviousDistance = 0;
		float FirstDistance = 0;
		for (int i = 0; i < DataArray.Num(); i++)
		{
			DataArray[i] = FVector4f(0,0,0,0);
		}
		
		for (int i = 0; i < TraceAngles.Num(); i++)
		{
			const float CurrentAngle = TraceAngles[i];

			const FVector TraceEnd = WorldTransform.TransformPositionNoScale(FVector(Math::Cos(CurrentAngle) * Radius, Math::Sin(CurrentAngle) * Radius, 0.0));
			const FHitResult Hit = Trace.QueryTraceSingle(WorldLocation, TraceEnd);

			const float CurrentDistance = Hit.bBlockingHit ? Hit.Distance : Radius;

			if(bSubstep)
			{
				if(i == 0)
				{
					// Store what distance the first trace hit at for the last substep
					FirstDistance = CurrentDistance;
				}
				else
				{
					// From the second trace and forward, try to substep between our trace and the previous trace
					StartSubsteppingBetween(PreviousAngle, PreviousDistance, CurrentAngle, CurrentDistance, Trace, MeshData, bHasChangedVertices);
				}
			}

			// Lastly, add the traced vertex, which is after all the substeps
			FVector VertexLocation = WorldTransform.InverseTransformPositionNoScale((Hit.bBlockingHit ? Hit.Location : TraceEnd));
			int VertexIndex = MeshData.AddVertex(VertexLocation, CurrentAngle, CurrentDistance / Radius);
			if(DataArray.Num() > 0)
			{
				int Index = Math::TruncToInt((CurrentAngle / TWO_PI) * DataArray.Num());
				DataArray[Index].X = float32(CurrentDistance / Radius);
			}
			
			if(!bHasChangedVertices && !PreviousMeshData.HasVertexAtIndex(VertexLocation, VertexIndex))
				bHasChangedVertices = true;

			// Store the previous angle and distance for next iteration
			PreviousAngle = CurrentAngle;
			PreviousDistance = CurrentDistance;
		}

		if(DataArray.Num() > 0)
		{
			// Since not all angles have a raycast, some pixels will have 0, this fills them in with neighbour values
			// 1. If the first entry 0 is 0, scan backwards and set it to be the first one we find that's not 0
			if(DataArray[0].X == 0)
			{
				for (int i = DataArray.Num() - 1; i >= 0; i--)
				{
					if(DataArray[i].X != 0)
					{
						DataArray[0] = DataArray[i];
						break;
					}
				}
			}
			// 2. once we guarantee entry 0 has data, we can loop over and "copy from the left if we are 0" to fill
			for (int i = 1; i < DataArray.Num(); i++)
			{
				if(DataArray[i].X == 0)
				{
					DataArray[i] = DataArray[i-1];
				}
			}
			// 3. Copy to texture
			Rendering::UpdateTexture2D(Data, DataArray);
		}


		if(bSubstep)
		{
			// We need to also substep between the last and first traces
			const float LastAngle = PreviousAngle - TWO_PI;	// Wrap around to be before the FirstAngle, so that the lerp works as expected
			const float LastDistance = PreviousDistance;
			const float FirstAngle = TraceAngles[0];
			StartSubsteppingBetween(LastAngle, LastDistance, FirstAngle, FirstDistance, Trace, MeshData, bHasChangedVertices);
		}
		
		if(!bHasChangedVertices && !MeshData.HasSameVertexCount(PreviousMeshData))
			bHasChangedVertices = true;

		return bHasChangedVertices;
	}

	/**
	 * If we define trace targets, figure out their angle relative to us, and then insert them into the angles array
	 */
	void InsertTraceTargetAngles(TArray<float>& TraceAngles) const
	{
		TraceAngles.Reserve(TraceAngles.Num() + TraceTargets.Num());

		for(auto TraceTarget : TraceTargets)
		{
			if(TraceTarget == nullptr)
				continue;

			const FVector TargetRelativeLocation = WorldTransform.InverseTransformPositionNoScale(TraceTarget.ActorLocation);
			FVector2D TargetRelativeDirection = FVector2D(TargetRelativeLocation.X, TargetRelativeLocation.Y);
			const float Distance = TargetRelativeDirection.Size();
			if(Distance > Radius)
				continue;

			TargetRelativeDirection /= Distance;

			float TraceAngle = Math::DirectionToAngleRadians(TargetRelativeDirection);
			TraceAngle = Math::Wrap(TraceAngle, 0, TWO_PI);
			TraceAngles.Add(TraceAngle);
		}

		TraceAngles.Sort();
	}

	void StartSubsteppingBetween(
		float StartAngle,
		float StartDistance,
		float EndAngle,
		float EndDistance,
		FHazeTraceSettings Trace,
		FSanctuaryDynamicLightDiscMeshData& MeshData,
		bool& bHasChangedVertices
	)
	{
		TArray<FSanctuaryDynamicLightDiscSubstepVertex> SubstepVertices;
		TrySubstepBetween(StartAngle, StartDistance, EndAngle, EndDistance, 0, Trace, SubstepVertices);

		// We need to sort the substep vertices to be in a clockwise direction
		SubstepVertices.Sort();

		for(FSanctuaryDynamicLightDiscSubstepVertex SubstepVertex : SubstepVertices)
		{
			// Add the substep vertex to the mesh data
			int VertexIndex = MeshData.AddVertex(SubstepVertex.Vertex, SubstepVertex.Angle, SubstepVertex.DistanceAlpha);
			if(DataArray.Num() > 0)
			{
				int Index = Math::TruncToInt((SubstepVertex.Angle / TWO_PI) * DataArray.Num());
				// technically wrong but should be good enough
				if(Index < 0) Index = DataArray.Num()-1;
				if(Index >= DataArray.Num()) Index = 0;
				DataArray[Index].X = float32(SubstepVertex.DistanceAlpha);
			}
			
			if(!bHasChangedVertices && !GetPreviousMeshData().HasVertexAtIndex(SubstepVertex.Vertex, VertexIndex))
				bHasChangedVertices = true;
		}
	}

	/**
	 * Check if we can and need to substep between StartAngle and EndAngle
	 */
	void TrySubstepBetween(
		float StartAngle,
		float StartDistance,
		float EndAngle,
		float EndDistance,
		int SubstepCount,
		FHazeTraceSettings Trace,
		TArray<FSanctuaryDynamicLightDiscSubstepVertex>& SubstepVertices) const
	{
		// Prevent substepping too deeply
		if(SubstepCount >= MaxSubsteps)
			return;

		// Only substep if the difference in distance is large enough
		if(Math::Abs(EndDistance - StartDistance) < SubstepDistanceThreshold)
			return;

		// SubstepAngle is inbetween Start and End
		const float SubstepAngle = (StartAngle + EndAngle) * 0.5;
		const FVector TraceEnd = WorldTransform.TransformPositionNoScale(FVector(Math::Cos(SubstepAngle) * Radius, Math::Sin(SubstepAngle) * Radius, 0.0));
		const FHitResult Hit = Trace.QueryTraceSingle(WorldLocation, TraceEnd);

		FVector VertexLocation;
		float SubstepDistance;

		if(Hit.bBlockingHit)
		{
			VertexLocation = Hit.ImpactPoint;
			SubstepDistance = Hit.Distance;
		}
		else
		{
			VertexLocation = TraceEnd;
			SubstepDistance = Radius;
		}

		// Store the substep vertex to be sorted later
		SubstepVertices.Add(FSanctuaryDynamicLightDiscSubstepVertex(
			WorldTransform.InverseTransformPositionNoScale(VertexLocation),
			SubstepAngle,
			SubstepDistance / Radius
		));

		// Try substepping to the left and right of the current substep
		TrySubstepBetween(StartAngle, StartDistance, SubstepAngle, SubstepDistance, SubstepCount + 1, Trace, SubstepVertices);
		TrySubstepBetween(EndAngle, EndDistance, SubstepAngle, SubstepDistance, SubstepCount + 1, Trace, SubstepVertices);
	}

	/**
	 * @param bForce If true, we will always create a new mesh section instead of updating the old one.
	 */
	private void UpdateMesh(bool bForce = false)
	{
		FSanctuaryDynamicLightDiscMeshData& MeshData = GetCurrentMeshData();

		if(bForce || !MeshData.HasSameVertexCount(GetPreviousMeshData()))
		{
			UpdateTriangles(MeshData.Vertices);

			ClearAllMeshSections();

			CreateMeshSection_LinearColor(
				0,
				MeshData.Vertices,
				Triangles,
				Normals,
				MeshData.UVs,
				MeshData.UVs,
				MeshData.UVs,
				MeshData.UVs,
				VertexColors,
				Tangents,
				true
			);
		}
		else
		{
			UpdateMeshSection_LinearColor(
				0,
				MeshData.Vertices,
				Normals,
				MeshData.UVs,
				MeshData.UVs,
				MeshData.UVs,
				MeshData.UVs,
				VertexColors,
				Tangents
			);
		}

#if EDITOR
		PreviewVertexCount = MeshData.Vertices.Num();
#endif
	}

	private void UpdateTriangles(TArray<FVector> Vertices)
	{
		Triangles.Reset(Vertices.Num() * 3);

		for (int i = 1; i < Vertices.Num(); i++)
		{
			Triangles.Add(0);
			Triangles.Add(Math::WrapIndex(i + 2, 1, Vertices.Num()));
			Triangles.Add(Math::WrapIndex(i + 1, 1, Vertices.Num()));	
		}
	}

	TArray<FVector> GetVertices() const
	{
		return GetCurrentMeshData().Vertices;
	}

	private FSanctuaryDynamicLightDiscMeshData& GetCurrentMeshData()
	{
		if(bUseMeshDataA)
			return MeshDataA;
		else
			return MeshDataB;
	}

	private FSanctuaryDynamicLightDiscMeshData GetCurrentMeshData() const
	{
		if(bUseMeshDataA)
			return MeshDataA;
		else
			return MeshDataB;
	}

	private FSanctuaryDynamicLightDiscMeshData& GetPreviousMeshData()
	{
		if(bUseMeshDataA)
			return MeshDataB;
		else
			return MeshDataA;
	}

	private FSanctuaryDynamicLightDiscMeshData GetPreviousMeshData() const
	{
		if(bUseMeshDataA)
			return MeshDataB;
		else
			return MeshDataA;
	}

	UFUNCTION(BlueprintCallable)
	void Enable()
	{
		RemoveComponentTickBlocker(this);
		RemoveComponentCollisionBlocker(this);
		//RemoveComponentVisualsBlocker(this);
	}

	UFUNCTION(BlueprintCallable)
	void Disable()
	{
		AddComponentTickBlocker(this);
		AddComponentCollisionBlocker(this);
		//AddComponentVisualsBlocker(this);
	}
};

#if EDITOR
UCLASS(NotBlueprintable)
class USanctuaryDynamicLightDiscComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryDynamicLightDiscComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USanctuaryDynamicLightDiscComponent>(Component);
		if(Comp == nullptr)
			return;

		for(auto TraceTarget : Comp.TraceTargets)
		{
			if(TraceTarget == nullptr)
				continue;

			DrawArrow(Comp.WorldLocation, TraceTarget.ActorLocation, FLinearColor::Yellow, 10, 3);
		}
	}
};
#endif