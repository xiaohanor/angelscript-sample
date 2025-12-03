UCLASS(Abstract)
class ATiltingWorldPainting : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = "Root")
    UFauxPhysicsAxisRotateComponent ForwardAxisRotateComp;

    UPROPERTY(DefaultComponent, Attach = "ForwardAxisRotateComp")
    UFauxPhysicsAxisRotateComponent OutAxisRotateComp;

    UPROPERTY(DefaultComponent, Attach = "OutAxisRotateComp")
    UFauxPhysicsWeightComponent Weight;

    UPROPERTY(DefaultComponent, Attach = "OutAxisRotateComp")
    UStaticMeshComponent Mesh;

    UPROPERTY(DefaultComponent)
    UTiltingWorldResponseComponent TiltingWorldResponseComp;
}