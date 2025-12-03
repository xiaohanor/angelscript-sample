class USolarFlareEffectComponent : UActorComponent
{
	TArray<USolarFireStaticMesh> SolarFireArray;
	TArray<UMaterialInstanceDynamic> DynamicMats;
	TArray<USolarFireNiagaraComponent> NiagaraArray;
	USolarFlareFireWaveReactionComponent ReactComp;

	TArray<FInstigator> Disablers;

	ASolarFlareFireDonutActor SolarFlareDonutWave;
	ASolarFlareSun Sun;

	float DeactivateTime;
	float TargetOpacity;
	float OpacitySpeed;
	float DefaultOpacitySpeed = 1.25;
	float Opacity;

	bool bEffectsActive = false;
	bool bNewActive;

	bool bEnableActivation = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(SolarFireArray);
		Owner.GetComponentsByClass(NiagaraArray);

		int Index = 0;

		for (USolarFireStaticMesh Mesh : SolarFireArray)
		{
			UMaterialInstanceDynamic DynamicMat = SolarFireArray[Index].CreateDynamicMaterialInstance(0);
			Mesh.SetMaterial(0, DynamicMat);
			DynamicMats.Add(DynamicMat);
			DynamicMat.SetScalarParameterValue(n"Opacity", 0.0);
			Index++;
		}

		ReactComp = USolarFlareFireWaveReactionComponent::GetOrCreate(Owner);
		ReactComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
		ReactComp.OnSolarPreFlareImpact.AddUFunction(this, n"OnSolarPreFlareImpact");
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		bEffectsActive = true;
		bNewActive = false;
		ActivateMelt();
	}

	UFUNCTION()
	private void OnSolarPreFlareImpact()
	{
		ActivatePreMelt();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Sun == nullptr)
		{
			Sun = TListedActors<ASolarFlareSun>().GetSingle();
			Sun.OnSolarFlareActivateWave.AddUFunction(this, n"OnSolarFlareActivateWave");
			Sun.OnSolarFlareNewFlareCreated.AddUFunction(this, n"OnSolarFlareNewFlareCreated");
		}

		if (bEffectsActive && Time::GameTimeSeconds > DeactivateTime)
		{
			bEffectsActive = false;
			DeactivateMelt();
		}

		Opacity = Math::FInterpConstantTo(Opacity, TargetOpacity, DeltaSeconds, OpacitySpeed);

		for (UMaterialInstanceDynamic Mat : DynamicMats)
		{
			Mat.SetScalarParameterValue(n"Opacity", Opacity);
		}
	}

	UFUNCTION()
	private void OnSolarFlareActivateWave()
	{
		bNewActive = true;
	}

	UFUNCTION()
	private void OnSolarFlareNewFlareCreated(ASolarFlareFireDonutActor NewDonut)
	{
		SolarFlareDonutWave = NewDonut;
	}

	void ActivatePreMelt()
	{
		if (HasDisabler())
			return;

		TargetOpacity = 2.0;
		OpacitySpeed = DefaultOpacitySpeed * 0.4;
	}

	void ActivateMelt()
	{
		if (HasDisabler())
			return;

		TargetOpacity = 3.0;
		OpacitySpeed = DefaultOpacitySpeed;
		DeactivateTime = Time::GameTimeSeconds + Sun.FireDuration;
		for (USolarFireNiagaraComponent NiagaraComp : NiagaraArray)
			NiagaraComp.Activate();
	}

	void DeactivateMelt()
	{
		TargetOpacity = 0.0;
		for (USolarFireNiagaraComponent NiagaraComp : NiagaraArray)
			NiagaraComp.Deactivate();
	}

	UFUNCTION()
	void AddDisabler(FInstigator Disabler)
	{
		DeactivateMelt();
		Disablers.AddUnique(Disabler);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator Disabler)
	{
		Disablers.Remove(Disabler);
	}

	bool HasDisabler()
	{
		return Disablers.Num() > 0;
	}
}

//Holds the effect system
//SM_FlamePlane_01
//MI_ObstacleMelt_02
class USolarFireStaticMesh : UStaticMeshComponent
{
	
}

//GameplayObstacleMelt_01
class USolarFireNiagaraComponent : UNiagaraComponent
{
	default bAutoActivate = false;
}
