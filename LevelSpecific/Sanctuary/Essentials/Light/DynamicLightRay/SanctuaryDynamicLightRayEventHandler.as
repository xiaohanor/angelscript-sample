UCLASS(Abstract)
class USanctuaryDynamicLightRayEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ASanctuaryDynamicLightRay LightRay;

	UPROPERTY()
	TArray<UNiagaraComponent> NiagaraComps;

	UPROPERTY()
	TArray<UNiagaraComponent> NiagaraRibbonComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightRay = Cast<ASanctuaryDynamicLightRay>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateRibbons(DeltaTime);
	}

	void UpdateRibbons(const float Dt)
	{
		if(IsLightRayActivated() == false)
		{
			// deactivate all ribbons
			for(auto IterComp : NiagaraRibbonComps)
			{
				if(IterComp == nullptr)
					continue;

				IterComp.Deactivate();
			}

			// DONE
			return;
		}

		// only activate the amount of ribbons needed.
		auto Locations = GetLightRayLocations();
		for(int i = 0; i < Locations.Num()-1; ++i)
		{
			NiagaraRibbonComps[i].Activate();
			NiagaraRibbonComps[i].SetWorldLocation(Locations[i]);
			bool bIsLastIndex = i == Locations.Num()-1;
			FVector EndPos = bIsLastIndex ? Locations[i] : Locations[i+1];
			NiagaraRibbonComps[i].SetNiagaraVariableVec3("BeamEnd", EndPos);
		}

		// deactivate emitters that are no longer needed
		for(int i = Locations.Num()-1; i < NiagaraRibbonComps.Num(); ++i)
		{
			NiagaraRibbonComps[i].Deactivate();
		}

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightRayMoved() 
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightRayActivated() 
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightRayDeactivated() 
	{
	}

	UFUNCTION(BlueprintPure)
	int GetNumOfNeededNiagaraComps()
	{
		return LightRay.MaximumBounces + 2;
	}

	UFUNCTION(BlueprintPure)
	TArray<FVector> GetLightRayLocations()
	{
		TArray<FVector> Locations;

		TArray<FSanctuaryLightRayPart> Parts;
		LightRay.GetLightRayParts(Parts);

		if(Parts.IsEmpty())
			return Locations;

		Locations.Add(Parts[0].StartLocation);

		for (int i = 0; i < Parts.Num(); i++)
		{
			Locations.Add(Parts[i].EndLocation);
		}
	
		return Locations;
	}

	UFUNCTION(BlueprintPure)
	bool IsLightRayActivated()
	{
		return LightRay.bIsActivated;
	}

};