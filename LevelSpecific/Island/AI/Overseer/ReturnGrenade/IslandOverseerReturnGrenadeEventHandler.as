
UCLASS(Abstract)
class UIslandOverseerReturnGrenadeEventHandler : UHazeEffectEventHandler
{
	TArray<USceneComponent> Sections;

	UPROPERTY()
	AIslandOverseerReturnGrenade ReturnGrenade;

	UPROPERTY()
	UNiagaraComponent VFX_FireSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ReturnGrenade = Cast<AIslandOverseerReturnGrenade>(Owner);
		ReturnGrenade.FireBar.GetChildrenComponents(false, Sections);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FireBeam_SendLocationsToNiagara();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FIslandOverseerReturnGrenadeOnLaunchEventData Data) 
	{
		// PrintToScreen("OnLaunched");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandImpact()
	{
		// PrintToScreen("OnLandImpact");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanded()
	{
		FireBeam_SpawnAndActivate();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDamaged(FIslandOverseerReturnGrenadeOnDamagedEventData Data) 
	{
		// PrintToScreen("OnLaunched");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreak(FIslandOverseerReturnGrenadeOnBreakEventData Data) 
	{
		FireBeam_Deactivate();
		// PrintToScreen("OnLaunched");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecover(FIslandOverseerReturnGrenadeOnRecoverEventData Data) 
	{
		FireBeam_SpawnAndActivate();
		// PrintToScreen("OnLaunched");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FIslandOverseerReturnGrenadeOnHitEventData Data) 
	{
		// PrintToScreen("OnLaunched");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode()
	{
		// PrintToScreen("OnLaunched");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractionStarted()
	{
		// PrintToScreen("OnLaunched");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReturn()
	{
		// PrintToScreen("OnLaunched");
	}

	void FireBeam_SpawnAndActivate()
	{
		VFX_FireSpline = Niagara::SpawnLoopingNiagaraSystemAttached(
			ReturnGrenade.VFXAsset_FireSpline,
			ReturnGrenade.FireBase
		);
		FireBeam_SendLocationsToNiagara();
	}

	void FireBeam_Deactivate()
	{
		VFX_FireSpline.DeactivateImmediate();
		VFX_FireSpline = nullptr;
	}

	void FireBeam_SendLocationsToNiagara()
	{
		if(VFX_FireSpline == nullptr)
			return;

		TArray<FVector> NiagaraSplineLocations;
		NiagaraSplineLocations.Reserve(Sections.Num() + 1);
		NiagaraSplineLocations.Add(ReturnGrenade.FireBar.GetWorldLocation());
		for(auto& IterSection : Sections)
			NiagaraSplineLocations.Add(IterSection.GetWorldLocation());
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(VFX_FireSpline, n"RuntimeSplinePoints", NiagaraSplineLocations);
	}

}

struct FIslandOverseerReturnGrenadeOnRecoverEventData
{
	UPROPERTY()
	bool bBlue;

	FIslandOverseerReturnGrenadeOnRecoverEventData(bool bIsBlue)
	{
		this.bBlue = bIsBlue;
	}
}


struct FIslandOverseerReturnGrenadeOnBreakEventData
{
	UPROPERTY()
	bool bBlue;

	UPROPERTY()
	float Duration;

	FIslandOverseerReturnGrenadeOnBreakEventData(bool bIsBlue, float InDuration)
	{
		this.bBlue = bIsBlue;
		Duration = InDuration;
	}
}

struct FIslandOverseerReturnGrenadeOnDamagedEventData
{
	UPROPERTY()
	bool bBlue;

	FIslandOverseerReturnGrenadeOnDamagedEventData(bool bIsBlue)
	{
		this.bBlue = bIsBlue;
	}
}

struct FIslandOverseerReturnGrenadeOnLaunchEventData
{
	UPROPERTY()
	FVector LaunchLocation;

	FIslandOverseerReturnGrenadeOnLaunchEventData(FVector InLaunchLocation)
	{
		LaunchLocation = InLaunchLocation;
	}
}

struct FIslandOverseerReturnGrenadeOnHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FIslandOverseerReturnGrenadeOnHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}
