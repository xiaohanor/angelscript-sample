

/**
 * 
 */

class UMagnetDroneVFXEventHandler : UMagnetDroneEventHandler
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_Trail_Movement;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_Trail_Attraction;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_Sparks;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_Distortion;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_Jump;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_JumpTrail;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_FailSparks;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UMaterialInterface DecalMaterial_Impact;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent SysComp_Trail_Movement;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent SysComp_Trail_Attraction;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent SysComp_Sparks;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent SysComp_Distortion;

	UPROPERTY(BlueprintReadWrite)
	UDecalComponent	DecalComp_Impact;

	UPROPERTY(BlueprintReadWrite)
	bool bDoOnceTriggered = false;

	UPROPERTY(BlueprintReadWrite)
	float AttractionTimeRemaining = 0.0;

	UPROPERTY(BlueprintReadWrite)
	float TimeUntilArrival = 0.0;

	UPROPERTY(BlueprintReadWrite)
	UMaterialInstanceDynamic DynamicMat;

	UPROPERTY(BlueprintReadWrite)
	UMaterialInstanceDynamic DynamicMatForDecal;

	UPROPERTY(BlueprintReadWrite)
    UNiagaraComponent SysComp_JumpTrail;

	UFUNCTION(BlueprintPure)
	float GetDroneMovementSpeed() const
	{
		return DroneComp.MoveComp.GetVelocity().Size();
	}

	UFUNCTION(BlueprintPure)
	float GetDroneMeshDiameter() const
	{
		return DroneComp.DroneMesh.GetBoundsRadius() * 2;
	}

	UFUNCTION(BlueprintPure)
	float GetDroneMeshRadius() const
	{
		return DroneComp.DroneMesh.GetBoundsRadius();
	}
}
