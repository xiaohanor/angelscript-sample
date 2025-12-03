UCLASS(Abstract)
class ULightCrowdDataComponent : UActorComponent
{
    UPROPERTY(EditDefaultsOnly)
    ULightCrowdSettings Settings;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        LightCrowd::GetPlayerComp().Initialize();
    }
}