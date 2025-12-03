event void FIslandForceFieldOnDepletedSignature();
event void FIslandForceFieldOnDepletingSignature(AHazeActor Instigator);
event void FIslandForceFieldOnSwitchedTypeSignature(EIslandForceFieldType NewType);

namespace IslandForceFieldComponent
{
	UFUNCTION(BlueprintPure)
	EIslandForceFieldType IslandForceFieldGetCurrentType(AActor Actor)
	{
		auto ForceFieldComp = UIslandForceFieldComponent::Get(Actor);
		devCheck(ForceFieldComp != nullptr, "Tried to get a force field component from an actor but it doesn't have one.");
		return ForceFieldComp.CurrentType;
	}

	UFUNCTION(BlueprintPure)
	bool IslandForceFieldIsReflectingBullets(AActor Actor)
	{
		auto ForceFieldComp = UIslandForceFieldComponent::Get(Actor);
		devCheck(ForceFieldComp != nullptr, "Tried to get a force field component from an actor but it doesn't have one.");
		return ForceFieldComp.IsReflectingBullets();
		
	}	
}

enum EIslandForceFieldState
{
	Full,
	Depleting,
	Depleted,
	Replenishing,
	Disabled
}

class UIslandForceFieldComponent: UPoseableMeshComponent
{
	access DebugAccess = private, UIslandForceFieldCapability (readonly);
	access ForceFieldCapabilityAccess = private, UIslandForceFieldCapability;
	access FakePunchotronForceFieldCapabilityAccess = private, UIslandFakePunchotronForceFieldCapability;

	UPROPERTY(EditAnywhere)
	TMap<EIslandForceFieldType, UMaterialInstance> ForceFieldMaterials;

	access:DebugAccess
	UPROPERTY(EditAnywhere)
	EIslandForceFieldType Type = EIslandForceFieldType::Blue;

	UPROPERTY(NotEditable)
	EIslandForceFieldType CurrentType;

	UPROPERTY(meta = (NotBlueprintCallable))
	FIslandForceFieldOnSwitchedTypeSignature OnSwitchedCurrentType;
	
	// Currently called from ForceFieldCapability.
	UPROPERTY(meta = (NotBlueprintCallable))
	FIslandForceFieldOnDepletedSignature OnDepleted;
	
	UPROPERTY(meta = (NotBlueprintCallable))
	FIslandForceFieldOnDepletingSignature OnDepleting;

	// Will toggle between red and blue type when respawning ForceField.
	UPROPERTY(EditAnywhere, Category="Respawnable ForceField")
	bool bAlternateTypes = false;

	// An auto-respawnable ForceField will be reset after cooldown.
	UPROPERTY(EditAnywhere, Category="Respawnable ForceField")
	bool bIsAutoRespawnable = false;

	UPROPERTY(EditAnywhere, Category="Respawnable ForceField")
	float AutoRespawnCooldown = 3.0;

	// Used by effect handler
	UPROPERTY(NotEditable)
	EIslandForceFieldEffectType EffectType = EIslandForceFieldEffectType::EnemyBlue;

	UMaterialInstanceDynamic MaterialInstance; // should be private
	private float CurrentIntegrity = 1.0;
	private FVector LocalBreachLocation;

	FLinearColor Color;
	FLinearColor FillColor;

	access:DebugAccess
	FHazeAcceleratedFloat AccIntegrity;
	
	private FHazeAcceleratedVector AccColor;
	
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
	const float ImpactTiming = 2.0;

	// Time for shield to disintegrate after impact
	UPROPERTY(EditAnywhere)
	private const float DisintegrationTime = 0.0;

	// Time for shield visuals to restore after respawn
	UPROPERTY(EditAnywhere)
	private const float RestorationTime = 0.0;

	private const float ImpactDuration = 0.2;
	private float ImpactTimer;

	access:DebugAccess
	EIslandForceFieldState CurrentState;
	
