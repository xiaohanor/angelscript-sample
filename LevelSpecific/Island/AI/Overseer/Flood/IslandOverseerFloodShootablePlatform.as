class AIslandOverseerFloodShootablePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.ConstrainBounce = 0.025;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent MeshContainer;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UIslandRedBlueImpactCounterResponseComponent ImpactCounterResponseComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandOverseerFloodShootablePlatformDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent, Attach=MeshContainer)
	UIslandRedBlueTargetableComponent RedBlueTargetable;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInterface RedMaterial;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInterface BlueMaterial;

	UPROPERTY(EditAnywhere, Category = "Setup")
	EIslandRedBlueWeaponType Color = EIslandRedBlueWeaponType::Red;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem RedHitEffect;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem BlueHitEffect;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (ClampMin = 0))
	float MaxMoveAmount = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (ClampMin = 0))
	float LimitMoveAmount = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SpringStrength = 0.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ImpulsePerShot = 50.0;

	UPROPERTY(EditAnywhere, Category = "Flash")
	float ShotEmissiveMax = 5.0;

	UPROPERTY(EditAnywhere, Category = "Flash")
	float ShotFlashDuration = 1.0;

	UPROPERTY(EditAnywhere)
	TArray<AIslandOverseerFloodShootablePlatform> LinkedPlatforms;

	UPROPERTY(EditAnywhere)
	AIslandOverseerFloodRespawnPoint LinkedRespawn;

	UPROPERTY(EditAnywhere)
	bool bUseOutsideBoss;

	float InitialEmissiveIntensity;
	float TimeLastShot;

	TArray<UMaterialInstanceDynamic> Materials;

	bool bIsFlashing = false;
	bool bOpened;
	bool bClosed;
	float StartTime;
	float Health = 1;
	bool bWithoutEffects;

	TArray<UStaticMeshComponent> Meshes;

	int MaterialIndex = 1;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<UStaticMeshComponent> StaticMeshes;
		MeshContainer.GetChildrenComponentsByClass(UStaticMeshComponent, false, StaticMeshes);

		for(auto Mesh : StaticMeshes)
		{
			if(Color == EIslandRedBlueWeaponType::Red)
			{
				Mesh.SetMaterial(MaterialIndex, RedMaterial);
			}
			else if(Color == EIslandRedBlueWeaponType::Blue)
			{
				Mesh.SetMaterial(MaterialIndex, BlueMaterial);
			}
		}

		TranslateComp.MinX = -MaxMoveAmount;
		TranslateComp.MaxX = 0;
		TranslateComp.SpringStrength = SpringStrength;

		RedBlueTargetable.UsableByPlayers = Color == EIslandRedBlueWeaponType::Red ? EHazeSelectPlayer::Mio : EHazeSelectPlayer::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTime = Time::GameTimeSeconds;

		if(Color == EIslandRedBlueWeaponType::Red)
			ImpactCounterResponseComp.BlockImpactForColor(EIslandRedBlueWeaponType::Blue, this);
		else if(Color == EIslandRedBlueWeaponType::Blue)
			ImpactCounterResponseComp.BlockImpactForColor(EIslandRedBlueWeaponType::Red, this);

		MeshContainer.GetChildrenComponentsByClass(UStaticMeshComponent, false, Meshes);

		for(UStaticMeshComponent Mesh : Meshes)
			Materials.Add(Mesh.CreateDynamicMaterialInstance(MaterialIndex));
		InitialEmissiveIntensity = Materials[MaterialIndex].GetScalarParameterValue(n"EmissiveIntensity");
	
		ImpactCounterResponseComp.OnImpactEvent.AddUFunction(this, n"OnBeenShot");

		FVector ImpulseDir = -ActorForwardVector;
		FVector Impulse = ImpulseDir * MaxMoveAmount * 5;

		// if (bUseOutsideBoss)
		Close();
		
		FauxPhysics::ApplyFauxImpulseToActor(this, Impulse);
		
		if(LinkedRespawn != nullptr)
			LinkedRespawn.AddActorDisable(this);

		RedBlueTargetable.SetUsableByPlayers(Color == EIslandRedBlueWeaponType::Red ? EHazeSelectPlayer::Mio : EHazeSelectPlayer::Zoe);

		TranslateComp.OnConstraintHit.AddUFunction(this, n"ConstraintHit");
	}

	UFUNCTION()
	private void ConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(bOpened && !bWithoutEffects)
			UIslandOverseerFloodShootablePlatformEventHandler::Trigger_OnRetractCompleted(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bClosed)
			return;

		if(bIsFlashing)
			HandleFlashing();

		if(Health <= 0)
			CompletelyOpen(false);
	}

	void CompletelyOpen(bool _bWithoutEffects)
	{
		if(bOpened)
			return;
		bOpened = true;

		if(LinkedRespawn != nullptr)
		{
			LinkedRespawn.RemoveActorDisable(this);
			LinkedRespawn.RevealedActivate();
		}
		
		FVector ImpulseDir = -ActorForwardVector;
		FVector Impulse = ImpulseDir * MaxMoveAmount * 5;
		FauxPhysics::ApplyFauxImpulseToActor(this, Impulse);
		AddActorCollisionBlock(this);
		RedBlueTargetable.SetUsableByPlayers(EHazeSelectPlayer::None);

		bWithoutEffects = _bWithoutEffects;
		if(bWithoutEffects)
			UIslandOverseerFloodShootablePlatformEventHandler::Trigger_OnRetractStarted(this);
	}

	private void HandleFlashing()
	{
		const float TimeSinceShot = Time::GetGameTimeSince(TimeLastShot);
		if(TimeSinceShot >= ShotFlashDuration)
		{
			bIsFlashing = false;
			for(auto Material : Materials)
				Material.SetScalarParameterValue(n"EmissiveIntensity", InitialEmissiveIntensity);
		}
		else
		{
			const float AdditionalEmissiveIntensity = Math::Sin((TimeSinceShot * PI) / ShotFlashDuration) * ShotEmissiveMax;
			for(auto Material : Materials)
				Material.SetScalarParameterValue(n"EmissiveIntensity", InitialEmissiveIntensity + AdditionalEmissiveIntensity);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBeenShot(FIslandRedBlueImpactResponseParams Data)
	{
		if(!bClosed)
			return;

		Health -= 0.1 * Data.ImpactDamageMultiplier;
		FVector ImpulseDir = -ActorForwardVector;
		FVector Impulse = ImpulseDir * (ImpulsePerShot * Data.ImpactDamageMultiplier);
		FauxPhysics::ApplyFauxImpulseToActor(this, Impulse);

		if(!bIsFlashing)
			TimeLastShot = Time::GameTimeSeconds;
		bIsFlashing = true;

		UNiagaraSystem SystemToSpawn = Color == EIslandRedBlueWeaponType::Red ? RedHitEffect : BlueHitEffect;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SystemToSpawn, Data.ImpactLocation);

		UIslandOverseerFloodShootablePlatformEventHandler::Trigger_OnHit(this);
	}

	void Close()
	{
		FVector ImpulseDir = ActorForwardVector;
		FVector Impulse = ImpulseDir * MaxMoveAmount * 5;
		FauxPhysics::ApplyFauxImpulseToActor(this, Impulse);
		bClosed = true;
	}
};

