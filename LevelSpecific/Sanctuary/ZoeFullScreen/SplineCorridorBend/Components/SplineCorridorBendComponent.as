UCLASS(HideCategories = "Debug Activation Cooking Tags Collision")
class USplineCorridorBendResponseComponent : UActorComponent
{
    UPROPERTY(EditAnywhere)
    float MinBend = 0.0;

    UPROPERTY(EditAnywhere)
    float MaxBend = 1.0;

    FHazeAcceleratedFloat AccBendAmount;
    float TargetBendAmount = 0.0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        USplineCorridorBendMioComponent::GetOrCreate(Game::GetMio()).OnSplineCorridorInput.AddUFunction(this, n"OnSplineCorridorInput");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(!HasControl())
            return;

        float BendAcceleration = USplineCorridorBendMioDataComponent::Get(Game::GetMio()).Settings.BendAcceleration;
        AccBendAmount.AccelerateTo(TargetBendAmount, 1.0 / BendAcceleration, DeltaSeconds);
    }

    UFUNCTION()
    void OnSplineCorridorInput(float Input)
    {
        TargetBendAmount = Math::Clamp(TargetBendAmount + Input, MinBend, MaxBend);
    }
}