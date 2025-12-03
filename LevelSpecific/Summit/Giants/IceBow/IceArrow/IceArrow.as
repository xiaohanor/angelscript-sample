/**
 * 
 */
 UCLASS(Abstract)
class AIceArrow : AHazeActor
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

    UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

    FIceArrowHitData HitData;
    bool bIsLaunched = false;

    float ChargeFactor = 0.0;

	UProjectileProximityManagerComponent ProximityManager;
	UIceArrowPlayerComponent IceArrowPlayerComp;

    float Gravity = 0.0;
    bool bActive = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetActorControlSide(Player);
        Activate(true);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        #if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog
		.Point("Actor Location", ActorLocation, 10.0, FLinearColor::Blue)
		.Value("Active", bIsLaunched)
		.Value("Charge Factor", ChargeFactor)
		;
		#endif
    }

    void Activate(bool bInitial = false)
    {
        if(bActive)
            return;

        bActive = true;

        if(!bInitial)
        {
            UnblockCapabilities(IceArrow::IceArrowTag, this);
            RemoveActorDisable(this);
        }

        UIceArrowEventHandler::Trigger_Activate(this);
    }

    void Deactivate()
    {
        if(!bActive)
            return;

        bActive = false;

        BlockCapabilities(IceArrow::IceArrowTag, this);
        AddActorDisable(this);
        
        bIsLaunched = false;
        HitData = FIceArrowHitData();

        UIceArrowEventHandler::Trigger_Deactivate(this);
    }

	void Launch(FVector InVelocity, float InGravity, UProjectileProximityManagerComponent InProximityManager, UIceArrowPlayerComponent InIceArrowPlayerComponent)
	{
        Gravity = InGravity;
		SetActorVelocity(InVelocity);
        bIsLaunched = true;

		ProximityManager = InProximityManager;
		if (ProximityManager != nullptr)
			ProximityManager.RegisterProjectile(this);

		IceArrowPlayerComp = InIceArrowPlayerComponent;
	}

    void OnHitActor(const FHitResult& HitResult)
    {
        check(HasControl());

        if(HitResult.Actor == nullptr)
        {
            IceArrowPlayerComp.RecycleIceArrow(this);
            return;
        }

        HitData = FIceArrowHitData(HitResult);

        OnHitActorIce();
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

        float Impulse = ChargeFactor * ResponseCompImpulseScale * HitImpulseScale;
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

        UIceArrowEventHandler::Trigger_Hit(this, EventData);

        IceArrowPlayerComp.RecycleIceArrow(this);
    }

    bool IntersectsWithResponseComp(UIceArrowResponseComponent ResponseComponent) const
    {
        if(ResponseComponent.bHitAnywhere)
            return true;

        switch(ResponseComponent.CollisionSettings.Type)
        {
            case EHazeShapeType::Sphere:
            {
                FSphere IceArrowCollisionSphere(Sphere.WorldLocation, Sphere.SphereRadius);
                FSphere ResponseComponentCollisionSphere(ResponseComponent.WorldLocation, ResponseComponent.CollisionSettings.SphereRadius);
                return IceArrowCollisionSphere.Intersects(ResponseComponentCollisionSphere);
            }
            case EHazeShapeType::Box:
            {
                // FB TODO: This intersection is in world space, right?
                FBox IceArrowCollisionBox = Sphere.GetBounds().Box;
                FBox ResponseComponentCollisionBox(-ResponseComponent.CollisionSettings.BoxExtents + ResponseComponent.WorldLocation, ResponseComponent.CollisionSettings.BoxExtents + ResponseComponent.WorldLocation);
                return IceArrowCollisionBox.Intersect(ResponseComponentCollisionBox);
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

	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		if (ProximityManager != nullptr)
			ProximityManager.UnregisterProjectile(this);
	}
	
    FHazeTraceSettings GetTraceSettings() const
    {
		FHazeTraceSettings Settings = Trace::InitChannel(ETraceTypeQuery::Visibility, n"IceArrow");
        Settings.UseSphereShape(Sphere.SphereRadius);

        if(IceBow::ShouldIgnoreOtherPlayer())
            Settings.IgnorePlayers();
        else
            Settings.IgnoreActor(Player);

		Settings.SetTraceComplex(false);
        return Settings;
    }
}