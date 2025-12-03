class ABattlefieldLaserImpactActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent Decal;
}