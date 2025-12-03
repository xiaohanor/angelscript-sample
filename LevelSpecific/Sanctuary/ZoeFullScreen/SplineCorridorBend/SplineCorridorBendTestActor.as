class ASplineCorridorBendTestActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USplineMeshComponent SplineMesh;
    default SplineMesh.Mobility = EComponentMobility::Movable;

    UPROPERTY(DefaultComponent)
    USplineCorridorBendResponseComponent SplineCorridorBendResponseComp;

    UPROPERTY(DefaultComponent)
    UHazeSplineComponent SplineCompUp;

    UPROPERTY(DefaultComponent)
    UHazeSplineComponent SplineCompDown;

    UPROPERTY(EditAnywhere, Meta = "ClampMin=0, ClampMax=1")
    float PreviewAlpha = 0.0;

    float PreviousAlpha = 0.0;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        ConstrainSplineComp(SplineCompUp);
        ConstrainSplineComp(SplineCompDown);

        PreviewAlpha = Math::Clamp(PreviewAlpha, 0.0, 1.0);
        SetEndFromAlpha(PreviewAlpha);
    }

    void ConstrainSplineComp(UHazeSplineComponent SplineComp)
    {
        while(SplineComp.SplinePoints.Num() < 2)
        {
            SplineComp.SplinePoints.Add(FHazeSplinePoint(FVector::ForwardVector * 100.0));
        }

        while(SplineComp.SplinePoints.Num() > 2)
        {
            SplineComp.SplinePoints.RemoveAt(SplineComp.SplinePoints.Num() - 1);
        }

        SplineComp.RelativeLocation = FVector::ZeroVector;
        SplineComp.SplinePoints[0].RelativeLocation = FVector::ZeroVector;
        SplineComp.SplinePoints[0].RelativeRotation = FQuat::Identity;
        SplineComp.SplinePoints[0].RelativeScale3D = FVector::OneVector;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        float Alpha = MinusAndPlusToNormalized(SplineCorridorBendResponseComp.AccBendAmount.Value);

        SetEndFromAlpha(Alpha);
    }

    private void SetEndFromAlpha(float Alpha)
    {
        if(Alpha < PreviousAlpha + KINDA_SMALL_NUMBER && Alpha > PreviousAlpha - KINDA_SMALL_NUMBER)
            return;

        FVector EndPosUp = SplineCompUp.SplinePoints[1].RelativeLocation;
        FVector EndTangentUp = SplineCompUp.SplinePoints[1].ArriveTangent;

        FVector EndPosDown = SplineCompDown.SplinePoints[1].RelativeLocation;
        FVector EndTangentDown = SplineCompDown.SplinePoints[1].ArriveTangent;

        FVector EndPos = Math::Lerp(EndPosDown, EndPosUp, Alpha);
        FVector EndTangent = Math::Lerp(EndTangentDown, EndTangentUp, Alpha);

        SplineMesh.SetEndPosition(EndPos, false);
        SplineMesh.SetEndTangent(EndTangent, false);

        SplineMesh.SetSplineUpDir(FVector::UpVector, false);

        SplineMesh.UpdateMesh();
        Print("UpdateMesh", 0.0);
        // SplineMesh.MarkRenderStateDirty();
        // Print("MarkRenderStateDirty", 0.0);

        PreviousAlpha = Alpha;
    }

    private float NormalizedToMinusAndPlus(float Normalized)
    {
        return (Normalized * 2.0) - 1.0;
    }

    private float MinusAndPlusToNormalized(float MinusToPlus)
    {
        return (MinusToPlus + 1.0) / 2.0;
    }
}