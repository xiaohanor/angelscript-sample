struct FBattlefieldLaserStartedParams
{
	UPROPERTY()
	USceneComponent AttachComp;

	UPROPERTY()
	FVector EndLocation;

	UPROPERTY()
	float BeamWidth;
}

struct FBattlefieldLaserUpdateParams
{
	UPROPERTY()
	FVector EndLocation;
}

UCLASS(Abstract)
class UBattlefieldLaserEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(Category = "Setup")
	TSubclassOf<ABattlefieldLaserImpactActor> ImpactClass;

	ABattlefieldLaserImpactActor Impact;

	UPROPERTY(Category = "Setup")
	UNiagaraSystem LaserSystem;

	UPROPERTY()
	UNiagaraComponent Laser;

	USceneComponent AttachComp;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserStarted(FBattlefieldLaserStartedParams Params) 
	{
		if (Impact == nullptr)
			Impact = SpawnActor(ImpactClass, Params.EndLocation);
		
		Impact.ImpactComp.Activate();
		AttachComp = Params.AttachComp;

		if (Laser == nullptr)	
        {
            Laser = Niagara::SpawnLoopingNiagaraSystemAttached(LaserSystem, Params.AttachComp);
            Laser.SetAutoDestroy(false);
            Laser.Activate(true);
        }
		else
		{
			// Laser.ReinitializeSystem();
			Laser.Activate(true);
		}

		Laser.SetNiagaraVariableVec3("BeamEnd", Params.EndLocation);
		Laser.SetNiagaraVariableVec3("BeamStart", Params.AttachComp.WorldLocation);
		Laser.SetNiagaraVariableFloat("BeamWidth", Params.BeamWidth);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateLaserPoint(FBattlefieldLaserUpdateParams Params)
	{
		if (Laser == nullptr)
			return;

		Laser.SetNiagaraVariableVec3("BeamStart", AttachComp.WorldLocation);
		Laser.SetNiagaraVariableVec3("BeamEnd", Params.EndLocation);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserEnd()
	{
		// Laser.DeactivateImmediate();
		Laser.Deactivate();
		Impact.ImpactComp.Deactivate();
	}
}