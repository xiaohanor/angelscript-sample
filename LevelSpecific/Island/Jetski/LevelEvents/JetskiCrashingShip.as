class AJetskiCrashingShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor CrashedShip;

	UPROPERTY(DefaultComponent)
	UJetskiEventSplineFollowComponent JetskiEventSplineFollowComponent;

	UPROPERTY(EditInstanceOnly)
	AHazeNiagaraActor Explosion01;
	UPROPERTY(EditInstanceOnly)
	AHazeNiagaraActor Explosion02;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JetskiEventSplineFollowComponent.OnJetskiEventReachedSplineEnd.AddUFunction(this, n"OnCrash");
	}

	UFUNCTION(BlueprintEvent)
	void OnCrash()
	{
		
	}
};