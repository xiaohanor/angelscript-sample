UCLASS(Abstract)
class AMeltdownBossPhaseTwoBat : AHazeActor
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> BatShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect BatFF;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UMeltdownBossObjectFadeComponent ObjectFade;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ObjectFade.Meshes.Add(Mesh);
	}
};