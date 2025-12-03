event void FIslandWalkerForceFieldEventSignature(UIslandWalkerForceFieldComponent ForceFieldComponent);

class UIslandWalkerForceFieldComponent: UStaticMeshComponent
{
	default RemoveTag(ComponentTags::Walkable);

	UPROPERTY()
	UMaterialInstance ForceFieldMaterial;

	UPROPERTY(EditAnywhere)
	EIslandForceFieldType Type = EIslandForceFieldType::Blue;

	UPROPERTY()
	FIslandWalkerForceFieldEventSignature OnDepleted;

	UPROPERTY()
	FIslandWalkerForceFieldEventSignature OnStartReplenishing;

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	UMaterialInstanceDynamic MaterialInstance;

	FVector OverrideBreachLocation = FVector::ZeroVector;

	private float CurrentIntegrity = 1.0;
	FVector LocalBreachLocation;

	UPROPERTY()
	FLinearColor BlueColour = FLinearColor(0.0, 2.0, 4.0, 1.0);

	UPROPERTY()
	FLinearColor RedColour = FLinearColor(10.0, 0.025, 0.0, 1.0);

	FLinearColor Colour;

	//FLinearColor EdgeColour;

	FHazeAcceleratedFloat AccIntegrity;
	FHazeAcceleratedVector AccColor;

	TInstigated<FName> CollisionProfile;

	AHazeActor Walker;

	float ImpactDuration = 0.5;
	float ImpactTimer;
	bool bPoweredDown = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto OwnerCharacter = Cast<AHazeCharacter>(Owner);
		if (OwnerCharacter == nullptr || OwnerCharacter.Mesh == nullptr)
			return;

		InitializeVisuals();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollisionProfile.SetDefaultValue(CollisionProfileName);		
	}

	void InitializeVisuals()
	{
		if (ForceFieldMaterial != nullptr)
		{
			SetForceFieldColours();
			MaterialInstance = Material::CreateDynamicMaterialInstance(this, ForceFieldMaterial);
			for (int i = 0; i < GetMaterials().Num(); i++)
			{
				SetMaterial(i, MaterialInstance);
			}

			if (MaterialInstance != nullptr)
			{
				MaterialInstance.SetVectorParameterValue(n"EmissiveColor", Colour);
			}
		}
	} 

	AHazePlayerCharacter GetUsablePlayer() const property
	{
		if (Type == EIslandForceFieldType::Blue)
			return Game::Zoe;
		return Game::Mio;
	}

	void SetForceFieldColours()
	{
		if(Type == EIslandForceFieldType::Blue)
		{
			Colour = BlueColour;
			return;
		}

		if (Type == EIslandForceFieldType::Red)
		{
			Colour = RedColour;
			return;
		}
		
		devError("Bad forcefield type in IslandWalkerForcefieldComponent!");
		return;
	}


	bool IsDepleted()
	{
		return CurrentIntegrity < SMALL_NUMBER;
	}

	float GetIntegrity() property
	{
		return CurrentIntegrity;
	}

	bool IsFull()
	{
		return CurrentIntegrity > 1.0 - SMALL_NUMBER;
	}

	bool IsDamaged()
	{
		return !IsFull();
	}
	
	void Replenish(float ReplenishAmount)
	{
		if (IsFull())
			return;
		if (bPoweredDown)
			return;

		CurrentIntegrity += ReplenishAmount;
		if (CurrentIntegrity > 1.0)
			CurrentIntegrity = 1.0;
	}

	bool bHasBeenDepleted = false;

	void Impact()
	{
		ImpactTimer = ImpactDuration;
		AccColor.Value = FVector(10.0, 10.0, 10.0);
	}

	void TakeDamage(float Damage, FVector WorldDamageLocation)
	{
		if (bPoweredDown)
			return;
		if (IsFull())
			LocalBreachLocation = WorldTransform.InverseTransformPositionNoScale(WorldDamageLocation).GetClampedToSize(BoundsRadius, BoundsRadius);
		if (!OverrideBreachLocation.IsZero())
			LocalBreachLocation = OverrideBreachLocation.GetClampedToSize(BoundsRadius, BoundsRadius);

		CurrentIntegrity -= Damage;
		if (CurrentIntegrity < 0.0)
			CurrentIntegrity = 0.0;

		if(CurrentIntegrity < SMALL_NUMBER)
			OnDepleted.Broadcast(this);

	}

	void TriggerBurstEffect()
	{
		FIslandForceFieldDepletedParams Params;
		Params.Location = Cast<AHazeActor>(Owner).ActorCenterLocation;
		UIslandForceFieldEffectHandler::Trigger_OnForceFieldDepleted(Cast<AHazeActor>(Owner), Params);		
	}

	void Reset()
	{
		CurrentIntegrity = 1.0;	
		bPoweredDown = false;	
		bHasBeenDepleted = false;
		AccIntegrity.SnapTo(CurrentIntegrity);
		ClearCollision(this);
		SetScalarParameterValueOnMaterials(n"Bubble0Radius", 0.0);
	}

	bool HasFinishedDepleting()
	{
		return AccIntegrity.Value < KINDA_SMALL_NUMBER;
	}

	void UpdateVisuals(float DeltaTime)
	{
		if (bPoweredDown)		
			AccIntegrity.AccelerateTo(0.0, 2.0, DeltaTime);
		else if (CurrentIntegrity < AccIntegrity.Value)
			AccIntegrity.AccelerateTo(CurrentIntegrity, 0.01, DeltaTime);
		else
			AccIntegrity.AccelerateTo(CurrentIntegrity, 1.0, DeltaTime);
		if (AccIntegrity.Value < 1.0 - SMALL_NUMBER)
		{
			float RadiusScaleFactor = 2.0;
			float Radius = (1.0 - AccIntegrity.Value);
			Radius *= BoundsRadius * RadiusScaleFactor;
			SetScalarParameterValueOnMaterials(n"Bubble0Radius", Radius);
			SetVectorParameterValueOnMaterials(n"Bubble0Loc", WorldTransform.TransformPositionNoScale(LocalBreachLocation));
		}

		if(ImpactTimer > 0)
		{
			ImpactTimer -= DeltaTime;

			if(ImpactTimer > 0)
			{
				AccColor.AccelerateTo(FVector(Colour.R, Colour.G, Colour.B), ImpactDuration, DeltaTime);
			}
			else
			{
				AccColor.Value = FVector(Colour.R, Colour.G, Colour.B);
			}

			SetVectorParameterValueOnMaterials(n"EmissiveColor", AccColor.Value);
		}
	}

	void ApplyCollision(FName Collision, FInstigator Instigator, EInstigatePriority Prio)
	{
		FName Current = CollisionProfile.Get();
		CollisionProfile.Apply(Collision, Instigator, Prio);
		if (!Current.IsEqual(CollisionProfile.Get()))
			SetCollisionProfileName(CollisionProfile.Get());
	}

	void ClearCollision(FInstigator Instigator)
	{
		FName Current = CollisionProfile.Get();
		CollisionProfile.Clear(Instigator);
		if (!Current.IsEqual(CollisionProfile.Get()))
			SetCollisionProfileName(CollisionProfile.Get());
	}

	void PowerDown()
	{
		if (bPoweredDown)
			return;
		bPoweredDown = true;
		if (IsFull())
			LocalBreachLocation = FVector::ZeroVector;
		CurrentIntegrity = 0.0;
		ApplyCollision(n"NoCollision", this, EInstigatePriority::High);
	}

	void PowerUp()
	{
		if (!bPoweredDown)
			return;
		
		bPoweredDown = false;
		ClearCollision(this);
	}
}
