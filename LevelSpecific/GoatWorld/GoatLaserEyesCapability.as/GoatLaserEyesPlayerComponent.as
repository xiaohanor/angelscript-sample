class UGoatLaserEyesPlayerComponent : UActorComponent
{
	UPROPERTY()
	FAimingSettings AimSettings;

	UPROPERTY()
	UNiagaraSystem LaserSystem;

	UPROPERTY()
	UNiagaraSystem ImpactSystem;

	UNiagaraComponent LeftLaserComp;
	UNiagaraComponent RightLaserComp;
}