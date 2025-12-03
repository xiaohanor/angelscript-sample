/**
 * 
 */
 UCLASS(Abstract)
class AWindArrow : AHazeActor
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

	UPROPERTY(DefaultComponent, BlueprintReadOnly, Attach = "Sphere")
	USceneComponent EndOfArrow;

	UPROPERTY(DefaultComponent, Attach = "Sphere")
	UHazeMovablePlayerTriggerComponent WindZone;
	default WindZone.Shape = FHazeShapeSettings::MakeCapsule(50.0, 200.0);
	default WindZone.RelativeRotation = FRotator::MakeFromZ(FVector::ForwardVector);
	default WindZone.ShapeColor = FLinearColor::Yellow;
	default WindZone.EditorLineThickness = 1.0;

    #if EDITOR
    UPROPERTY(DefaultComponent)
    UTemporalLogTransformLoggerComponent TemporalLogTransform;
    #endif

    UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilityClasses.Add(UWindArrowMovementCapability);
	default CapabilityComponent.DefaultCapabilityClasses.Add(UWindArrowAttachedCapability);
	default CapabilityComponent.DefaultCapabilityClasses.Add(UWindArrowFollowBowCapability);

	UPROPERTY(EditDefaultsOnly)
	FVector WindZoneRelativeOffset;

    FWindArrowHitData HitData;
    bool bIsLaunched = false;

    float ChargeFactor = 0.0;

	UProjectileProximityManagerComponent ProximityManager;
	UWindArrowPlayerComponent WindArrowPlayerComp;

    float Gravity = 0.0;
    bool bActive = false;
	bool bIsAttached = false;
	FQuat TargetQuat;
	FQuat DefaultRelativeMeshQuat;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		WindZone.RelativeLocation = -FVector::ForwardVector * WindZone.Shape.CapsuleHalfHeight + WindZoneRelativeOffset;
	}
