event void FWindJavelinDissipateEvent(AWindJavelin WindJavelin);

/**
 * 
 */
 UCLASS(Abstract)
class AWindJavelin : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent Sphere;
    default Sphere.SphereRadius = 16.0;
    default Sphere.bAffectDynamicIndirectLighting = false;
	default Sphere.bCanEverAffectNavigation = false;
	default Sphere.SetCollisionProfileName(n"NoCollision");
	default Sphere.SetGenerateOverlapEvents(false);
  	default Sphere.BodyInstance.bNotifyRigidBodyCollision = false;
  	default Sphere.BodyInstance.bUseCCD = false;
	default Sphere.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Sphere.bCastDynamicShadow = false;
	default Sphere.AddTag(ComponentTags::HideOnCameraOverlap);

    UPROPERTY(DefaultComponent, BlueprintReadOnly, Attach = "Sphere")
    USceneComponent SpringPivot;

    UPROPERTY(DefaultComponent, BlueprintReadOnly, Attach = "SpringPivot")
    UStaticMeshComponent Mesh;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

    FHitResult HitData;
    bool bIsThrown = false;

    UWindJavelinSettings Settings;

    UPROPERTY(DefaultComponent)
	UWindJavelinConeComponent WindJavelinConeComponent;

    UPROPERTY()
	FWindJavelinDissipateEvent OnWindJavelinDissipated;

    #if EDITOR
    UPROPERTY(DefaultComponent)
    UTemporalLogTransformLoggerComponent TemporalLogTransform;
    #endif

    /**
	 * To avoid checking too many actors, set them manually.
	 */
	TArray<FWindJavelinResponseComponentData> ResponseComponentsToInfluence;
	bool bPreparedToDestroy = false;
    bool bDestroyed = false;

	UProjectileProximityManagerComponent ProximityManager;
    UWindJavelinPlayerComponent PlayerComp;

    float Gravity = 0.0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Player = WindJavelin::GetPlayer();
        PlayerComp = UWindJavelinPlayerComponent::Get(Player);
        SetActorControlSide(Player);
    }

    void Throw(FVector InVelocity, float InGravity, UProjectileProximityManagerComponent ProjectileProximityManager = nullptr)
	{
        check(!bIsThrown);
        Gravity = InGravity;
		SetActorVelocity(InVelocity);
        bIsThrown = true;

		ProximityManager = ProjectileProximityManager;
		if (ProximityManager != nullptr)
			ProximityManager.RegisterProjectile(this);
	}

    void OnHitActor(const FHitResult& InHitData)
    {
        if(InHitData.Actor == nullptr)
        {
            DestroyActor();
            return;
        }

        HitData = InHitData;

        bool bHasValidAttachment = GetHasValidAttachment();

        FWindJavelinHitEventData EventData;
        EventData.bHitValidSurface = bHasValidAttachment;
        EventData.Component = InHitData.Component;
        EventData.ImpactNormal = InHitData.ImpactNormal;
        EventData.ImpactPoint = InHitData.ImpactPoint;

        if(HasControl())
        {
            UWindJavelinResponseComponent ResponseComponent = UWindJavelinResponseComponent::Get(InHitData.Actor);
            if(ResponseComponent != nullptr)
            {
                ResponseComponent.OnHitByWindJavelin.Broadcast(EventData);
            }
        }

        if(bHasValidAttachment)
            UWindJavelinProjectileEventHandler::Trigger_HitValid(this, EventData);
        else
            UWindJavelinProjectileEventHandler::Trigger_HitInvalid(this, EventData);
    }

    /**
     * Also used by WindJavelinAttachedCapability
     */
    bool GetHasValidAttachment() const
    {
        if(!GetHasValidHitData())
            return false;

        if(Settings.bRequireWindJavelinTag && !HitData.Component.HasTag(WindJavelin::WindJavelinHittableTag))
            return false;

        return true;
    }

    bool GetHasValidHitData() const
    {
        return HitData.Component != nullptr;
    }

    void PrepareToDestroy()
    {
        if(bPreparedToDestroy)
            return;

        bPreparedToDestroy = true;

        if (HitData.Component != nullptr)
        {
            UWindJavelinResponseComponent AttachResponseComp = UWindJavelinResponseComponent::Get(HitData.Actor);
            if (AttachResponseComp != nullptr)
                AttachResponseComp.DetachWindJavelin(this);
        }

        for(auto Response : ResponseComponentsToInfluence)
            Response.Component.ExitWindCone(this);

        OnWindJavelinDissipated.Broadcast(this);

        Mesh.SetHiddenInGame(true);

        UWindJavelinProjectileEventHandler::Trigger_Destroyed(this);
    }

    void UnPrepareToDestroy()
    {
        if(!bPreparedToDestroy)
            return;

        Mesh.SetHiddenInGame(false);

        bPreparedToDestroy = false;
    }

	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		if (ProximityManager != nullptr)
			ProximityManager.UnregisterProjectile(this);
	}
}