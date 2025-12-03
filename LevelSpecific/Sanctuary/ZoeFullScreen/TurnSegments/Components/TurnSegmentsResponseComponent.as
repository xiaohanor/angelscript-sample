event void FOnSegmentTurned(float TurnAmount);

class UTurnSegmentResponseComponent : UActorComponent
{
    UPROPERTY()
    FOnSegmentTurned SegmentTurned;

    UTurnSegmentsMioComponent TurnSegmentsComp;

    UPROPERTY(EditAnywhere)
    TArray<AActor> SegmentActors;

    TArray<UTurnSegmentResponseComponent> Neighbors;
    FRotator Rotation;
    float Velocity;

    UPROPERTY(EditAnywhere)
    bool bDebug = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        TurnSegmentsComp = UTurnSegmentsMioComponent::GetOrCreate(Game::GetMio());
        TurnSegmentsComp.ResponseComponents.Add(this);

        for(auto SegmentActor : SegmentActors)
        {
            auto Segment = UTurnSegmentResponseComponent::Get(SegmentActor);
            if(Segment != nullptr)
                Neighbors.Add(Segment);
        }
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        TurnSegmentsComp.ResponseComponents.RemoveSingleSwap(this);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
    }

    void OnPlayerTurnSegment(float TurnAmount)
    {
        SegmentTurned.Broadcast(TurnAmount);
    }

    UTurnSegmentsMioDataComponent GetTurnSegmentsDataComp() const
    {
        return UTurnSegmentsMioDataComponent::Get(Game::GetMio());
    }

    bool IsEdge() const
    {
        return Neighbors.Num() == 1;
    }
}