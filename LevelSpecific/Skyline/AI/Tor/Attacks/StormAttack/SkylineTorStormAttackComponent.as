class USkylineTorStormAttackComponent : UActorComponent
{
	UPROPERTY()
	TArray<FSkylineTorStormAttackBeam> Beams;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UFUNCTION()
	void SpawnBeams(UNiagaraSystem NiagaraAsset, UMaterialInterface DecalMaterial)
	{
		for(auto& IterBeam : Beams)
		{
			// NIAGARA
			if(NiagaraAsset != nullptr)
			{
				auto SpawnedNiagaraComp = Niagara::SpawnLoopingNiagaraSystemAttached(
					NiagaraAsset,
					Owner.GetRootComponent()
				);

				IterBeam.VFX_Beam = SpawnedNiagaraComp;
			}

			// DECAL
			if(DecalMaterial != nullptr)
			{
				auto SpawnedDecal = Decal::SpawnDecalAtLocation(
					DecalMaterial, 
					FVector::OneVector * 250.0, 
					FVector::ZeroVector,
					FRotator::MakeFromEuler(FVector(0.0, -90.0, 0.0)),
					0.0
				);

				IterBeam.VFX_Decal = SpawnedDecal;
			}
		}
	}

	UFUNCTION()
	void UpdateBeams(bool bDrawDebug = false)
	{
		for(auto& IterBeam : Beams)
		{
			SendBeamDataToNiagara(IterBeam, bDrawDebug);
		}
	}

	UFUNCTION()
	void SendBeamDataToNiagara(FSkylineTorStormAttackBeam& Beam, bool bDrawDebug = false)
	{
		if(Beam.VFX_Beam == nullptr)
		{
			return;
		}

		Beam.VFX_Beam.SetNiagaraVariableVec3("Start", Beam.StartLocation);
		Beam.VFX_Beam.SetNiagaraVariableVec3("StartTangent", Beam.ControlPoint1);
		Beam.VFX_Beam.SetNiagaraVariableVec3("EndTangent", Beam.ControlPoint2);
		Beam.VFX_Beam.SetNiagaraVariableVec3("End", Beam.EndLocation);

		Beam.VFX_Beam.SetWorldLocation(Beam.EndLocation);

#if EDITOR
		if(bDrawDebug)
		{
			BezierCurve::DebugDraw_2CP(
				Beam.StartLocation,
				Beam.ControlPoint1,
				Beam.ControlPoint2,
				Beam.EndLocation,
				FLinearColor::LucBlue,
				10
			);
		}
#endif

	}

}

struct FSkylineTorStormAttackBeam
{
	// locations controlled by gameplay
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector ControlPoint1;
	UPROPERTY()
	FVector ControlPoint2;
	UPROPERTY()
	FVector EndLocation;

	// Event handler will assign these up on the blueprint layer
	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent VFX_Beam;
	UPROPERTY(BlueprintReadWrite)
	UDecalComponent VFX_Decal;
}
