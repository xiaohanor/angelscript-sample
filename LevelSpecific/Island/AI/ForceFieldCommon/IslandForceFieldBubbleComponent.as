event void FShieldBurstEffect(EIslandForceFieldEffectType EffectType);
event void FShieldBurst();
event void FShieldReset();

struct FIslandForceFieldBubble
{
	FIslandForceFieldBubble()
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

	FHazeAcceleratedFloat AccIntegrity;

	void InitializeVisuals(AActor Owner, int ForceFieldSpawnIndex, UStaticMesh Mesh, UMaterialInstance ForceFieldMaterial, float Scale, USceneComponent AttachParent, FName Collision, bool bIsWalkable = false)
	{
		if (MeshComp == nullptr)
		{
			devCheck(Mesh != nullptr, "IslandForceFieldBubbleComponent has no Mesh assigned!");

			// These meshes need to be networked since we can hit them with bullets,
			// so we need to give them a unique name on the actor.
			FName MeshCompName = n"ForceFieldBubbleMesh";
			MeshCompName.SetNumber(ForceFieldSpawnIndex + 10);
			
			MeshComp = UStaticMeshComponent::Create(Owner, MeshCompName);

			MeshComp.SetCollisionProfileName(Collision);
			if (!bIsWalkable)
				MeshComp.RemoveTag(n"Walkable");
			MeshComp.RemoveTag(n"Vaultable");
			MeshComp.RemoveTag(n"WallScrambleable");
			MeshComp.RemoveTag(n"WallRunnable");
			MeshComp.RemoveTag(n"LedgeGrabbable");
			MeshComp.RemoveTag(n"LedgeRunnable");
			MeshComp.RemoveTag(n"LedgeClimbable");
			MeshComp.AddLocalOffset(Cast<AHazeActor>(Owner).ActorCenterLocation - Owner.ActorLocation);
			MeshComp.StaticMesh = Mesh;
			MeshComp.WorldScale3D = FVector(Scale);

			if(AttachParent != nullptr)
				MeshComp.AttachToComponent(AttachParent);
		}

		if (ForceFieldMaterial != nullptr && MaterialInstance == nullptr)
		{
			MaterialInstance = Material::CreateDynamicMaterialInstance(Owner, ForceFieldMaterial);			
						
			for (int i = 0; i < MeshComp.GetNumMaterials(); i++)
			{
				MeshComp.SetMaterial(i, MaterialInstance);
			}

			if (MaterialInstance != nullptr)
			{
				ApplyOriginalColor();
			}
		}
	}

	void ApplyOverrideColor(EIslandForceFieldType OverrideType)
	{
		FLinearColor Color = IslandForceField::GetForceFieldColor(OverrideType);
		FLinearColor OutlineColor = IslandForceField::GetForceFieldColor(OverrideType) * 0.1;
		SetColors(Color, OutlineColor);
	}

	void ApplyOriginalColor()
	{
		FLinearColor Color = IslandForceField::GetForceFieldColor(Type);
		FLinearColor OutlineColor = IslandForceField::GetForceFieldColor(Type);
		SetColors(Color, OutlineColor);
	}

	void SetVisibility(bool bIsVisible)
	{
		MeshComp.SetVisibility(bIsVisible);
	}

	private void SetColors(FLinearColor _Color, FLinearColor _OutlineColor)
	{		
		MaterialInstance.SetVectorParameterValue(n"Color", _Color);		
		MaterialInstance.SetVectorParameterValue(n"FresnelOutlineColor", _OutlineColor);
	}
}

class UIslandForceFieldBubbleComponent : USceneComponent
{
	access InternalWithCapability = private, UIslandForceFieldBubbleCapability;

	UPROPERTY()
	UStaticMesh Mesh;

	UPROPERTY()
	UMaterialInstance ForceFieldMaterial;
	
	UPROPERTY(EditAnywhere)
	TArray<EIslandForceFieldType> ForceFieldTypes;

	UPROPERTY(EditAnywhere)
	float BaseScale = 2.0;
	
	UPROPERTY(EditAnywhere)
	float ScaleInterval = 0.1;

	// Triggers immediately after depleting current layer
	UPROPERTY()
	FShieldBurstEffect OnShieldBurstEffect;

