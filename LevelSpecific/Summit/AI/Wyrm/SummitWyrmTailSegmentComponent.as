class USummitWyrmTailSegmentComponent : UHazeSkeletalMeshComponentBase
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	USummitWyrmSettings Settings;

	UPROPERTY(Category = "Animation")
	UAnimSequence Animation;

	UPROPERTY()
	UStaticMesh StaticMesh;

	UPROPERTY()
	FVector Scale = FVector(2.5, 2.5, 1.8);

	UPROPERTY()
	FVector RelativeOffset = FVector::UpVector * 80.0;

	UPROPERTY()
	UMaterialInterface MaterialOverride;

	UMaterialInstanceDynamic MeltingMetalMaterial;

	float Health = 1.0;
	bool bIsMetal = false;
	bool bIsDisabled = false;

	// Metal only
	bool bIsMelting = false;
	bool bIsDissolving = false;
	float MeltAlpha = 0.0;
	float DissolveAlpha = 0.0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (StaticMesh == nullptr)
			return;

		Settings = USummitWyrmSettings::GetSettings(Cast<AHazeActor>(Owner));

		UMaterialInterface Material;

		if (MaterialOverride != nullptr)
			Material = MaterialOverride;
		else
		{
			if (Materials.Num() == 0)
				Material = StaticMesh.GetMaterial(0);
			else
				Material = Materials[0];
		}
		
		MeltingMetalMaterial = CreateDynamicMaterialInstance(0, Material);
		
		// Temp model until we have a skeletal mesh
		auto StaticMeshComponent = UStaticMeshComponent::Create(Owner);
		StaticMeshComponent.StaticMesh = StaticMesh;
		StaticMeshComponent.AttachToComponent(this);
		StaticMeshComponent.WorldScale3D = Owner.ActorScale3D * Scale;
		StaticMeshComponent.RelativeLocation += RelativeOffset;
		StaticMeshComponent.SetMaterial(0, MeltingMetalMaterial);
		StaticMeshComponent.SetCollisionProfileName(n"NoCollision");

		auto Collision = UCapsuleComponent::Create(Owner);
		Collision.AttachToComponent(this);
		Collision.GenerateOverlapEvents = false;
		Collision.SetCapsuleHalfHeight(200.0);
		Collision.SetCapsuleRadius(100.0);
		Collision.RelativeLocation += FVector::UpVector * 50.0;
		Collision.RelativeRotation += FRotator(90.0, 0.0, 0.0);
		Collision.SetCollisionProfileName(n"EnemyIgnoreEnemy");
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceEnemy, ECollisionResponse::ECR_Block);
	}

	void TakeDamage(float Damage)
	{
		Health -= Damage;
	}

	bool IsAlive()
	{
		return Health > 0.0;
	}

	bool IsDisabled()
	{
		return bIsDisabled;
	}

	void TriggerDestroyedEffect()
	{
		if (bIsMetal)
			StartMelting();
		else
			USummitWyrmEffectHandler::Trigger_OnCrystalSegmentSmashed(Cast<AHazeActor>(Owner), FWyrmCrystalSegmentDamageParams(this));
	}
	
	void StartMelting()
	{
		if (!bIsMetal)
			return;
		
		SetComponentTickEnabled(true);
		bIsMelting = true;
	}

	private void OnDissolved()
	{
		SetComponentTickEnabled(false);
		DisableInternal();
	}

	void ResetMeltingState()
	{
		if (!bIsMetal)
			return;
		
		bIsMelting = false;
		bIsDissolving = false;
		MeltingMetalMaterial.SetScalarParameterValue(n"BlendMelt", 0.0);
		MeltingMetalMaterial.SetScalarParameterValue(n"BlendDissolve", 0.0);
	}

	void Disable()
	{		
		if (bIsMetal)
		{
			if (!bIsMelting)
				StartMelting();
		}
		else
		{
			DisableInternal();
		}
	}

	private void DisableInternal()
	{
		bIsDisabled = true;
		AddComponentVisualsBlocker(this);
		AddComponentTickBlocker(this);
		AddComponentCollisionBlocker(this);

		TArray<USceneComponent> ChildComps;
		GetChildrenComponents(true, ChildComps);
		for (USceneComponent& Comp : ChildComps)
		{
			Comp.AddComponentVisualsBlocker(this);
			Comp.AddComponentTickBlocker(this);

			UPrimitiveComponent PrimitiveComp = Cast<UPrimitiveComponent>(Comp);
			if (PrimitiveComp != nullptr)
			{
				PrimitiveComp.AddComponentCollisionBlocker(this);
			}
		}

	}

	void Enable()
	{
		FInstigator Instigator = this; // temp
		bIsDisabled = false;
		RemoveComponentVisualsBlocker(Instigator);
		RemoveComponentTickBlocker(Instigator);
		RemoveComponentCollisionBlocker(Instigator);

		TArray<USceneComponent> ChildComps;
		GetChildrenComponents(true, ChildComps);
		for (USceneComponent& Comp : ChildComps)
		{
			Comp.RemoveComponentVisualsBlocker(Instigator);
			Comp.RemoveComponentTickBlocker(Instigator);

			UPrimitiveComponent PrimitiveComp = Cast<UPrimitiveComponent>(Comp);
			if (PrimitiveComp != nullptr)
			{
				PrimitiveComp.RemoveComponentCollisionBlocker(Instigator);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsDissolving)
		{
			DissolveAlpha += DeltaSeconds / Settings.HurtReactionMetalMeltDissolveDuration;
			if (DissolveAlpha > 1.0)
			{
				DissolveAlpha = 1.0;
				OnDissolved();
			}
			MeltingMetalMaterial.SetScalarParameterValue(n"BlendDissolve", DissolveAlpha);
		}
		else if (bIsMelting)
		{			
			MeltAlpha += DeltaSeconds / Settings.HurtReactionMetalMeltDissolveDuration;
			if (MeltAlpha > 1.0)
			{
				MeltAlpha = 1.0;
				bIsDissolving = true;
			}
			MeltingMetalMaterial.SetScalarParameterValue(n"BlendMelt", MeltAlpha);
		}
	}

}
