struct FIslandOverseerForceField
{
	FIslandOverseerForceField()
	{
		AccIntegrity.SnapTo(1.0);
	}

	EIslandForceFieldType Type = EIslandForceFieldType::Blue;

	// Used by effect handler
	UPROPERTY()	
	EIslandForceFieldEffectType EffectType = EIslandForceFieldEffectType::EnemyBlue;

	UMaterialInstanceDynamic MaterialInstance;
	FVector LocalBreachLocation;
	UStaticMeshComponent MeshComp;

	FLinearColor Color;
	FLinearColor FillColor;

	FHazeAcceleratedFloat AccIntegrity;
	FHazeAcceleratedVector AccColor;

	void InitializeVisuals(AActor Owner, UMaterialInstance ForceFieldMaterial, UStaticMeshComponent InMeshComp)
	{
		MeshComp = InMeshComp;

		if (ForceFieldMaterial != nullptr && MaterialInstance == nullptr)
		{
			MaterialInstance = Material::CreateDynamicMaterialInstance(Owner, ForceFieldMaterial);			
			for (int i = 0; i < MeshComp.GetNumMaterials(); i++)
			{
				MeshComp.SetMaterial(i, MaterialInstance);
			}
		}
	}
}

class UIslandOverseerForceFieldComponent : UStaticMeshComponent
{
	UPROPERTY()
	UMaterialInstance RedForceFieldMaterial;

	UPROPERTY()
	UMaterialInstance BlueForceFieldMaterial;
	
	UPROPERTY(EditAnywhere)
	TArray<EIslandForceFieldType> ForceFieldTypes;

	// Triggers immediately after depleting current layer
	UPROPERTY()
	FShieldBurstEffect OnShieldBurstEffect;

	// Triggers immediately after depleting current layer
	UPROPERTY()
	FShieldBurst OnShieldBurst;

	UPROPERTY()
	FShieldReset OnShieldReset;

	// Reacts to normal bullets
	UPROPERTY(EditAnywhere)
	bool bHasBulletResponse = false;

	// Damage dealt to force field by player attack
	UPROPERTY(EditAnywhere)
	float DefaultBulletDamage = 0.1;

	// Damage dealt to force field by player grenade
	UPROPERTY(EditAnywhere)
	float DefaultGrenadeDamage = 10.0;

	// Damage replenished over time
	UPROPERTY(EditAnywhere)
	float ReplenishAmountPerSecond = 0.1;

	// Time window for registering second hit for collab shields.
	UPROPERTY(EditAnywhere)
	float ImpactTiming = 0.5;

	// Time for shield to disintegrate after impact
	UPROPERTY(EditAnywhere)
	float DisintegrationTime = 0.0;

	// Try fetching the red blue impact response component among child components
	UPROPERTY(EditAnywhere)
	bool bTryGetImpactResponseFromChildren;

	TArray<FIslandOverseerForceField> ForceFields;

	float CurrentIntegrity = 0.0;
	int CurrentForceFieldIndex = 0;

	bool bLayerHasBurst = false;
	float BurstTime;

