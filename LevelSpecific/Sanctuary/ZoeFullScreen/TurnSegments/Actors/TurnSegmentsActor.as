UCLASS(Abstract)
class ATurnSegmentsActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, ShowOnActor)
    UTurnSegmentResponseComponent TurnSegmentResponseComponent;

    FRotator StartRotation;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        TurnSegmentResponseComponent.SegmentTurned.AddUFunction(this, n"SegmentTurned");
        StartRotation = ActorRotation;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Only update when we have velocity
        if(Math::Abs(TurnSegmentResponseComponent.Velocity) < 0.1)
            return;

        // Drag
        const float IntegratedDragFactor = Math::Exp(-TurnSegmentResponseComponent.GetTurnSegmentsDataComp().Settings.SegmentFriction);
		TurnSegmentResponseComponent.Velocity = TurnSegmentResponseComponent.Velocity * Math::Pow(IntegratedDragFactor, DeltaSeconds);

        // Move
        TurnSegmentResponseComponent.Rotation.Roll += TurnSegmentResponseComponent.Velocity * DeltaSeconds;

        // Apply
        SetActorRotation(FRotator(0.0, 0.0, TurnSegmentResponseComponent.Rotation.Roll).Compose(StartRotation));
    }

    UFUNCTION(NotBlueprintCallable)
    void SegmentTurned(float TurnAmount)
    {
        TurnSegmentResponseComponent.Velocity += TurnAmount;
    }

    UFUNCTION(CallInEditor)
    void SetMaterial(UMaterial Material)
    {
    }
}