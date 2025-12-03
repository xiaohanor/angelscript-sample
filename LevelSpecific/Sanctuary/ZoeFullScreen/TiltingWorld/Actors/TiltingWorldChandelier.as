UCLASS(Abstract)
class ATiltingWorldChandelier : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = "Root")
    UFauxPhysicsConeRotateComponent FauxConeRotateComp;

    UPROPERTY(DefaultComponent, Attach = "FauxConeRotateComp")
    UFauxPhysicsWeightComponent FauxWeightComp;

    UPROPERTY(DefaultComponent)
    UTiltingWorldResponseComponent TiltingWorldResponseComp;

    UPROPERTY(DefaultComponent, Attach = "FauxConeRotateComp")
    UStaticMeshComponent Chain;

    UPROPERTY(DefaultComponent, Attach = "FauxConeRotateComp")
    UStaticMeshComponent Chandelier;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Make sure the chandellier is facing down
        FauxConeRotateComp.CurrentRotation = FauxConeRotateComp.WorldTransform.InverseTransformRotation(FauxConeRotateComp.CurrentRotation);
    }
}