	float ImpactDuration = 0.2;
	float ImpactTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto OwnerCharacter = Cast<AHazeCharacter>(Owner);
		if (OwnerCharacter == nullptr || OwnerCharacter.Mesh == nullptr)
			return;
		//ReconstructForceFields();	// This created superfluous meshes in runtime?
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RemoveTag(n"Walkable");
	}

	void Hide()
	{
		AddComponentVisualsBlocker(this);
		AddComponentCollisionBlocker(this);
	}

	void Show()
	{
		RemoveComponentVisualsBlocker(this);
		RemoveComponentCollisionBlocker(this);
	}

	void ReconstructForceFields()
	{
		ForceFields.Empty(ForceFieldTypes.Num());		

		// Create new		
		int i = 0;
		for (EIslandForceFieldType Type : ForceFieldTypes)
		{					
			ForceFields.Add(FIslandOverseerForceField());			
			FIslandOverseerForceField& Shield = ForceFields.Last();
			Shield.Type = Type;
			Shield.EffectType = IslandForceField::GetEffectType(Owner, Type);
			UMaterialInstance Material = Type == EIslandForceFieldType::Blue ? BlueForceFieldMaterial : RedForceFieldMaterial;
			Shield.InitializeVisuals(Owner, Material, this);
			Shield.AccIntegrity.SnapTo(1.0);
			i++;
		}
		CurrentIntegrity = float(ForceFields.Num());
		CurrentForceFieldIndex = ForceFields.Num() - 1;
	}

	bool IsDepleted()
	{
		return CurrentIntegrity < SMALL_NUMBER;
	}

	float GetIntegrity() property
	{
		return CurrentIntegrity;
	}

	EIslandForceFieldType GetCurrentForceFieldType()
	{
		if (CurrentForceFieldIndex < 0)
			return EIslandForceFieldType::MAX;

		return ForceFields[CurrentForceFieldIndex].Type;
	}

	float GetCurrentForceFieldIntegrity()
	{
		int Whole = int(CurrentIntegrity);
		float Fraction = CurrentIntegrity - float(Whole);

		if (IsCurrentFull())
			return 1.00;

		return Fraction;
	}

	bool IsCurrentFull()
	{
		int Whole = int(CurrentIntegrity);
		if (Whole < 1)
			return false;

		float Fraction = CurrentIntegrity - float(Whole);		
		return Fraction < 0.0 + SMALL_NUMBER && !bLayerHasBurst;
	}
	
	bool IsCurrentDamaged()
	{
		return !IsCurrentFull();
	}

	void Replenish(float ReplenishAmount)
	{
		if (IsCurrentFull())
			return;

		if (GetCurrentForceFieldIntegrity() <= SMALL_NUMBER)
			return;
		
		// Discard overshoot, floor to X.00
		int Whole = int(CurrentIntegrity);
		float Fraction = CurrentIntegrity - float(Whole);
	 	Fraction += ReplenishAmount;
		if (Fraction > 1.0)
			CurrentIntegrity = float(Whole + 1);
		else
	 		CurrentIntegrity = float(Whole) + Fraction;
	}

	void Impact(FVector Location)
	{
		FIslandOverseerForceField CurrentForceField = GetCurrentForceField();

		FIslandForceFieldImpactParams Params;
		Params.Location = Location;
		Params.ForceFieldType = CurrentForceField.EffectType;
		UIslandForceFieldEffectHandler::Trigger_OnForceFieldImpact(Cast<AHazeActor>(Owner), Params);

		ImpactTimer = ImpactDuration;
		
		CurrentForceField.AccColor.Value = FVector(100, 100, 100);
	}

	private	FIslandOverseerForceField& GetCurrentForceField()
	{	
		return ForceFields[CurrentForceFieldIndex];
	}

	// Temp
	// Assumes that explosion is within range
	FVector GetExplosionImpactLocation(FVector ExplosionLocation)
	{
		FVector ActorCenterLocation = Cast<AHazeActor>(Owner).ActorCenterLocation;
		FVector DirToExplosionLocation = (ExplosionLocation - ActorCenterLocation).GetSafeNormal();		
		FIslandOverseerForceField& CurrentForceField = GetCurrentForceField();
		FVector ImpactLocation = ActorCenterLocation + DirToExplosionLocation * CurrentForceField.MeshComp.WorldScale * 100;
		return ImpactLocation;
	}

	void TakeDamage(float Damage, FVector WorldDamageLocation)
	{
		check(Damage > 0, "Damage is less than or equal to 0");

		if (CurrentIntegrity < SMALL_NUMBER)
			return;		

		if (IsCurrentFull())
		{
			FIslandOverseerForceField& CurrentForceField = GetCurrentForceField();
			CurrentForceField.LocalBreachLocation = WorldTransform.InverseTransformPosition(WorldDamageLocation);
		}
		
		float Whole = Math::FloorToFloat(CurrentIntegrity);
		if (IsCurrentFull() && Whole > 0.0)
			Whole -= 1.0;
		CurrentIntegrity = Math::Max(Whole, CurrentIntegrity - Damage); // Cap damage to within current shield layer
		if (CurrentIntegrity < Whole + SMALL_NUMBER)
		{
			bLayerHasBurst = true;
			BurstTime = Time::GameTimeSeconds;
		}

		check(CurrentIntegrity >= 0, "CurrentIntegrity is less than 0");
	}

	void TriggerBurstEffect(EIslandForceFieldEffectType EffectType)
	{
		FIslandForceFieldDepletedParams Params;
		Params.Location = Cast<AHazeActor>(Owner).ActorCenterLocation;
		Params.ForceFieldType = EffectType;
		UIslandForceFieldEffectHandler::Trigger_OnForceFieldDepleted(Cast<AHazeActor>(Owner), Params);
		FIslandForceFieldDepletedPlayerEventParams PlayerParams;
		PlayerParams.DepletedByPlayer = EffectType == EIslandForceFieldEffectType::EnemyRed ? Game::Mio : Game::Zoe;
		PlayerParams.DepletedByPlayer = EffectType == EIslandForceFieldEffectType::EnemyBoth ? nullptr : PlayerParams.DepletedByPlayer; // Special case for when both players deplete the shield.
		PlayerParams.ForceFieldOwner = Cast<AHazeActor>(Owner);
		PlayerParams.ForceFieldType = EffectType;
		UIslandForceFieldPlayerEffectHandler::Trigger_OnForceFieldDepleted(Game::Mio, PlayerParams);
		UIslandForceFieldPlayerEffectHandler::Trigger_OnForceFieldDepleted(Game::Zoe, PlayerParams);
	}


	void Reset()
	{
		bLayerHasBurst = false;
		CurrentIntegrity = float(ForceFields.Num());
		CurrentForceFieldIndex = ForceFields.Num() - 1;
		ReconstructForceFields();
		for (FIslandOverseerForceField ForceField : ForceFields)
		{
			ForceField.MeshComp.SetScalarParameterValueOnMaterials(n"Radius", 0.0);
		}
		OnShieldReset.Broadcast();
	}
	
	// Depleted when innermost shield is depleted
	bool HasFinishedDepleting()
	{
		return ForceFields.Num() > 0 ? ForceFields[0].AccIntegrity.Value < KINDA_SMALL_NUMBER : true;
	}

	private bool HasFinishedDepletingCurrent()
	{
		if (!bLayerHasBurst)
			return false;
				
		if (ForceFields[CurrentForceFieldIndex].AccIntegrity.Value > KINDA_SMALL_NUMBER)
			return false;
		
		return true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDestroyCurrentLayer()
	{		
		bLayerHasBurst = false;
		Hide();
		EIslandForceFieldEffectType EffectType = ForceFields[CurrentForceFieldIndex].EffectType;
		CurrentForceFieldIndex = Math::Max(CurrentForceFieldIndex - 1, 0);
		OnShieldBurstEffect.Broadcast(EffectType);
	}

	void Update(float DeltaTime)
	{
		FIslandOverseerForceField& CurrentForceField = GetCurrentForceField();
				
		// Update breach
		float CurrentIntegrityFraction = GetCurrentForceFieldIntegrity();
		CurrentForceField.AccIntegrity.AccelerateTo(CurrentIntegrityFraction, DisintegrationTime, DeltaTime);
		if (CurrentForceField.AccIntegrity.Value < 1.0 - SMALL_NUMBER)
		{
			float RadiusScaleFactor = 2.5;
			float Radius = (1.0 - CurrentForceField.AccIntegrity.Value);
			Radius *= CurrentForceField.MeshComp.BoundsRadius * RadiusScaleFactor;
			CurrentForceField.MeshComp.SetScalarParameterValueOnMaterials(n"Radius", Radius);
			CurrentForceField.MeshComp.SetVectorParameterValueOnMaterials(n"DissolvePoint", WorldTransform.TransformPosition(CurrentForceField.LocalBreachLocation));
		}


		// Impact blink effect
		if(ImpactTimer > 0)
		{
			ImpactTimer -= DeltaTime;

			FLinearColor CurrentColour = CurrentForceField.Color;

			if(ImpactTimer > 0)
			{
				CurrentForceField.AccColor.AccelerateTo(FVector(CurrentColour.R, CurrentColour.G, CurrentColour.B), ImpactDuration, DeltaTime);
			}
			else
			{
				CurrentForceField.AccColor.Value = FVector(CurrentColour.R, CurrentColour.G, CurrentColour.B);
			}

			CurrentForceField.MeshComp.SetVectorParameterValueOnMaterials(n"Color", CurrentForceField.AccColor.Value);
		}


		// Remove current layer when depleted
		if (HasControl() && HasFinishedDepletingCurrent())
		{
			CrumbDestroyCurrentLayer();
		}
	}
}
