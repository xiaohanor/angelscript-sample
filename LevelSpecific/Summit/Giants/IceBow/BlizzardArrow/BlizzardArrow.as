/**
 * 
 */
 UCLASS(Abstract)
class ABlizzardArrow : AHazeActor
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
    UStaticMeshComponent Mesh;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    #if EDITOR
    UPROPERTY(DefaultComponent)
    UTemporalLogTransformLoggerComponent TemporalLogTransform;
    #endif

    UPROPERTY(DefaultComponent)
	UWindJavelinConeComponent WindJavelinConeComponent;

    UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

    FBlizzardArrowHitData HitData;
    bool bIsLaunched = false;

	UProjectileProximityManagerComponent ProximityManager;

    float Gravity = 0.0;

    TArray<FWindJavelinResponseComponentData> ResponseComponentsToInfluence;

    bool bActive = false;
	UBlizzardArrowSettings Settings;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Settings = UBlizzardArrowSettings::GetSettings(this);
        SetActorControlSide(Player);

        Activate(true);
    }

    void Activate(bool bInitial = false)
    {
        if(bActive)
            return;

        bActive = true;

        if(!bInitial)
        {
            UnblockCapabilities(BlizzardArrow::BlizzardArrowCapabilityTag, this);
            RemoveActorDisable(this);
        }

        if (ProximityManager != nullptr)
			ProximityManager.RegisterProjectile(this);

        UBlizzardArrowEventHandler::Trigger_Activate(this);
    }

    void Deactivate()
    {
        if(!bActive)
            return;

        bActive = false;

        BlockCapabilities(BlizzardArrow::BlizzardArrowCapabilityTag, this);
        AddActorDisable(this);

        bIsLaunched = false;
        HitData = FBlizzardArrowHitData();

        if (ProximityManager != nullptr)
			ProximityManager.UnregisterProjectile(this);

        if (HitData.Component != nullptr)
        {
            UWindJavelinResponseComponent AttachResponseComp = UWindJavelinResponseComponent::Get(HitData.Component.Owner);
            if (AttachResponseComp != nullptr)
                AttachResponseComp.DetachWindJavelin(this);
        }
        
        UBlizzardArrowEventHandler::Trigger_Deactivate(this);
    }

	void Launch(FVector InVelocity, float InGravity, UProjectileProximityManagerComponent InProximityManager)
	{
		ProximityManager = InProximityManager;

        Activate();

        Gravity = InGravity;
		SetActorVelocity(InVelocity);
        bIsLaunched = true;
	}

    void OnHitActor(const FHitResult& HitResult)
    {
        check(HasControl());

        if(HitResult.Actor == nullptr)
        {
            Deactivate();
            return;
        }

        HitData = FBlizzardArrowHitData(HitResult);

        OnHitActorIce();
        OnHitActorWind();
    }

    private void OnHitActorIce()
    {
        check(HasControl());

        const float HitImpulseScale = UIceArrowSettings::GetSettings(Player).HitImpulseScale;

        float ResponseCompImpulseScale = 0.0;

        TArray<UIceArrowResponseComponent> ResponseComponents;
        HitData.Component.Owner.GetComponentsByClass(ResponseComponents);

        if(ResponseComponents.Num() > 0)
        {
            for(int i = ResponseComponents.Num() - 1; i >= 0; i--)
            {
                if (IntersectsWithResponseComp(ResponseComponents[i]))
                    ResponseCompImpulseScale += ResponseComponents[i].IceArrowImpulseScale;
                else
                    ResponseComponents.RemoveAtSwap(i);
            }

            // Average all the hit response components impulse scales
            if(ResponseComponents.Num() > 0)
                ResponseCompImpulseScale /= ResponseComponents.Num();
        }
        else
        {
            ResponseCompImpulseScale = 1.0;
        }

        float Impulse = ResponseCompImpulseScale * HitImpulseScale;
        FIceArrowHitEventData EventData(this);
        CrumbOnHitActorIce(ResponseComponents, EventData, Impulse);
    }

    UFUNCTION(CrumbFunction)
    private void CrumbOnHitActorIce(TArray<UIceArrowResponseComponent> HitResponseComponents, FIceArrowHitEventData EventData, float HitImpulse)
    {
        for(auto HitResponseComponent : HitResponseComponents)
            HitResponseComponent.OnHitByIceArrow.Broadcast(EventData);

        if(HitImpulse > KINDA_SMALL_NUMBER)
            FauxPhysics::ApplyFauxImpulseToParentsAt(EventData.Component, EventData.ImpactPoint, GetActorVelocity() * HitImpulse);
    }

    private void OnHitActorWind()
    {
        check(HasControl());

        bool bHasValidAttachment = GetHasValidAttachment();

        UWindJavelinResponseComponent ResponseComponent = UWindJavelinResponseComponent::Get(HitData.Component.Owner);

        FBlizzardArrowHitEventData EventData;
        EventData.bHitValidSurface = bHasValidAttachment;
        EventData.HitComponent = HitData.Component;
        EventData.ImpactNormal = HitData.ImpactNormal;
        EventData.ImpactPoint = HitData.ImpactPoint;

		FHazeTraceSettings BlizzardTraceSettings = GetTraceSettings();
		EventData.AudioTraceParams = FHazeAudioTraceQuery(HitData.Component,
														HitData.ImpactPoint,
														HitData.ImpactNormal,
														BlizzardTraceSettings.Shape,
														BlizzardTraceSettings.bTraceComplex);

        CrumbOnHitActorWind(ResponseComponent, EventData);
    }

    UFUNCTION(CrumbFunction)
    void CrumbOnHitActorWind(UWindJavelinResponseComponent HitResponseComponent, FBlizzardArrowHitEventData EventData)
    {
        if(HitResponseComponent != nullptr)
        {
            FWindJavelinHitEventData WindJavelinHitEventData;
            WindJavelinHitEventData.bHitValidSurface = EventData.bHitValidSurface;
            WindJavelinHitEventData.Component = EventData.HitComponent;
            WindJavelinHitEventData.ImpactNormal = EventData.ImpactNormal;
            WindJavelinHitEventData.ImpactPoint = EventData.ImpactPoint;
            HitResponseComponent.OnHitByWindJavelin.Broadcast(WindJavelinHitEventData);
        }

        if(EventData.bHitValidSurface)
            UBlizzardArrowEventHandler::Trigger_HitValid(this, EventData);
        else
            UBlizzardArrowEventHandler::Trigger_HitInvalid(this, EventData);

        if(!EventData.bHitValidSurface)
            Deactivate();
    }

    bool IntersectsWithResponseComp(UIceArrowResponseComponent ResponseComponent) const
    {
        if(ResponseComponent.bHitAnywhere)
            return true;

        switch(ResponseComponent.CollisionSettings.Type)
        {
            case EHazeShapeType::Sphere:
            {
                FSphere BlizzardArrowCollisionSphere(Sphere.WorldLocation, Sphere.SphereRadius);
                FSphere ResponseComponentCollisionSphere(ResponseComponent.WorldLocation, ResponseComponent.CollisionSettings.SphereRadius);
                return BlizzardArrowCollisionSphere.Intersects(ResponseComponentCollisionSphere);
            }
            case EHazeShapeType::Box:
            {
                // FB TODO: This intersection is in world space, right?
                FBox BlizzardArrowCollisionBox = Sphere.GetBounds().Box;
                FBox ResponseComponentCollisionBox(-ResponseComponent.CollisionSettings.BoxExtents + ResponseComponent.WorldLocation, ResponseComponent.CollisionSettings.BoxExtents + ResponseComponent.WorldLocation);
                return BlizzardArrowCollisionBox.Intersect(ResponseComponentCollisionBox);
            }

            default:
                check(false);  // Unhandled case
        }

        return false;
    }

    bool GetbHasHitData() const property
    {
        return HitData.Component != nullptr;
    }

    /**
     * Also used by WindJavelinAttachedCapability
     */
    bool GetHasValidAttachment() const
    {
        check(HasControl());
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

	FHazeTraceSettings GetTraceSettings() const
    {
		FHazeTraceSettings BlizzardTraceSettings = Trace::InitChannel(ETraceTypeQuery::Visibility, n"BlizzardArrow");
        BlizzardTraceSettings.UseSphereShape(Sphere.SphereRadius);

        if(IceBow::ShouldIgnoreOtherPlayer())
            BlizzardTraceSettings.IgnorePlayers();
        else
            BlizzardTraceSettings.IgnoreActor(Player);

		BlizzardTraceSettings.SetTraceComplex(false);
        return BlizzardTraceSettings;
    }
}