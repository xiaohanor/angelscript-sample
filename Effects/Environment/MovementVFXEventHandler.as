
/**
 * Expand upon audios foot step handling for VFX.
 */

USTRUCT()
struct FDragonStepData
{
    UPROPERTY()
    FHitResult Hit;
    UPROPERTY()
    UMeshComponent DragonMesh; 
    UPROPERTY()
    UPhysicalMaterial PhysMat;
    UPROPERTY()
    bool bIsPlant;
}

class UMovementVFXEventHandler : UMovementAudioEventHandler
{
    UFUNCTION(BlueprintEvent)
    void OnDragonStep( FDragonStepData StepData) 
	{

	};
}