	// Triggers immediately after depleting current layer
	UPROPERTY()
	FShieldBurst OnShieldBurst;

	UPROPERTY()
	FShieldReset OnShieldReset;

	// Damage dealt to force field by player grenade
	UPROPERTY(EditAnywhere)
	float DefaultGrenadeDamage = 10.0;

	// Damage replenished over time
	UPROPERTY(EditAnywhere)
	float ReplenishAmountPerSecond = 0.1;

	// Time window for registering second hit for collab shields.
	UPROPERTY(EditAnywhere)
	float ImpactTiming = 2.0;

	// Time for shield to disintegrate after impact
	UPROPERTY(EditAnywhere)
	float DisintegrationTime = 0.0;

	// Attach to parent component
	UPROPERTY(EditAnywhere)
	bool bAttachToParentComponent = false;

	// Attach to parent component
	UPROPERTY(EditAnywhere)
	FName Collision = n"EnemyCharacter";

	// Try fetching the red blue impact response component among child components
	UPROPERTY(EditAnywhere)
	bool bTryGetImpactResponseFromChildren;

	// Set tag walkable on forcefield mesh.
	UPROPERTY(EditAnywhere)
	bool bIsWalkable = false;

	TArray<FIslandForceFieldBubble> ForceFields;

	float CurrentIntegrity = 0.0;
	int CurrentForceFieldIndex = 0;
	int ForceFieldSpawnIndex = 0;