#endif

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		DefaultRelativeMeshQuat = Mesh.RelativeRotation.Quaternion();
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
            UnblockCapabilities(WindArrow::WindArrowTag, this);
            //RemoveActorDisable(this);
			Mesh.RemoveComponentVisualsBlocker(this);
        }

        UWindArrowEventHandler::Trigger_Activate(this);
    }

    void Deactivate()
    {
        if(!bActive)
            return;

        bActive = false;

		UWindArrowEventHandler::Trigger_Deactivate(this);
        BlockCapabilities(WindArrow::WindArrowTag, this);
        //AddActorDisable(this);
		Mesh.AddComponentVisualsBlocker(this);
        
        bIsLaunched = false;
		bIsAttached = false;
        HitData = FWindArrowHitData();

		DetachFromActor(EDetachmentRule::KeepWorld);
    }

	void Launch(FVector InVelocity, float InGravity, UProjectileProximityManagerComponent InProximityManager, UWindArrowPlayerComponent InWindArrowPlayerComponent)
	{
        Gravity = InGravity;
		SetActorVelocity(InVelocity);
        bIsLaunched = true;

		ProximityManager = InProximityManager;
		if (ProximityManager != nullptr)
			ProximityManager.RegisterProjectile(this);

		WindArrowPlayerComp = InWindArrowPlayerComponent;
	}

	bool IsAttachedToActor(AActor In_Actor) const
	{
		return AttachParentActor == In_Actor;
	}

	bool IsAttachedToAnyPlayer() const
	{
		if(AttachParentActor == nullptr)
			return false;

		return AttachParentActor.IsA(AHazePlayerCharacter);
	}

	AHazePlayerCharacter GetAttachedToPlayer() const property
	{
		devCheck(IsAttachedToAnyPlayer(), "Tried to get the player the wind arrow is attached to bu it is not attached to a player");
		return Cast<AHazePlayerCharacter>(AttachParentActor);
	}

    void OnHitActor(const FHitResult& HitResult)
    {
        check(HasControl());

        if(HitResult.Actor == nullptr)
        {
            WindArrowPlayerComp.RecycleWindArrow(this);
            return;
        }

        HitData = FWindArrowHitData(HitResult);

        OnHitActorWind();
    }

    private void OnHitActorWind()
    {
        check(HasControl());

        const float HitImpulseScale = UWindArrowSettings::GetSettings(Player).HitImpulseScale;

        float ResponseCompImpulseScale = 0.0;

        TArray<UWindArrowResponseComponent> ResponseComponents;
        HitData.Component.Owner.GetComponentsByClass(ResponseComponents);

        if(ResponseComponents.Num() > 0)
        {
            for(int i = ResponseComponents.Num() - 1; i >= 0; i--)
            {
                if (IntersectsWithResponseComp(ResponseComponents[i]))
                    ResponseCompImpulseScale += ResponseComponents[i].WindArrowImpulseScale;
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
        FWindArrowHitEventData EventData(this);
        CrumbOnHitActorWind(ResponseComponents, EventData, Impulse);
    }

    UFUNCTION(CrumbFunction)
    private void CrumbOnHitActorWind(TArray<UWindArrowResponseComponent> HitResponseComponents, FWindArrowHitEventData EventData, float HitImpulse)
    {
        for(auto HitResponseComponent : HitResponseComponents)
            HitResponseComponent.OnHitByWindArrow.Broadcast(EventData);

        if(HitImpulse > KINDA_SMALL_NUMBER)
            FauxPhysics::ApplyFauxImpulseToParentsAt(EventData.Component, EventData.ImpactPoint, GetActorVelocity() * HitImpulse);

        UWindArrowEventHandler::Trigger_Hit(this, EventData);

        //WindArrowPlayerComp.RecycleWindArrow(this);
		FQuat OriginalQuat = Mesh.ComponentQuat;
		AttachRootComponentTo(EventData.Component, NAME_None, EAttachLocation::KeepWorldPosition);
		ActorLocation = EventData.ImpactPoint;
		ActorQuat = FQuat::MakeFromXZ(-EventData.ImpactNormal, ActorForwardVector);
		Mesh.ComponentQuat = OriginalQuat;
		TargetQuat = ActorTransform.TransformRotation(DefaultRelativeMeshQuat);
		bIsAttached = true;

		if(IsAttachedToAnyPlayer())
			ApplyKnockdown(AttachedToPlayer, 500.0, 0.5);
    }

	void ApplyKnockdown(AHazePlayerCharacter In_Player, float Length, float Duration)
	{
		In_Player.ApplyKnockdown(ActorForwardVector.GetSafeNormal2D() * Length, Duration);
	}

    bool IntersectsWithResponseComp(UWindArrowResponseComponent ResponseComponent) const
    {
        if(ResponseComponent.bHitAnywhere)
            return true;

        switch(ResponseComponent.CollisionSettings.Type)
        {
            case EHazeShapeType::Sphere:
            {
                FSphere WindArrowCollisionSphere(Sphere.WorldLocation, Sphere.SphereRadius);
                FSphere ResponseComponentCollisionSphere(ResponseComponent.WorldLocation, ResponseComponent.CollisionSettings.SphereRadius);
                return WindArrowCollisionSphere.Intersects(ResponseComponentCollisionSphere);
            }
            case EHazeShapeType::Box:
            {
                // FB TODO: This intersection is in world space, right?
                FBox WindArrowCollisionBox = Sphere.GetBounds().Box;
                FBox ResponseComponentCollisionBox(-ResponseComponent.CollisionSettings.BoxExtents + ResponseComponent.WorldLocation, ResponseComponent.CollisionSettings.BoxExtents + ResponseComponent.WorldLocation);
                return WindArrowCollisionBox.Intersect(ResponseComponentCollisionBox);
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
		FHazeTraceSettings Settings = Trace::InitChannel(ETraceTypeQuery::Visibility, n"WindArrow");
        Settings.UseSphereShape(Sphere.SphereRadius);

        if(IceBow::ShouldIgnoreOtherPlayer())
            Settings.IgnorePlayers();
        else
            Settings.IgnoreActor(Player);

		Settings.SetTraceComplex(false);
        return Settings;
    }
}