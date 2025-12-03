enum ELightCrowdAgentState
{
    Spawning,
    Active,
    Despawning,
    Deactive
}

UCLASS(Abstract)
class ALightCrowdAgent : AHazeActor
{
    default PrimaryActorTick.bStartWithTickEnabled = false;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = "Root")
    UPointLightComponent Light;
    bool bLightFullIntensity = true;

    UPROPERTY(DefaultComponent, Attach = "Light")
    UNiagaraComponent Niagara;

    UPROPERTY(DefaultComponent, Attach = "Light")
    UStaticMeshComponent GlowOrb;
    default GlowOrb.CollisionEnabled = ECollisionEnabled::NoCollision;

    UPROPERTY(DefaultComponent)
    UHazeMovementComponent MoveComp;

    UPROPERTY(DefaultComponent)
    UHazeCapabilityComponent CapabilityComp; 

    ELightCrowdAgentState State = ELightCrowdAgentState::Active;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        LightCrowd::GetPlayerComp().Agents.Add(this);

        ULightCrowdSettings Settings = LightCrowd::GetPlayerComp().Settings;
        if(Settings == nullptr)
            return;

        Light.SetAttenuationRadius(Settings.AgentLightRange);
        Light.SetIntensity(Settings.AgentLightIntensity);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        if(EndPlayReason == EEndPlayReason::Destroyed)
            LightCrowd::GetPlayerComp().Agents.RemoveSingle(this);
    }
}