	bool bLayerHasBurst = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto OwnerCharacter = Cast<AHazeCharacter>(Owner);
		if (OwnerCharacter == nullptr || OwnerCharacter.Mesh == nullptr)
			return;
		//ReconstructForceFields();	// This created superfluous meshes in runtime?
	}

	void AddVisualsBlockers(FInstigator Instigator)
	{
		for (FIslandForceFieldBubble ForceField : ForceFields)
		{
			if (ForceField.MeshComp != nullptr)
				ForceField.MeshComp.AddComponentVisualsBlocker(Instigator);
		}
	}

	void RemoveVisualsBlockers(FInstigator Instigator)
	{
		for (FIslandForceFieldBubble ForceField : ForceFields)
		{
			if (ForceField.MeshComp != nullptr)
				ForceField.MeshComp.RemoveComponentVisualsBlocker(Instigator);
		}
	}

	void AddCollisionBlockers(FInstigator Instigator)
	{
		for (FIslandForceFieldBubble ForceField : ForceFields)
		{
			if (ForceField.MeshComp != nullptr)
				ForceField.MeshComp.AddComponentCollisionBlocker(Instigator);
		}
	}

	void RemoveCollisionBlockers(FInstigator Instigator)
	{
		for (FIslandForceFieldBubble ForceField : ForceFields)
		{
			if (ForceField.MeshComp != nullptr)
				ForceField.MeshComp.RemoveComponentCollisionBlocker(Instigator);
		}
	}


	void ReconstructForceFields()
	{
		ForceFields.Empty(ForceFieldTypes.Num());		

		// Create new		
		float Scale = BaseScale;
		int i = 0;
		for (EIslandForceFieldType Type : ForceFieldTypes)
		{					
			ForceFields.Add(FIslandForceFieldBubble());			
			FIslandForceFieldBubble& Shield = ForceFields.Last();
			Shield.Type = Type;
			Shield.EffectType = IslandForceField::GetEffectType(Owner, Type);

			USceneComponent AttachComponent;
			if(bAttachToParentComponent)
				AttachComponent = AttachParent;

			Shield.InitializeVisuals(Owner, ForceFieldSpawnIndex, Mesh, ForceFieldMaterial, Scale, AttachComponent, Collision, bIsWalkable);
			if (ForceFieldTypes.Num() > 1 && i != ForceFieldTypes.Num() - 1)
				Shield.SetVisibility(false);

			Scale += ScaleInterval;
			ForceFieldSpawnIndex += 1;
			Shield.AccIntegrity.SnapTo(1.0);
			i++;
		}
		CurrentIntegrity = float(ForceFields.Num());
		CurrentForceFieldIndex = ForceFields.Num() - 1;
	}

	void OverrideVisuals(EIslandForceFieldType OverrideShieldColor)
	{
		check(CurrentForceFieldIndex < ForceFields.Num());
		FIslandForceFieldBubble& ForceField = ForceFields[CurrentForceFieldIndex];
		ForceField.ApplyOverrideColor(OverrideShieldColor);
	}

	void ClearOverrideVisuals()
	{
		check(CurrentForceFieldIndex < ForceFields.Num());
		FIslandForceFieldBubble& ForceField = ForceFields[CurrentForceFieldIndex];
		ForceField.ApplyOriginalColor();
	}

	bool IsDepleted() const
	{
		return CurrentIntegrity < SMALL_NUMBER;
	}

	bool IsEnabled() const
	{
		return ForceFields.Num() > 0;
	}

	float GetIntegrity() const property
	{
		return CurrentIntegrity;
	}

	EIslandForceFieldType GetCurrentForceFieldType() const
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

	access:InternalWithCapability
	FIslandForceFieldBubble& GetCurrentForceFieldBubble()
	{	
		return ForceFields[CurrentForceFieldIndex];
	}

	// Temp
	// Assumes that explosion is within range
	FVector GetExplosionImpactLocation(FVector ExplosionLocation)
	{
		FVector ActorCenterLocation = Cast<AHazeActor>(Owner).ActorCenterLocation;
		FVector DirToExplosionLocation = (ExplosionLocation - ActorCenterLocation).GetSafeNormal();		
		FIslandForceFieldBubble& CurrentForceField = GetCurrentForceFieldBubble();
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
			FIslandForceFieldBubble& CurrentForceField = GetCurrentForceFieldBubble();
			CurrentForceField.LocalBreachLocation = WorldTransform.InverseTransformPosition(WorldDamageLocation);
		}
		
		float Whole = Math::FloorToFloat(CurrentIntegrity);
		if (IsCurrentFull() && Whole > 0.0)
			Whole -= 1.0;
		CurrentIntegrity = Math::Max(Whole, CurrentIntegrity - Damage); // Cap damage to within current shield layer
		if (CurrentIntegrity < Whole + SMALL_NUMBER)
			bLayerHasBurst = true;

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
		for (FIslandForceFieldBubble& ForceField : ForceFields)
		{
			ForceField.AccIntegrity.SnapTo(1.0);
			ForceField.MeshComp.SetScalarParameterValueOnMaterials(n"Radius", 0.0);
			ForceField.MeshComp.RemoveComponentCollisionBlocker(this);
			ForceField.MeshComp.RemoveComponentVisualsBlocker(this);
		}
		OnShieldReset.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	void CrumbReset()
	{
		Reset();
	}
	
	// Depleted when innermost shield is depleted
	bool HasFinishedDepleting() const
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
	private void CrumbDestroyCurrentLayer(float _CurrentIntegrity)
	{	
		TEMPORAL_LOG(this).Event("CrumbDestroyCurrentLayer");
		bLayerHasBurst = false;
		CurrentIntegrity = _CurrentIntegrity; // Remote may not have taken damage yet.
		ForceFields[CurrentForceFieldIndex].AccIntegrity.SnapTo(0.0); // Remote may not have reached 0 yet.
		ForceFields[CurrentForceFieldIndex].MeshComp.AddComponentVisualsBlocker(this);
		ForceFields[CurrentForceFieldIndex].MeshComp.AddComponentCollisionBlocker(this);
		EIslandForceFieldEffectType EffectType = ForceFields[CurrentForceFieldIndex].EffectType;
		CurrentForceFieldIndex = Math::Max(CurrentForceFieldIndex - 1, 0);
		OnShieldBurstEffect.Broadcast(EffectType);
		ShowNextLayer();
	}

	private void ShowNextLayer()
	{
		ForceFields[CurrentForceFieldIndex].SetVisibility(true);
	}

	void Update(float DeltaTime)
	{
		FIslandForceFieldBubble& CurrentForceField = GetCurrentForceFieldBubble();
				
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

		// Remove current layer when depleted
		if (HasControl() && HasFinishedDepletingCurrent())
		{			
			CrumbDestroyCurrentLayer(CurrentIntegrity);
		}
	}
}
