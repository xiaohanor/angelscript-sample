UCLASS(Abstract)
class ARedSpaceSpinningSpike : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpinningRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UDeathTriggerComponent DeathTrigger;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	float SpinSpeed = 900.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SpinningRoot.AddLocalRotation(FRotator(0.0, SpinSpeed * DeltaTime, 0.0));
	}
}

class ARedSpaceSpinningSpikeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(5.0);

	TArray<ARedSpaceSpinningSpike> AllSpikes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AllSpikes = TListedActors<ARedSpaceSpinningSpike>().Array;
	}

	UFUNCTION()
	void ShowSpikes()
	{
		for (ARedSpaceSpinningSpike Spike : AllSpikes)
		{
			Spike.SetActorHiddenInGame(false);
		}
	}

	UFUNCTION()
	void HideSpikes()
	{
		for (ARedSpaceSpinningSpike Spike : AllSpikes)
		{
			Spike.SetActorHiddenInGame(true);
		}
	}
}