	// Initial state when spawned or respawned.
	UPROPERTY(EditAnywhere)
	EIslandForceFieldState InitialState = EIslandForceFieldState::Full;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto OwnerCharacter = Cast<AHazeCharacter>(Owner);
		if (OwnerCharacter == nullptr || OwnerCharacter.Mesh == nullptr)
			return;
		CurrentType = Type;
		if (!IsEnabled())
			return;
		InitializeVisuals(OwnerCharacter.Mesh, CurrentType);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChangeState(InitialState);
		if (!IsEnabled())
			return;
		EffectType = IslandForceField::GetEffectType(Owner, Type);		
	}

	bool IsEnabled()
	{		
#if EDITOR
		// Checks type for legacy reasons.
		if (Type == EIslandForceFieldType::MAX)
			devCheck (InitialState == EIslandForceFieldState::Disabled, "ForceField implies disabled, but InitialState is set to " + InitialState);
#endif
		return Type != EIslandForceFieldType::MAX || InitialState != EIslandForceFieldState::Disabled;
	}

	void InitializeVisuals(UHazeSkeletalMeshComponentBase BaseMeshComp, EIslandForceFieldType OverrideShieldColor = EIslandForceFieldType::MAX)
	{
		EIslandForceFieldType ShieldColor = OverrideShieldColor == EIslandForceFieldType::MAX ? CurrentType : OverrideShieldColor;
		SetSkinnedAssetAndUpdate(BaseMeshComp.SkeletalMeshAsset); // TODO: enforce lower LOD
		SetWorldScale3D(BaseMeshComp.GetWorldScale());

		UMaterialInstance CurrentMaterialInstance = nullptr;
		if (ForceFieldMaterials.Contains(ShieldColor) && ForceFieldMaterials[ShieldColor] != nullptr)
			CurrentMaterialInstance = ForceFieldMaterials[ShieldColor];

		devCheck(CurrentMaterialInstance != nullptr, "ForceFields CurrentMaterialInstance is not set. Specify in defaults.");				

		MaterialInstance = Material::CreateDynamicMaterialInstance(this, CurrentMaterialInstance);
		for (int i = 0; i < BaseMeshComp.SkeletalMeshAsset.GetMaterials().Num(); i++)
		{
			SetMaterial(i, MaterialInstance);
		}

		// if (MaterialInstance != nullptr)
		// {
		// 	Color = IslandForceField::GetForceFieldColor(ShieldColor);
		// 	MaterialInstance.SetVectorParameterValue(n"Color", Color);
		// 	FillColor = IslandForceField::GetForceFieldFillColor(ShieldColor);
		// 	MaterialInstance.SetVectorParameterValue(n"FillColor", FillColor);
		// }
	}

	// Alternate between red and blue.
	private void AlternateType()
	{
		if (HasControl())
		{
			devCheck(CurrentType != EIslandForceFieldType::Both && CurrentType != EIslandForceFieldType::MAX, "ForceField type is set to alternate, but CurrentType is not valid.");
			CurrentType = (CurrentType == EIslandForceFieldType::Blue) ? EIslandForceFieldType::Red : EIslandForceFieldType::Blue;
			CrumbAlternateType(CurrentType);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbAlternateType(EIslandForceFieldType NewType)
	{
		CurrentType = NewType;
		auto OwnerCharacter = Cast<AHazeCharacter>(Owner);
		OnSwitchedCurrentType.Broadcast(CurrentType);
		InitializeVisuals(OwnerCharacter.Mesh);

		FIslandForceSwitchTypeParams Params;
		Params.ForceFieldOwner = Cast<AHazeActor>(Owner);
		Params.NewForceFieldType = CurrentType;
		UIslandForceFieldEffectHandler::Trigger_OnForceFieldSwitchedType(Cast<AHazeActor>(Owner), Params);
		UIslandForceFieldPlayerEffectHandler::Trigger_OnForceFieldSwitchedType(Game::Mio, Params);
		UIslandForceFieldPlayerEffectHandler::Trigger_OnForceFieldSwitchedType(Game::Zoe, Params);
	}

	bool IsReflectingBullets()
	{
		return CurrentState == EIslandForceFieldState::Full;
	}

	bool IsDepleted() const
	{
		return CurrentState == EIslandForceFieldState::Depleted;
	}

	// Forcefield is already gone, but visuals are still running.
	bool IsDepleting() const
	{
		return CurrentState == EIslandForceFieldState::Depleting;
	}

	float GetIntegrity() const property
	{
		return CurrentIntegrity;
	}

	bool IsFull()
	{
		return CurrentState == EIslandForceFieldState::Full;
	}

	bool IsDamaged()
	{
		return !IsFull();
	}

	bool IsReplenishing()
	{
		return CurrentState == EIslandForceFieldState::Replenishing;
	}

	
	void Replenish(float ReplenishAmount)
	{
		if (IsFull())
			return;
		// Do not replenish if being depleted, CurrentIntegrity will be restored when ForceField is respawned.
		if (IsDepleting())
			return;
		
		CurrentIntegrity += ReplenishAmount;
		CurrentIntegrity = Math::Min(CurrentIntegrity, 1.0);
	}

	private void RespawnForceField()
	{
		if (bAlternateTypes)
			AlternateType();
			
		RestoreIntegrity();
		//LocalBreachLocation = WorldTransform.InverseTransformPosition(Owner.ActorLocation); 
	}

	access:ForceFieldCapabilityAccess
	UFUNCTION(CrumbFunction)
	void CrumbRespawnForceField()
	{
		RespawnForceField();
	}

	void Impact(FVector Location)
	{
		FIslandForceFieldImpactParams Params;
		Params.Location = Location;		
		Params.ForceFieldType = EffectType;
		
		UIslandForceFieldEffectHandler::Trigger_OnForceFieldImpact(Cast<AHazeActor>(Owner), Params);

		ImpactTimer = ImpactDuration;
		AccColor.Value = FVector(100, 100, 100);
	}


	void TakeDamage(float Damage, FVector WorldDamageLocation, AHazeActor Instigator, bool bAlwaysUpdateLocation = false)
	{
		if (IsFull() || bAlwaysUpdateLocation)
			LocalBreachLocation = WorldTransform.InverseTransformPosition(WorldDamageLocation);

		CurrentIntegrity -= Damage;
		CurrentIntegrity = Math::Clamp(CurrentIntegrity, 0, 1.0);
		if (CurrentState != EIslandForceFieldState::Depleting)
		{
			ChangeState(EIslandForceFieldState::Depleting);
			OnDepleting.Broadcast(Instigator);
		}
	}

	void TriggerBurstEffect()
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
		CurrentType = Type;
		if (InitialState == EIslandForceFieldState::Depleted || InitialState == EIslandForceFieldState::Depleting)
			CurrentIntegrity = 0.0;
		else
			CurrentIntegrity = 1.0;
		AccIntegrity.SnapTo(CurrentIntegrity);
		ChangeState(InitialState);
		SetScalarParameterValueOnMaterials(n"Radius", 0.0);
		auto OwnerCharacter = Cast<AHazeCharacter>(Owner);
		if (OwnerCharacter != nullptr)
			InitializeVisuals(OwnerCharacter.Mesh);
	}

	void RestoreIntegrity()
	{
		CurrentIntegrity = 1.0;
		ChangeState(EIslandForceFieldState::Replenishing);
	}

	access:FakePunchotronForceFieldCapabilityAccess
	void SetIntegrity(float _Integrity)
	{
		CurrentIntegrity = _Integrity;
		AccIntegrity.SnapTo(CurrentIntegrity);
	}

	private void ChangeState(EIslandForceFieldState NewState)
	{
		CurrentState = NewState;
	}

	private float ReachedValueTolerance = 0.1;
	void UpdateVisuals(float DeltaTime)
	{	
		float Duration;
		if (CurrentState == EIslandForceFieldState::Full)
		{
			AccIntegrity.SnapTo(1.0);
		}
		else if (CurrentState == EIslandForceFieldState::Depleting)
		{
			Duration = DisintegrationTime;
			AccIntegrity.AccelerateTo(CurrentIntegrity, Duration, DeltaTime);

			if (AccIntegrity.Value < ReachedValueTolerance)
			{
				ChangeState(EIslandForceFieldState::Depleted);
			}
		}
		else if (CurrentState == EIslandForceFieldState::Depleted)
		{
			AccIntegrity.SnapTo(0.0);
		}
		else if (CurrentState == EIslandForceFieldState::Replenishing)
		{
			Duration = RestorationTime;
			AccIntegrity.AccelerateTo(CurrentIntegrity, Duration, DeltaTime);
			if (AccIntegrity.Value > 1.0 - ReachedValueTolerance)
			{				
				ChangeState(EIslandForceFieldState::Full);
			}
		}		
		
		// Update vfx
		// if (AccIntegrity.Value < 1.0 - SMALL_NUMBER)
		// {
		// 	float RadiusScaleFactor = 1.5;
		// 	float Radius = (1.0 - AccIntegrity.Value);
		// 	Radius *= BoundsRadius * RadiusScaleFactor;
		// 	SetScalarParameterValueOnMaterials(n"Radius", Radius);
		// 	SetVectorParameterValueOnMaterials(n"DissolvePoint", WorldTransform.TransformPosition(LocalBreachLocation));
		// }	


		if (!bHasBulletResponse)
			return;

		// Handle bullet impact colours
		if(ImpactTimer > 0)
		{
			ImpactTimer -= DeltaTime;

			if(ImpactTimer > 0)
			{
				AccColor.AccelerateTo(FVector(Color.R, Color.G, Color.B), ImpactDuration, DeltaTime);
			}
			else
			{
				AccColor.Value = FVector(Color.R, Color.G, Color.B);
			}

			SetVectorParameterValueOnMaterials(n"Color", AccColor.Value);
		}
	}


	UFUNCTION(DevFunction)
	void DevTakeForceFieldDamageLight()
	{
		TakeDamage(0.1, Cast<AHazeActor>(Owner).ActorCenterLocation, Cast<AHazeActor>(Owner));
	}
	
	UFUNCTION(DevFunction)
	void DevTakeForceFieldDamageHeavy()
	{
		TakeDamage(1.0, Cast<AHazeActor>(Owner).ActorCenterLocation, Cast<AHazeActor>(Owner));
	}
}
