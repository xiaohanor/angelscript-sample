class ASummitWindTunnel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WindTunnel;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent WindFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};