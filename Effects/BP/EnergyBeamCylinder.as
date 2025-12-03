UCLASS(Abstract)
class AEnergyBeamCylinder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_EnergyBeam;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent FX_EnergyShield_01;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent FX_EnergyShield_02;
	};
