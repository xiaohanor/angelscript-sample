struct FSplineCorridorBendCachedSpline
{
    FVector StartWorldPos;
    FVector StartWorldTangent;
    FVector EndWorldPos;
    FVector EndWorldTangent;

    FVector MiddleWorldPos;

    FRotator SplineRotation;
}

UCLASS(Abstract)
class ASplineCorridorBendActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USplineMeshComponent SplineMeshComp;
    default SplineMeshComp.Mobility = EComponentMobility::Movable;

    UPROPERTY(EditAnywhere)
    float Scale = 1.0;

    UPROPERTY(VisibleAnywhere)
    ASplineCorridorBendActorSplineSpawner Spawner;

    UPROPERTY(VisibleAnywhere)
    float DistanceAlongSpline;
    
    UPROPERTY(VisibleAnywhere)
    float Offset;

    float CachedStretchRatio;
    float CachedStartDistance;
    float CachedEndDistance;

    FSplineCorridorBendCachedSpline CachedUp;
    FSplineCorridorBendCachedSpline CachedDown;

    FVector FakeBoundsExtent = FVector(500.0, 500.0, 500.0);
    
    // UPROPERTY(EditAnywhere)
    // bool bDebug = false;

    // private float CurrentAlpha;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        SplineMeshComp.SetStartScale(FVector2D(Scale, Scale), false);
        SplineMeshComp.SetEndScale(FVector2D(Scale, Scale), false);
        SplineMeshComp.UpdateMesh();
    }

    void CacheStartAndEnd()
    {
        CachedStretchRatio = Offset / GetMeshLength();

        CachedStartDistance = DistanceAlongSpline - (Offset * 0.5);
        CachedEndDistance = DistanceAlongSpline + (Offset * 0.5);

        CachedUp = GetCachedSplineData(SplineCompUp);
        CachedDown = GetCachedSplineData(SplineCompDown);
    }

    FSplineCorridorBendCachedSpline GetCachedSplineData(UHazeSplineComponent SplineComp)
    {
        FSplineCorridorBendCachedSpline Cache;

        CalculateWorldPosAndTangent(SplineComp, CachedStartDistance, Cache.StartWorldPos, Cache.StartWorldTangent);
        CalculateWorldPosAndTangent(SplineComp, CachedEndDistance, Cache.EndWorldPos, Cache.EndWorldTangent);

        Cache.MiddleWorldPos = Math::Lerp(Cache.StartWorldPos, Cache.EndWorldPos, 0.5);

        Cache.SplineRotation = SplineComp.GetWorldRotationAtSplineDistance(DistanceAlongSpline).Rotator();

        return Cache;
    }

    void ResetBend(bool bResetActorTransform)
    {
        if(bResetActorTransform)
            SetActorLocationAndRotation(Spawner.ActorLocation + Spawner.SplineCompUp.ForwardVector * DistanceAlongSpline, Spawner.ActorRotation);

        FVector StartPos = FVector(Offset * -0.5, 0, 0);
        FVector StartTangent = FVector::ForwardVector * 6000.0;
        FVector EndPos = FVector(Offset * 0.5, 0.0, 0.0);
        FVector EndTangent = FVector::ForwardVector * 6000.0;
        SplineMeshComp.SetStartAndEnd(StartPos, StartTangent, EndPos, EndTangent, false);
        SplineMeshComp.UpdateMesh();
    }

    void SetBendFromAlpha(float Alpha)
    {
        //CurrentAlpha = Alpha;

        FVector ActorPos = GetWorldMiddlePosLerped(Alpha);
        FRotator ActorRot = GetSplineRotationLerped(Alpha);
        SetActorLocationAndRotation(ActorPos, ActorRot);

        // Uncomment all of this to enable changing the spline mesh
        // Current solution causes desync between visuals and collision, not sure how to fix without huge performance cost

        FVector StartPos;
        FVector StartTangent;
        GetRelativePosAndTangentLerped(Alpha, true, StartPos, StartTangent);

        StartTangent *= CachedStretchRatio;

        FVector EndPos;
        FVector EndTangent;
        GetRelativePosAndTangentLerped(Alpha, false, EndPos, EndTangent);

        EndTangent *= CachedStretchRatio;

        SplineMeshComp.SetStartAndEnd(StartPos, StartTangent, EndPos, EndTangent, false);

        if(SplineMeshComp.IsCollisionEnabled())
            SplineMeshComp.UpdateMesh();
        else
            SplineMeshComp.MarkRenderStateDirty();
    }

    FVector GetMeshExtents() const
    {
        return SplineMeshComp.StaticMesh.BoundingBox.Extent;
    }

    float GetMeshLength() const
    {
        return GetMeshExtents().X * 2.0;
    }

    float GetMeshHeight() const
    {
        return GetMeshExtents().Z * 2.0;
    }

    private void GetRelativePosAndTangentLerped(float Alpha, bool bStart, FVector& RelativePos, FVector& RelativeTangent)
    {
        FVector WorldPos;
        FVector WorldTangent;

        if(bStart)
            GetWorldStartPosAndTangentLerped(Alpha, WorldPos, WorldTangent);
        else
            GetWorldEndPosAndTangentLerped(Alpha, WorldPos, WorldTangent);

        RelativePos = SplineMeshComp.WorldTransform.InverseTransformPositionNoScale(WorldPos);
        RelativeTangent = SplineMeshComp.WorldTransform.InverseTransformVectorNoScale(WorldTangent);
    }

    private void GetWorldStartPosAndTangentLerped(float Alpha, FVector& WorldPos, FVector& WorldTangent)
    {
        WorldPos = Math::Lerp(CachedUp.StartWorldPos, CachedDown.StartWorldPos, Alpha);
        WorldTangent = Math::Lerp(CachedUp.StartWorldTangent, CachedDown.StartWorldTangent, Alpha);
    }

    private void GetWorldEndPosAndTangentLerped(float Alpha, FVector& WorldPos, FVector& WorldTangent)
    {
        WorldPos = Math::Lerp(CachedUp.EndWorldPos, CachedDown.EndWorldPos, Alpha);
        WorldTangent = Math::Lerp(CachedUp.EndWorldTangent, CachedDown.EndWorldTangent, Alpha);
    }

    private FVector GetWorldMiddlePosLerped(float Alpha)
    {
        return Math::Lerp(CachedUp.MiddleWorldPos, CachedDown.MiddleWorldPos, Alpha);
    }

    private void CalculateWorldPosAndTangent(UHazeSplineComponent SplineComp, float Distance, FVector& WorldPos, FVector& WorldTangent)
    {
        WorldPos = SplineComp.GetWorldLocationAtSplineDistance(Distance);
        WorldTangent = SplineComp.GetWorldTangentAtSplineDistance(Distance);
    }

    private FRotator GetSplineRotationLerped(float Alpha)
    {
        return Math::LerpShortestPath(CachedUp.SplineRotation, CachedDown.SplineRotation, Alpha);
    }

    UHazeSplineComponent GetSplineCompUp() const property
    {
        return Spawner.SplineCompUp;
    }

    UHazeSplineComponent GetSplineCompDown() const property
    {
        return Spawner.SplineCompDown;
    }

    FBox GetFakeBounds()
    {
        FVector Min = ActorLocation - FakeBoundsExtent;
        FVector Max = ActorLocation + FakeBoundsExtent;
        return FBox(Min, Max);
    }
}