#if EDITOR
class UIslandOverseerFloodShootablePlatformDummyComponent : UActorComponent {};

class UIslandOverseerFloodShootablePlatformComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandOverseerFloodShootablePlatformDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UIslandOverseerFloodShootablePlatformDummyComponent>(Component);
		if(Comp == nullptr)
		 	return;
		auto Platform = Cast<AIslandOverseerFloodShootablePlatform>(Component.Owner);
		if(Platform == nullptr)
			return;
		FBox BoundingBox = Platform.GetActorLocalBoundingBox(true, false);
		FVector Center = Platform.ActorTransform.TransformPosition(BoundingBox.Center);
		FVector MoveAmount = (-Platform.ActorForwardVector * Platform.MaxMoveAmount) * Platform.ActorScale3D;
		FVector LimitAmount = (-Platform.ActorForwardVector * Platform.LimitMoveAmount) * Platform.ActorScale3D;
		FVector MaxLocation = Center + MoveAmount;
		FVector LimitLocation = Center + LimitAmount;
		FVector Extent = BoundingBox.Extent * Platform.ActorScale3D;

		TArray<UStaticMeshComponent> StaticMeshes;
		Platform.MeshContainer.GetChildrenComponentsByClass(UStaticMeshComponent, false, StaticMeshes);
		DrawWireBox(MaxLocation, Extent
			, Platform.ActorQuat, FLinearColor::Purple, 5);
		DrawWireBox(LimitLocation, Extent*1.1
			, Platform.ActorQuat, FLinearColor::Teal, 5);
		DrawWorldString("Max Location", MaxLocation + Extent, FLinearColor::Purple, 1.5, 2000, false);
	}
}

#endif