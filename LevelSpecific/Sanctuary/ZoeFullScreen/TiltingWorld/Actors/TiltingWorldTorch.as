UCLASS(Abstract)
class ATiltingWorldTorch : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Mesh;

    UPROPERTY(DefaultComponent, Attach = "Mesh")
    UNiagaraComponent NiagaraComp;

    UPROPERTY(DefaultComponent)
    UTiltingWorldResponseComponent TiltingWorldResponseComp;

    UPROPERTY(EditAnywhere)
    float TorchSpeed = 150.0;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        const FVector TorchDir = TiltingWorldResponseComp.GetWorldUp();
        NiagaraComp.SetVariableVec3(n"Gravity", TorchDir * TorchSpeed);
    }
}