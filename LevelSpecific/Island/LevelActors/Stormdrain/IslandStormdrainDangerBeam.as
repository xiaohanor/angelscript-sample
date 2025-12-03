UCLASS(Abstract)
class AIslandStormdrainDangerBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DangerVFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		Player.KillPlayer();
	}
};
