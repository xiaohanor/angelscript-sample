class AScifiGravityGrenadeObject : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UScifiGravityGrenadeImpactResponseComponent ImpactResponse;

	UPROPERTY(DefaultComponent)
	UScifiGravityGrenadeTargetableComponent TargetComponent;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);

	TArray<UScifiGravityGrenadeAffectedObject> AffectedComponents;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> LinkedActors;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	private float LastImpactDuration = 0;
	
	UPROPERTY(EditInstanceOnly)
	float TimeActive = 5;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(AActor LinkedActor : LinkedActors)
		{
			auto FoundComponent = UScifiGravityGrenadeAffectedObject::Get(LinkedActor);
			if(FoundComponent != nullptr)
			{
				AffectedComponents.Add(FoundComponent);
			}
		}
	}

	void OnImpact(AHazePlayerCharacter Player, UScifiGravityGrenadeTargetableComponent Target)
	{
		//Print("Gravity Grenade Object Impact", 3);
		for(UScifiGravityGrenadeAffectedObject AffectedObjectComponents : AffectedComponents)
		{
			AffectedObjectComponents.GravityGrenadeEnable();
			//Print("Call Gravity Grenade Enable in " + AffectedObjectComponents.GetName(), 3);
		}

		ActorTickEnabled = true;
		LastImpactDuration = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Print("Gravity Grenade Object Ticking", 0);
		LastImpactDuration += DeltaSeconds;
		
		if(LastImpactDuration > TimeActive)
		{
			for(UScifiGravityGrenadeAffectedObject AffectedObjectComponents : AffectedComponents)
			{
				AffectedObjectComponents.GravityGrenadeDisable();
				//Print("Disabled Component" + AffectedObjectComponents.GetName(), 3);
			}

			ActorTickEnabled = false;
		}
	}

}


event void FScifiGravityGrenadeEffectStarted();
event void FScifiGravityGrenadeEffectStopped();

class UScifiGravityGrenadeAffectedObject : UActorComponent
{
	FScifiGravityGrenadeEffectStarted GravityGrenadeEffectStarted;
	FScifiGravityGrenadeEffectStopped GravityGrenadeEffectStopped;
	bool bIsActive = false;
	default ComponentTickEnabled = false;
	//default PrimaryComponentTick.bStartWithTickEnabled = false;

	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedQuat AcceleratedQuat;

	UPROPERTY(EditAnywhere)
	float ForwardStiffness = 10;
	UPROPERTY(EditAnywhere)
	float ForwardDampening = 0.8;
	UPROPERTY(EditAnywhere)
	float BackwardsStiffness = 5;
	UPROPERTY(EditAnywhere)
	float BackwardsDampening = 0.8;
	UPROPERTY(EditAnywhere)
	FTransform StartTransform;
	FTransform EndTransform;
	FTransform TargetTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto FindTargetLocationComponent = UScifiGravityGrenadeAffectedObjectTargetLocation::Get(GetOwner());
		if(FindTargetLocationComponent == nullptr)
		{
			Print("Missing Target Component in Actor: " + GetOwner().GetName(), 5);
		}
		else
		{
			EndTransform = FindTargetLocationComponent.GetWorldTransform();
			StartTransform = GetOwner().ActorTransform;
			AcceleratedLocation.Value = StartTransform.Location;
			AcceleratedQuat.Value = StartTransform.Rotation;
			TargetTransform = StartTransform;
		}

		
	}

	void GravityGrenadeEnable()
	{
		bIsActive = true;
		GravityGrenadeEffectStarted.Broadcast();
		ComponentTickEnabled = true;
		TargetTransform = EndTransform;
		Print("Component Enabled", 3);
	}

	void GravityGrenadeDisable()
	{
		bIsActive = false;
		GravityGrenadeEffectStopped.Broadcast();
		TargetTransform = StartTransform;
		Print("Component Disabled", 3);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedLocation.SpringTo(TargetTransform.Location, 1 * ForwardStiffness , 1 * ForwardDampening, DeltaSeconds);
		AcceleratedQuat.SpringTo(TargetTransform.Rotation, 1 * ForwardStiffness , 1 * ForwardDampening, DeltaSeconds);
		GetOwner().SetActorLocationAndRotation(AcceleratedLocation.Value, AcceleratedQuat.Value.Rotator());
		Print("Ticking", 0);
	}
}

class UScifiGravityGrenadeAffectedObjectTargetLocation : USceneComponent
{
	UPROPERTY(EditInstanceOnly)
	bool bPreviewTransform;

	bool bInternalPreview;
	FTransform CachedTransform;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bPreviewTransform)
		{
			if(!bInternalPreview)
			{
				bInternalPreview = true;
				CachedTransform = GetOwner().GetActorTransform();
			}

			GetOwner().SetActorTransform(this.GetWorldTransform());
		}


		else if(bInternalPreview != bPreviewTransform)
		{
			GetOwner().SetActorTransform(CachedTransform);
			CachedTransform = GetOwner().GetActorTransform();
			bInternalPreview = false;
		}
	}
}