event void FOnStormSiegeMetalDestroyed(AStormSiegeMetalFortification DestroyedMetal);
event void FOnStormSiegeMetalRegrown();

class AStormSiegeMetalFortification : AHazeActor
{
	UPROPERTY()
	FOnStormSiegeMetalDestroyed OnStormSiegeMetalDestroyed;

	UPROPERTY()
	FOnStormSiegeMetalRegrown OnStormSiegeMetalRegrown;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MainMesh;
	default MainMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonAcidAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MetalFortRegrowCapability"); 

	UPROPERTY()
	UStormSiegeMetalFortificationSettings DefaultSettings;
	UStormSiegeMetalFortificationSettings Settings;

	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem OwningGem;

	TArray<UStaticMeshComponent> MeshComps;
	TArray<FVector> OriginalMeshPositions;
	TArray<UMetalFortMovingStaticMeshComponent> MetalMeshes;
	float ImpulseForce = 65000.0;
	bool bMelted;
	bool bPermaDestroyed;

	UPROPERTY()
	float DestructionScale = 1.0;

	UPROPERTY()
	bool bHideMeshes = true;

	UPROPERTY()
	bool bCanRegrow = true;

	int HitCount;

	float DissovleStart = -0.1;
	float DissolveTarget = 0.8;
	float CurrentDissolve;

	TArray<UMaterialInstanceDynamic> MeltMaterials;
	UMaterialInstanceDynamic MeltMaterialMainMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MetalMeshes);
		MainMesh.SetScalarParameterValueOnMaterials(n"DissolveStep", DissovleStart);
		CurrentDissolve = DissovleStart;

		if (DefaultSettings != nullptr)
			ApplyDefaultSettings(DefaultSettings);

		Settings = UStormSiegeMetalFortificationSettings::GetSettings(this);

		GetComponentsByClass(MeshComps);

		if (bHideMeshes)
		{
			for (UStaticMeshComponent Mesh : MeshComps)
			{
				if (Mesh == MainMesh)
					continue;

				if (Cast<UMetalFortMovingStaticMeshComponent>(Mesh) != nullptr)
					continue;

				Mesh.SetHiddenInGame(true);
				OriginalMeshPositions.Add(Mesh.WorldLocation);
			}
		}

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			if (Mesh == MainMesh)
				continue;

			UMaterialInstanceDynamic NewMeltMat = Mesh.CreateDynamicMaterialInstance(0);
			Mesh.SetMaterial(0, NewMeltMat);
			MeltMaterials.Add(NewMeltMat);
		}

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		if (OwningGem != nullptr)
			OwningGem.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");

		MeltMaterialMainMesh = MainMesh.CreateDynamicMaterialInstance(0);
		MainMesh.SetMaterial(0, MeltMaterialMainMesh);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bMelted && CurrentDissolve > DissovleStart)
		{
			CurrentDissolve = Math::FInterpConstantTo(CurrentDissolve, DissovleStart, DeltaSeconds, 0.45);
			MainMesh.SetScalarParameterValueOnMaterials(n"DissolveStep", CurrentDissolve);
		}
	}
	
	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		if (bPermaDestroyed)
			return;
		
		bPermaDestroyed = true;

		if (!bMelted && HasControl())
			Crumb_DestroyStormSiegeMetal();
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (bMelted)
			return;
		
		if (HitCount == 0)
		{	
			FStormSiegeMetalAcidifiedParams Params;
			Params.AttachComp = MeshRoot;
			UStormSiegeMetalFortificationEffectHandler::Trigger_OnMetalAcidifiedActivate(this, Params);
		}

		HitCount++;
		float BlendMelt = HitCount;
		BlendMelt /= 4.0;

		if (MeltMaterialMainMesh != nullptr)
		{
			MeltMaterialMainMesh.SetScalarParameterValue(n"BlendMelt", BlendMelt);
		}

		for (UMaterialInstanceDynamic Mat : MeltMaterials)
		{
			Mat.SetScalarParameterValue(n"BlendMelt", BlendMelt);
		}

		if (HitCount < Settings.HitCount)
			return;

		bMelted = true;

		if (HasControl())
			Crumb_DestroyStormSiegeMetal();
	}

	void RegrowFort()
	{
		if (OwningGem == nullptr)
			return;

		if (bPermaDestroyed)
			return;
		
		MeltMaterialMainMesh.SetScalarParameterValue(n"BlendMelt", 0.0);

		for (UMaterialInstanceDynamic Mat : MeltMaterials)
		{
			Mat.SetScalarParameterValue(n"BlendMelt", 0.0);
		}

		bMelted = false;
		HitCount = 0;
		MainMesh.SetHiddenInGame(false);

		for (UMetalFortMovingStaticMeshComponent MetalMesh : MetalMeshes)
			MetalMesh.SetHiddenInGame(false);

		int CurrentIndex = 0;

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			if (Mesh == MainMesh)
				continue;

			if (Cast<UMetalFortMovingStaticMeshComponent>(Mesh) != nullptr)
				continue;

			Mesh.SetSimulatePhysics(false);
			Mesh.SetHiddenInGame(true);
			Mesh.WorldLocation = OriginalMeshPositions[CurrentIndex];
			CurrentIndex++;
		}

		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		AutoAimComp.Enable(this);

		FStormSiegeMetalRegrowParams Params;
		Params.Location = ActorLocation;
		UStormSiegeMetalFortificationEffectHandler::Trigger_OnMetalRegrow(this, Params);

		OnStormSiegeMetalRegrown.Broadcast();
	}

	//Crumb this
	UFUNCTION(CrumbFunction)
	void Crumb_DestroyStormSiegeMetal()
	{
		for (UStaticMeshComponent Mesh : MeshComps)
		{
			if (Mesh == MainMesh)
				continue;

			if (Cast<UMetalFortMovingStaticMeshComponent>(Mesh) != nullptr)
				continue;

			Mesh.SetHiddenInGame(false);
			Mesh.SetSimulatePhysics(true);
			FVector Impulse = (Mesh.WorldLocation - ActorLocation).GetSafeNormal() * ImpulseForce;
			Mesh.AddImpulse(Impulse);
		}

		MainMesh.SetHiddenInGame(true);

		for (UMetalFortMovingStaticMeshComponent MetalMesh : MetalMeshes)
			MetalMesh.SetHiddenInGame(true);

		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		AutoAimComp.Disable(this);

		FStormSiegeMetalDestroyedParams Params;
		Params.Location = ActorLocation;
		Params.Scale = DestructionScale;
		UStormSiegeMetalFortificationEffectHandler::Trigger_OnMetalDestroyed(this, Params);
		UStormSiegeMetalFortificationEffectHandler::Trigger_OnMetalAcidifiedDeactivate(this);
		CurrentDissolve = DissolveTarget;

		OnStormSiegeMetalDestroyed.Broadcast(this);
	}
}

class UMetalFortMovingStaticMeshComponent : UStaticMeshComponent
{

}