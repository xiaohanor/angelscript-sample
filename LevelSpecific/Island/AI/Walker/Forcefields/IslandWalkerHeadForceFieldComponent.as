event void FIslandWalkerHeadForceFieldEventSignature();

class UIslandWalkerHeadForceFieldComponent: UHazeSkeletalMeshComponentBase
{
	default RemoveTag(ComponentTags::Walkable);

	UPROPERTY()
	UMaterialInstance ForceFieldMaterial_Red;

	UPROPERTY()
	UMaterialInstance ForceFieldMaterial_Blue;

	UPROPERTY(EditAnywhere)
	EIslandForceFieldType Type = EIslandForceFieldType::Blue;

	UPROPERTY()
	FIslandWalkerHeadForceFieldEventSignature OnDepleted;

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	UMaterialInstanceDynamic MaterialInstance_Red;

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	UMaterialInstanceDynamic MaterialInstance_Blue;

	FVector OverrideBreachLocation = FVector::ZeroVector;

	private float CurrentIntegrity = 1.0;
	FVector LocalBreachLocation;

	FHazeAcceleratedFloat AccIntegrity;

	TInstigated<FName> CollisionProfile;

	AHazeCharacter WalkerHead;

	bool bPoweredDown = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollisionProfile.SetDefaultValue(CollisionProfileName);	
	}

	void InitializeVisuals()
	{
		if (WalkerHead != nullptr)
		{
			SetSkinnedAssetAndUpdate(WalkerHead.Mesh.SkinnedAsset);
			SetLeaderPoseComponent(WalkerHead.Mesh);
			SetWorldScale3D(WalkerHead.Mesh.GetWorldScale());
		}

		if (ForceFieldMaterial_Red != nullptr)
			MaterialInstance_Red = Material::CreateDynamicMaterialInstance(this, ForceFieldMaterial_Red);
		if (ForceFieldMaterial_Blue != nullptr)
			MaterialInstance_Blue = Material::CreateDynamicMaterialInstance(this, ForceFieldMaterial_Blue);

		SetForceFieldColours();
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
			if (MaterialInstance_Blue == nullptr)
				return;
			for (int i = 0; i < GetMaterials().Num(); i++)
			{
				SetMaterial(i, MaterialInstance_Blue);
			}
			return;
		}

		if (Type == EIslandForceFieldType::Red)
		{
			if (MaterialInstance_Red == nullptr)
				return;
			for (int i = 0; i < GetMaterials().Num(); i++)
			{
				SetMaterial(i, MaterialInstance_Red);
			}
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

		if (CurrentIntegrity < SMALL_NUMBER)
			OnDepleted.Broadcast();
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
		SetScalarParameterValueOnMaterials(n"Radius", 0.0);
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
			SetScalarParameterValueOnMaterials(n"Radius", Radius);
			SetVectorParameterValueOnMaterials(n"DissolvePoint", WorldTransform.TransformPositionNoScale(LocalBreachLocation));
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
